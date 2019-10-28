module FeedbackValidations
  extend ActiveSupport::Concern

  included do
    validates :user_participation_response, presence: true
    validates :email, email_address: { presence: true }, if: :user_is_interested?
  end

  def user_is_interested?
    user_participation_response == 'interested'
  end
end
