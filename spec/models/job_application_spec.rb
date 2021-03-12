require "rails_helper"

RSpec.describe JobApplication, type: :model do
  it { is_expected.to belong_to(:jobseeker) }
  it { is_expected.to belong_to(:vacancy) }
  it { is_expected.to have_many(:job_application_details) }
  it { is_expected.to have_many(:employment_history) }
  it { is_expected.to have_many(:references) }

  context "when saving change to status" do
    subject { create(:job_application) }

    it "updates status timestamp" do
      freeze_time do
        expect { subject.submitted! }.to change { subject.submitted_at }.from(3.days.ago).to(Time.current)
      end
    end
  end
end
