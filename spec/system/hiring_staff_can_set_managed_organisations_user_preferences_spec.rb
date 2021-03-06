require "rails_helper"

RSpec.describe "Hiring staff can set managed organisations user preferences" do
  let(:school1) { create(:school, name: "Happy Rainbows School") }
  let(:school2) { create(:school, name: "Dreary Grey School") }
  let(:school3) { create(:school, :closed, name: "Closed School") }
  let(:publisher_preference) { PublisherPreference.last }

  before do
    allow(Rails.configuration.allowed_local_authorities)
      .to receive(:include?).with(school_group.local_authority_code).and_return(true)

    SchoolGroupMembership.find_or_create_by(school_id: school1.id, school_group_id: school_group.id)
    SchoolGroupMembership.find_or_create_by(school_id: school2.id, school_group_id: school_group.id)
    SchoolGroupMembership.find_or_create_by(school_id: school3.id, school_group_id: school_group.id)

    stub_accepted_terms_and_conditions
    OmniAuth.config.test_mode = true

    stub_authentication_step(school_urn: nil, trust_uid: school_group.uid, la_code: school_group.local_authority_code)
    stub_authorisation_step
    stub_sign_in_with_multiple_organisations

    visit root_path
    sign_in_publisher
  end

  after do
    OmniAuth.config.mock_auth[:default] = nil
    OmniAuth.config.mock_auth[:dfe] = nil
    OmniAuth.config.test_mode = false
  end

  context "when current_organisation is a trust" do
    let(:school_group) { create(:trust) }

    scenario "it shows the trust head office option" do
      visit organisation_managed_organisations_path
      expect(page.current_path).to eq(organisation_managed_organisations_path)
      expect(page).to have_content(I18n.t("publishers.organisations.managed_organisations.show.options.school_group"))
    end

    scenario "it does not show closed school option" do
      visit organisation_managed_organisations_path
      expect(page.current_path).to eq(organisation_managed_organisations_path)
      expect(page).not_to have_content(school3.name)
    end

    scenario "it allows school group users to select which organisation's jobs they want to manage" do
      visit organisation_managed_organisations_path

      expect(page).to have_content(
        I18n.t("publishers.organisations.managed_organisations.show.panel.title", organisation: school_group.name),
      )

      check I18n.t("publishers.organisations.managed_organisations.show.options.school_group")
      check school1.name

      click_on I18n.t("buttons.continue")

      expect(page.current_path).to eq(organisation_path)
      expect(publisher_preference.managed_school_ids).to eq([school_group.id, school1.id])
    end

    scenario "it allows school group users to select to manage all jobs" do
      visit organisation_managed_organisations_path

      expect(page).to have_content(
        I18n.t("publishers.organisations.managed_organisations.show.panel.title", organisation: school_group.name),
      )

      check I18n.t("publishers.organisations.managed_organisations.show.options.all")
      check school1.name

      click_on I18n.t("buttons.continue")

      expect(page.current_path).to eq(organisation_path)
      expect(publisher_preference.managed_organisations).to eq("all")
      expect(publisher_preference.managed_school_ids).to eq([])
    end
  end

  context "when current_organisation is a local_authority" do
    let(:school_group) { create(:local_authority) }

    scenario "it does not show the trust head office option" do
      visit organisation_managed_organisations_path
      expect(page.current_path).to eq(organisation_managed_organisations_path)
      expect(page).not_to have_content(
        I18n.t("publishers.organisations.managed_organisations.show.options.school_group"),
      )
    end
  end
end
