class Jobseekers::JobApplicationMailer < Jobseekers::BaseMailer
  def application_shortlisted(job_application)
    @job_application = job_application
    @vacancy = @job_application.vacancy
    @organisation_name = @vacancy.parent_organisation.name
    @contact_email = @vacancy.contact_email
    @jobseeker = @job_application.jobseeker

    @template = NOTIFY_JOBSEEKER_APPLICATION_SHORTLISTED_TEMPLATE
    @to = @jobseeker.email

    view_mail(@template, to: @to, subject: I18n.t("jobseekers.job_application_mailer.application_shortlisted.subject"))
  end

  def application_submitted(job_application)
    @vacancy = job_application.vacancy
    @organisation_name = @vacancy.parent_organisation.name
    @contact_email = @vacancy.contact_email
    @jobseeker = job_application.jobseeker

    @template = NOTIFY_JOBSEEKER_APPLICATION_SUBMITTED_TEMPLATE
    @to = @jobseeker.email

    view_mail(@template, to: @to, subject: I18n.t("jobseekers.job_application_mailer.application_submitted.subject"))
  end

  def application_unsuccessful(job_application)
    @job_application = job_application
    @vacancy = @job_application.vacancy
    @organisation_name = @vacancy.parent_organisation.name
    @contact_email = @vacancy.contact_email
    @jobseeker = @job_application.jobseeker

    @template = NOTIFY_JOBSEEKER_APPLICATION_UNSUCCESSFUL_TEMPLATE
    @to = @jobseeker.email

    view_mail(@template, to: @to, subject: I18n.t("jobseekers.job_application_mailer.application_unsuccessful.subject"))
  end
end
