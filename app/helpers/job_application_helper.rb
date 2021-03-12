module JobApplicationHelper
  JOB_APPLICATION_STATUS_TAG_COLOURS = {
    draft: "pink", submitted: "blue", shortlisted: "green", rejected: "red", withdrawn: "grey"
  }.freeze

  def job_application_status_tag(status)
    govuk_tag text: status, colour: JOB_APPLICATION_STATUS_TAG_COLOURS[status.to_sym], classes: "govuk-!-margin-bottom-2"
  end
end
