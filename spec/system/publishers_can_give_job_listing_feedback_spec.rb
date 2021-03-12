require "rails_helper"

RSpec.describe "Pubishers can give job listing feedback" do
  let(:publisher) { create(:publisher) }
  let(:organisation) { create(:school) }
  let(:comment) { "I love this service!" }

  before do
    login_publisher(publisher: publisher, organisation: organisation)
    visit organisation_job_summary_path(vacancy.id)
  end

  context "when the vacancy is not published" do
    let(:vacancy) { create(:vacancy, :draft, organisation_vacancies_attributes: [{ organisation: organisation }]) }

    it "redirects to review page" do
      expect(current_path).to eq(organisation_job_review_path(vacancy.id))
    end
  end

  context "when the vacancy is published" do
    let(:vacancy) { create(:vacancy, :published, organisation_vacancies_attributes: [{ organisation: organisation }]) }

    it "submits blank feedback, renders error and then submits feedback successfully" do
      click_on I18n.t("buttons.submit_feedback")

      expect(page).to have_content("There is a problem")

      choose I18n.t("helpers.label.publishers_job_listing_feedback_form.rating_options.somewhat_satisfied")
      fill_in "publishers_job_listing_feedback_form[comment]", with: comment

      expect { click_on I18n.t("buttons.submit_feedback") }
        .to have_triggered_event(:feedback_provided)
        .with_base_data(user_anonymised_publisher_id: anonymised_form_of(Publisher.first.oid))
        .and_data(comment: comment, feedback_type: "vacancy_publisher", vacancy_id: vacancy.id)

      expect(current_path).to eq(jobs_with_type_organisation_path(:published))

      expect(page).to have_content(I18n.t("messages.jobs.feedback.success"))
    end
  end
end
