module JobApplicationHelper
  PUBLISHER_STATUS_MAPPINGS = { submitted: "review", unsuccessful: "rejected" }.freeze

  JOB_APPLICATION_STATUS_TAG_COLOURS = {
    draft: "pink", submitted: "blue", shortlisted: "green", unsuccessful: "red", withdrawn: "grey"
  }.freeze

  def job_application_status_tag(status)
    govuk_tag text: status,
              colour: JOB_APPLICATION_STATUS_TAG_COLOURS[status.to_sym],
              classes: "govuk-!-margin-bottom-2"
  end

  def publisher_job_application_status_tag(status)
    govuk_tag text: PUBLISHER_STATUS_MAPPINGS[status.to_sym],
              colour: JOB_APPLICATION_STATUS_TAG_COLOURS[status.to_sym],
              classes: "govuk-!-margin-bottom-2"
  end
end
