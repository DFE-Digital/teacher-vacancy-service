class Publishers::BaseController < ApplicationController
  before_action :authenticate_publisher!,
                :check_terms_and_conditions

  def check_terms_and_conditions
    redirect_to terms_and_conditions_path unless current_publisher.accepted_terms_and_conditions?
  end
end
