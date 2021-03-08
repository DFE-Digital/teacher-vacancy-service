class Shared::FiltersComponent < GovukComponent::Base
  attr_accessor :filters, :form, :items, :options

  def initialize(filters:, form:, items:, options:, classes: [], html_attributes: {})
    super(classes: classes, html_attributes: html_attributes)

    @filters = filters
    @form = form
    @items = items
    @options = options
  end

  def render?
    filters.present?
  end

  def applied_text
    filters[:total_count].positive? ? "(#{filters[:total_count]} applied)" : ""
  end

  def display_remove_buttons
    filters[:total_count].positive? && options[:remove_buttons]
  end

  def mobile_modifier(selector)
    options[:mobile_variant] ? "#{selector}--mobile" : selector
  end
end
