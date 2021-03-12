require "rails_helper"

RSpec.describe "School viewing vacancies" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before { login_publisher(publisher: publisher, organisation: school) }

  scenario "A school publisher sees advisory text when there are no vacancies" do
    visit organisation_path

    expect(page).to have_content(I18n.t("publishers.no_vacancies_component.heading"))
    expect(page).not_to have_css(".vacancies")
  end

  scenario "A school publisher can see a list of vacancies" do
    vacancy1 = create(:vacancy)
    vacancy1.organisation_vacancies.create(organisation: school)
    vacancy2 = create(:vacancy)
    vacancy2.organisation_vacancies.create(organisation: school)

    visit organisation_path

    expect(page).to have_content(school.name)
    expect(page).to have_content(vacancy1.job_title)
    expect(page).to have_content(vacancy2.job_title)
  end

  scenario "A draft vacancy show page shows a flash message with the status" do
    vacancy = create(:vacancy, status: "draft")
    vacancy.organisation_vacancies.create(organisation: school)

    visit organisation_job_path(vacancy.id)

    expect(page).to have_content(school.name)
    expect(page).to have_content(vacancy.job_title)
    expect(page).to have_content(I18n.t("publishers.vacancies.show.notice"))
  end

  scenario "A published vacancy show page does not show a flash message with the status" do
    vacancy = create(:vacancy, status: "published")
    vacancy.organisation_vacancies.create(organisation: school)

    visit organisation_job_path(vacancy.id)

    expect(page).to have_content(school.name)
    expect(page).to have_content(vacancy.job_title)
  end

  scenario "clicking on more information does not increment the counter" do
    vacancy = create(:vacancy, status: "published")
    vacancy.organisation_vacancies.create(organisation: school)

    visit organisation_job_path(vacancy.id)

    expect { click_on I18n.t("jobs.apply") }.not_to have_enqueued_job(PersistVacancyGetMoreInfoClickJob)
  end
end
