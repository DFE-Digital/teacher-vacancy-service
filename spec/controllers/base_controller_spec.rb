require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def test_action
      head :ok
    end
  end

  before do
    routes.draw { get "test_action" => "anonymous#test_action" }
  end

  describe "page_visited events" do
    it "triggers a `page_visited` event on a request" do
      expect { get :test_action }.to have_triggered_event(:page_visited).with_request_data
    end
  end

  describe "click_event events" do
    it "triggers a `click_event` event on a request" do
      expect { get :test_action, params: { click_event: "this_event" } }
        .to have_triggered_event(:this_event).with_request_data
    end
  end

  describe "sets headers" do
    it "robots are asked not to index or to follow" do
      get :test_action
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end
  end

  describe "#strip_empty_checkboxes" do
    controller do
      before_action { strip_empty_checkboxes(%i[nothing_to_remove_field array_field string_field], :test_form) }

      def strip_test_action
        head :ok
      end
    end

    before do
      routes.draw { get "strip_test_action" => "anonymous#strip_test_action" }

      get :strip_test_action, params: {
        test_form: {
          nothing_to_remove_field: %w[first_box second_box],
          array_field: ["first_box", ""],
          string_field: "",
        },
      }
    end

    it "removes empty checkboxes as expected" do
      expect(controller.params[:test_form][:nothing_to_remove_field]).to eq(%w[first_box second_box])
      expect(controller.params[:test_form][:array_field]).to eq(%w[first_box])
      expect(controller.params[:test_form][:string_field]).to eq("")
    end
  end

  describe "AB testing helpers" do
    let(:ab_tests) { double(AbTests, current_variants: {}) }

    before do
      allow(AbTests).to receive(:new).and_return(ab_tests)
      get :test_action, params: params
    end

    describe "#ab_variant_for" do
      context "when no override is given" do
        let(:params) { {} }

        it "returns the variant as determined by AbTests" do
          expect(ab_tests).to receive(:variant_for).with(:foo).and_return(:bar)
          expect(controller.view_context.ab_variant_for(:foo)).to eq(:bar)
        end
      end

      context "when an override is given" do
        let(:params) { { ab_test_override: { foo: :baz } } }

        it "returns the variant as determined by AbTests" do
          expect(ab_tests).not_to receive(:variant_for).with(:foo)
          expect(controller.view_context.ab_variant_for(:foo)).to eq(:baz)
        end
      end
    end
  end
end
