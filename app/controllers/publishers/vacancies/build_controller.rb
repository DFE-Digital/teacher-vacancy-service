class Publishers::Vacancies::BuildController < Publishers::Vacancies::BaseController
  include Wicked::Wizard
  include Publishers::Wizardable
  include OrganisationHelper

  steps :job_location, :schools, :job_details, :pay_package, :important_dates, :documents, :applying_for_the_job,
        :job_summary

  before_action :set_vacancy
  before_action :convert_date_params, only: %i[update]
  before_action :strip_checkbox_params, only: %i[update]
  before_action :set_multiple_schools
  before_action :set_school_options
  before_action :set_up_show_form, only: %i[show]
  before_action :set_up_update_form, only: %i[update]

  def show
    case step
    when :job_location
      skip_step if current_organisation.is_a?(School)
    when :schools
      job_location = session[:job_location].presence || @vacancy.job_location
      skip_step if current_organisation.is_a?(School) || job_location == "central_office"
    when :job_details
      @job_details_back_path = @vacancy.central_office? ? wizard_path(:job_location) : wizard_path(:schools)
    when :documents
      return redirect_to(organisation_job_documents_path(@vacancy.id))
    end

    render_wizard
  end

  def update
    if params[:commit] == t("buttons.save_and_return_later")
      save_listing_and_return_later
    elsif @form.complete_and_valid?
      update_vacancy
      if params[:commit] == t("buttons.update_job")
        update_listing
      elsif params[:commit] == t("buttons.continue") && session[:current_step] == :review
        update_incomplete_listing
      else
        render_wizard @vacancy
      end
    else
      replace_errors_in_form(@date_errors, @form) if step == :important_dates
      render_wizard
    end
  end

  private

  def convert_date_params
    return unless step == :important_dates

    publish_in_past = @vacancy.published? && @vacancy.reload.publish_on.past?
    delete_publish_on_params if @vacancy.published? && @vacancy.reload.publish_on.past?
    dates_to_convert = publish_in_past ? %i[starts_on expires_on] : %i[starts_on publish_on expires_on]
    @date_errors = convert_multiparameter_attributes_to_dates(:publishers_job_listing_important_dates_form, dates_to_convert)
  end

  def delete_publish_on_params
    params.require(:publishers_job_listing_important_dates_form)
          .extract!("publish_on(3i)", "publish_on(2i)", "publish_on(1i)")
  end

  def finish_wizard_path
    edit_organisation_job_path(@vacancy.id)
  end

  def save_listing_and_return_later
    update_vacancy
    @vacancy.save(validate: false)
    redirect_saved_draft_with_message
  end

  def set_multiple_schools
    return unless step == :schools && current_organisation.is_a?(SchoolGroup)

    job_location = session[:job_location].presence || @vacancy.job_location
    @multiple_schools = job_location == "at_multiple_schools"
  end

  def set_school_options
    return unless step == :schools && current_organisation.is_a?(SchoolGroup)

    @school_options = current_organisation.schools.not_closed.order(:name).map do |school|
      OpenStruct.new({ id: school.id, name: school.name, address: full_address(school) })
    end
  end

  def set_up_show_form
    return if step == "wicked_finish"

    @form = FORMS[step].new(@vacancy.attributes.symbolize_keys.merge(organisation_ids: @vacancy.organisation_ids))
  end

  def set_up_update_form
    @form = FORMS[step].new(send(FORM_PARAMS[step], params))
    @form.id = @vacancy.id
    @form.status = @vacancy.status
  end

  def strip_checkbox_params
    return unless STRIP_CHECKBOXES.key?(step)

    strip_empty_checkboxes(STRIP_CHECKBOXES[step], "publishers_job_listing_#{step}_form".to_sym)
  end

  def update_incomplete_listing
    @vacancy.save
    redirect_updated_job_with_message
  end

  def update_listing
    job_location = session[:job_location].presence || @vacancy.job_location
    @vacancy.save
    if step == :job_location && job_location != "central_office"
      redirect_to wizard_path(:schools)
    else
      redirect_updated_job_with_message
    end
  end

  def update_vacancy
    @vacancy.assign_attributes(@form.params_to_save)
    @vacancy.refresh_slug
    update_google_index(@vacancy) if @vacancy.listed?
  end
end
