require "rails_helper"

RSpec.describe PerformancePlatformTransactionsQueueJob, type: :job do
  include ActiveJob::TestHelper

  let(:date_to_upload) { Date.current.beginning_of_day.in_time_zone - 1.day }

  subject(:job) { described_class.perform_later(date_to_upload.to_s) }

  it "enqueues a job to send all published job from yesterday" do
    pp = instance_double(PerformancePlatformSender::Transactions)

    expect(PerformancePlatformSender::Base).to receive(:by_type).with(:transactions).and_return(pp)
    expect(pp).to receive(:call).with(date: date_to_upload.to_s)

    perform_enqueued_jobs { job }
  end
end
