class GeneralFeedback < ApplicationRecord
  include Auditor::Model

  enum visit_purpose: { other_purpose: 0, find_teaching_job: 1, list_teaching_job: 2 }
  enum user_participation_response: { interested: 0, not_interested: 1 }

  validates :visit_purpose, presence: true
  validates :visit_purpose_comment, length: { maximum: 1200 }, if: :visit_purpose_comment?
  validates :comment, length: { maximum: 1200 }, if: :comment?
  validates :user_participation_response, presence: true
  validates :email, email_address: { presence: true }, if: :user_is_interested?

  scope :published_on, (->(date) { where(created_at: date.all_day) })

  def user_is_interested?
    return true if user_participation_response == 'interested'
  end

  def to_row
    [
      Time.zone.now.to_s,
      visit_purpose,
      visit_purpose_comment,
      rating,
      comment,
      created_at.to_s,
      user_participation_response,
      email
    ]
  end
end
