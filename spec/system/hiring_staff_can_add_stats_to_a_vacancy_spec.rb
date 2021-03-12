require "rails_helper"
require "sanitize"

RSpec.describe "Submitting effectiveness feedback on expired vacancies", js: true do
  let(:job_title_link_selector) { ".view-vacancy-link" }

  let(:school) { create(:school) }
  let(:publisher) { create(:publisher) }

  before do
    login_publisher(publisher: publisher, organisation: school)
    vacancy = create(:vacancy, :published_slugged)
    vacancy.organisation_vacancies.create(organisation: school)
  end

  context "when there are vacancies awaiting feedback" do
    let!(:vacancy) { create(:vacancy, :expired) }
    let!(:another_vacancy) { create(:vacancy, :expired) }
    let!(:third_vacancy) { create(:vacancy, :expired) }

    before do
      vacancy.organisation_vacancies.create(organisation: school)
      another_vacancy.organisation_vacancies.create(organisation: school)
      third_vacancy.organisation_vacancies.create(organisation: school)
    end

    scenario "hiring staff can see notice of vacancies awaiting feedback" do
      visit organisation_path

      within("div.govuk-notification--notice") do
        expect(page).to have_content("3 jobs")
      end
    end

    scenario "displays the vacancies awaiting feedback" do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      expect(page).to have_link(vacancy.job_title, href: organisation_job_path(vacancy.id))
      expect(page).to have_link(another_vacancy.job_title, href: organisation_job_path(another_vacancy.id))
      expect(page).to have_link(third_vacancy.job_title, href: organisation_job_path(third_vacancy.id))

      submit_feedback_for(vacancy)
      within("div.govuk-notification--notice") do
        expect(page).to have_content("2 jobs")
      end

      submit_feedback_for(another_vacancy)
      within("div.govuk-notification--notice") do
        expect(page).to have_content("1 job")
      end
    end

    scenario "when adding feedback, it saves feedback to the model" do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      submit_feedback_for(vacancy)

      vacancy.reload
      expect(vacancy.hired_status).to eq("hired_tvs")
      expect(vacancy.listed_elsewhere).to eq("listed_paid")
    end

    scenario "when an option is not selected in a javascript disabled browser", js: false do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      within(".card-component", text: vacancy.job_title) do
        select I18n.t("jobs.feedback.hired_status.hired_tvs"), from: "vacancy_hired_status"
        click_on I18n.t("buttons.submit")
      end

      expect(page).to have_content(I18n.t("messages.jobs.feedback.error_body"))
      expect(page).to have_content(vacancy.job_title)

      expect(page).to_not have_content(I18n.t("messages.jobs.feedback.inline_error"))

      expect(vacancy.hired_status).to eq(nil)
      expect(vacancy.listed_elsewhere).to eq(nil)
    end

    scenario "when an option is not selected in a javascript enabled browser" do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      within(".card-component", text: vacancy.job_title) do
        select I18n.t("jobs.feedback.hired_status.hired_tvs"), from: "vacancy_hired_status"
        click_on I18n.t("buttons.submit")
      end

      expect(page).to have_content(I18n.t("messages.jobs.feedback.inline_error"))
      expect(page).to have_content(vacancy.job_title)

      expect(page).to_not have_content(I18n.t("messages.jobs.feedback.error_body"))

      expect(vacancy.hired_status).to eq(nil)
      expect(vacancy.listed_elsewhere).to eq(nil)
    end

    scenario "input error styling only displays on blank selection field(s)" do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      within(".card-component", text: vacancy.job_title) do
        click_on I18n.t("buttons.submit")
      end

      expect(page).to have_content(I18n.t("messages.jobs.feedback.inline_error"), count: 2)

      within(".card-component", text: vacancy.job_title) do
        select I18n.t("jobs.feedback.hired_status.hired_tvs"), from: "vacancy_hired_status"
        click_on I18n.t("buttons.submit")

        select "--", from: "vacancy_hired_status"

        select I18n.t("jobs.feedback.listed_elsewhere.listed_paid"), from: "vacancy_listed_elsewhere"
        click_on I18n.t("buttons.submit")
      end

      expect(page).to have_content(I18n.t("messages.jobs.feedback.inline_error"), count: 1)
    end

    scenario "when all feedback has been submitted" do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      expect(page).to have_link(vacancy.job_title, href: organisation_job_path(vacancy.id))
      expect(page).to have_link(another_vacancy.job_title, href: organisation_job_path(another_vacancy.id))
      expect(page).to have_link(third_vacancy.job_title, href: organisation_job_path(third_vacancy.id))

      submit_feedback_for(vacancy)
      submit_feedback_for(another_vacancy)
      submit_feedback_for(third_vacancy)

      expect(page).not_to have_content(I18n.t("jobs.manage.awaiting_feedback.intro"))
      expect(page).not_to have_link(vacancy.job_title, href: organisation_job_path(vacancy.id))
      expect(page).not_to have_link(another_vacancy.job_title, href: organisation_job_path(another_vacancy.id))
      expect(page).not_to have_link(third_vacancy.job_title, href: organisation_job_path(third_vacancy.id))
    end

    scenario "when adding feedback to an invalid vacancy, it saves the feedback to the model" do
      invalid_starts_on_date = 10.days.ago
      invalid_vacancy = create(:vacancy, :expired, starts_on: invalid_starts_on_date)
      invalid_vacancy.organisation_vacancies.create(organisation: school)

      visit jobs_with_type_organisation_path(type: :awaiting_feedback)
      submit_feedback_for(invalid_vacancy)

      invalid_vacancy.reload
      expect(invalid_vacancy.hired_status).to eq("hired_tvs")
      expect(invalid_vacancy.listed_elsewhere).to eq("listed_paid")
    end
  end

  context "when there are no vacancies awaiting feedback" do
    scenario "hiring staff can not see notification badge" do
      visit jobs_with_type_organisation_path(type: :awaiting_feedback)

      expect(page).to have_content(I18n.t("jobs.manage.awaiting_feedback.no_jobs.no_filters"))
    end
  end

  def submit_feedback_for(vacancy)
    within(".card-component", text: vacancy.job_title) do
      select I18n.t("jobs.feedback.hired_status.hired_tvs"), from: "vacancy_hired_status"
      select I18n.t("jobs.feedback.listed_elsewhere.listed_paid"), from: "vacancy_listed_elsewhere"
      click_on I18n.t("buttons.submit")
    end

    expect(page).to have_content(
      strip_tags(I18n.t("messages.jobs.feedback.submitted_html", job_title: vacancy.job_title)),
    )
  end
end
