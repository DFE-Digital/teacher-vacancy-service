require "rails_helper"

RSpec.describe "Jobseekers can add references to their job application" do
  let(:jobseeker) { create(:jobseeker) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:organisation) { create(:school) }
  let(:job_application) { create(:job_application, :status_draft, jobseeker: jobseeker, vacancy: vacancy) }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    login_as(jobseeker, scope: :jobseeker)
  end

  describe "references" do
    context "when completing a job application" do
      it "allows jobseekers to add references" do
        visit jobseekers_job_application_build_path(job_application, :references)
        click_on I18n.t("buttons.add_reference")
        validates_step_complete
        fill_in_reference
        expect { click_on I18n.t("jobseekers.job_applications.details.form.references.save") }
          .to change { job_application.references.count }.by(1)
        expect(page).to have_content("Jim Referee")
      end

      context "when there is at least one reference" do
        let(:reference) do
          { name: "John",
            job_title: "Teacher",
            organisation: "A school",
            relationship_to_applicant: "Supervisor",
            email_address: "test@email.com",
            phone_number: "01234 567890" }
        end

        before do
          job_application.job_application_details.create(details_type: "references", data: reference)
          visit jobseekers_job_application_build_path(job_application, :references)
        end

        it "allows jobseekers to delete references" do
          expect { click_on "Delete" }.to change { job_application.references.count }.by(-1)
          expect(page).to have_content(I18n.t("messages.jobseekers.job_applications.references.deleted"))
          expect(page).not_to have_content("John")
        end

        it "allows jobseekers to edit references" do
          click_on "Edit"
          fill_in "Name", with: ""
          validates_step_complete
          fill_in "Name", with: "Jason"
          expect { click_on I18n.t("jobseekers.job_applications.details.form.references.save") }
            .to change { job_application.references.first.data["name"] }.from("John").to("Jason")
        end
      end
    end
  end

  def validates_step_complete
    click_on I18n.t("jobseekers.job_applications.details.form.references.save")
    expect(page).to have_content("There is a problem")
  end
end
