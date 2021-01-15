require "dfe_sign_in_api"

class UpdateDsiUsersInDb
  include DFESignIn

  def run!
    get_response_pages.each { |page| convert_to_users(page) }
  end

  private

  def convert_to_users(dsi_users)
    dsi_users.each do |dsi_user|
      Publisher.transaction do
        publisher = Publisher.find_or_initialize_by(oid: dsi_user["userId"])

        publisher.email = dsi_user["email"]
        publisher.given_name = dsi_user["givenName"]
        publisher.family_name = dsi_user["familyName"]

        # When a user is associated with multiple organisations,
        # DfE Sign In returns 1 user object per organisation.
        # Each of these user objects has the same userId.
        urn = dsi_user.dig("organisation", "URN")
        uid = dsi_user.dig("organisation", "UID")
        la_code = la_code(dsi_user)

        school = School.find_by(urn: urn) if urn
        trust = SchoolGroup.find_by(uid: uid) if uid
        local_authority = SchoolGroup.find_by(local_authority_code: la_code) if la_code
        organisation = (school || trust || local_authority)

        if organisation
          publisher.organisations << organisation
        else
          Rollbar.log(:error, "No organisation found for oid:#{publisher.oid},urn:#{urn},uid:#{uid},la_code:#{la_code}")
        end

        # TODO: Remove dsi_data entirely once new publisher/organisation relationship is working well
        school_urns = publisher.dsi_data&.[]("school_urns") || []
        trust_uids = publisher.dsi_data&.[]("trust_uids") || []
        la_codes = publisher.dsi_data&.[]("la_codes") || []

        publisher.dsi_data = {
          school_urns: (school_urns | [urn]).compact,
          trust_uids: (trust_uids | [uid]).compact,
          la_codes: (la_codes | [la_code]).compact,
        }
        publisher.save
      end
    end
  end

  def api_response(page: 1)
    DFESignIn::API.new.users(page: page)
  end
end
