require "rails_helper"

RSpec.describe "Publishers can view a job application" do
  let(:organisation) { create(:school) }
  let(:vacancy) { create(:vacancy, :expired, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:job_application) { create(:job_application, :status_submitted, vacancy: vacancy) }
  let(:oid) { SecureRandom.uuid }

  let(:show_page) { PageObjects::Publishers::Vacancies::JobApplications::Show.new }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    stub_publishers_auth(urn: organisation.urn, oid: oid)
    show_page.load(job_id: vacancy.id, id: job_application.id)
  end

  it "shows the job application page" do
    # TODO: Complete this spec
    expect(page).to have_content("TV12345 - #{job_application.application_data['first_name']} #{job_application.application_data['last_name']}")
  end

  context "when the job application status is unsuccessful" do
    let(:job_application) { create(:job_application, :status_unsuccessful, vacancy: vacancy) }

    it "shows the correct calls to action and timeline" do
      expect(show_page.actions).not_to have_css("a", class: "govuk-button", text: I18n.t("buttons.shortlist"))
      expect(show_page.actions).not_to have_css("a", class: "govuk-button--warning", text: I18n.t("buttons.reject"))
      expect(show_page.actions).to have_css("a", class: "govuk-button--secondary", text: I18n.t("buttons.download_application"))

      expect(show_page.timeline).to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.rejected"))
      expect(show_page.timeline).not_to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.shortlisted"))
      expect(show_page.timeline).to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.submitted"))

      expect(show_page.timeline.dates(text: I18n.t("jobseekers.job_applications.status_timestamps.rejected")).first.text)
        .to include(format_date(job_application.unsuccessful_at.to_date) + I18n.t("jobs.time_at") + format_time(job_application.unsuccessful_at))
      expect(show_page.timeline.dates(text: I18n.t("jobseekers.job_applications.status_timestamps.submitted")).first.text)
        .to include(format_date(job_application.submitted_at.to_date) + I18n.t("jobs.time_at") + format_time(job_application.submitted_at))
    end
  end

  context "when the job application status is shortlisted" do
    let(:job_application) { create(:job_application, :status_shortlisted, vacancy: vacancy) }

    it "shows the correct calls to action and timeline" do
      expect(show_page.actions).not_to have_css("a", class: "govuk-button", text: I18n.t("buttons.shortlist"))
      expect(show_page.actions).to have_css("a", class: "govuk-button--warning", text: I18n.t("buttons.reject"))
      expect(show_page.actions).to have_css("a", class: "govuk-button--secondary", text: I18n.t("buttons.download_application"))

      expect(show_page.timeline).not_to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.rejected"))
      expect(show_page.timeline).to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.shortlisted"))
      expect(show_page.timeline).to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.submitted"))

      expect(show_page.timeline.dates(text: I18n.t("jobseekers.job_applications.status_timestamps.shortlisted")).first.text)
        .to include(format_date(job_application.shortlisted_at.to_date) + I18n.t("jobs.time_at") + format_time(job_application.shortlisted_at))
      expect(show_page.timeline.dates(text: I18n.t("jobseekers.job_applications.status_timestamps.submitted")).first.text)
        .to include(format_date(job_application.submitted_at.to_date) + I18n.t("jobs.time_at") + format_time(job_application.submitted_at))
    end
  end

  context "when the job application status is submitted" do
    it "shows the correct calls to action and timeline" do
      expect(show_page.actions).to have_css("a", class: "govuk-button", text: I18n.t("buttons.shortlist"))
      expect(show_page.actions).to have_css("a", class: "govuk-button--warning", text: I18n.t("buttons.reject"))
      expect(show_page.actions).to have_css("a", class: "govuk-button--secondary", text: I18n.t("buttons.download_application"))

      expect(show_page.timeline).not_to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.rejected"))
      expect(show_page.timeline).not_to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.shortlisted"))
      expect(show_page.timeline).to have_dates(text: I18n.t("jobseekers.job_applications.status_timestamps.submitted"))

      expect(show_page.timeline.dates(text: I18n.t("jobseekers.job_applications.status_timestamps.submitted")).first.text)
        .to include(format_date(job_application.submitted_at.to_date) + I18n.t("jobs.time_at") + format_time(job_application.submitted_at))
    end
  end
end
