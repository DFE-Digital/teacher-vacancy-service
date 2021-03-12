module AuthHelpers
  def login_publisher(publisher:, organisation:)
    page.set_rack_session(publisher_organisation_id: organisation.id)
    login_as(publisher, scope: :publisher)
  end

  def stub_authentication_step(organisation_id: "939eac36-0777-48c2-9c2c-b87c948a9ee0",
                               school_urn: "110627", trust_uid: nil, la_code: nil,
                               email: "an-email@example.com")
    category = "001" if school_urn.present?
    category = "010" if trust_uid.present?
    category = "002" if la_code.present?
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      provider: "dfe",
      uid: "161d1f6a-44f1-4a1a-940d-d1088c439da7",
      info: {
        email: email,
      },
      extra: {
        raw_info: {
          organisation: {
            id: organisation_id,
            urn: school_urn,
            uid: trust_uid,
            category: { id: category },
            establishmentNumber: la_code,
          },
        },
      },
    )
  end

  def stub_authorisation_step(organisation_id: "939eac36-0777-48c2-9c2c-b87c948a9ee0",
                              fixture_file: "dfe_sign_in_authorisation_response.json")
    user_id = "161d1f6a-44f1-4a1a-940d-d1088c439da7"
    authorisation_response = File.read(Rails.root.join("spec", "fixtures", fixture_file))

    stub_request(
      :get,
      "https://test-url.local/services/test-service-id/organisations/#{organisation_id}/users/#{user_id}",
    ).to_return(body: authorisation_response, status: 200)
  end

  def stub_authorisation_step_with_not_found
    authorisation_response = File.read(
      Rails.root.join("spec/fixtures/dfe_sign_in_missing_authorisation_response.html"),
    )

    stub_request(
      :get,
      "https://test-url.local/services/test-service-id/organisations/939eac36-0777-48c2-9c2c-b87c948a9ee0/users/161d1f6a-44f1-4a1a-940d-d1088c439da7",
    ).to_return(body: authorisation_response, status: 404)
  end

  def stub_authorisation_step_with_external_error
    authorisation_response = File.read(
      Rails.root.join("spec/fixtures/dfe_sign_in_authorisation_external_error.json"),
    )

    stub_request(
      :get,
      "https://test-url.local/services/test-service-id/organisations/939eac36-0777-48c2-9c2c-b87c948a9ee0/users/161d1f6a-44f1-4a1a-940d-d1088c439da7",
    ).to_return(body: authorisation_response, status: 500)
  end

  def stub_sign_in_with_multiple_organisations(user_id: "161d1f6a-44f1-4a1a-940d-d1088c439da7",
                                               fixture_file: "dfe_sign_in_user_organisations_response.json")

    authorisation_response = File.read(Rails.root.join("spec", "fixtures", fixture_file))

    stub_request(
      :get,
      "https://test-url.local/users/#{user_id}/organisations",
    ).to_return(body: authorisation_response, status: 200)
  end

  def stub_sign_in_with_single_organisation(user_id: "some-user-id",
                                            fixture_file:
                                            "dfe_sign_in_user_user_organisations_response_with_single.json")
    authorisation_response = File.read(Rails.root.join("spec", "fixtures", fixture_file))

    stub_request(
      :get,
      "https://test-url.local/users/#{user_id}/organisations",
    ).to_return(body: authorisation_response, status: 200)
  end

  def sign_in_publisher
    visit new_publisher_session_path
    within("form.publisher-sign-in") { click_on I18n.t("buttons.sign_in") }
  end

  def stub_accepted_terms_and_conditions
    create(:publisher, oid: "161d1f6a-44f1-4a1a-940d-d1088c439da7", accepted_terms_at: 1.day.ago)
  end
end
