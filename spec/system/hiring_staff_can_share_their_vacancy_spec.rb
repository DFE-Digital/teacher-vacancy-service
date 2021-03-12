require "rails_helper"

RSpec.describe "Hiring staff can share their vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before { login_publisher(publisher: publisher, organisation: school) }

  scenario "A school can visit their page as the jobseeker would" do
    vacancy = create(:vacancy)
    vacancy.organisation_vacancies.create(organisation: school)

    visit organisation_path

    click_on(vacancy.job_title)
    click_on(I18n.t("jobs.view_public_link"))

    expected_url = URI("localhost:3000#{job_path(vacancy)}")

    expect(current_url).to match(expected_url.to_s)
    expect(page).to have_content(vacancy.job_title)
  end
end
