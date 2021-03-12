require "rails_helper"

RSpec.describe "Jobseekers can manage their job applications" do
  let(:jobseeker) { create(:jobseeker) }
  let(:organisation) { create(:school) }

  let(:vacancy1) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:vacancy2) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:vacancy3) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:vacancy4) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }

  let(:job_applications_page) { PageObjects::Jobseekers::JobApplications::Index.new }

  before { allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true) }

  context "when logged in" do
    before { login_as(jobseeker, scope: :jobseeker) }

    context "when there are job applications" do
      let!(:draft_job_application1) { create(:job_application, updated_at: 1.day.ago, jobseeker: jobseeker, vacancy: vacancy1) }
      let!(:draft_job_application2) { create(:job_application, updated_at: 2.days.ago, jobseeker: jobseeker, vacancy: vacancy2) }
      let!(:submitted_job_application1) { create(:job_application, :status_submitted, submitted_at: 1.day.ago, jobseeker: jobseeker, vacancy: vacancy3) }
      let!(:submitted_job_application2) { create(:job_application, :status_submitted, submitted_at: 2.days.ago, jobseeker: jobseeker, vacancy: vacancy4) }

      before { job_applications_page.load }

      context "when the jobseeker views job applications" do
        it "shows draft job applications then submitted job applications" do
          expect(job_applications_page.heading).to have_content(I18n.t("jobseekers.job_applications.index.page_title"))
          expect(job_applications_page).to have_cards(count: 4)
          expect(job_applications_page.cards[0].header).to have_content(draft_job_application1.vacancy.job_title)
          expect(job_applications_page.cards[1].header).to have_content(draft_job_application2.vacancy.job_title)
          expect(job_applications_page.cards[2].header).to have_content(submitted_job_application1.vacancy.job_title)
          expect(job_applications_page.cards[3].header).to have_content(submitted_job_application2.vacancy.job_title)
        end

        it "can continue a draft application" do
          job_applications_page
            .cards(text: draft_job_application1.vacancy.job_title).first.actions
            .links(text: I18n.t("jobseekers.job_applications.index.continue_application")).first.click

          expect(current_path).to eq(jobseekers_job_application_review_path(draft_job_application1))
        end

        it "can view a submitted application" do
          job_applications_page
            .cards(text: submitted_job_application1.vacancy.job_title).first.actions
            .links(text: I18n.t("jobseekers.job_applications.index.view_application")).first.click

          expect(current_path).to eq(jobseekers_job_application_path(submitted_job_application1))
        end

        it "can delete a draft application" do
          # TODO: Do this when delete draft application functionality implemented
        end

        it "can withdraw a submitted application" do
          # TODO: Do this when withdraw submitted application functionality implemented
        end
      end
    end

    context "when there are no job applications" do
      before { job_applications_page.load }

      it "shows zero job applications" do
        expect(job_applications_page).to have_content(I18n.t("jobseekers.job_applications.index.no_job_applications"))
      end
    end
  end

  context "when logged out" do
    before { job_applications_page.load }

    it "redirects to the sign in page" do
      expect(current_path).to eq(new_jobseeker_session_path)
    end
  end
end
