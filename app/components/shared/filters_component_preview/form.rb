class Shared::FiltersComponentPreview::Form
  include ActiveModel::Model

  attr_reader :remove_buttons, :mobile_variant, :close_all, :search, :scroll, :small, :options

  def initialize(params = {})
    preview_criteria = if params[:shared_filters_component_preview_form].present?
      JSON.parse(params[:shared_filters_component_preview_form].to_json).symbolize_keys
    else
      {}
    end

    # options
    @remove_buttons = preview_criteria[:remove_buttons] || false
    @mobile_variant = preview_criteria[:mobile_variant] || false
    @close_all = preview_criteria[:close_all] || false

    # # item
    @search = preview_criteria[:search] || false
    @scroll = preview_criteria[:scroll] || false

    # formbuilder
    @small = preview_criteria[:small] || false
  end
end
