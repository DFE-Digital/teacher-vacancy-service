require "rails_helper"

RSpec.describe "Jobseekers can start a job application" do
  let(:jobseeker) { build_stubbed(:jobseeker) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: school }]) }
  let(:school) { create(:school) }
  let(:created_job_application) { JobApplication.first }
  let(:new_job_application_page) { PageObjects::Jobseekers::JobApplications::New.new }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(jobseeker_applications_enabled?)
    visit job_path(vacancy)
  end

  context "when JobseekerApplicationsFeature is enabled" do
    let(:jobseeker_applications_enabled?) { true }

    context "when the jobseeker has not applied to the job before" do
      context "when the jobseeker has an account" do
        let!(:jobseeker) { create(:jobseeker) }

        context "when the jobseeker is signed in" do
          before { login_as(jobseeker, scope: :jobseeker) }

          context "when clicking apply on the job page" do
            before { click_on I18n.t("jobseekers.job_applications.apply") }

            it "starts a job application" do
              expect(current_path).to eq(new_jobseekers_job_job_application_path(vacancy.id))
              expect(new_job_application_page.caption).to have_content(vacancy.job_title)

              expect { new_job_application_page.start_application.click }.to change { JobApplication.count }.by(1)

              expect(current_path).to eq(jobseekers_job_application_build_path(created_job_application, :personal_details))
            end
          end
        end

        context "when the jobseeker is not signed in" do
          context "when clicking apply on the job page" do
            before { click_on I18n.t("jobseekers.job_applications.apply") }

            it "starts a job application after signing in" do
              expect(current_path).not_to eq(new_jobseekers_job_job_application_path(vacancy.id))

              sign_in_jobseeker

              expect(current_path).to eq(new_jobseekers_job_job_application_path(vacancy.id))
              expect(new_job_application_page.caption).to have_content(vacancy.job_title)

              expect { new_job_application_page.start_application.click }.to change { JobApplication.count }.by(1)

              expect(current_path).to eq(jobseekers_job_application_build_path(created_job_application, :personal_details))
            end
          end
        end
      end

      context "when the jobseeker does not have an account" do
        context "when clicking apply on the job page" do
          before { click_on I18n.t("jobseekers.job_applications.apply") }

          it "starts a job application after signing up" do
            expect(current_path).not_to eq(new_jobseekers_job_job_application_path(vacancy.id))

            click_on I18n.t("jobseekers.sessions.new.no_account.link")
            sign_up_jobseeker
            visit first_link_from_last_mail

            expect(current_path).to eq(new_jobseekers_job_job_application_path(vacancy.id))
            expect(new_job_application_page.caption).to have_content(vacancy.job_title)

            expect { new_job_application_page.start_application.click }.to change { JobApplication.count }.by(1)

            expect(current_path).to eq(jobseekers_job_application_build_path(created_job_application, :personal_details))
          end
        end
      end
    end

    context "when the jobseeker has a draft application for the job" do
      context "when clicking apply on the job page" do
        let!(:jobseeker) { create(:jobseeker) }
        let!(:job_application) { create(:job_application, jobseeker: jobseeker, vacancy: vacancy) }

        before do
          login_as(jobseeker, scope: :jobseeker)
          click_on I18n.t("jobseekers.job_applications.apply")
        end

        it "redirects to job applications dashboard with correct message" do
          expect(current_path).to eq(jobseekers_job_applications_path)
          expect(page)
            .to have_content(strip_tags(I18n.t("messages.jobseekers.job_applications.already_exists.draft_html",
                                               job_title: vacancy.job_title,
                                               link: jobseekers_job_application_review_path(job_application))))
        end
      end
    end

    context "when the jobseeker has a submitted application for the job" do
      context "when clicking apply on the job page" do
        let!(:jobseeker) { create(:jobseeker) }
        let!(:job_application) { create(:job_application, :status_submitted, jobseeker: jobseeker, vacancy: vacancy) }

        before do
          login_as(jobseeker, scope: :jobseeker)
          click_on I18n.t("jobseekers.job_applications.apply")
        end

        it "redirects to job applications dashboard with correct message" do
          expect(current_path).to eq(jobseekers_job_applications_path)
          expect(page).to have_content(I18n.t("messages.jobseekers.job_applications.already_exists.submitted",
                                              job_title: vacancy.job_title))
        end
      end
    end
  end

  context "when JobseekerApplicationsFeature is disabled" do
    let(:jobseeker_applications_enabled?) { false }

    it "returns not found" do
      visit new_jobseekers_job_job_application_path(vacancy.id)
      expect(page.status_code).to eq(404)
    end
  end
end
