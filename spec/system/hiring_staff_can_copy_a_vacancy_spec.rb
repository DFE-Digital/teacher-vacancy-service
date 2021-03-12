require "rails_helper"

RSpec.describe "Copying a vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  let(:document_copy) { double("document_copy") }

  before do
    allow(DocumentCopy).to receive(:new).and_return(document_copy)
    allow(document_copy).to receive(:copy).and_return(document_copy)
    allow(document_copy).to receive_message_chain(:copied, :web_content_link).and_return("test_url")
    allow(document_copy).to receive_message_chain(:copied, :id).and_return("test_id")
    allow(document_copy).to receive(:google_error).and_return(false)
  end

  before { login_publisher(publisher: publisher, organisation: school) }

  describe "#cancel_copy" do
    scenario "a copy can be cancelled using the cancel copy back link" do
      original_vacancy = build(:vacancy, :past_publish)
      original_vacancy.save(validate: false) # Validation prevents publishing on a past date
      original_vacancy.organisation_vacancies.create(organisation: school)

      new_vacancy = original_vacancy.dup
      new_vacancy.job_title = "A new job title"

      visit organisation_path

      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      fill_in_copy_vacancy_form_fields(new_vacancy)

      click_on(I18n.t("buttons.cancel_copy"), class: "govuk-back-link")

      expect(page.current_path).to eq(organisation_path)
      expect(page).not_to have_content("A new job title")
    end

    scenario "a copy can be cancelled using the cancel copy link" do
      original_vacancy = build(:vacancy, :past_publish)
      original_vacancy.save(validate: false) # Validation prevents publishing on a past date
      original_vacancy.organisation_vacancies.create(organisation: school)

      new_vacancy = original_vacancy.dup
      new_vacancy.job_title = "A new job title"

      visit organisation_path

      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      fill_in_copy_vacancy_form_fields(new_vacancy)

      click_on(I18n.t("buttons.cancel_copy"), class: "govuk-link")

      expect(page.current_path).to eq(organisation_path)
      expect(page).not_to have_content("A new job title")
    end
  end

  scenario "a job can be successfully copied and published" do
    original_vacancy = build(:vacancy, :past_publish)
    original_vacancy.save(validate: false) # Validation prevents publishing on a past date
    original_vacancy.organisation_vacancies.create(organisation: school)

    new_vacancy = original_vacancy.dup
    new_vacancy.organisation_vacancies.build(organisation: school)
    new_vacancy.job_title = "A new job title"
    new_vacancy.starts_on = 35.days.from_now
    new_vacancy.publish_on = 0.days.from_now
    new_vacancy.expires_at = new_vacancy.expires_on = 30.days.from_now

    visit organisation_path

    within(".card-component__actions") do
      click_on I18n.t("jobs.manage.copy_link_text")
    end

    within("h1.govuk-heading-m") do
      expect(page).to have_content(I18n.t("jobs.copy_job_title", job_title: original_vacancy.job_title))
    end

    fill_in_copy_vacancy_form_fields(new_vacancy)
    click_on I18n.t("buttons.continue")

    within("h2.govuk-heading-l") do
      expect(page).to have_content(I18n.t("jobs.copy_review_heading"))
    end
    click_on I18n.t("buttons.submit_job_listing")

    expect(page).to have_content(I18n.t("publishers.vacancies.summary.success"))
  end

  context "when the original job is now invalid" do
    scenario "the job can be successfully copied but not published until valid" do
      original_vacancy = build(:vacancy, :complete, about_school: nil, job_location: "at_one_school")
      original_vacancy.send(:set_slug)
      original_vacancy.save(validate: false)
      original_vacancy.organisation_vacancies.create(organisation: school)

      visit organisation_path

      new_vacancy = original_vacancy.dup
      new_vacancy.job_title = "A new job title"
      new_vacancy.starts_on = 35.days.from_now
      new_vacancy.publish_on = 0.days.from_now
      new_vacancy.expires_at = new_vacancy.expires_on = 30.days.from_now

      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      within("h1.govuk-heading-m") do
        expect(page).to have_content(I18n.t("jobs.copy_job_title", job_title: original_vacancy.job_title))
      end

      fill_in_copy_vacancy_form_fields(new_vacancy)
      click_on I18n.t("buttons.continue")

      within("h2.govuk-heading-l") do
        expect(page).to have_content(I18n.t("jobs.copy_review_heading"))
      end

      expect(page).to have_content(I18n.t("messages.jobs.action_required.heading"))
      expect(page).to have_content(I18n.t("messages.jobs.action_required.message"))
      expect(page).to have_content(I18n.t("job_summary_errors.about_school.blank", organisation: "school"))

      click_on I18n.t("buttons.submit_job_listing")
      expect(page).to have_content(I18n.t("messages.jobs.action_required.heading"))
      expect(page).to have_content(I18n.t("messages.jobs.action_required.message"))
      expect(page).to have_content(I18n.t("job_summary_errors.about_school.blank", organisation: "school"))

      click_header_link(I18n.t("jobs.job_summary"))
      fill_in "publishers_job_listing_job_summary_form[about_school]", with: "Some description about the school"
      click_on I18n.t("buttons.update_job")

      within("h2.govuk-heading-l") do
        expect(page).to have_content(I18n.t("jobs.copy_review_heading"))
      end
      expect(page).to have_content("Some description about the school")

      click_on I18n.t("buttons.submit_job_listing")

      expect(page).to have_content(I18n.t("publishers.vacancies.summary.success"))
    end
  end

  context "when the original job is pending/scheduled/future_publish" do
    scenario "a job can be successfully copied" do
      original_vacancy = create(:vacancy, :future_publish)
      original_vacancy.organisation_vacancies.create(organisation: school)

      visit organisation_path

      click_on I18n.t("publishers.vacancies_component.pending.tab_heading")
      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      within("h1.govuk-heading-m") do
        expect(page).to have_content(I18n.t("jobs.copy_job_title", job_title: original_vacancy.job_title))
      end

      click_on I18n.t("buttons.continue")

      within("h2.govuk-heading-l") do
        expect(page).to have_content(I18n.t("jobs.copy_review_heading"))
      end
    end
  end

  context "when the original job has expired" do
    scenario "a job can be successfully copied" do
      original_vacancy = create(:vacancy, :expired)
      original_vacancy.organisation_vacancies.create(organisation: school)

      new_vacancy = original_vacancy.dup
      new_vacancy.job_title = "A new job title"
      new_vacancy.starts_on = 35.days.from_now
      new_vacancy.publish_on = 0.days.from_now
      new_vacancy.expires_on = 30.days.from_now

      visit organisation_path

      click_on I18n.t("publishers.vacancies_component.expired.tab_heading")
      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      within("h1.govuk-heading-m") do
        expect(page).to have_content(I18n.t("jobs.copy_job_title", job_title: original_vacancy.job_title))
      end

      fill_in_copy_vacancy_form_fields(new_vacancy)
      click_on I18n.t("buttons.continue")

      within("h2.govuk-heading-l") do
        expect(page).to have_content(I18n.t("jobs.copy_review_heading"))
      end
    end
  end

  context "when a copied job has an invalid date" do
    scenario "it shows a validation error" do
      original_vacancy = build(:vacancy, :past_publish)
      original_vacancy.save(validate: false) # Validation prevents publishing on a past date
      original_vacancy.organisation_vacancies.create(organisation: school)

      new_vacancy = original_vacancy.dup
      new_vacancy.job_title = "A new job title"
      new_vacancy.publish_on = 0.days.from_now
      new_vacancy.expires_at = new_vacancy.expires_on

      visit organisation_path

      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      within("h1.govuk-heading-m") do
        expect(page).to have_content(I18n.t("jobs.copy_job_title", job_title: original_vacancy.job_title))
      end

      fill_in_copy_vacancy_form_fields(new_vacancy)
      fill_in "publishers_job_listing_copy_vacancy_form[expires_on(2i)]", with: "090"

      click_on I18n.t("buttons.continue")
      expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.expires_on.invalid"))
    end
  end

  describe "validations" do
    let!(:original_vacancy) do
      vacancy = build(:vacancy, :past_publish)
      vacancy.save(validate: false) # Validation prevents publishing on a past date
      vacancy.organisation_vacancies.create(organisation: school)
      vacancy
    end
    let(:new_vacancy) { build(:vacancy, original_vacancy.attributes.merge(new_attributes)) }

    before do
      visit organisation_path

      within(".card-component__actions") do
        click_on I18n.t("jobs.manage.copy_link_text")
      end

      expect(page).to have_content(I18n.t("jobs.copy_job_title", job_title: original_vacancy.job_title))

      fill_in_copy_vacancy_form_fields(new_vacancy)
      click_on I18n.t("buttons.continue")
    end

    context "when publish on is blank" do
      let(:new_attributes) { { publish_on: nil } }

      it "shows an error" do
        expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.publish_on.blank"))
      end
    end

    context "when publish on date is in the past" do
      let(:new_attributes) { { publish_on: 1.day.ago } }

      it "shows an error" do
        expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.publish_on.before_today"))
      end
    end

    context "when expires on is blank" do
      let(:new_attributes) { { expires_on: nil } }

      it "shows an error" do
        expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.expires_on.blank"))
      end
    end

    context "when job title is blank" do
      let(:new_attributes) { { job_title: nil } }

      it "shows an error" do
        expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.job_title.blank"))
      end
    end
  end
end
