require "rails_helper"

RSpec.describe "Creating a vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school_group) { create(:local_authority) }
  let(:school1) { create(:school, name: "First school") }
  let(:school2) { create(:school, name: "Second school") }
  let(:vacancy) { build(:vacancy, :at_one_school, :complete) }

  before do
    login_publisher(publisher: publisher, organisation: school_group)
    SchoolGroupMembership.find_or_create_by(school_id: school1.id, school_group_id: school_group.id)
    SchoolGroupMembership.find_or_create_by(school_id: school2.id, school_group_id: school_group.id)
    allow(PublisherPreference).to receive(:find_by).and_return(instance_double(PublisherPreference))
  end

  scenario "resets session current_step" do
    page.set_rack_session(current_step: :review)

    visit organisation_path
    click_on I18n.t("buttons.create_job")

    fill_in_job_location_form_field(vacancy)
    click_on I18n.t("buttons.continue")

    expect(page.get_rack_session["current_step"]).to be nil
  end

  context "when job is located at a single school in the local authority" do
    let(:vacancy) { build(:vacancy, :at_one_school, :complete) }

    describe "#job_location" do
      scenario "displays error message unless a school is selected" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_location"))
        end

        fill_in_job_location_form_field(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_location"))
        end

        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_location"))
        end
        within("div.govuk-error-summary") do
          expect(page).to have_content(I18n.t("schools_errors.organisation_ids.blank"))
        end

        fill_in_school_form_field(school2)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 2, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_details"))
        end
      end
    end
  end

  context "when job is located at multiple schools in the local authority" do
    let(:vacancy) { build(:vacancy, :at_multiple_schools, :complete) }

    describe "#job_location" do
      scenario "displays error message unless at least 2 schools are selected" do
        visit organisation_path
        click_on I18n.t("buttons.create_job")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_location"))
        end

        fill_in_job_location_form_field(vacancy)
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_location"))
        end

        check school1.name, name: "publishers_job_listing_schools_form[organisation_ids][]", visible: false
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 1, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_location"))
        end
        within("div.govuk-error-summary") do
          expect(page).to have_content(I18n.t("schools_errors.organisation_ids.invalid"))
        end

        check school1.name, name: "publishers_job_listing_schools_form[organisation_ids][]", visible: false
        check school2.name, name: "publishers_job_listing_schools_form[organisation_ids][]", visible: false
        click_on I18n.t("buttons.continue")

        expect(page).to have_content(I18n.t("jobs.current_step", step: 2, total: 8))
        within("h2.govuk-heading-l") do
          expect(page).to have_content(I18n.t("jobs.job_details"))
        end
      end
    end
  end
end
