require "rails_helper"

RSpec.describe "Hiring staff session" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before do
    allow(AuthenticationFallback).to receive(:enabled?).and_return(false)
    login_publisher(publisher: publisher, organisation: school)
  end

  after do
    travel_back
  end

  it "expires after TIMEOUT_PERIOD and redirects to login page" do
    visit organisation_path
    click_on I18n.t("buttons.create_job")

    travel(Publisher.timeout_in + 1.minute) do
      click_on I18n.t("buttons.continue")

      expect(page).to have_content(I18n.t("devise.failure.timeout"))
    end
  end

  it "doesn't expire before TIMEOUT_PERIOD" do
    visit organisation_path
    click_on I18n.t("buttons.create_job")

    travel(Publisher.timeout_in - 1.minute) do
      click_on I18n.t("buttons.continue")

      expect(page.current_path).to eq organisation_job_build_path(Vacancy.last.id, :job_details)
    end
  end
end
