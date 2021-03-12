require "rails_helper"

RSpec.describe Jobseekers::JobApplicationMailer, type: :mailer do
  let(:jobseeker) { create(:jobseeker, email: email) }
  let(:email) { "test@email.com" }
  let(:organisation) { build(:school) }
  let(:vacancy) { build(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:contact_email) { vacancy.contact_email }

  let(:expected_data) do
    {
      notify_template: notify_template,
      email_identifier: anonymised_form_of(email),
      user_anonymised_jobseeker_id: anonymised_form_of(jobseeker.id),
      user_anonymised_publisher_id: nil,
    }
  end

  describe "#application_rejected" do
    let(:job_application) { build(:job_application, :status_rejected, jobseeker: jobseeker, vacancy: vacancy) }
    let(:mail) { described_class.application_rejected(job_application) }
    let(:notify_template) { NOTIFY_JOBSEEKER_APPLICATION_REJECTED_TEMPLATE }

    it "sends a `jobseeker_application_rejected` email" do
      expect(mail.subject).to eq(I18n.t("jobseekers.job_application_mailer.application_rejected.subject"))
      expect(mail.to).to eq(["test@email.com"])
      expect(mail.body.encoded).to include(I18n.t("jobseekers.job_application_mailer.application_rejected.heading"))
                               .and include(I18n.t("jobseekers.job_application_mailer.shared.more_info.description",
                                                   email: "[#{contact_email}](mailto:#{contact_email})"))
    end

    it "triggers a `jobseeker_application_rejected` email event" do
      expect { mail.deliver_now }.to have_triggered_event(:jobseeker_application_rejected).with_data(expected_data)
    end
  end

  describe "#application_shortlisted" do
    let(:job_application) { build(:job_application, :status_shortlisted, jobseeker: jobseeker, vacancy: vacancy) }
    let(:mail) { described_class.application_shortlisted(job_application) }
    let(:notify_template) { NOTIFY_JOBSEEKER_APPLICATION_SHORTLISTED_TEMPLATE }

    it "sends a `jobseeker_application_shortlisted` email" do
      expect(mail.subject).to eq(I18n.t("jobseekers.job_application_mailer.application_shortlisted.subject"))
      expect(mail.to).to eq(["test@email.com"])
      expect(mail.body.encoded).to include(I18n.t("jobseekers.job_application_mailer.application_shortlisted.heading"))
                               .and include(I18n.t("jobseekers.job_application_mailer.shared.more_info.description",
                                                   email: "[#{contact_email}](mailto:#{contact_email})"))
    end

    it "triggers a `jobseeker_application_shortlisted` email event" do
      expect { mail.deliver_now }.to have_triggered_event(:jobseeker_application_shortlisted).with_data(expected_data)
    end
  end

  describe "#application_submitted" do
    let(:job_application) { build(:job_application, :status_submitted, jobseeker: jobseeker, vacancy: vacancy) }
    let(:mail) { described_class.application_submitted(job_application) }
    let(:notify_template) { NOTIFY_JOBSEEKER_APPLICATION_SUBMITTED_TEMPLATE }

    it "sends a `jobseeker_application_submitted` email" do
      expect(mail.subject).to eq(I18n.t("jobseekers.job_application_mailer.application_submitted.subject"))
      expect(mail.to).to eq(["test@email.com"])
      expect(mail.body.encoded).to include(I18n.t("jobseekers.job_application_mailer.application_submitted.heading",
                                                  organisation_name: organisation.name))
                               .and include(I18n.t("jobseekers.job_application_mailer.shared.more_info.description",
                                                   email: "[#{contact_email}](mailto:#{contact_email})"))
    end

    it "triggers a `jobseeker_application_submitted` email event" do
      expect { mail.deliver_now }.to have_triggered_event(:jobseeker_application_submitted).with_data(expected_data)
    end
  end
end
