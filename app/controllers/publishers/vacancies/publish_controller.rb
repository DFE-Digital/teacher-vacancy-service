class Publishers::Vacancies::PublishController < Publishers::Vacancies::BaseController
  before_action :set_vacancy

  def create
    if @vacancy.published?
      redirect_to organisation_job_path(@vacancy.id), notice: t("messages.jobs.already_published")
    elsif all_steps_valid? && PublishVacancy.new(@vacancy, current_publisher, current_organisation).call
      update_google_index(@vacancy) if @vacancy.listed?
      reset_session_vacancy!
      redirect_to organisation_job_summary_path(@vacancy.id)
    else
      redirect_to review_path_with_errors(@vacancy), danger: {
        title: t("errors.jobs.unable_to_publish_title"), body: t("errors.jobs.unable_to_publish_body")
      }
    end
  end
end
