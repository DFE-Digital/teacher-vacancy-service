class CopyVacancyForm < VacancyForm
  include ActiveModel::Model
  include VacancyExpiryTimeFieldValidations

  delegate :starts_on_yyyy, :starts_on_mm, :starts_on_dd,
           :ends_on_dd, :ends_on_mm, :ends_on_yyyy,
           :expires_on_dd, :expires_on_mm, :expires_on_yyyy,
           :publish_on_dd, :publish_on_mm, :publish_on_yyyy,
           :errors, to: :vacancy

  attr_accessor :expiry_time_hh, :expiry_time_mm, :expiry_time_meridiem

  validates_presence_of :publish_on
  validate :publish_on_must_not_be_in_the_past

  def publish_on_must_not_be_in_the_past
    return unless publish_on.present? && publish_on.past?

    errors.add(:publish_on, I18n.t('activerecord.errors.models.vacancy.attributes.publish_on.before_today'))
  end

  def initialize(vacancy:)
    @expiry_time_hh = vacancy.expiry_time&.strftime('%-l')
    @expiry_time_mm = vacancy.expiry_time&.strftime('%-M')
    @expiry_time_meridiem = vacancy.expiry_time&.strftime('%P')
    self.vacancy = vacancy
    self.job_title = vacancy.job_title

    self.publish_on = nil if vacancy.publish_on.past?
    reset_date_fields if vacancy.expires_on.past?
  end

  def apply_changes!(params = {})
    assign_attributes(params.extract!(:expiry_time_hh, :expiry_time_mm, :expiry_time_meridiem))
    vacancy.assign_attributes(params)
    vacancy.expiry_time = compose_expiry_time
    vacancy
  end

  private

  def compose_expiry_time
    return nil if [expiry_time_hh, expiry_time_mm, expiry_time_meridiem].any? { |attr| attr.to_s.empty? }

    expiry_time_string = "#{expires_on_dd}-#{expires_on_mm}-#{expires_on_yyyy}" \
                         " #{expiry_time_hh}:#{expiry_time_mm} #{expiry_time_meridiem}"

    Time.zone.parse(expiry_time_string)
  end

  def reset_date_fields
    self.starts_on  = nil
    self.ends_on    = nil
    self.expires_on = nil
    self.publish_on = nil
  end
end
