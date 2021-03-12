require "rails_helper"

RSpec.describe "Jobseekers can add employment history to their job application" do
  let(:jobseeker) { create(:jobseeker) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:organisation) { create(:school) }
  let(:job_application) { create(:job_application, :status_draft, jobseeker: jobseeker, vacancy: vacancy) }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    login_as(jobseeker, scope: :jobseeker)
  end

  describe "employment history" do
    context "when completing a job application" do
      it "allows jobseekers to add a current role" do
        visit jobseekers_job_application_build_path(job_application, :employment_history)
        click_on I18n.t("buttons.add_role")
        validates_step_complete
        fill_in_current_role
        expect { click_on I18n.t("jobseekers.job_applications.details.form.employment_history.save") }
          .to change { job_application.employment_history.count }.by(1)
        expect(page).to have_content("The Best Teacher")
      end

      it "allows jobseekers to add employment history" do
        visit jobseekers_job_application_build_path(job_application, :employment_history)
        click_on I18n.t("buttons.add_role")
        validates_step_complete
        fill_in_employment_history
        expect { click_on I18n.t("jobseekers.job_applications.details.form.employment_history.save") }
          .to change { job_application.employment_history.count }.by(1)
        expect(page).to have_content("The Best Teacher")
        expect(page).to have_content(Date.new(2020, 0o7, 30).to_s)
      end

      it "allows jobseekers to add gaps in employment" do
        visit jobseekers_job_application_build_path(job_application, :employment_history)
        choose "Yes", name: "jobseekers_job_application_employment_history_form[gaps_in_employment]"
        fill_in "jobseekers_job_application_employment_history_form[gaps_in_employment_details]", with: "Some details about gaps in employment"
        click_on I18n.t("buttons.save_as_draft")
        expect(job_application.reload.application_data["gaps_in_employment"]).to eq("yes")
        expect(job_application.reload.application_data["gaps_in_employment_details"]).to eq("Some details about gaps in employment")
      end

      context "when there is at least one role" do
        let(:role) do
          { organisation: "A school",
            job_title: "Teacher",
            main_duties: "Lots of different duties",
            "started_on(1i)": "2020",
            "started_on(2i)": "01",
            "started_on(3i)": "01",
            current_role: "yes" }
        end

        before do
          job_application.job_application_details.create(details_type: "employment_history", data: role)
          visit jobseekers_job_application_build_path(job_application, :employment_history)
        end

        it "allows jobseekers to delete employment history" do
          expect { click_on "Delete" }.to change { job_application.employment_history.count }.by(-1)
          expect(page).to have_content(I18n.t("messages.jobseekers.job_applications.employment_history.deleted"))
          expect(page).not_to have_content("Teacher")
        end

        it "allows jobseekers to edit employment history" do
          click_on "Edit"
          fill_in "School or other organisation", with: ""
          validates_step_complete
          fill_in "School or other organisation", with: "A different school"
          expect { click_on I18n.t("jobseekers.job_applications.details.form.employment_history.save") }
            .to change { job_application.employment_history.first.data["organisation"] }
            .from("A school").to("A different school")
        end
      end
    end
  end

  def validates_step_complete
    click_on I18n.t("jobseekers.job_applications.details.form.employment_history.save")
    expect(page).to have_content("There is a problem")
  end
end
