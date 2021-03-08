class Shared::NotificationComponentPreview < ViewComponent::Preview
  layout "preview"

  @variants = [
    OpenStruct.new(id: "success", name: "Success", title: "Success alert", description: "Sometimes dismissable."),
    OpenStruct.new(id: "notice", name: "Notice", title: "General information alert", description: "Sometimes dismissable."),
    OpenStruct.new(id: "danger", name: "Danger", title: "Warnings to user", description: "Never dismissable. This is a warning message or something potentially bad for the user."),
    OpenStruct.new(id: "empty", name: "Empty", title: "Inline emphasis", description: "Basic inline emphasis."),
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
