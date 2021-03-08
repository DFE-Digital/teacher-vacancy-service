class Shared::NotificationComponent < GovukComponent::Base
  def initialize(variant: "success",
                 links: nil,
                 title: "",
                 body: "",
                 dismiss: true,
                 background: false,
                 icon: false,
                 classes: [],
                 html_attributes: {})

    super(classes: classes, html_attributes: html_attributes)
    @body = body
    @title = title
    @variant = variant
    @links = links
    @dismiss = variant == "danger" ? false : dismiss
    @background = background
    @icon = icon
    @html_attributes = html_attributes || default_html_attributes
  end

  def notification_classes
    applied_class = "govuk-notification--#{@variant} "
    applied_class += background_class if @background
    applied_class += icon_class if @icon
    applied_class += dismissable_class if @dismiss
    applied_class
  end

  def background_class
    "govuk-notification__background "
  end

  def icon_class
    "icon icon--left icon--#{@variant} "
  end

  def dismissable_class
    "js-dismissible"
  end

  def default_html_attributes
    if @variant == "empty"
      {}
    else
      { role: "alert", tabindex: "-1" }
    end
  end
end
