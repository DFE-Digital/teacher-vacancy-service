require "rails_helper"
RSpec.describe "Hiring staff can edit a vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before do
    login_publisher(publisher: publisher, organisation: school)
    vacancy.organisation_vacancies.create(organisation: school)
  end

  context "when attempting to edit a draft vacancy" do
    let(:vacancy) { create(:vacancy, :draft) }

    scenario "redirects to the review vacancy page" do
      visit edit_organisation_job_path(vacancy.id)

      expect(page).to have_content(I18n.t("jobs.review_heading"))
    end
  end

  context "when editing a published vacancy" do
    let(:vacancy) do
      VacancyPresenter.new(
        create(:vacancy, :complete, job_location: "at_one_school",
                                    job_roles: %i[teacher sen_specialist], working_patterns: %w[full_time part_time],
                                    publish_on: Date.current, expires_on: Time.zone.tomorrow),
      )
    end

    context "when the vacancy is now invalid" do
      before do
        vacancy.about_school = nil
        vacancy.suitable_for_nqt = nil
        vacancy.save(validate: false)
      end

      scenario "shows action required error message" do
        visit edit_organisation_job_path(vacancy.id)

        expect(page).to have_content(I18n.t("messages.jobs.action_required.heading"))
        expect(page).to have_content(I18n.t("messages.jobs.action_required.message"))
        expect(page).to have_content(I18n.t("job_summary_errors.about_school.blank", organisation: "school"))
        expect(page).to have_content(I18n.t("job_details_errors.suitable_for_nqt.inclusion"))
      end
    end

    scenario "shows all vacancy information" do
      visit edit_organisation_job_path(vacancy.id)

      verify_all_vacancy_details(vacancy)
    end

    scenario "takes you to the edit page" do
      visit edit_organisation_job_path(vacancy.id)

      within("h1.govuk-heading-m") do
        expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
      end
    end

    scenario "vacancy state is edit_published" do
      visit edit_organisation_job_path(vacancy.id)
      expect(Vacancy.last.state).to eq("edit_published")

      click_header_link(I18n.t("jobs.job_details"))
      expect(Vacancy.last.state).to eq("edit_published")
    end

    scenario "create a job sidebar is not present" do
      visit edit_organisation_job_path(vacancy.id)

      expect(page).to_not have_content("Creating a job listing steps")
    end

    describe "#cancel_and_return_later" do
      scenario "can cancel and return from job details page" do
        visit edit_organisation_job_path(vacancy.id)

        click_header_link(I18n.t("jobs.job_details"))
        expect(page).to have_content(I18n.t("buttons.cancel_and_return"))

        click_on I18n.t("buttons.cancel_and_return")
        expect(page.current_path).to eq(edit_organisation_job_path(vacancy.id))
      end
    end

    describe "#job_details" do
      scenario "can not be edited when validation fails" do
        visit edit_organisation_job_path(vacancy.id)

        within("h1.govuk-heading-m") do
          expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
        end
        click_header_link(I18n.t("jobs.job_details"))

        fill_in "publishers_job_listing_job_details_form[job_title]", with: ""
        click_on I18n.t("buttons.update_job")

        expect(page).to have_content("Enter a job title")
      end

      scenario "can be successfully edited" do
        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.job_details"))

        fill_in "publishers_job_listing_job_details_form[job_title]", with: "Assistant Head Teacher"
        click_on I18n.t("buttons.update_job")

        expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: "Assistant Head Teacher"))
        expect(page).to have_content("Assistant Head Teacher")
      end

      scenario "ensures the vacancy slug is updated when the title is saved" do
        vacancy = create(:vacancy, :published, slug: "the-vacancy-slug")
        vacancy.organisation_vacancies.create(organisation: school)
        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.job_details"))

        fill_in "publishers_job_listing_job_details_form[job_title]", with: "Assistant Head Teacher"
        click_on I18n.t("buttons.update_job")

        expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: "Assistant Head Teacher"))
        expect(page).to have_content("Assistant Head Teacher")

        visit job_path(vacancy.reload)
        expect(page.current_path).to eq("/jobs/assistant-head-teacher")
      end

      scenario "notifies the Google index service" do
        expect_any_instance_of(Publishers::Vacancies::ApplicationController)
          .to receive(:update_google_index).with(vacancy)

        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.job_details"))

        fill_in "publishers_job_listing_job_details_form[job_title]", with: "Assistant Head Teacher"
        click_on I18n.t("buttons.update_job")
      end
    end

    describe "#pay_package" do
      scenario "can not be edited when validation fails" do
        visit edit_organisation_job_path(vacancy.id)

        within("h1.govuk-heading-m") do
          expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
        end

        click_header_link(I18n.t("jobs.pay_package"))

        fill_in "publishers_job_listing_pay_package_form[salary]", with: ""
        click_on I18n.t("buttons.update_job")

        within_row_for(text: I18n.t("jobs.salary")) do
          expect(page).to have_content(I18n.t("pay_package_errors.salary.blank"))
        end
      end

      scenario "can be successfully edited" do
        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.pay_package"))

        fill_in "publishers_job_listing_pay_package_form[salary]", with: "Pay scale 1 to Pay scale 2"
        click_on I18n.t("buttons.update_job")

        expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: vacancy.job_title))
        expect(page).to have_content("Pay scale 1 to Pay scale 2")
      end

      scenario "adds a job to update the Google index in the queue" do
        expect_any_instance_of(Publishers::Vacancies::ApplicationController)
          .to receive(:update_google_index).with(vacancy)

        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.pay_package"))

        fill_in "publishers_job_listing_pay_package_form[salary]", with: "Pay scale 1 to Pay scale 2"
        click_on I18n.t("buttons.update_job")
      end
    end

    describe "#important_dates" do
      def edit_date(date_type, date)
        fill_in "publishers_job_listing_important_dates_form[#{date_type}(3i)]", with: date&.day.presence || ""
        fill_in "publishers_job_listing_important_dates_form[#{date_type}(2i)]", with: date&.month.presence || ""
        fill_in "publishers_job_listing_important_dates_form[#{date_type}(1i)]", with: date&.year.presence || ""
        click_on I18n.t("buttons.update_job")
      end

      scenario "can not be edited when validation fails" do
        visit edit_organisation_job_path(vacancy.id)

        within("h1.govuk-heading-m") do
          expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
        end
        click_header_link(I18n.t("jobs.important_dates"))

        edit_date("expires_on", nil)

        within_row_for(element: "legend",
                       text: strip_tags(I18n.t("helpers.legend.publishers_job_listing_important_dates_form.expires_on"))) do
          expect(page).to have_content(I18n.t("important_dates_errors.expires_on.blank"))
        end
      end

      scenario "can not be saved when expiry time validation fails" do
        visit edit_organisation_job_path(vacancy.id)

        within("h1.govuk-heading-m") do
          expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
        end
        click_header_link(I18n.t("jobs.important_dates"))

        fill_in "publishers_job_listing_important_dates_form[expires_at_hh]", with: "88"
        click_on I18n.t("buttons.update_job")

        within_row_for(element: "legend",
                       text: strip_tags(I18n.t("helpers.legend.publishers_job_listing_important_dates_form.expires_at"))) do
          expect(page).to have_content(I18n.t("important_dates_errors.expires_at.wrong_format"))
        end
      end

      scenario "can be successfully edited" do
        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.important_dates"))

        expiry_date = Date.current + 1.week
        edit_date("expires_on", expiry_date)

        expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: vacancy.job_title))
        # Using String#strip to get rid of an initial space in e.g. " 1 July 2020" which caused test failures
        # due to a leading newline in the body ("\n1 July 2020").
        expect(page).to have_content(expiry_date.to_s.strip)
      end

      scenario "adds a job to update the Google index in the queue" do
        expect_any_instance_of(Publishers::Vacancies::ApplicationController)
          .to receive(:update_google_index).with(vacancy)

        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.important_dates"))

        expiry_date = Date.current + 1.week
        edit_date("expires_on", expiry_date)
      end

      context "when the job post has already been published" do
        context "when the publication date is in the past" do
          scenario "renders the publication date as text and does not allow editing" do
            vacancy = build(:vacancy, :published, slug: "test-slug", publish_on: 1.day.ago)
            vacancy.save(validate: false)
            vacancy.organisation_vacancies.create(organisation: school)
            vacancy = VacancyPresenter.new(vacancy)
            visit edit_organisation_job_path(vacancy.id)

            click_header_link(I18n.t("jobs.important_dates"))
            expect(page).to have_content(I18n.t("jobs.publication_date"))
            expect(page).to have_content(format_date(vacancy.publish_on))
            expect(page).not_to have_css("#publishers_job_listing_important_dates_form_publish_on_dd")

            fill_in "publishers_job_listing_important_dates_form[expires_on(3i)]", with: vacancy.expires_on.day
            click_on I18n.t("buttons.update_job")

            expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: vacancy.job_title))
            verify_all_vacancy_details(vacancy)
          end
        end

        context "when the publication date is in the future" do
          scenario "renders the publication date as text and allows editing" do
            vacancy = create(:vacancy, :published, publish_on: Time.current + 3.days)
            vacancy.organisation_vacancies.create(organisation: school)
            vacancy = VacancyPresenter.new(vacancy)
            visit edit_organisation_job_path(vacancy.id)
            click_header_link(I18n.t("jobs.important_dates"))

            expect(page).to have_css("#publishers_job_listing_important_dates_form_publish_on_3i")

            publish_on = Date.current + 1.week
            edit_date("publish_on", publish_on)

            expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: vacancy.job_title))

            vacancy.publish_on = publish_on
            verify_all_vacancy_details(vacancy)
          end
        end
      end
    end

    describe "#supporting_documents" do
      let(:document_upload) { double("document_upload") }
      let(:filename) { "blank_job_spec.pdf" }

      before do
        allow(DocumentUpload).to receive(:new).and_return(document_upload)
        allow(document_upload).to receive(:upload)
        allow(document_upload).to receive_message_chain(:uploaded, :web_content_link).and_return("test_url")
        allow(document_upload).to receive_message_chain(:uploaded, :id).and_return("test_id")
        allow(document_upload).to receive(:safe_download).and_return(true)
        allow(document_upload).to receive(:google_error).and_return(false)
      end

      scenario "can edit documents" do
        visit edit_organisation_job_path(vacancy.id)

        click_header_link(I18n.t("jobs.supporting_documents"))

        expect(page).to have_content(I18n.t("helpers.label.publishers_job_listing_documents_form.documents"))

        upload_document(
          "new_publishers_job_listing_documents_form",
          "publishers-job-listing-documents-form-documents-field",
          "spec/fixtures/files/#{filename}",
        )
        click_on I18n.t("buttons.update_job")

        expect(current_path).to eq(edit_organisation_job_path(vacancy.id))
        expect(page).to have_content(filename)
      end
    end

    describe "#applying_for_the_job" do
      scenario "can not be edited when validation fails" do
        visit edit_organisation_job_path(vacancy.id)

        within("h1.govuk-heading-m") do
          expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
        end
        click_header_link(I18n.t("jobs.applying_for_the_job"))

        fill_in "publishers_job_listing_applying_for_the_job_form[application_link]", with: "some link"
        click_on I18n.t("buttons.update_job")

        within_row_for(text: I18n.t("jobs.application_link")) do
          expect(page).to have_content(I18n.t("applying_for_the_job_errors.application_link.url"))
        end
      end

      scenario "can be successfully edited" do
        visit edit_organisation_job_path(vacancy.id)

        click_header_link(I18n.t("jobs.applying_for_the_job"))
        vacancy.application_link = "https://tvs.com"

        fill_in "publishers_job_listing_applying_for_the_job_form[application_link]", with: vacancy.application_link
        click_on I18n.t("buttons.update_job")

        expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: vacancy.job_title))

        verify_all_vacancy_details(vacancy)
      end

      scenario "adds a job to update the Google index in the queue" do
        expect_any_instance_of(Publishers::Vacancies::ApplicationController)
          .to receive(:update_google_index).with(vacancy)

        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.applying_for_the_job"))

        fill_in "publishers_job_listing_applying_for_the_job_form[application_link]", with: "https://schooljobs.com"
        click_on I18n.t("buttons.update_job")
      end
    end

    describe "#job_summary" do
      scenario "can not be edited when validation fails" do
        visit edit_organisation_job_path(vacancy.id)

        within("h1.govuk-heading-m") do
          expect(page).to have_content(I18n.t("jobs.edit_job_title", job_title: vacancy.job_title))
        end
        click_header_link(I18n.t("jobs.job_summary"))

        fill_in "publishers_job_listing_job_summary_form[job_summary]", with: ""
        click_on I18n.t("buttons.update_job")

        within_row_for(text: I18n.t("jobs.job_summary")) do
          expect(page).to have_content(I18n.t("job_summary_errors.job_summary.blank"))
        end
      end

      scenario "can be successfully edited" do
        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.job_summary"))

        fill_in "publishers_job_listing_job_summary_form[job_summary]", with: "A summary about the job."
        click_on I18n.t("buttons.update_job")

        expect(page.body).to include(I18n.t("messages.jobs.listing_updated", job_title: vacancy.job_title))
        expect(page).to have_content("A summary about the job.")
      end

      scenario "adds a job to update the Google index in the queue" do
        expect_any_instance_of(Publishers::Vacancies::ApplicationController)
          .to receive(:update_google_index).with(vacancy)

        visit edit_organisation_job_path(vacancy.id)
        click_header_link(I18n.t("jobs.job_summary"))

        fill_in "publishers_job_listing_job_summary_form[job_summary]", with: "A summary about the job."
        click_on I18n.t("buttons.update_job")
      end
    end
  end
end
