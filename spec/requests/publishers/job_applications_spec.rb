require "rails_helper"

RSpec.describe "Job applications", type: :request do
  let(:organisation) { build(:school) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:job_application) { create(:job_application, :status_submitted, vacancy: vacancy) }
  let(:publisher) { create(:publisher, accepted_terms_at: 1.day.ago) }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    # TODO: Remove this stub when publishers are associated to organisations
    allow_any_instance_of(Publishers::AuthenticationConcerns).to receive(:current_organisation).and_return(organisation)
    sign_in(publisher, scope: :publisher)
  end

  describe "GET #reject" do
    context "when the job application status is not draft or withdrawn" do
      it "renders the reject page" do
        expect(get(organisation_job_job_application_reject_path(vacancy.id, job_application.id)))
          .to render_template(:reject)
      end
    end

    context "when the job application status is draft" do
      let(:job_application) { create(:job_application, :status_draft, vacancy: vacancy) }

      it "raises an error" do
        expect { get(organisation_job_job_application_reject_path(vacancy.id, job_application.id)) }
          .to raise_error(ActionController::RoutingError, /Cannot reject/)
      end
    end

    context "when the job application status is withdrawn" do
      let(:job_application) { create(:job_application, :status_withdrawn, vacancy: vacancy) }

      it "raises an error" do
        expect { get(organisation_job_job_application_reject_path(vacancy.id, job_application.id)) }
          .to raise_error(ActionController::RoutingError, /Cannot reject/)
      end
    end
  end

  describe "GET #shortlist" do
    context "when the job application status is not draft or withdrawn" do
      it "renders the show page" do
        expect(get(organisation_job_job_application_shortlist_path(vacancy.id, job_application.id)))
          .to render_template(:shortlist)
      end
    end

    context "when the job application status is draft" do
      let(:job_application) { create(:job_application, :status_draft, vacancy: vacancy) }

      it "raises an error" do
        expect { get(organisation_job_job_application_shortlist_path(vacancy.id, job_application.id)) }
          .to raise_error(ActionController::RoutingError, /Cannot shortlist/)
      end
    end

    context "when the job application status is withdrawn" do
      let(:job_application) { create(:job_application, :status_withdrawn, vacancy: vacancy) }

      it "raises an error" do
        expect { get(organisation_job_job_application_shortlist_path(vacancy.id, job_application.id)) }
          .to raise_error(ActionController::RoutingError, /Cannot shortlist/)
      end
    end
  end

  describe "GET #show" do
    context "when the job application status is not draft or withdrawn" do
      it "renders the show page" do
        expect(get(organisation_job_job_application_path(vacancy.id, job_application.id))).to render_template(:show)
      end
    end

    context "when the job application status is draft" do
      let(:job_application) { create(:job_application, :status_draft, vacancy: vacancy) }

      it "raises an error" do
        expect { get(organisation_job_job_application_path(vacancy.id, job_application.id)) }
          .to raise_error(ActionController::RoutingError, /Cannot view/)
      end
    end

    context "when the job application status is withdrawn" do
      let(:job_application) { create(:job_application, :status_withdrawn, vacancy: vacancy) }

      it "raises an error" do
        expect { get(organisation_job_job_application_path(vacancy.id, job_application.id)) }
          .to raise_error(ActionController::RoutingError, /Cannot view/)
      end
    end
  end

  describe "POST #update_status" do
    let(:commit) { I18n.t("buttons.shortlist") }
    let(:params) { { publishers_job_application_update_status_form: { test: "param" }, commit: commit } }

    context "when the job application status is not draft or withdrawn" do
      context "when shortlisting a job application" do
        let(:commit) { I18n.t("buttons.shortlist") }

        it "updates the status" do
          expect { post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params) }
            .to change { job_application.reload.status }.from("submitted").to("shortlisted")
        end

        it "sends an email" do
          assert_emails 1 do
            post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params)
          end
        end

        it "redirects to job applications page" do
          # TODO: Update expectation when redirect is updated
          expect(post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params))
            .to redirect_to(organisation_jobs_path)
        end
      end

      context "when rejecting a job application" do
        let(:commit) { I18n.t("buttons.reject") }

        it "updates the status" do
          expect { post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params) }
            .to change { job_application.reload.status }.from("submitted").to("unsuccessful")
        end

        it "sends an email" do
          assert_emails 1 do
            post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params)
          end
        end

        it "redirects to job applications page" do
          # TODO: Update expectation when redirect is updated
          expect(post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params))
            .to redirect_to(organisation_jobs_path)
        end
      end
    end

    context "when the job application status is draft" do
      let(:job_application) { create(:job_application, :status_draft, vacancy: vacancy) }

      it "raises an error" do
        expect { post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params) }
          .to raise_error(ActionController::RoutingError, /Cannot shortlist or reject/)
      end
    end

    context "when the job application status is withdrawn" do
      let(:job_application) { create(:job_application, :status_withdrawn, vacancy: vacancy) }

      it "raises an error" do
        expect { post(organisation_job_job_application_update_status_path(vacancy.id, job_application.id), params: params) }
          .to raise_error(ActionController::RoutingError, /Cannot shortlist or reject/)
      end
    end
  end
end
