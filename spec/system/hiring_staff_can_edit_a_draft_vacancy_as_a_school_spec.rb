require "rails_helper"
RSpec.describe "Hiring staff can edit a draft vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }
  let!(:vacancy) do
    VacancyPresenter.new(build(:vacancy, :complete,
                               job_title: "Draft vacancy",
                               working_patterns: %w[full_time part_time]))
  end
  let(:draft_vacancy) { Vacancy.find_by(job_title: vacancy.job_title) }

  before { login_publisher(publisher: publisher, organisation: school) }

  context "editing an incomplete draft vacancy" do
    before do
      visit organisation_path
      click_on I18n.t("buttons.create_job")
      fill_in_job_details_form_fields(vacancy)
      click_on I18n.t("buttons.continue")
    end

    describe "#redirects_to" do
      scenario "incomplete pay package step" do
        visit edit_organisation_job_path(id: draft_vacancy.id)

        expect(page).to have_content(I18n.t("jobs.current_step", step: 2, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.pay_package"))
        end
      end

      scenario "incomplete important dates step" do
        visit edit_organisation_job_path(id: draft_vacancy.id)

        draft_vacancy.salary = "Pay scale 1 to Pay scale 2"
        draft_vacancy.benefits = "Gym, health insurance"

        fill_in_pay_package_form_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 3, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.important_dates"))
        end
      end

      scenario "documents step not completed" do
        visit edit_organisation_job_path(id: draft_vacancy.id)

        draft_vacancy.salary = "Pay scale 1 to Pay scale 2"
        draft_vacancy.benefits = "Gym, health insurance"

        fill_in_pay_package_form_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        draft_vacancy.starts_on = 1.year.from_now
        draft_vacancy.expires_on = draft_vacancy.starts_on - 1.day
        draft_vacancy.expires_at = Time.current
        draft_vacancy.publish_on = 1.day.from_now

        fill_in_important_dates_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 4, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.supporting_documents"))
        end
      end

      scenario "incomplete application details step" do
        visit edit_organisation_job_path(id: draft_vacancy.id)

        draft_vacancy.salary = "Pay scale 1 to Pay scale 2"
        draft_vacancy.benefits = "Gym, health insurance"

        fill_in_pay_package_form_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        draft_vacancy.starts_on = 1.year.from_now
        draft_vacancy.expires_on = draft_vacancy.starts_on - 1.day
        draft_vacancy.expires_at = Time.current
        draft_vacancy.publish_on = 1.day.from_now

        fill_in_important_dates_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.applying_for_the_job"))
        end
      end

      scenario "incomplete job summary step" do
        visit edit_organisation_job_path(id: draft_vacancy.id)

        draft_vacancy.salary = "Pay scale 1 to Pay scale 2"
        draft_vacancy.benefits = "Gym, health insurance"

        fill_in_pay_package_form_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        draft_vacancy.starts_on = 1.year.from_now
        draft_vacancy.expires_on = draft_vacancy.starts_on - 1.day
        draft_vacancy.expires_at = Time.current
        draft_vacancy.publish_on = 1.day.from_now

        fill_in_important_dates_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        draft_vacancy.contact_email = "test@email.com"
        draft_vacancy.application_link = "https://example.com"

        fill_in_applying_for_the_job_form_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 6, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_summary"))
        end
      end
    end

    context "after editing a different vacancy" do
      # We use the session to store vacancy attributes, make sure it doesn't leak between edits.
      before do
        visit edit_organisation_job_path(id: draft_vacancy.id)

        draft_vacancy.salary = "Pay scale 1 to Pay scale 2"
        draft_vacancy.benefits = "Gym, health insurance"

        fill_in_pay_package_form_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        draft_vacancy.starts_on = 1.year.from_now
        draft_vacancy.expires_on = draft_vacancy.starts_on - 1.day
        draft_vacancy.expires_at = Time.current
        draft_vacancy.publish_on = 1.day.from_now

        fill_in_important_dates_fields(draft_vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        edit_a_published_vacancy
      end

      scenario "then editing the draft redirects to incomplete step" do
        visit organisation_job_path(id: draft_vacancy.id)
        expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))
      end

      def edit_a_published_vacancy
        published_vacancy = create(:vacancy, :published)
        published_vacancy.organisation_vacancies.create(organisation: school)
        visit edit_organisation_job_path(published_vacancy.id)
        click_header_link(I18n.t("jobs.applying_for_the_job"))

        fill_in "publishers_job_listing_applying_for_the_job_form[application_link]", with: "https://example.com"
        click_on I18n.t("buttons.update_job")

        expect(page.body).to include(
          I18n.t("messages.jobs.listing_updated", job_title: published_vacancy.job_title),
        )
      end
    end
  end

  context "editing a complete draft vacancy" do
    let(:vacancy) { create(:vacancy, :draft) }

    before { vacancy.organisation_vacancies.create(organisation: school) }

    scenario "vacancy state is edit" do
      visit organisation_job_review_path(vacancy.id, edit_draft: true)

      expect(Vacancy.last.state).to eq("edit")
      within("h2.govuk-heading-l") do
        expect(page).to have_content(I18n.t("jobs.review_heading"))
      end
    end

    describe "#cancel_and_return_later" do
      scenario "can cancel and return from job details page" do
        visit organisation_job_review_path(vacancy.id)

        click_header_link(I18n.t("jobs.job_details"))
        expect(page).to have_content(I18n.t("buttons.cancel_and_return"))

        click_on I18n.t("buttons.cancel_and_return")
        expect(page.current_path).to eq(organisation_job_review_path(vacancy.id))
      end
    end
  end
end
