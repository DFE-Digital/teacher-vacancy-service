require "rails_helper"

RSpec.describe Shared::ProcessStepsComponent, type: :component do
  let(:vacancy) { create(:vacancy, completed_step: completed_step) }
  let(:completed_step) { 0 }
  let(:current_step_number) { 1 }
  let(:current_organisation) { build(:school_group) }
  let(:process_title) { "Process title" }
  let(:steps) do
    {
      job_location: { number: 1, title: I18n.t("jobs.job_location") },
      schools: { number: 1, title: I18n.t("jobs.job_location") },
      job_details: { number: 2, title: I18n.t("jobs.job_details") },
      pay_package: { number: 3, title: I18n.t("jobs.pay_package") },
      important_dates: { number: 4, title: I18n.t("jobs.important_dates") },
      supporting_documents: { number: 5, title: I18n.t("jobs.supporting_documents") },
      documents: { number: 5, title: I18n.t("jobs.supporting_documents") },
      applying_for_the_job: { number: 6, title: I18n.t("jobs.applying_for_the_job") },
      job_summary: { number: 7, title: I18n.t("jobs.job_summary") },
      review: { number: 8, title: I18n.t("jobs.review_heading") },
    }.freeze
  end

  let(:steps_adjust) { current_organisation.is_a?(SchoolGroup) ? 0 : 1 }

  before do
    allow_any_instance_of(Publishers::AuthenticationConcerns).to receive(:current_organisation).and_return(current_organisation)
  end

  let!(:inline_component) { render_inline(described_class.new(process: vacancy, service: ProcessSteps.new({ steps: steps, adjust: steps_adjust, step: :job_location }), title: process_title)) }

  it "renders the sidebar" do
    expect(rendered_component).to include(process_title)
  end

  it "renders the job details step" do
    expect(rendered_component).to include(I18n.t("jobs.job_details"))
  end

  it "renders the pay package step" do
    expect(rendered_component).to include(I18n.t("jobs.pay_package"))
  end

  it "renders the important dates step" do
    expect(rendered_component).to include(I18n.t("jobs.important_dates"))
  end

  it "renders the supporting documents step" do
    expect(rendered_component).to include(I18n.t("jobs.supporting_documents"))
  end

  it "renders the application details step" do
    expect(rendered_component).to include(I18n.t("jobs.applying_for_the_job"))
  end

  it "renders the job summary step" do
    expect(rendered_component).to include(I18n.t("jobs.job_summary"))
  end

  it "renders the review step" do
    expect(rendered_component).to include(I18n.t("jobs.review_heading"))
  end

  context "when a School user creates a job" do
    let(:current_organisation) { build(:school) }
    let!(:inline_component) { render_inline(described_class.new(process: vacancy, service: ProcessSteps.new({ steps: steps, adjust: steps_adjust, step: :job_location }), title: process_title)) }

    it "does not render the job location step" do
      expect(rendered_component).not_to include(I18n.t("jobs.job_location"))
    end
  end

  context "when a SchoolGroup user creates a job" do
    it "renders the job location step" do
      expect(rendered_component).to include(I18n.t("jobs.job_location"))
    end
  end

  context "when a step is active" do
    let(:component_active_step) do
      inline_component.css(".process-steps-component__step--active .process-steps-component__circle-background").to_html
    end

    it "renders active class on current_step" do
      expect(component_active_step).to include(current_step_number.to_s)
    end
  end

  context "when a step is completed" do
    let(:completed_step) { 1 }
    let(:current_step) { 2 }
    let(:component_completed_step) do
      inline_component.css(".process-steps-component__step--visited .process-steps-component__circle-background").to_html
    end

    it "renders visited class on completed steps" do
      expect(component_completed_step).to include(component_completed_step.to_s)
    end
  end
end
