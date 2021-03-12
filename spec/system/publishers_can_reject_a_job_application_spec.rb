require "rails_helper"

RSpec.describe "Publishers can reject a job application" do
  let(:organisation) { create(:school) }
  let(:vacancy) { create(:vacancy, :expired, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:job_application) { create(:job_application, :status_submitted, vacancy: vacancy) }
  let(:oid) { SecureRandom.uuid }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    stub_publishers_auth(urn: organisation.urn, oid: oid)
    visit organisation_job_job_application_path(vacancy.id, job_application.id)
  end

  it "shortlists the job application after confirmation" do
    click_on I18n.t("buttons.reject")

    expect(current_path).to eq(organisation_job_job_application_reject_path(vacancy.id, job_application.id))

    fill_in "publishers_job_application_update_status_form[rejection_reasons]", with: "Some rejection reasons"
    click_on I18n.t("buttons.reject")

    # TODO: Update expecation when redirect is updated
    expect(current_path).to eq(organisation_jobs_path)
    expect(page).to have_content(I18n.t("publishers.vacancies.job_applications.update_status.unsuccessful",
                                        name: "#{job_application.application_data['first_name']} #{job_application.application_data['last_name']}"))
    expect(job_application.reload.status).to eq("unsuccessful")
  end
end
