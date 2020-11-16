class Shared::NotificationComponentPreview::Form
  include ActiveModel::Model

  attr_reader :background, :dismiss, :title, :body, :variant

  def initialize(params = {})
    preview_criteria = if params[:shared_notification_component_preview_form].present?
      JSON.parse(params[:shared_notification_component_preview_form].to_json).symbolize_keys
    else
      {}
    end

    @background = preview_criteria[:background] || false
    @dismiss = preview_criteria[:dismiss] || false
    @title = preview_criteria[:title] || "title text"
    @body = preview_criteria[:body] || "body text"
    @variant = preview_criteria[:variant] || "success"
  end
end
