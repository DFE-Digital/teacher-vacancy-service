class HiringStaff::Vacancies::VacancyPublishFeedbackController < HiringStaff::Vacancies::ApplicationController
  def new
    vacancy = Vacancy.published.find_by!(id: params[:job_id])
    if vacancy.publish_feedback.present?
      return redirect_to school_path,
                         notice: I18n.t('errors.vacancy_publish_feedback.already_submitted')
    end

    @feedback = VacancyPublishFeedback.new
  end

  def create
    vacancy = Vacancy.published.find_by!(id: params[:job_id])
    @feedback = VacancyPublishFeedback.create(
      vacancy_publish_feedback_params.merge(vacancy: vacancy, user: current_user)
    )

    return render 'new' unless @feedback.save

    Auditor::Audit.new(vacancy, 'vacancy.publish_feedback.create', current_session_id).log

    redirect_to school_path, notice: I18n.t('messages.feedback.submitted')
  end

  private

  def vacancy_publish_feedback_params
    params.require(:vacancy_publish_feedback).permit(:rating, :comment, :user_participation_response, :email)
  end
end
