require "rails_helper"

RSpec.describe "Hiring staff can view a public vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before { login_publisher(publisher: publisher, organisation: school) }

  scenario "A vacancy page view is not tracked" do
    vacancy = create(:vacancy, :published)
    vacancy.organisation_vacancies.create(organisation: school)

    expect { visit job_path(vacancy) }.not_to have_enqueued_job(PersistVacancyPageViewJob)
  end
end
