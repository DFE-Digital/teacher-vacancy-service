require "rails_helper"

RSpec.describe "Editing a School’s details" do
  let(:publisher) { create(:publisher) }
  let(:school) { create(:school) }

  before { login_publisher(publisher: publisher, organisation: school) }

  scenario "it allows school users to edit the school details" do
    visit organisation_path

    expect(page).to have_content(school.name)
    expect(page).to have_content(school.description)
    expect(page).to have_content(school.url)

    click_on "Change school description"
    expect(find_field("publishers_organisation_form[website]").value).to eq(school.url)
    fill_in "publishers_organisation_form[description]", with: "Our school prides itself on excellence."
    fill_in "publishers_organisation_form[website]", with: "https://www.this-is-a-test-url.tvs"
    click_on I18n.t("buttons.save_changes")

    expect(page).to have_content("Our school prides itself on excellence.")
    expect(page).to have_content("https://www.this-is-a-test-url.tvs")
    expect(page).to have_content("Details updated for #{school.name}")
    expect(page.current_path).to eq(organisation_path)
  end
end
