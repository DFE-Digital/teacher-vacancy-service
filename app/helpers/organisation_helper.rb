module OrganisationHelper
  OFSTED_REPORT_ENDPOINT = 'https://reports.ofsted.gov.uk/oxedu_providers/full/(urn)/'

  def location(organisation)
    [organisation.name, organisation.town, organisation.county].reject(&:blank?).join(', ')
  end

  def full_address(organisation)
    [organisation.address, organisation.town, organisation.county, organisation.postcode].compact.join(', ')
  end

  def school_type_with_religious_character(school)
    school_type = school.school_type.label.singularize
    school.has_religious_character? ? school_type + ', ' + school.gias_data['ReligiousCharacter (name)'] : school_type
  end

  def school_size(school)
    if school.gias_data.present?
      return number_of_pupils(school) if school.gias_data['NumberOfPupils'].present?
      return school_capacity(school) if school.gias_data['SchoolCapacity'].present?
    end
    t('schools.no_information')
  end

  def ofsted_report(school)
    if school.gias_data.present? && school.gias_data['URN'].present?
      OFSTED_REPORT_ENDPOINT + school.gias_data['URN'].to_s
    end
  end

  def age_range(school)
    if school.minimum_age && school.maximum_age?
      "#{school.minimum_age} to #{school.maximum_age}"
    else
      t('schools.not_given')
    end
  end

  def edit_vacancy_section_number(section, organisation)
    sections = {
      job_location: 1,
      job_details: 2,
      pay_package: 3,
      important_dates: 4,
      supporting_documents: 5,
      application_details: 6,
      job_summary: 7,
    }
    section_number = organisation.is_a?(SchoolGroup) ? sections[section] : sections[section] - 1
    "#{section_number}."
  end

  def school_group_location_heading(job_location)
    I18n.t("school_groups.job_location_heading.#{job_location}")
  end

  private

  def number_of_pupils(school)
    t('schools.size.enrolled', pupils: pupils, number: school.gias_data['NumberOfPupils'])
  end

  def school_capacity(school)
    t('schools.size.up_to', capacity: school.gias_data['SchoolCapacity'], pupils: pupils)
  end

  def pupils
    t('schools.size.pupils').pluralize
  end
end