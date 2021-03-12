class JobApplication < ApplicationRecord
  before_save :update_status_timestamp, if: :will_save_change_to_status?

  extend ArrayEnum

  array_enum completed_steps: {
    personal_details: 0,
    professional_status: 2,
    employment_history: 3,
    personal_statement: 4,
    references: 5,
    equal_opportunities: 6,
    ask_for_support: 7,
    declarations: 8,
  }

  # If you want to add a status, be sure to add a `status_at` column to the `job_applications` table
  enum status: { draft: 0, submitted: 1, shortlisted: 2, unsuccessful: 3, withdrawn: 4 }, _default: 0

  belongs_to :jobseeker
  belongs_to :vacancy

  has_many :job_application_details, dependent: :destroy
  has_many :employment_history, -> { where(details_type: "employment_history") }, class_name: "JobApplicationDetail"
  has_many :references, -> { where(details_type: "references") }, class_name: "JobApplicationDetail"

  private

  def update_status_timestamp
    self["#{status}_at"] = Time.current
  end
end
