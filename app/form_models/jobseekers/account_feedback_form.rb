class Jobseekers::AccountFeedbackForm
  include ActiveModel::Model

  attr_accessor :origin, :comment, :rating

  validates :comment, length: { maximum: 1200 }, if: -> { comment.present? }
  validates :rating, inclusion: { in: Feedback.ratings.keys }
end
