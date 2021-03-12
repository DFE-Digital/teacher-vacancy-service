require "rails_helper"

RSpec.describe "Jobseekers can view a job application" do
  let(:jobseeker) { create(:jobseeker) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:organisation) { create(:school) }
  let(:job_application) { create(:job_application, :status_submitted, jobseeker: jobseeker, vacancy: vacancy) }

  let(:show_page) { PageObjects::Jobseekers::JobApplications::Show.new }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    login_as(jobseeker, scope: :jobseeker)
    show_page.load(id: job_application.id)
  end

  it "displays all the job application information" do
    expect(show_page.banner.job_title.text).to eq(vacancy.job_title)

    expect(show_page.banner.status.text).to eq(job_application.status)

    expect(show_page.timeline.dates(text: "Application submitted").first.text)
      .to include(format_date(job_application.submitted_at.to_date) + I18n.t("jobs.time_at") + format_time(job_application.submitted_at))

    expect(page).not_to have_content(I18n.t("jobseekers.job_applications.show.shortlist_alert.title"))
    expect(page).not_to have_content(I18n.t("jobseekers.job_applications.show.feedback"))

    show_page.steps(text: I18n.t("jobseekers.job_applications.build.personal_details.heading")).first.within do |personal_details|
      %w[first_name last_name previous_names phone_number teacher_reference_number national_insurance_number].each do |attribute|
        expect(personal_details.body.rows(id: "personal_details_#{attribute}").first.value.text).to eq(job_application.application_data[attribute])
      end
      expect(personal_details.body.rows(id: "personal_details_your_address").first.value.text).to include(job_application.application_data["building_and_street"])
      expect(personal_details.body.rows(id: "personal_details_your_address").first.value.text).to include(job_application.application_data["town_or_city"])
      expect(personal_details.body.rows(id: "personal_details_your_address").first.value.text).to include(job_application.application_data["postcode"])
    end

    show_page.steps(text: I18n.t("jobseekers.job_applications.build.professional_status.heading")).first.within do |professional_status|
      expect(professional_status.body.rows(id: "professional_status_qualified_teacher_status").first.value.text).to include(job_application.application_data["qualified_teacher_status"].capitalize)
      expect(professional_status.body.rows(id: "professional_status_qualified_teacher_status").first.value.text).to include(job_application.application_data["qualified_teacher_status_year"])
      expect(professional_status.body.rows(id: "professional_status_statutory_induction_complete").first.value.text).to eq(job_application.application_data["statutory_induction_complete"].capitalize)
    end

    job_application.employment_history.order(:created_at).each_with_index do |employment_history_details, index|
      show_page.steps(text: I18n.t("jobseekers.job_applications.build.employment_history.heading")).first.within do |employment_history|
        employment_history.body.accordions(text: employment_history_details.data["job_title"], id: "employment_history_#{index}").first.within do |accordion|
          expect(accordion.content.rows(id: "employment_history_organisation").first.value.text).to eq(employment_history_details.data["organisation"])
          expect(accordion.content.rows(id: "employment_history_salary").first.value.text).to eq(employment_history_details.data["salary"])
          expect(accordion.content.rows(id: "employment_history_subjects").first.value.text).to eq(employment_history_details.data["subjects"])
          expect(accordion.content.rows(id: "employment_history_main_duties").first.value.text).to eq(employment_history_details.data["main_duties"])
          expect(accordion.content.rows(id: "employment_history_started_on").first.value.text).to eq(employment_history_details.data["started_on"])
          expect(accordion.content.rows(id: "employment_history_current_role").first.value.text).to eq(employment_history_details.data["current_role"].capitalize)
          expect(accordion.content.rows(id: "employment_history_ended_on").first.value.text).to eq(employment_history_details.data["ended_on"])
          expect(accordion.content.rows(id: "employment_history_reason_for_leaving").first.value.text).to eq(employment_history_details.data["reason_for_leaving"])
        end
      end
    end

    show_page.steps(text: I18n.t("jobseekers.job_applications.build.personal_statement.heading")).first.within do |personal_statement|
      expect(personal_statement.body.text).to eq(job_application.application_data["personal_statement"])
    end

    job_application.references.order(:created_at).each_with_index do |reference_details, index|
      show_page.steps(text: I18n.t("jobseekers.job_applications.build.references.heading")).first.within do |reference|
        reference.body.accordions(text: reference_details.data["name"], id: "reference_#{index}").first.within do |accordion|
          expect(accordion.content.rows(id: "reference_job_title").first.value.text).to eq(reference_details.data["job_title"])
          expect(accordion.content.rows(id: "reference_organisation").first.value.text).to eq(reference_details.data["organisation"])
          expect(accordion.content.rows(id: "reference_relationship_to_applicant").first.value.text).to eq(reference_details.data["relationship_to_applicant"])
          expect(accordion.content.rows(id: "reference_email_address").first.value.text).to eq(reference_details.data["email_address"])
          expect(accordion.content.rows(id: "reference_phone_number").first.value.text).to eq(reference_details.data["phone_number"])
        end
      end
    end

    show_page.steps(text: I18n.t("jobseekers.job_applications.build.equal_opportunities.heading")).first.within do |equal_opportunities|
      expect(equal_opportunities.body.rows(id: "equal_opportunities_disability").first.value.text).to eq(job_application.application_data["disability"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_gender").first.value.text).to include(job_application.application_data["gender"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_gender").first.value.text).to include(job_application.application_data["gender_description"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_orientation").first.value.text).to include(job_application.application_data["orientation"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_orientation").first.value.text).to include(job_application.application_data["orientation_description"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_ethnicity").first.value.text).to include(job_application.application_data["ethnicity"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_ethnicity").first.value.text).to include(job_application.application_data["ethnicity_description"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_religion").first.value.text).to include(job_application.application_data["religion"].capitalize)
      expect(equal_opportunities.body.rows(id: "equal_opportunities_religion").first.value.text).to include(job_application.application_data["religion_description"].capitalize)
    end

    show_page.steps(text: I18n.t("jobseekers.job_applications.build.ask_for_support.heading")).first.within do |ask_for_support|
      expect(ask_for_support.body.rows(id: "ask_for_support_support_needed").first.value.text).to include(job_application.application_data["support_needed"].capitalize)
      expect(ask_for_support.body.rows(id: "ask_for_support_support_needed").first.value.text).to include(job_application.application_data["support_details"])
    end

    show_page.steps(text: I18n.t("jobseekers.job_applications.build.declarations.heading")).first.within do |declarations|
      expect(declarations.body.rows(id: "declarations_banned_or_disqualified").first.value.text).to eq(job_application.application_data["banned_or_disqualified"].capitalize)
      expect(declarations.body.rows(id: "declarations_close_relationships").first.value.text).to include(job_application.application_data["close_relationships"].capitalize)
      expect(declarations.body.rows(id: "declarations_close_relationships").first.value.text).to include(job_application.application_data["close_relationships_details"])
      expect(declarations.body.rows(id: "declarations_right_to_work_in_uk").first.value.text).to eq(job_application.application_data["right_to_work_in_uk"].capitalize)
    end
  end

  context "when job application status is shortlisted" do
    let(:job_application) { create(:job_application, :status_shortlisted, jobseeker: jobseeker, vacancy: vacancy) }

    it "displays what happens next notification" do
      expect(page).to have_content(I18n.t("jobseekers.job_applications.show.shortlist_alert.title"))
    end
  end

  context "when job application status is unsuccessful" do
    let(:job_application) { create(:job_application, :status_unsuccessful, jobseeker: jobseeker, vacancy: vacancy) }

    it "displays feedback" do
      expect(page).to have_content(I18n.t("jobseekers.job_applications.show.feedback"))
      expect(page).to have_content(job_application.application_data["rejection_reasons"])
    end
  end
end
