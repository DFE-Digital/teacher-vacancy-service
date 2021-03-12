class Publishers::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  PUBLISHER_CATEGORIES = {
    "001" => :school,
    "002" => :local_authority,
    "010" => :multi_academy_trust,
  }.freeze

  skip_before_action :verify_authenticity_token, only: :dfe

  def new
    # This is defined by the class name of our Omniauth strategy
    redirect_to "/auth/dfe"
  end

  def dfe
    perform_dfe_sign_in_authorisation
  end

  def failure
    redirect_to root_path
  end

  private

  def auth_hash
    request.env["omniauth.auth"]
  end

  def user_id
    auth_hash["uid"]
  end

  def identifier
    auth_hash["info"]["email"]
  end

  def publisher_category
    # In organisation['category'], DSI provides an 'id' and a 'name' attribute.
    # The mapping is documented in this table:
    # https://github.com/david-mears-dfe/login.dfe.public-api/blob/patch-1/README.md#organisation-categories
    # I am using the id as I imagine that is more stable than the name.
    category_id = auth_hash.dig("extra", "raw_info", "organisation", "category", "id")
    PUBLISHER_CATEGORIES[category_id]
  end

  def school_urn
    auth_hash.dig("extra", "raw_info", "organisation", "urn")
  end

  def trust_uid
    auth_hash.dig("extra", "raw_info", "organisation", "uid")
  end

  def local_authority_code
    # All organisations have an establishmentNumber, but we only want this for identifying LAs by.
    auth_hash.dig("extra", "raw_info", "organisation", "establishmentNumber")
  end

  def organisation_id
    auth_hash.dig("extra", "raw_info", "organisation", "id")
  end

  def id_token
    auth_hash.dig("credentials", "id_token")
  end

  def perform_dfe_sign_in_authorisation
    authorisation = Authorisation.new(organisation_id: organisation_id, user_id: user_id)
    authorisation.call
    check_authorisation(authorisation)
  end

  def check_authorisation(authorisation_permissions)
    if authorisation_permissions.authorised? && organisation_id_present? && allowed_user?
      sign_in_publisher
      trigger_sign_in_event(:success, :dsi, user_id)
      redirect_to organisation_path
    else
      trigger_sign_in_event(:failure, :dsi, user_id)
      @identifier = identifier
      render "not_authorised"
    end
  end

  def sign_in_publisher
    publisher = Publisher.find_or_create_by(oid: user_id)
    organisation = organisation_from_request
    OrganisationPublisher.find_or_create_by(organisation_id: organisation.id, publisher_id: publisher.id)

    sign_in(publisher)
    sign_out(:jobseeker)
    session.update(publisher_dsi_token: id_token, publisher_organisation_id: organisation.id)
    use_school_group_if_available
  end

  def organisation_from_request
    case publisher_category
    when :school
      School.find_by!(urn: school_urn)
    when :local_authority
      SchoolGroup.find_by!(local_authority_code: local_authority_code)
    when :multi_academy_trust
      SchoolGroup.find_by!(uid: trust_uid)
    end
  end

  def redirect_for_fallback_authentication
    redirect_to new_auth_email_path if AuthenticationFallback.enabled?
  end

  def organisation_id_present?
    school_urn.present? || trust_uid.present? || local_authority_code.present?
  end

  def allowed_user?
    school_urn.present? || trust_uid.present? || (local_authority_code.present? && allowed_la_user?)
  end

  def allowed_la_user?
    return true unless Rails.configuration.enforce_local_authority_allowlist

    Rails.configuration.allowed_local_authorities.include?(local_authority_code)
  end

  def use_school_group_if_available
    publisher = Publisher.find_by(email: identifier)
    publisher_trusts = publisher&.dsi_data&.fetch("trust_uids", [])
    publisher_local_authorities = publisher&.dsi_data&.fetch("la_codes", [])
    return unless publisher_trusts&.any? || publisher_local_authorities&.any?

    school = School.find_by(urn: school_urn)
    school_group = school&.school_groups&.first
    return unless school_group

    session.update(publisher_organisation_id: school_group.id) if publisher_trusts.include?(school_group.uid) || publisher_local_authorities.include?(school_group.local_authority_code)
  end

  def trigger_sign_in_event(success_or_failure, sign_in_type, publisher_oid = nil)
    request_event.trigger(
      :publisher_sign_in_attempt,
      user_anonymised_publisher_id: StringAnonymiser.new(publisher_oid),
      success: success_or_failure == :success,
      sign_in_type: sign_in_type,
    )
  end
end
