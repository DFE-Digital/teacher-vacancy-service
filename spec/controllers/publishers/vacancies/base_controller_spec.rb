require "rails_helper"

RSpec.describe Publishers::Vacancies::BaseController, type: :controller do
  describe "#update_google_index" do
    let!(:vacancy) { create(:vacancy) }

    context "when DisableExpensiveJobs is not enabled" do
      before { allow(DisableExpensiveJobs).to receive(:enabled?).and_return(false) }

      it "does perform the task" do
        expect(UpdateGoogleIndexQueueJob).to receive(:perform_later)
        controller.update_google_index(vacancy)
      end
    end

    context "when DisableExpensiveJobs is enabled" do
      before { allow(DisableExpensiveJobs).to receive(:enabled?).and_return(true) }

      it "does NOT perform the task" do
        expect(UpdateGoogleIndexQueueJob).not_to receive(:perform_later)
        controller.update_google_index(vacancy)
      end
    end
  end

  describe "#remove_google_index" do
    let!(:vacancy) { create(:vacancy) }

    context "when DisableExpensiveJobs is not enabled" do
      before { allow(DisableExpensiveJobs).to receive(:enabled?).and_return(false) }

      it "does perform the task" do
        expect(RemoveGoogleIndexQueueJob).to receive(:perform_later)
        controller.remove_google_index(vacancy)
      end
    end

    context "when DisableExpensiveJobs is enabled" do
      before { allow(DisableExpensiveJobs).to receive(:enabled?).and_return(true) }

      it "does NOT perform the task" do
        expect(RemoveGoogleIndexQueueJob).not_to receive(:perform_later)
        controller.remove_google_index(vacancy)
      end
    end
  end

  describe "#convert_multiparameter_attributes_to_dates" do
    let(:params) do
      { test_form: dates }
    end

    before do
      allow(controller).to receive(:params).and_return(params)
    end

    context "date present in params" do
      let(:dates) { { 'starts_on(3i)': "01", 'starts_on(2i)': "01", 'starts_on(1i)': "2020" } }

      it "converts date params to a Date object" do
        subject.convert_multiparameter_attributes_to_dates(:test_form, [:starts_on])
        expect(controller.params[:test_form][:starts_on]).to eq(Date.parse("2020-01-01"))
      end
    end

    context "invalid date in params" do
      let(:dates) { { 'starts_on(3i)': "100", 'starts_on(2i)': "", 'starts_on(1i)': "2020" } }

      it "the form object has an invalid date error" do
        expect(subject.convert_multiparameter_attributes_to_dates(:test_form, [:starts_on])[:starts_on]).to eq(
          I18n.t("activerecord.errors.models.vacancy.attributes.starts_on.invalid"),
        )
      end

      it "does not convert date params to a Date object" do
        expect(controller.params[:test_form][:starts_on]).to eq(nil)
      end
    end

    context "date not present in params" do
      let(:dates) { { 'starts_on(3i)': "", 'starts_on(2i)': "", 'starts_on(1i)': "" } }

      it "does not convert date params to a Date object" do
        subject.convert_multiparameter_attributes_to_dates(:test_form, [:starts_on])
        expect(controller.params[:test_form][:starts_on]).to eq(nil)
      end
    end
  end
end
