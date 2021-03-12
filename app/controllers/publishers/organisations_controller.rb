class Publishers::OrganisationsController < Publishers::BaseController
  before_action :redirect_to_user_preferences

  def show
    @multiple_organisations = session_has_multiple_organisations?
    @organisation = current_organisation
    @selected_type = params[:type]

    @filters = Publishers::VacancyFilter.new(current_publisher, current_organisation).to_h
    @managed_organisations_form = Publishers::ManagedOrganisationsForm.new(@filters)

    @sort = Publishers::VacancySort.new(@organisation, @selected_type).update(column: params[:sort_column])
    @sort_form = SortForm.new(@sort.column)

    @awaiting_feedback_count = @organisation.vacancies.awaiting_feedback.count
    flash.now[:notice] = t(".awaiting", count: @awaiting_feedback_count) if @awaiting_feedback_count.positive?

    render_draft_saved_message if params[:from_review]
  end

  private

  def current_publisher_preferences
    return unless current_organisation.is_a?(SchoolGroup)

    PublisherPreference.find_by(publisher_id: current_publisher.id, school_group_id: current_organisation.id)
  end

  def redirect_to_user_preferences
    return unless current_organisation.is_a?(SchoolGroup) && current_publisher_preferences.nil?

    redirect_to organisation_managed_organisations_path
  end

  def session_has_multiple_organisations?
    session[:publisher_multiple_organisations] == true
  end

  def render_draft_saved_message
    vacancy = current_organisation.all_vacancies.find(params[:from_review])
    flash.now[:success] = t("messages.jobs.draft_saved_html", job_title: vacancy.job_title)
  end
end
