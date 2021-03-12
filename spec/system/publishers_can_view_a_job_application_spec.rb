require "rails_helper"

RSpec.describe "Publishers can view a job application" do
  let(:publisher) { create(:publisher) }
  let(:organisation) { create(:school) }
  let(:vacancy) { create(:vacancy, :expired, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:job_application) { create(:job_application, :status_submitted, vacancy: vacancy) }

  before do
    login_publisher(publisher: publisher, organisation: organisation)
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    visit organisation_job_job_application_path(vacancy.id, job_application.id)
  end

  it "shows the job application page" do
    # TODO: Complete this spec
    expect(page).to have_content("TV12345 - #{job_application.application_data['first_name']} #{job_application.application_data['last_name']}")
  end
end
