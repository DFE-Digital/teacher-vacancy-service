require "rails_helper"
RSpec.describe "School deleting vacancies" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }
  let(:vacancy) { create(:vacancy) }

  before do
    login_publisher(publisher: publisher, organisation: school)
    vacancy.organisation_vacancies.create(organisation: school)
    stub_document_deletion_of_vacancy
  end

  scenario "A school can delete a vacancy from a list" do
    vacancy2 = create(:vacancy)
    vacancy2.organisation_vacancies.create(organisation: school)

    delete_vacancy(school, vacancy.id)

    within(".card-component__actions") do
      expect(page).not_to have_content(vacancy.job_title)
    end
    expect(page).to have_content(vacancy2.job_title)
    expect(page).to have_content(
      strip_tags(I18n.t("publishers.vacancies.destroy.success_html", job_title: vacancy.job_title)),
    )
  end

  scenario "Deleting a vacancy triggers deletion of its supporting documents" do
    expect(vacancy).to receive(:delete_documents)

    delete_vacancy(school, vacancy.id)
  end

  scenario "The last vacancy is deleted" do
    delete_vacancy(school, vacancy.id)

    expect(page).to have_content(I18n.t("publishers.no_vacancies_component.heading"))
  end

  scenario "Notifies the Google index service" do
    expect_any_instance_of(Publishers::Vacancies::ApplicationController)
      .to receive(:remove_google_index).with(vacancy)

    delete_vacancy(school, vacancy.id)
  end

  private

  def delete_vacancy(school, vacancy_id)
    visit organisation_path(school)

    within(".card-component#vacancy_#{vacancy_id}") do
      click_on "Delete"
    end
  end

  def stub_document_deletion_of_vacancy
    # Stub vacancy lookup so that the controller uses these tests' vacancy objects
    # to wrap the vacancy, instead of creating its own new vacancy object.
    # We need to use a `vacancy` object created in the test so that we can stub out the method
    # Vacancy#delete_documents, which otherwise will attempt HTTP connections.
    allow_any_instance_of(Publishers::Vacancies::ApplicationController).to receive_message_chain(
      :current_organisation, :all_vacancies, :find
    ).and_return(vacancy)
    allow(vacancy).to receive(:delete_documents).and_return(nil)
  end
end
