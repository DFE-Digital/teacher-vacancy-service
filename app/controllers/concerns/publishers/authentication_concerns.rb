module Publishers::AuthenticationConcerns
  extend ActiveSupport::Concern

  included do
    helper_method :current_organisation
  end

  def current_organisation
    @current_organisation ||= Organisation.find(session[:publisher_organisation_id])
  end

  def sign_out_publisher!
    session.delete(:publisher_organisation_id)
    session.delete(:publisher_dsi_token)
    sign_out(:publisher)
  end
end
