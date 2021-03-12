class Jobseekers::JobApplicationsController < Jobseekers::BaseController
  before_action :redirect_if_job_application_exists, only: %i[new create]

  helper_method :job_application, :review_form, :vacancy

  def new
    request_event.trigger(:vacancy_apply_clicked, vacancy_id: vacancy.id)
  end

  def create
    new_job_application = current_jobseeker.job_applications.create(vacancy: vacancy)
    redirect_to jobseekers_job_application_build_path(new_job_application, :personal_details)
  end

  def submit
    return redirect_to expired_jobseekers_job_job_application_path(vacancy.id) unless vacancy.listed?

    if params[:commit] == t("buttons.save_as_draft")
      redirect_to jobseekers_job_applications_path, success: t("messages.jobseekers.job_applications.saved")
    elsif review_form.valid?
      job_application.update(status: :submitted, submitted_at: Time.zone.now)
      Jobseekers::JobApplicationMailer.application_submitted(job_application).deliver_later
      @application_feedback_form = Jobseekers::JobApplication::FeedbackForm.new
    else
      render :review
    end
  end

  def confirm_destroy
    raise ActionController::RoutingError, "Cannot delete non-draft application" unless job_application.draft?
  end

  def destroy
    raise ActionController::RoutingError, "Cannot delete non-draft application" unless job_application.draft?

    job_application.destroy
    redirect_to jobseekers_job_applications_path,
                success: t("messages.jobseekers.job_applications.draft_deleted", job_title: vacancy.job_title)
  end

  private

  def job_application
    @job_application ||= current_jobseeker.job_applications.find(params[:job_application_id] || params[:id])
  end

  def redirect_if_job_application_exists
    job_application = current_jobseeker.job_applications.find_by(vacancy_id: vacancy.id)
    return unless job_application

    if job_application.submitted?
      redirect_to jobseekers_job_applications_path,
                  danger: t("messages.jobseekers.job_applications.already_exists.submitted",
                            job_title: vacancy.job_title)
    elsif job_application.draft?
      redirect_to jobseekers_job_applications_path,
                  danger: t("messages.jobseekers.job_applications.already_exists.draft_html",
                            job_title: vacancy.job_title, link: jobseekers_job_application_review_path(job_application))
    end
  end

  def review_form
    @review_form ||= Jobseekers::JobApplication::ReviewForm.new(review_form_attributes)
  end

  def review_form_attributes
    case action_name
    when "review"
      {}
    when "submit"
      review_form_params
    end
  end

  def review_form_params
    params.require(:jobseekers_job_application_review_form).permit(:confirm_data_accurate, :confirm_data_usage)
          .merge(completed_steps: job_application.completed_steps)
  end

  def vacancy
    @vacancy ||= if params[:job_id].present?
                   Vacancy.live.find(params[:job_id])
                 else
                   job_application.vacancy
                 end
  end
end
