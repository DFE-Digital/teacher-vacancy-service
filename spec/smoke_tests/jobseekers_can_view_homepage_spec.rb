require "capybara/rspec"
require "i18n_helper"

DEFAULT_DOMAIN = "teaching-vacancies.service.gov.uk".freeze

RSpec.describe "Page availability", js: true, smoke_test: true do
  after do |example|
    # Print page on failure to help triage failures
    puts page.html if example.exception
  end

  context "Jobseeker visits vacancy page" do
    let(:smoke_test_domain) { (ENV.include? "SMOKE_TEST_DOMAIN") && !ENV["SMOKE_TEST_DOMAIN"].empty? ? ENV["SMOKE_TEST_DOMAIN"] : DEFAULT_DOMAIN }
    let(:page) { Capybara::Session.new(:selenium_chrome_headless) }

    it "ensures users can search and view a job vacancy page" do
      page.visit "https://#{smoke_test_domain}/404" # you need to be on the domain to set the cookie

      page.driver.browser.manage.add_cookie(name: "smoke_test", value: "1", domain: smoke_test_domain)
      page.driver.browser.manage.add_cookie(name: "consented-to-cookies", value: "no", domain: smoke_test_domain)

      page.visit "https://#{smoke_test_domain}/"
      expect(page).to have_content(I18n.t("jobs.heading"))

      page.fill_in I18n.t("jobs.filters.keyword"), with: "Maths"
      page.click_on I18n.t("buttons.search")

      expect(page).to have_content(I18n.t("subscriptions.link.text"))

      vacancy_page = page.first(".view-vacancy-link")
      unless vacancy_page.nil?
        vacancy_page.click
        expect(page).to have_content(I18n.t("jobs.job_summary"))
        expect(page.current_url).to include("https://#{smoke_test_domain}/jobs/")
      end
    end
  end
end
