require "rails_helper"

RSpec.describe "School viewing public listings" do
  def set_up_omniauth_config
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:default] = nil
    OmniAuth.config.mock_auth[:dfe] = nil
  end

  before do
    OmniAuth.config.test_mode = true
  end

  after(:each) do
    set_up_omniauth_config
  end

  let!(:school) { create(:school, urn: "110627") }

  context "when signed in with DfE Sign In" do
    before do
      stub_accepted_terms_and_conditions
      stub_authentication_step(school_urn: "110627")
      stub_authorisation_step
      stub_sign_in_with_multiple_organisations
      allow(AuthenticationFallback).to receive(:enabled?) { false }
    end

    scenario "A signed in school publisher sees a link back to their own dashboard when viewing public listings" do
      visit root_path

      sign_in_publisher

      link_to_dashboard_is_visible_to_publishers?
    end
  end

  def link_to_dashboard_is_visible_to_publishers?
    expect(page).to have_content(school.name)
    within(".govuk-header__navigation") { expect(page).to have_content(I18n.t("nav.school_page_link")) }

    click_on(I18n.t("app.title"))
    expect(page).to have_content(I18n.t("jobs.heading"))

    click_on(I18n.t("nav.school_page_link"), match: :first)
    expect(page).to have_content(school.name)
  end
end
