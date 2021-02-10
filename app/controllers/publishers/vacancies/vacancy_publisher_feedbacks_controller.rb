class Publishers::Vacancies::VacancyPublisherFeedbacksController < Publishers::Vacancies::ApplicationController
  before_action :set_vacancy, only: %i[new create]

  def new
    return redirect_to organisation_path, notice: t(".already_submitted") if already_submitted?

    @vacancy_publisher_feedback_form = Publishers::Vacancies::VacancyPublisherFeedbackForm.new
  end

  def create
    @vacancy_publisher_feedback_form = Publishers::Vacancies::VacancyPublisherFeedbackForm.new(feedback_params)

    if @vacancy_publisher_feedback_form.valid?
      @feedback = Feedback.create(feedback_params)
      Auditor::Audit.new(@vacancy, "vacancy.publish_feedback.create", current_publisher_oid).log
      trigger_feedback_provided_event
      redirect_to organisation_path, success: t("messages.jobs.feedback.submitted_html", job_title: @vacancy.job_title)
    else
      render "new"
    end
  end

  private

  def feedback_params
    params.require(:publishers_vacancies_vacancy_publisher_feedback_form)
          .permit(:comment, :user_participation_response, :email)
          .merge(feedback_type: "vacancy_publisher", vacancy_id: @vacancy.id, publisher_id: current_publisher.id)
  end

  def set_vacancy
    @vacancy = Vacancy.published.find(params[:job_id])
  end

  def already_submitted?
    # TODO: remove the first part of the disjunction when VacancyPublishFeedback class is removed
    @vacancy.publish_feedback.present? || Feedback.find_by(vacancy_id: @vacancy.id)&.vacancy_publisher?
  end
end