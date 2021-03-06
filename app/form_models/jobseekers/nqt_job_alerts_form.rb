class Jobseekers::NqtJobAlertsForm
  include ActiveModel::Model

  attr_accessor :keywords, :location, :email
  attr_writer :location_reference

  validates :keywords, presence: true
  validates :location, presence: true
  validates :email, presence: true
  validates :email, format: { with: Devise.email_regexp }

  validate :unique_job_alert

  def initialize(params = {})
    @keywords = params[:keywords]
    @location = params[:location]
    @email = params[:email]
    @location_reference = location_reference
  end

  def job_alert_params
    {
      email: email,
      frequency: :daily,
      search_criteria: nqt_job_alert_hash,
    }
  end

  def location_reference
    if LocationPolygon.include?(location)
      I18n.t("subscriptions.location_polygon_text", location: location)
    else
      I18n.t("subscriptions.location_radius_text", location: location, radius: 10)
    end
  end

  private

  def nqt_job_alert_hash
    {
      keyword: "nqt #{keywords}",
      location: location,
      radius: 10,
    }.compact
  end

  def unique_job_alert
    return unless Subscription.where(job_alert_params).exists?

    errors.add(:base, I18n.t("subscriptions.errors.duplicate_alert"))
  end
end
