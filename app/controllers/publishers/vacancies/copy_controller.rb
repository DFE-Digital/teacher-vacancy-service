class Publishers::Vacancies::CopyController < Publishers::Vacancies::BaseController
  before_action :set_vacancy
  before_action :set_up_copy_form, only: %i[create]

  def new
    reset_date_fields if @vacancy.publish_on.past?
    @copy_form = Publishers::JobListing::CopyVacancyForm.new(@vacancy.attributes.symbolize_keys)
  end

  def create
    if @copy_form.complete_and_valid?
      new_vacancy = CopyVacancy.new(@vacancy).call
      new_vacancy.assign_attributes(@copy_form.params_to_save)
      new_vacancy.refresh_slug
      new_vacancy.save
      update_google_index(new_vacancy) if new_vacancy.listed?
      redirect_to organisation_job_review_path(new_vacancy.id)
    else
      replace_errors_in_form(@date_errors, @copy_form)
      render :new
    end
  end

  private

  def copy_form_params
    params.require(:publishers_job_listing_copy_vacancy_form)
          .permit(:state, :job_title, :publish_on, :expires_on, :starts_on,
                  :expires_at_hh, :expires_at_mm, :expires_at_meridiem)
  end

  def set_up_copy_form
    @date_errors = convert_multiparameter_attributes_to_dates(
      :publishers_job_listing_copy_vacancy_form, %i[publish_on expires_on starts_on]
    )
    @copy_form = Publishers::JobListing::CopyVacancyForm.new(copy_form_params)
  end

  def reset_date_fields
    @vacancy.expires_on = nil
    @vacancy.starts_on = nil
    @vacancy.publish_on = nil
  end
end
