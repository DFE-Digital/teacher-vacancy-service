require "indexing"

class Publishers::Vacancies::ApplicationController < Publishers::BaseController
  helper_method :process_steps, :step_current, :steps_adjust

  def steps_adjust
    current_organisation.is_a?(SchoolGroup) ? 0 : 1
  end

  def step_current
    defined?(step) ? step : :review
  end

  def process_steps
    @process_steps ||= ProcessSteps.new(steps: steps_config, adjust: steps_adjust, step: step_current)
  end

  def all_steps_valid?
    step_valid?(Publishers::JobListing::JobDetailsForm) &&
      step_valid?(Publishers::JobListing::PayPackageForm) &&
      step_valid?(Publishers::JobListing::ImportantDatesForm) &&
      step_valid?(Publishers::JobListing::ApplyingForTheJobForm) &&
      step_valid?(Publishers::JobListing::JobSummaryForm)
  end

  def step_valid?(step_form)
    form = step_form.new(@vacancy.attributes)
    form.complete_and_valid?.tap do |valid|
      @vacancy.errors.merge!(form.errors)
      session[:current_step] = nil unless valid
    end
  end

  def convert_multiparameter_attributes_to_dates(form_key, fields)
    date_errors = {}
    fields.each do |field|
      date_params = flatten_date_hash(
        params[form_key].extract!(:"#{field}(1i)", :"#{field}(2i)", :"#{field}(3i)"), field
      )
      begin
        params[form_key][field] = date_params.all?(0) ? nil : Date.new(*date_params)
      rescue ArgumentError
        date_errors[field] = t("activerecord.errors.models.vacancy.attributes.#{field}.invalid")
      end
    end
    date_errors
  end

  def flatten_date_hash(hash, field)
    %w[1 2 3].map { |i| hash[:"#{field}(#{i}i)"].to_i }
  end

  def readable_job_location(job_location, school_name: nil, schools_count: nil)
    case job_location
    when "at_one_school"
      school_name
    when "at_multiple_schools"
      t("publishers.organisations.readable_job_location.at_multiple_schools_with_count", count: schools_count)
    when "central_office"
      t("publishers.organisations.readable_job_location.central_office")
    end
  end

  def redirect_saved_draft_with_message
    redirect_to jobs_with_type_organisation_path("draft"), success: t("messages.jobs.draft_saved_html", job_title: @vacancy.job_title)
  end

  def redirect_updated_job_with_message
    updated_job_path = @vacancy.published? ? edit_organisation_job_path(@vacancy.id) : organisation_job_review_path(@vacancy.id)
    redirect_to updated_job_path, success: {
      title: t("messages.jobs.listing_updated", job_title: @vacancy.job_title),
      body: t("messages.jobs.manage_jobs_html", link: helpers.back_to_manage_jobs_link(@vacancy)),
    }
  end

  def remove_google_index(job)
    return if DisableExpensiveJobs.enabled?

    url = job_url(job)
    RemoveGoogleIndexQueueJob.perform_later(url)
  end

  def replace_errors_in_form(errors, form_object)
    errors.each do |field, error|
      form_object.errors.delete(field)
      form_object.errors.add(field, error)
    end
  end

  def reset_session_vacancy!
    session[:job_location] = nil
    session[:current_step] = nil
  end

  def review_path_with_errors(vacancy)
    organisation_job_review_path(job_id: vacancy.id, anchor: "errors", source: "publish")
  end

  def set_vacancy
    @vacancy = current_organisation.all_vacancies.find(params[:job_id].presence || params[:id].presence)
  end

  def update_google_index(job)
    return if DisableExpensiveJobs.enabled?

    url = job_url(job)
    UpdateGoogleIndexQueueJob.perform_later(url)
  end
end
