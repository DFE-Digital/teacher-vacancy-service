require "rails_helper"
RSpec.describe "Hiring staff can sign out with DfE Sign In" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before { allow(AuthenticationFallback).to receive(:enabled?).and_return(false) }

  scenario "as an authenticated user" do
    login_publisher(publisher: publisher, organisation: school)

    visit root_path

    click_on(I18n.t("nav.sign_out"))

    within(".govuk-header__navigation") { expect(page).to have_content(I18n.t("nav.for_schools")) }
    expect(page).to have_content(I18n.t("devise.sessions.signed_out"))
  end
end
