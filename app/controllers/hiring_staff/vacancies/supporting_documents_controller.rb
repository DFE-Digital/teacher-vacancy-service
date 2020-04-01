class HiringStaff::Vacancies::SupportingDocumentsController < HiringStaff::Vacancies::ApplicationController
  before_action :redirect_unless_vacancy

  def new
    @supporting_documents_form = SupportingDocumentsForm.new(session[:vacancy_attributes])
    @supporting_documents_form.valid? if %i[step_3_intro review].include?(session[:current_step])
  end

  def create
    @supporting_documents_form = SupportingDocumentsForm.new(supporting_documents_form_params)
    store_vacancy_attributes(@supporting_documents_form.vacancy.attributes)

    if @supporting_documents_form.valid?
      update_vacancy(supporting_documents_form_params, @vacancy)
      return redirect_to_next_step(@vacancy)
    end

    session[:current_step] = :step_3_intro unless session[:current_step].eql?(:review)
    redirect_to supporting_documents_school_job_path(anchor: 'errors')
  end

  private

  def supporting_documents_form_params
    (params[:supporting_documents_form] || params).permit(:supporting_documents).merge(completed_step: current_step)
  end

  def next_step
    @supporting_documents_form.supporting_documents == 'yes' ?
      school_job_documents_path(session_vacancy_id) : application_details_school_job_path
  end
end
