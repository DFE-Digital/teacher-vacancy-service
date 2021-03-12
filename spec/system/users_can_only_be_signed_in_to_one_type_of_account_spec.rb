require "rails_helper"

RSpec.describe "Users can only be signed in to one type of account" do
  let(:jobseeker) { create(:jobseeker) }
  let!(:publisher) { create(:publisher, dsi_data: dsi_data) }

  let(:school) { create(:school, urn: "110627") }
  let(:dsi_data) { { "school_urns" => [school.urn], "trust_uids" => [], "la_codes" => [] } }

  let(:authentication_fallback_enabled?) { false }

  before do
    allow(AuthenticationFallback).to receive(:enabled?).and_return(authentication_fallback_enabled?)
  end

  context "when a jobseeker is signed in" do
    before do
      login_as(jobseeker, scope: :jobseeker)
    end

    context "when email fallback is disabled" do
      let(:dsi_email_address) { Faker::Internet.email }

      before do
        OmniAuth.config.test_mode = true
        stub_accepted_terms_and_conditions
        stub_authentication_step email: dsi_email_address
        stub_authorisation_step
        stub_sign_in_with_multiple_organisations
      end

      after do
        OmniAuth.config.mock_auth[:default] = nil
        OmniAuth.config.mock_auth[:dfe] = nil
        OmniAuth.config.test_mode = false
      end

      it "signs out from the jobseeker account when signing in as a publisher using DSI" do
        visit jobseekers_account_path
        expect(page).to have_content(I18n.t("jobseekers.accounts.show.page_title"))

        visit root_path
        sign_in_publisher
        expect(page).to have_current_path(organisation_path)

        visit jobseekers_account_path
        expect(current_path).to eq(new_jobseeker_session_path)
      end
    end

    context "when email fallback is enabled" do
      let(:authentication_fallback_enabled?) { true }
      let(:login_key) do
        publisher.emergency_login_keys.create(
          not_valid_after: Time.current + Publishers::SignIn::Email::SessionsController::EMERGENCY_LOGIN_KEY_DURATION,
        )
      end

      it "signs out from the jobseeker account when signing in as a publisher using DSI" do
        visit jobseekers_account_path
        expect(page).to have_content(I18n.t("jobseekers.accounts.show.page_title"))

        visit auth_email_choose_organisation_path(login_key: login_key.id)
        expect(page).to have_current_path(organisation_path)

        visit jobseekers_account_path
        expect(current_path).to eq(new_jobseeker_session_path)
      end
    end
  end

  context "when a publisher is signed in" do
    before { login_publisher(publisher: publisher, organisation: school) }

    context "when email fallback is disabled" do
      it "signs out from the publisher account when signing in as a jobseeker" do
        visit organisation_path
        expect(current_path).to eq(organisation_path)

        visit new_jobseeker_session_path
        sign_in_jobseeker

        expect(current_path).to eq(jobseeker_root_path)

        visit organisation_path
        expect(current_path).to eq(new_publisher_session_path)
      end
    end

    context "when email fallback is enabled" do
      let(:authentication_fallback_enabled?) { true }

      it "signs out from the publisher account when signing in as a jobseeker" do
        visit organisation_path
        expect(current_path).to eq(organisation_path)

        visit new_jobseeker_session_path
        sign_in_jobseeker

        expect(current_path).to eq(jobseeker_root_path)

        visit organisation_path
        expect(current_path).to eq(new_publisher_session_path)
      end
    end
  end
end
