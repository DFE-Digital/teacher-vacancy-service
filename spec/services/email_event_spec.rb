require "rails_helper"

RSpec.describe EmailEvent do
  subject { described_class.new(notify_template, email, jobseeker: jobseeker, publisher: publisher) }

  let(:notify_template) { "test_template" }
  let(:email) { "test@email.com" }
  let(:jobseeker) { instance_double(Jobseeker, id: 1234, email: "test@email.com") }
  let(:publisher) { instance_double(Publisher, oid: 4321) }

  describe "#trigger" do
    let(:expected_data) do
      {
        type: :best_ever_email_event,
        occurred_at: "1999-12-31T23:59:59.000000Z",
        notify_template: notify_template,
        email_identifier: anonymised_form_of("test@email.com"),
        user_anonymised_jobseeker_id: anonymised_form_of("1234"),
        user_anonymised_publisher_id: anonymised_form_of("4321"),
        data: [{ key: "foozy", value: "barzy" }],
      }
    end

    it "enqueues a SendEventToDataWarehouseJob with the expected payload" do
      expect(SendEventToDataWarehouseJob).to receive(:perform_later).with("events", expected_data)

      travel_to(Time.zone.local(1999, 12, 31, 23, 59, 59)) do
        subject.trigger(:best_ever_email_event, foozy: "barzy")
      end
    end
  end
end