class Shared::ReviewComponentPreview < ViewComponent::Preview
  layout "preview"

  @variants = []

  @form = Shared::ReviewComponentPreview::Form

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
