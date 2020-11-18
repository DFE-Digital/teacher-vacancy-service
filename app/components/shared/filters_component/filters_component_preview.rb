class Shared::FiltersComponentPreview < ViewComponent::Preview
  layout "preview"

  @variants = []
  @groups = []

  @form = Shared::FiltersComponentPreview::Form

  def self.variants
    @variants
  end

  def self.form
    @form
  end

  def self.groups
    @groups
  end

  def default
  end
end
