require "rails_helper"

RSpec.describe "Editing a draft vacancy" do
  let(:publisher) { create(:publisher) }
  let(:school_group) { create(:trust) }
  let(:school1) { create(:school, name: "First school") }
  let(:school2) { create(:school, name: "Second school") }
  let(:vacancy) { create(:vacancy, :central_office, :draft) }

  before do
    login_publisher(publisher: publisher, organisation: school_group)
    vacancy.organisation_vacancies.create(organisation: school_group)
    SchoolGroupMembership.find_or_create_by(school_id: school1.id, school_group_id: school_group.id)
    SchoolGroupMembership.find_or_create_by(school_id: school2.id, school_group_id: school_group.id)
  end

  describe "#job_location" do
    scenario "can edit job location" do
      visit organisation_job_review_path(vacancy.id)

      expect(page).to have_content(I18n.t("school_groups.job_location_heading.central_office"))
      expect(page).to have_content(full_address(school_group))
      expect(Vacancy.find(vacancy.id).readable_job_location).to eq(
        I18n.t("publishers.organisations.readable_job_location.central_office"),
      )

      change_job_location(vacancy, "at_one_school")

      expect(page.current_path).to eq(organisation_job_build_path(vacancy.id, :schools))
      fill_in_school_form_field(school1)
      click_on I18n.t("buttons.update_job")

      expect(page.current_path).to eq(organisation_job_review_path(vacancy.id))
      expect(page).to have_content(I18n.t("school_groups.job_location_heading.at_one_school"))
      expect(page).to have_content(full_address(school1))
      expect(Vacancy.find(vacancy.id).readable_job_location).to eq(school1.name)

      change_job_location(vacancy, "at_one_school")

      expect(page.current_path).to eq(organisation_job_build_path(vacancy.id, :schools))
      fill_in_school_form_field(school2)
      click_on I18n.t("buttons.update_job")

      expect(page.current_path).to eq(organisation_job_review_path(vacancy.id))
      expect(page).to have_content(I18n.t("school_groups.job_location_heading.at_one_school"))
      expect(page).to have_content(full_address(school2))
      expect(Vacancy.find(vacancy.id).readable_job_location).to eq(school2.name)

      change_job_location(vacancy, "at_multiple_schools")

      expect(page.current_path).to eq(organisation_job_build_path(vacancy.id, :schools))
      check school1.name, name: "publishers_job_listing_schools_form[organisation_ids][]", visible: false
      check school2.name, name: "publishers_job_listing_schools_form[organisation_ids][]", visible: false
      click_on I18n.t("buttons.update_job")

      expect(page.current_path).to eq(organisation_job_review_path(vacancy.id))
      expect(page).to have_content(I18n.t("school_groups.job_location_heading.at_multiple_schools",
                                          organisation_type: "trust"))
      expect(Vacancy.find(vacancy.id).readable_job_location).to eq("More than one school (2)")

      change_job_location(vacancy, "central_office")

      expect(page.current_path).to eq(organisation_job_review_path(vacancy.id))
      expect(page).to have_content(I18n.t("school_groups.job_location_heading.central_office"))
      expect(page).to have_content(full_address(school_group))
      expect(Vacancy.find(vacancy.id).readable_job_location).to eq(
        I18n.t("publishers.organisations.readable_job_location.central_office"),
      )
    end
  end
end
