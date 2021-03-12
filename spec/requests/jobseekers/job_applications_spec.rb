require "rails_helper"

RSpec.describe "Job applications", type: :request do
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: build(:school) }]) }
  let(:jobseeker) { create(:jobseeker) }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    sign_in(jobseeker, scope: :jobseeker)
  end

  describe "GET #new" do
    it "triggers a `vacancy_apply_clicked` event" do
      expect { get new_jobseekers_job_job_application_path(vacancy.id) }
        .to have_triggered_event(:vacancy_apply_clicked)
        .and_data(vacancy_id: vacancy.id)
    end

    context "when a job application for the job already exists" do
      let!(:job_application) { create(:job_application, jobseeker: jobseeker, vacancy: vacancy) }

      it "redirects to `jobseekers_job_applications_path`" do
        expect(get(new_jobseekers_job_job_application_path(vacancy.id))).to redirect_to(jobseekers_job_applications_path)
      end
    end
  end

  describe "POST #create" do
    context "when a job application for the job already exists" do
      let!(:job_application) { create(:job_application, jobseeker: jobseeker, vacancy: vacancy) }

      it "redirects to `jobseekers_job_applications_path`" do
        expect(post(jobseekers_job_job_application_path(vacancy.id))).to redirect_to(jobseekers_job_applications_path)
      end
    end
  end

  describe "GET #confirm_destroy" do
    context "when the application is a draft" do
      let!(:job_application) { create(:job_application, jobseeker: jobseeker, vacancy: vacancy) }

      it "shows a confirmation page" do
        expect(get(jobseekers_job_application_confirm_destroy_path(job_application.id))).to render_template(:confirm_destroy)
      end
    end

    context "when the application is not a draft" do
      let!(:job_application) { create(:job_application, :status_submitted, jobseeker: jobseeker, vacancy: vacancy) }

      it "raises an error" do
        expect { get(jobseekers_job_application_confirm_destroy_path(job_application.id)) }.to raise_error(ActionController::RoutingError, /non-draft/)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when the application is a draft" do
      let!(:job_application) { create(:job_application, jobseeker: jobseeker, vacancy: vacancy) }

      it "deletes the application" do
        expect { delete(jobseekers_job_application_path(job_application.id)) }.to change { JobApplication.count }.by(-1)
      end

      it "redirects back to the index of applications" do
        expect(delete(jobseekers_job_application_path(job_application.id))).to redirect_to(jobseekers_job_applications_path)
      end
    end

    context "when the application is not a draft" do
      let!(:job_application) { create(:job_application, :status_submitted, jobseeker: jobseeker, vacancy: vacancy) }

      it "raises an error and does not delete the application" do
        expect { delete(jobseekers_job_application_path(job_application.id)) }.to raise_error(ActionController::RoutingError, /non-draft/)
        expect(JobApplication.count).to eq(1)
      end
    end
  end
end
