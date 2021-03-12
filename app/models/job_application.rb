class JobApplication < ApplicationRecord
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

  enum status: { draft: 0, submitted: 1, shortlisted: 2, rejected: 3, withdrawn: 4 }, _default: 0

  belongs_to :jobseeker
  belongs_to :vacancy

  has_many :job_application_details, dependent: :destroy
  has_many :employment_history, -> { where(details_type: "employment_history") }, class_name: "JobApplicationDetail"
  has_many :references, -> { where(details_type: "references") }, class_name: "JobApplicationDetail"
end
