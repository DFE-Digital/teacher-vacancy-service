class Shared::NotificationComponentPreview < ViewComponent::Preview
  layout "preview"

  @variants = [
    OpenStruct.new(id: "success", name: "Success"),
    OpenStruct.new(id: "notice", name: "Notice"),
    OpenStruct.new(id: "danger", name: "Danger"),
  ]

  @form = Shared::NotificationComponentPreview::Form

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
