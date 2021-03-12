class Publishers::SessionsController < Devise::SessionsController
  def destroy
    @publisher_dsi_token = session[:publisher_dsi_token]
    session.delete(:publisher_organisation_id)
    session.delete(:publisher_dsi_token)
    super
  end

  private

  def after_sign_out_path_for(_resource)
    return new_auth_email_path if AuthenticationFallback.enabled?

    url = URI.parse("#{ENV['DFE_SIGN_IN_ISSUER']}/session/end")
    url.query = { post_logout_redirect_uri: new_publisher_session_url, id_token_hint: @publisher_dsi_token }.to_query
    url.to_s
  end

  def after_sign_in_path_for(_resource)
    organisation_path
  end
end
