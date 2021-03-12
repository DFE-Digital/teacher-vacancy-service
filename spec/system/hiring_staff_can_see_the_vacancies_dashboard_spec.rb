require "rails_helper"

RSpec.describe "Hiring staff can see the vacancies dashboard" do
  let(:publisher) { create(:publisher) }

  scenario "school with geolocation" do
    school = create(:school, northing: "1", easting: "2")

    login_publisher(publisher: publisher, organisation: school)
    vacancy = create(:vacancy, status: "published")
    vacancy.organisation_vacancies.create(organisation: school)

    visit organisation_path

    click_on(vacancy.job_title)

    expect(page).to have_content(vacancy.job_title)
    expect(page).to have_content(vacancy.job_summary)
  end

  context "with no jobs" do
    scenario "hiring staff see a message informing them they have no jobs" do
      school = create(:school)

      login_publisher(publisher: publisher, organisation: school)
      visit organisation_path

      expect(page).to have_content(I18n.t("publishers.no_vacancies_component.heading"))
    end
  end

  context "viewing the lists of jobs on the school page" do
    let(:school) { create(:school) }

    let!(:published_vacancy) { create(:vacancy, :published) }
    let!(:draft_vacancy) { create(:vacancy, :draft) }
    let!(:pending_vacancy) { create(:vacancy, :future_publish) }
    let!(:expired_vacancy) do
      expired_vacancy = build(:vacancy, :expired)
      expired_vacancy.save(validate: false)
      expired_vacancy
    end

    before do
      published_vacancy.organisation_vacancies.create(organisation: school)
      draft_vacancy.organisation_vacancies.create(organisation: school)
      pending_vacancy.organisation_vacancies.create(organisation: school)
      expired_vacancy.organisation_vacancies.create(organisation: school)
      login_publisher(publisher: publisher, organisation: school)
    end

    scenario "jobs are split into sections" do
      vacancies = create_list(:vacancy, 5, :published)
      vacancies.each { |vacancy| vacancy.organisation_vacancies.create(organisation: school) }

      visit organisation_path

      expect(page).to have_content(I18n.t("publishers.vacancies_component.published.tab_heading"))
      expect(page).to have_content(I18n.t("publishers.vacancies_component.draft.tab_heading"))
      expect(page).to have_content(I18n.t("publishers.vacancies_component.pending.tab_heading"))
      expect(page).to have_content(I18n.t("publishers.vacancies_component.expired.tab_heading"))
      expect(page).to have_content(I18n.t("publishers.vacancies_component.awaiting_feedback.tab_heading"))
    end

    scenario "with published vacancies" do
      visit organisation_path

      within(".moj-primary-navigation__list") do
        click_on(I18n.t("publishers.vacancies_component.published.tab_heading"))
      end

      within(".moj-filter-layout__content") do
        expect(page).to have_content(published_vacancy.job_title)
        expect(page).to have_css(".card-component", count: 1)
      end
    end

    scenario "with draft vacancies" do
      visit organisation_path

      within(".moj-primary-navigation__list") do
        click_on(I18n.t("publishers.vacancies_component.draft.tab_heading"))
      end

      within(".moj-filter-layout__content") do
        expect(page).to have_content(I18n.t("jobs.manage.draft.time_created"))
        expect(page).to have_content(format_date(draft_vacancy.created_at.to_date))
        expect(page).to have_content(format_date(draft_vacancy.updated_at.to_date))
        expect(page).to have_content(draft_vacancy.job_title)
        expect(page).to have_css(".card-component", count: 1)
      end
    end

    scenario "with pending vacancies" do
      visit organisation_path

      within(".moj-primary-navigation__list") do
        click_on(I18n.t("publishers.vacancies_component.pending.tab_heading"))
      end

      within(".moj-filter-layout__content") do
        expect(page).to have_content(I18n.t("jobs.publication_date"))
        expect(page).to have_content(pending_vacancy.job_title)
        expect(page).to have_content(format_date(pending_vacancy.publish_on))
        expect(page).to have_content(format_date(pending_vacancy.expires_on))
        expect(page).to have_css(".card-component", count: 1)
      end
    end

    scenario "with expired vacancies" do
      visit organisation_path

      within(".moj-primary-navigation__list") do
        click_on(I18n.t("publishers.vacancies_component.expired.tab_heading"))
      end

      within(".moj-filter-layout__content") do
        expect(page).to have_content(expired_vacancy.job_title)
        expect(page).to have_content(format_date(expired_vacancy.expires_on))
        expect(page).to have_content(format_date(expired_vacancy.publish_on))
        expect(page).to have_css(".card-component", count: 1)
      end
    end

    context "when a draft vacancy has been updated" do
      let!(:draft_vacancy) do
        create(:vacancy, :draft, created_at: 3.days.ago, updated_at: 1.day.ago)
      end

      before { draft_vacancy.organisation_vacancies.create(organisation: school) }

      scenario "shows the last updated at" do
        draft_vacancy
        visit organisation_path

        within(".moj-primary-navigation__list") do
          click_on(I18n.t("publishers.vacancies_component.draft.tab_heading"))
        end

        within(".moj-filter-layout__content") do
          expect(page).to have_content(format_date(draft_vacancy.created_at.to_date))
          expect(page).to have_content(format_date(draft_vacancy.updated_at.to_date))
        end
      end
    end
  end
end
