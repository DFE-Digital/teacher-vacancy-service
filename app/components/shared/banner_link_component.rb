class Shared::BannerLinkComponent < ViewComponent::Base
  attr_accessor :icon_class, :link_id, :link_method, :link_path, :link_text, :params

  def initialize(icon_class:, link_id:, link_method:, link_path:, link_text:, params: nil)
    @icon_class = icon_class
    @link_id = link_id
    @link_method = link_method
    @link_path = link_path
    @link_text = link_text
    @params = params
  end

  def call
    button_to link_text, link_path,
              method: link_method, params: params,
              class: "banner-link-component__button govuk-body-s govuk-!-font-weight-bold icon icon--left icon--#{icon_class}", id: link_id, form_class: "banner-link-component"
  end
end
