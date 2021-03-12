require "rails_helper"

RSpec.describe "Creating a vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school, name: "Salisbury School") }

  before { login_publisher(publisher: publisher, organisation: school) }

  scenario "Visiting the school page" do
    visit organisation_path

    expect(page).to have_content("Salisbury School")
    expect(page).to have_content(/#{school.address}/)
    expect(page).to have_content(/#{school.town}/)

    click_on I18n.t("buttons.create_job")

    expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 7))
  end

  context "creating a new vacancy" do
    let(:suitable_for_nqt) { "no" }
    let(:vacancy) do
      VacancyPresenter.new(build(:vacancy, :complete,
                                 job_roles: %i[teacher sen_specialist],
                                 suitable_for_nqt: suitable_for_nqt,
                                 working_patterns: %w[full_time part_time],
                                 publish_on: Date.current))
    end

    scenario "redirects to step 1, job details" do
      visit organisation_path
      click_on I18n.t("buttons.create_job")

      expect(page.current_path).to eq(organisation_job_build_path(Vacancy.last.id, :job_details))
      expect(page).to have_content(I18n.t("jobs.create_a_job_title_no_org"))
      expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 7))
    end

    scenario "resets session current_step" do
      page.set_rack_session(current_step: :review)

      visit organisation_path
      click_on I18n.t("buttons.create_job")

      fill_in_job_details_form_fields(vacancy)
      click_on I18n.t("buttons.continue")

      expect(page.get_rack_session["current_step"]).to be nil
    end

    describe "#job_details" do
      scenario "is invalid unless all mandatory fields are submitted" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        click_on I18n.t("buttons.continue")

        mandatory_fields = %w[job_title working_patterns]

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
        end

        mandatory_fields.each do |field|
          within_row_for(element: field == "job_title" ? "label" : "legend", text: I18n.t("jobs.#{field}")) do
            expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.#{field}.blank"))
          end
        end
      end

      scenario "redirects to step 2, pay package, when submitted successfully" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 2, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.pay_package"))
        end
      end

      context "when job is selected as suitable for NQTs" do
        let(:suitable_for_nqt) { "yes" }

        scenario "Suitable for NQTs is appended to the job roles" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          expect(Vacancy.last.job_roles).to include("nqt_suitable")
        end
      end

      scenario "vacancy state is create" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        expect(Vacancy.last.state).to eq("create")
      end
    end

    describe "#pay_package" do
      scenario "is invalid unless all mandatory fields are submitted" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
        end

        within_row_for(text: I18n.t("jobs.salary")) do
          expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.salary.blank"))
        end
      end

      scenario "redirects to step 3, important dates, when submitted successfuly" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 3, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.important_dates"))
        end
      end
    end

    describe "#important_dates" do
      scenario "is invalid unless all mandatory fields are submitted" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
        end

        within_row_for(element: "legend",
                       text: strip_tags(I18n.t("helpers.legend.publishers_job_listing_important_dates_form.publish_on"))) do
          expect(page).to have_content(I18n.t("important_dates_errors.publish_on.blank"))
        end

        within_row_for(element: "legend",
                       text: strip_tags(I18n.t("helpers.legend.publishers_job_listing_important_dates_form.expires_on"))) do
          expect(page).to have_content(I18n.t("important_dates_errors.expires_on.blank"))
        end

        within_row_for(element: "legend",
                       text: strip_tags(I18n.t("helpers.legend.publishers_job_listing_important_dates_form.expires_at"))) do
          expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.expires_at.blank"))
        end
      end

      scenario "redirects to step 4, supporting documents, when submitted successfuly" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_important_dates_fields(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 4, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.supporting_documents"))
        end
      end
    end

    describe "#documents" do
      let(:documents_vacancy) { create(:vacancy) }

      before { documents_vacancy.organisation_vacancies.create(organisation: school) }

      scenario "hiring staff can select a file for upload" do
        visit organisation_job_documents_path(documents_vacancy.id)
        page.attach_file("publishers-job-listing-documents-form-documents-field", Rails.root.join("spec/fixtures/files/blank_job_spec.pdf"))
        expect(page.find("#publishers-job-listing-documents-form-documents-field").value).to_not be nil
      end

      context "when uploading files" do
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

        scenario "displays uploaded file in a table" do
          visit organisation_job_documents_path(documents_vacancy.id)

          upload_document(
            "new_publishers_job_listing_documents_form",
            "publishers-job-listing-documents-form-documents-field",
            "spec/fixtures/files/#{filename}",
          )

          expect(page).to have_content(filename)
        end

        scenario "displays error message when invalid file type is uploaded" do
          visit organisation_job_documents_path(documents_vacancy.id)

          allow_any_instance_of(Publishers::Vacancies::DocumentsController)
            .to receive_message_chain(:valid_content_type?).and_return(false)

          upload_document(
            "new_publishers_job_listing_documents_form",
            "publishers-job-listing-documents-form-documents-field",
            "spec/fixtures/files/#{filename}",
          )

          expect(page).to have_content(I18n.t("jobs.file_type_error_message", filename: filename))
        end

        scenario "displays error message when large file is uploaded" do
          stub_const("#{Publishers::Vacancies::DocumentsController}::FILE_SIZE_LIMIT", 1.kilobyte)
          visit organisation_job_documents_path(documents_vacancy.id)

          upload_document(
            "new_publishers_job_listing_documents_form",
            "publishers-job-listing-documents-form-documents-field",
            "spec/fixtures/files/#{filename}",
          )

          expect(page).to have_content(I18n.t("jobs.file_size_error_message", filename: filename, size_limit: "1 KB"))
        end

        scenario "displays error message when virus file is uploaded" do
          visit organisation_job_documents_path(documents_vacancy.id)

          allow(document_upload).to receive(:safe_download).and_return(false)

          upload_document(
            "new_publishers_job_listing_documents_form",
            "publishers-job-listing-documents-form-documents-field",
            "spec/fixtures/files/#{filename}",
          )

          expect(page).to have_content(I18n.t("jobs.file_virus_error_message", filename: filename))
        end

        scenario "displays error message when file not uploaded" do
          visit organisation_job_documents_path(documents_vacancy.id)

          allow(document_upload).to receive(:google_error).and_return(true)

          upload_document(
            "new_publishers_job_listing_documents_form",
            "publishers-job-listing-documents-form-documents-field",
            "spec/fixtures/files/#{filename}",
          )

          expect(page).to have_content(I18n.t("jobs.file_google_error_message", filename: filename))
        end
      end

      context "when deleting uploaded files", js: true do
        let(:document_delete) { double("document_delete") }

        before do
          allow(DocumentDelete).to receive(:new).and_return(document_delete)

          create :document, vacancy: documents_vacancy, name: "delete_me.pdf"
          create :document, vacancy: documents_vacancy, name: "do_not_delete_me.pdf"

          visit organisation_job_documents_path(documents_vacancy.id)

          find('[data-file-name="delete_me.pdf"]').click
        end

        scenario "deletes them" do
          allow(document_delete).to receive(:delete).and_return(true)

          click_on "Yes, remove file"

          within "#js-xhr-flashes" do
            expect(page).to have_content "delete_me.pdf was removed"
          end
        end

        scenario "shows errors" do
          allow(document_delete).to receive(:delete).and_return(false)

          click_on "Yes, remove file"

          within "#js-gem-c-modal-dialogue__error" do
            expect(page).to have_content "An error occurred while removing the file."
          end
        end
      end
    end

    describe "#applying_for_the_job" do
      scenario "is invalid unless all mandatory fields are submitted" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_important_dates_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
        end

        within_row_for(text: strip_tags(I18n.t("helpers.label.publishers_job_listing_applying_for_the_job_form.contact_email"))) do
          expect(page).to have_content(I18n.t("applying_for_the_job_errors.contact_email.blank"))
        end
      end

      scenario "redirects to the job summary page when submitted successfully" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_important_dates_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        fill_in_applying_for_the_job_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 6, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_summary"))
        end
      end
    end

    describe "#job_summary" do
      scenario "is invalid unless all mandatory fields are submitted" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_important_dates_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        fill_in_applying_for_the_job_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
        end

        within_row_for(text: I18n.t("jobs.job_summary")) do
          expect(page).to have_content(I18n.t("activerecord.errors.models.vacancy.attributes.job_summary.blank"))
        end

        within_row_for(text: I18n.t("jobs.about_school", school: school.name)) do
          expect(page).to have_content(school.description)
        end
      end

      scenario "redirects to the vacancy review page when submitted successfully" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        fill_in_job_details_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_pay_package_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_important_dates_fields(vacancy)
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.continue")

        fill_in_applying_for_the_job_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        fill_in_job_summary_form_fields(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 7, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.review_heading"))
        end
        verify_all_vacancy_details(vacancy)
      end
    end

    describe "#review" do
      context "redirects the user back to the last incomplete step" do
        scenario "redirects to step 2, pay package, when that step has not been completed" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          v = Vacancy.find_by(job_title: vacancy.job_title)
          visit organisation_job_path(id: v.id)

          expect(page).to have_content(I18n.t("jobs.current_step", step: 2, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.pay_package"))
          end
        end

        scenario "redirects to step 5, application details, when that step has not been completed" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_pay_package_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_important_dates_fields(vacancy)
          click_on I18n.t("buttons.continue")

          click_on I18n.t("buttons.continue")

          v = Vacancy.find_by(job_title: vacancy.job_title)
          visit organisation_job_path(id: v.id)

          expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.applying_for_the_job"))
          end
        end

        scenario "redirects to step 6, job summary, when that step has not been completed" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_pay_package_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_important_dates_fields(vacancy)
          click_on I18n.t("buttons.continue")

          click_on I18n.t("buttons.continue")

          fill_in_applying_for_the_job_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          v = Vacancy.find_by(job_title: vacancy.job_title)
          visit organisation_job_path(id: v.id)

          expect(page).to have_content(I18n.t("jobs.current_step", step: 6, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.job_summary"))
          end
        end

        scenario "vacancy state is review when all steps completed" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_pay_package_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_important_dates_fields(vacancy)
          click_on I18n.t("buttons.continue")

          click_on I18n.t("buttons.continue")

          fill_in_applying_for_the_job_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_job_summary_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          expect(Vacancy.last.state).to eq("review")
          expect(page).to have_content(I18n.t("jobs.current_step", step: 7, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.review_heading"))
          end
        end

        scenario "vacancy state is review" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_pay_package_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_important_dates_fields(vacancy)
          click_on I18n.t("buttons.continue")

          click_on I18n.t("buttons.continue")

          fill_in_applying_for_the_job_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_job_summary_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          expect(Vacancy.last.state).to eq("review")
          expect(page).to have_content(I18n.t("jobs.current_step", step: 7, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.review_heading"))
          end

          click_header_link(I18n.t("jobs.applying_for_the_job"))
          expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.applying_for_the_job"))
          end
          expect(Vacancy.last.state).to eq("review")

          click_on I18n.t("buttons.update_job")
          expect(Vacancy.last.state).to eq("review")

          click_header_link(I18n.t("jobs.job_details"))
          expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 7))
          within("h2.govuk-heading-l") do
            expect(page).to have_content(I18n.t("jobs.job_details"))
          end
          expect(Vacancy.last.state).to eq("review")
        end
      end

      scenario "is not available for published vacancies" do
        vacancy = create(:vacancy, :published)
        vacancy.organisation_vacancies.create(organisation: school)

        visit organisation_job_review_path(vacancy.id)

        expect(page).to have_current_path(organisation_job_path(vacancy.id))
      end

      context "when a start date has been given" do
        scenario "lists all the vacancy details correctly" do
          vacancy = create(:vacancy, :complete, :draft)
          vacancy.organisation_vacancies.create(organisation: school)

          vacancy = VacancyPresenter.new(vacancy)
          visit organisation_job_review_path(vacancy.id)

          expect(page).to have_content(I18n.t("jobs.review_heading"))

          verify_all_vacancy_details(vacancy)
        end
      end

      context "when the start date is as soon as possible" do
        scenario "lists all the vacancy details correctly" do
          vacancy = create(:vacancy, :complete, :draft, :starts_asap)
          vacancy.organisation_vacancies.create(organisation: school)

          vacancy = VacancyPresenter.new(vacancy)
          visit organisation_job_review_path(vacancy.id)

          expect(page).to have_content(I18n.t("jobs.review_heading"))

          verify_all_vacancy_details(vacancy)
        end
      end

      context "when the listing is full-time" do
        scenario "lists all the full-time vacancy details correctly" do
          vacancy = create(:vacancy, :complete, :draft, working_patterns: %w[full_time])
          vacancy.organisation_vacancies.create(organisation: school)

          vacancy = VacancyPresenter.new(vacancy)

          visit organisation_job_review_path(vacancy.id)

          expect(page).to have_content(I18n.t("jobs.review_heading"))

          verify_all_vacancy_details(vacancy)
        end
      end

      context "when the listing is part-time" do
        scenario "lists all the part-time vacancy details correctly" do
          vacancy = create(:vacancy, :complete, :draft, working_patterns: %w[part_time])
          vacancy.organisation_vacancies.create(organisation: school)

          vacancy = VacancyPresenter.new(vacancy)

          visit organisation_job_review_path(vacancy.id)

          expect(page).to have_content(I18n.t("jobs.review_heading"))

          verify_all_vacancy_details(vacancy)
        end
      end

      context "when the listing is both full- and part-time" do
        scenario "lists all the working pattern vacancy details correctly" do
          vacancy = create(:vacancy, :complete, :draft, working_patterns: %w[full_time part_time])
          vacancy.organisation_vacancies.create(organisation: school)

          vacancy = VacancyPresenter.new(vacancy)

          visit organisation_job_review_path(vacancy.id)

          expect(page).to have_content(I18n.t("jobs.review_heading"))

          verify_all_vacancy_details(vacancy)
        end
      end

      context "edit job_details_details" do
        scenario "updates the vacancy details" do
          vacancy = create(:vacancy, :draft, :complete)
          vacancy.organisation_vacancies.create(organisation: school)
          visit organisation_job_review_path(vacancy.id)
          click_header_link(I18n.t("jobs.job_details"))

          expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 7))

          fill_in "publishers_job_listing_job_details_form[job_title]", with: "An edited job title"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("jobs.review_heading"))
          expect(page).to have_content("An edited job title")
        end

        scenario "fails validation until values are set correctly" do
          vacancy = create(:vacancy, :draft, :complete)
          vacancy.organisation_vacancies.create(organisation: school)
          visit organisation_job_review_path(vacancy.id)
          click_header_link(I18n.t("jobs.job_details"))

          fill_in "publishers_job_listing_job_details_form[job_title]", with: ""
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content("Enter a job title")

          fill_in "publishers_job_listing_job_details_form[job_title]", with: "A new job title"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("jobs.review_heading"))
          expect(page).to have_content("A new job title")
        end
      end

      context "editing the supporting_documents" do
        scenario "updates the vacancy details" do
          visit organisation_path
          click_on I18n.t("buttons.create_job")

          fill_in_job_details_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_pay_package_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_important_dates_fields(vacancy)
          click_on I18n.t("buttons.continue")

          click_on I18n.t("buttons.continue")

          fill_in_applying_for_the_job_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          fill_in_job_summary_form_fields(vacancy)
          click_on I18n.t("buttons.continue")

          expect(page).to have_content(I18n.t("jobs.review_heading"))

          click_header_link(I18n.t("jobs.supporting_documents"))

          expect(page).to have_content(I18n.t("jobs.current_step", step: 4, total: 7))
          expect(page).to have_content(I18n.t("helpers.label.publishers_job_listing_documents_form.documents"))

          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("jobs.review_heading"))
        end
      end

      context "editing applying_for_the_job" do
        scenario "fails validation until values are set correctly" do
          vacancy = create(:vacancy, :draft, :complete)
          vacancy.organisation_vacancies.create(organisation: school)
          visit organisation_job_review_path(vacancy.id)
          click_header_link(I18n.t("jobs.applying_for_the_job"))

          expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))

          fill_in "publishers_job_listing_applying_for_the_job_form[contact_email]", with: "not a valid email"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content("Enter an email address in the correct format, like name@example.com")

          fill_in "publishers_job_listing_applying_for_the_job_form[contact_email]", with: "a@valid.email"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("jobs.review_heading"))
          expect(page).to have_content("a@valid.email")
        end

        scenario "fails validation correctly when an invalid link is entered" do
          vacancy = create(:vacancy, :draft, :complete)
          vacancy.organisation_vacancies.create(organisation: school)
          visit organisation_job_review_path(vacancy.id)
          click_header_link(I18n.t("jobs.applying_for_the_job"))

          expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))

          fill_in "publishers_job_listing_applying_for_the_job_form[application_link]", with: "www invalid.domain.com"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("applying_for_the_job_errors.application_link.url"))

          fill_in "publishers_job_listing_applying_for_the_job_form[application_link]", with: "www.valid-domain.com"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("jobs.review_heading"))
          expect(page).to have_content("www.valid-domain.com")
        end

        scenario "updates the vacancy details" do
          vacancy = create(:vacancy, :draft, :complete)
          vacancy.organisation_vacancies.create(organisation: school)
          visit organisation_job_review_path(vacancy.id)
          click_header_link(I18n.t("jobs.applying_for_the_job"))

          expect(page).to have_content(I18n.t("jobs.current_step", step: 5, total: 7))

          fill_in "publishers_job_listing_applying_for_the_job_form[contact_email]", with: "an@email.com"
          click_on I18n.t("buttons.update_job")

          expect(page).to have_content(I18n.t("jobs.review_heading"))
          expect(page).to have_content("an@email.com")
        end
      end

      scenario "redirects to the summary page when published" do
        vacancy = create(:vacancy, :draft)
        vacancy.organisation_vacancies.create(organisation: school)
        visit organisation_job_review_path(vacancy.id)
        click_on I18n.t("buttons.submit_job_listing")

        expect(current_path).to eq(organisation_job_summary_path(vacancy.id))
      end
    end

    describe "#publish" do
      scenario "cannot be published unless the details are valid" do
        yesterday_date = Time.zone.yesterday
        vacancy = create(:vacancy, :draft, publish_on: Time.zone.tomorrow)
        vacancy.organisation_vacancies.create(organisation: school)
        vacancy.assign_attributes expires_on: yesterday_date
        vacancy.save(validate: false)

        visit organisation_job_review_path(vacancy.id)

        expect(page).to have_content(I18n.t("jobs.current_step", step: 3, total: 7))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.important_dates"))
        end

        expect(find_field("publishers_job_listing_important_dates_form[expires_on(3i)]").value).to eq(yesterday_date.day.to_s)
        expect(find_field("publishers_job_listing_important_dates_form[expires_on(2i)]").value).to eq(yesterday_date.month.to_s)
        expect(find_field("publishers_job_listing_important_dates_form[expires_on(1i)]").value).to eq(yesterday_date.year.to_s)

        click_on I18n.t("buttons.continue")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
        end

        within_row_for(element: "legend",
                       text: strip_tags(I18n.t("helpers.legend.publishers_job_listing_important_dates_form.expires_on"))) do
          expect(page).to have_content(I18n.t("important_dates_errors.expires_on.before_today"))
        end

        expiry_date = Date.current + 1.week

        fill_in "publishers_job_listing_important_dates_form[expires_on(3i)]", with: expiry_date.day
        fill_in "publishers_job_listing_important_dates_form[expires_on(2i)]", with: expiry_date.month
        fill_in "publishers_job_listing_important_dates_form[expires_on(1i)]", with: expiry_date.year
        click_on I18n.t("buttons.continue")

        click_on I18n.t("buttons.submit_job_listing")
        expect(current_path).to eq(organisation_job_summary_path(vacancy.id))
      end

      scenario "can be published at a later date" do
        vacancy = create(:vacancy, :draft, publish_on: Time.zone.tomorrow)
        vacancy.organisation_vacancies.create(organisation: school)

        visit organisation_job_review_path(vacancy.id)
        click_on "Confirm and submit job"

        expect(page).to have_content("Your job listing will be posted on #{format_date(vacancy.publish_on)}.")
        visit organisation_job_path(vacancy.id)
        expect(page).to have_content(format_date(vacancy.publish_on).to_s)
      end

      scenario "displays the expiration date and time on the confirmation page" do
        vacancy = create(:vacancy, :draft, expires_at: 5.days.from_now)
        vacancy.organisation_vacancies.create(organisation: school)
        visit organisation_job_review_path(vacancy.id)
        click_on I18n.t("buttons.submit_job_listing")

        expect(page)
          .to have_content(I18n.t("publishers.vacancies.summary.date_expires",
                                  application_deadline: OrganisationVacancyPresenter.new(vacancy).application_deadline))
      end

      scenario "a published vacancy cannot be republished" do
        vacancy = create(:vacancy, :draft, publish_on: Time.zone.tomorrow)
        vacancy.organisation_vacancies.create(organisation: school)

        visit organisation_job_review_path(vacancy.id)
        click_on "Confirm and submit job"
        expect(page).to have_content("The job listing has been completed")

        visit organisation_job_publish_path(vacancy.id)

        expect(page).to have_content(I18n.t("messages.jobs.already_published"))
      end

      scenario "a published vacancy cannot be edited" do
        vacancy = create(:vacancy, :published)
        vacancy.organisation_vacancies.create(organisation: school)

        visit organisation_job_review_path(vacancy.id)
        expect(page.current_path).to eq(organisation_job_path(vacancy.id))
        expect(page).to have_content(I18n.t("messages.jobs.already_published"))
      end

      context "adds a job to update the Google index in the queue" do
        scenario "if the vacancy is published immediately" do
          vacancy = create(:vacancy, :draft, publish_on: Date.current)
          vacancy.organisation_vacancies.create(organisation: school)

          expect_any_instance_of(Publishers::Vacancies::ApplicationController)
            .to receive(:update_google_index).with(vacancy)

          visit organisation_job_review_path(vacancy.id)
          click_on I18n.t("buttons.submit_job_listing")
        end
      end
    end
  end
end
