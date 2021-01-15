class Publisher < ApplicationRecord
  include Auditor::Model

  has_many :emergency_login_keys

  has_many :dsi_memberships
  has_many :organisations, through: :dsi_memberships

  def accepted_terms_and_conditions?
    accepted_terms_at.present?
  end

  def update_organisations_from_dsi_data(dsi_data)
    # TODO
  end
end
