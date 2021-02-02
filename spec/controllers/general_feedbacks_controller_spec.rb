require "rails_helper"

RSpec.describe GeneralFeedbacksController, type: :controller do
  describe "#create" do
    let(:feedback) { instance_double(Feedback).as_null_object }
    let(:feedback_form) { instance_double(GeneralFeedbackForm) }
    let(:feedback_form_valid?) { true }
    let(:recaptcha_valid?) { true }
    let(:recaptcha_score) { 0.9 }

    before do
      allow(Feedback).to receive(:new).and_return(feedback)
      allow(GeneralFeedbackForm).to receive(:new).and_return(feedback_form)
      allow(feedback_form).to receive(:valid?).and_return(feedback_form_valid?)
      allow(feedback_form).to receive(:class).and_return(GeneralFeedbackForm)
      allow(controller).to receive(:recaptcha_reply).and_return({ "score" => recaptcha_score })
      allow(controller).to receive(:verify_recaptcha).and_return(recaptcha_valid?)
    end

    context "when verify_recaptcha is valid" do
      it "verifies the recaptcha" do
        expect(controller).to receive(:verify_recaptcha)
        post :create, params: { general_feedback_form: attributes_for(:feedback) }
      end

      it "sends the Feedback instance and action (both required) when it verifies the recaptcha" do
        expect(controller).to receive(:verify_recaptcha).with(model: feedback, action: "feedback")
        post :create, params: { general_feedback_form: attributes_for(:feedback) }
      end

      it "sets the recaptcha score on the Feedback record" do
        expect(feedback).to receive(:recaptcha_score=).with(0.9)
        post :create, params: { general_feedback_form: attributes_for(:feedback) }
      end

      it "saves the Feedback record" do
        expect(feedback).to receive(:save)
        post :create, params: { general_feedback_form: attributes_for(:feedback) }
      end

      context "and the recaptcha score is not valid" do
        let(:recaptcha_score) { 0.1 }

        it "redirects to invalid_recaptcha_path" do
          post :create, params: { general_feedback_form: attributes_for(:feedback) }
          expect(response).to redirect_to(invalid_recaptcha_path(form_name: "General feedback form"))
        end

        it "does not save the Feedback record" do
          expect(feedback).not_to receive(:save)
          post :create, params: { general_feedback_form: attributes_for(:feedback) }
        end
      end

      context "and the recaptcha score is valid" do
        context "and feedback is valid" do
          it "saves the Feedback record" do
            expect(feedback).to receive(:save)
            post :create, params: { general_feedback_form: attributes_for(:feedback) }
          end

          it "redirects to root" do
            post :create, params: { general_feedback_form: attributes_for(:feedback) }
            expect(response).to redirect_to(root_url)
          end
        end

        context "and feedback is not valid" do
          let(:feedback_form_valid?) { false }

          it "does not save the Feedback record" do
            expect(feedback).not_to receive(:save)
            post :create, params: { general_feedback_form: attributes_for(:feedback) }
          end

          it "renders :new" do
            post :create, params: { general_feedback_form: attributes_for(:feedback) }
            expect(response).to render_template(:new)
          end
        end
      end
    end

    context "when verify_recaptcha is not valid" do
      let(:recaptcha_valid?) { false }

      it "does not set the recaptcha score on the Feedback record" do
        expect(feedback).not_to receive(:recaptcha_score=)
        post :create, params: { general_feedback_form: attributes_for(:feedback) }
      end

      context "and feedback form is valid" do
        it "saves the Feedback record" do
          expect(feedback).to receive(:save)
          post :create, params: { general_feedback_form: attributes_for(:feedback) }
        end

        it "redirects to root" do
          post :create, params: { general_feedback_form: attributes_for(:feedback) }
          expect(response).to redirect_to(root_url)
        end
      end

      context "and feedback form is not valid" do
        let(:feedback_form_valid?) { false }

        it "does not save the Feedback record" do
          expect(feedback).not_to receive(:save)
          post :create, params: { general_feedback_form: attributes_for(:feedback) }
        end

        it "renders :new" do
          post :create, params: { general_feedback_form: attributes_for(:feedback) }
          expect(response).to render_template(:new)
        end
      end
    end
  end
end
