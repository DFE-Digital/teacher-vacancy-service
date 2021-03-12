require "rails_helper"

RSpec.describe "Jobseekers can save a job application" do
  let(:jobseeker) { create(:jobseeker) }
  let(:organisation) { create(:school) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:job_application) { create(:job_application, :status_draft, vacancy: vacancy, jobseeker: jobseeker) }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    login_as(jobseeker, scope: :jobseeker)
  end

  it "allows jobseekers to save application and go to dashboard" do
    visit jobseekers_job_application_build_path(job_application, :personal_details)
    fill_in_personal_details
    and_it_saves_the_job_application
  end

  def save_as_draft
    click_on I18n.t("buttons.save_as_draft")
  end

  def and_it_saves_the_job_application
    expect { save_as_draft }.to change { JobApplication.first.application_data }.from({}).to(
      {
        "postcode" => "F1 4KE",
        "last_name" => "Frusciante",
        "first_name" => "John",
        "phone_number" => "01234 123456",
        "town_or_city" => "Fakeopolis",
        "previous_names" => "",
        "building_and_street" => "123 Fake Street",
        "teacher_reference_number" => "AB 99/12345",
        "national_insurance_number" => "AB 12 12 12 A",
      },
    )
    expect(current_path).to eq(jobseekers_job_applications_path)
    expect(page).to have_content(I18n.t("messages.jobseekers.job_applications.saved"))
  end
end
