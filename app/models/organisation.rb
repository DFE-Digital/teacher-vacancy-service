class Organisation < ApplicationRecord
  has_many :organisation_vacancies, dependent: :destroy
  has_many :vacancies, through: :organisation_vacancies

  scope :not_closed, -> { where.not(establishment_status: "Closed") }
  scope :schools, -> { where(type: "School") }
  scope :school_groups, -> { where(type: "SchoolGroup") }
  scope :trusts, -> { school_groups.where.not(uid: nil) }
  scope :local_authorities, -> { school_groups.where.not(local_authority_code: nil) }

  alias_attribute :data, :gias_data

  JOB_SORTING_OPTIONS_BASE = [
    [I18n.t("jobs.sort_by.expires_on.ascending"), "expires_on"],
    [I18n.t("jobs.sort_by.job_title.ascending"), "job_title"],
    [I18n.t("jobs.sort_by.location.ascending"), "readable_job_location"],
  ].freeze

  JOB_SORTING_OPTIONS_EXTENDED = (JOB_SORTING_OPTIONS_BASE + [I18n.t("jobs.sort_by.published_date.ascending"), "publish_on"]).freeze

  JOB_SORTING_OPTIONS = {
    published: JOB_SORTING_OPTIONS_BASE,
    pending: JOB_SORTING_OPTIONS_EXTENDED,
    draft: JOB_SORTING_OPTIONS_EXTENDED,
    expired: JOB_SORTING_OPTIONS_BASE,
  }.freeze

  def all_vacancies
    ids = is_a?(School) ? [id] : [id] + schools.pluck(:id)
    Vacancy.in_organisation_ids(ids)
  end
end
