class Publishers::Vacancies::StatisticsController < Publishers::Vacancies::BaseController
  before_action :set_vacancy

  def update
    if valid?
      vacancy = Vacancy.find(params[:job_id])
      update_vacancy(vacancy)

      redirect_to jobs_with_type_organisation_path(type: :awaiting_feedback),
                  success: t("messages.jobs.feedback.submitted_html", job_title: vacancy.job_title)
    else
      redirect_to jobs_with_type_organisation_path(type: :awaiting_feedback), danger: {
        title: t("messages.jobs.feedback.error_title"),
        body: t("messages.jobs.feedback.error_body"),
      }
    end
  end

  private

  def update_vacancy(vacancy)
    vacancy.listed_elsewhere = statistics_params[:listed_elsewhere]
    vacancy.hired_status = statistics_params[:hired_status]

    # The expired vacancy can be invalid, if validations have been
    # added which weren't in place at time of publication.
    vacancy.save(validate: false)
  end

  def valid?
    statistics_params[:listed_elsewhere].present? && statistics_params[:hired_status].present?
  end

  def statistics_params
    params.require(:vacancy).permit(:listed_elsewhere, :hired_status)
  end
end
