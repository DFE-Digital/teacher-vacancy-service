class Shared::FiltersComponentPreview < ViewComponent::Preview
  layout "preview"

  @options = [
    OpenStruct.new(id: 'remove_buttons', name: 'remove selected buttons'),
    OpenStruct.new(id: 'mobile_variant', name: 'mobile variant'),
    OpenStruct.new(id: 'close_all', name: 'close all groups'),
    OpenStruct.new(id: 'search', name: 'search checkbox group'),
    OpenStruct.new(id: 'mobile', name: 'scroll large groups'),
    OpenStruct.new(id: 'small', name: 'small size checkboxes'),
  ]

  @form = Shared::FiltersComponentPreview::Form

  def self.form
    @form
  end

  def self.options
    @options || []
  end

  def self.variants
    @variants || []
  end

  def default
  end
end
