class Publishers::VacancyFilter
  attr_reader :managed_school_ids, :managed_organisations

  def initialize(publisher, organisation)
    school_group = (organisation if organisation.is_a?(SchoolGroup))
    @publisher_preference = PublisherPreference.find_or_initialize_by(publisher: publisher, school_group: school_group)
    @managed_school_ids = @publisher_preference.managed_school_ids
    @managed_organisations = @publisher_preference.managed_organisations
  end

  def update(params)
    @managed_school_ids = params[:managed_school_ids]&.reject(&:blank?)
    @managed_organisations = params[:managed_organisations]

    if managed_organisations&.include?("all") || (managed_organisations.blank? && managed_school_ids&.none?)
      @managed_organisations = "all"
      @managed_school_ids = []
    end

    @publisher_preference.update(managed_organisations: managed_organisations, managed_school_ids: managed_school_ids)
  end

  def to_h
    {
      managed_organisations: managed_organisations,
      managed_school_ids: managed_school_ids,
    }
  end
end
