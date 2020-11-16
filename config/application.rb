require_relative "boot"

require "kaminari"
require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
# require 'sprockets/railtie'
# require "rails/test_unit/railtie"
require "view_component/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# These are needed in configuration before autoloading kicks in
require_relative "../lib/logging/colour_log_formatter"
require_relative "../lib/modules/aws_ip_ranges"
require_relative "../lib/vcap_services"

module TeacherVacancyService
  class Application < Rails::Application
    config.load_defaults 6.1

    config.time_zone = "Europe/London"

    # Automatically add `id: uuid` on any generated migrations
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.action_view.sanitized_allowed_tags = %w[p br strong em ul li h1 h2 h3 h4 h5]
    config.action_view.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

    # Settings in config/environments/* take precedence over those
    # specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Use custom error pages
    config.exceptions_app = routes

    config.active_job.queue_adapter = :sidekiq

    config.action_mailer.delivery_method = :notify
    config.action_mailer.deliver_later_queue_name = :high
    config.action_mailer.notify_settings = {
      api_key: ENV["NOTIFY_KEY"],
    }

    # Set up backing services through VCAP_SERVICES if running on Cloudfoundry (GOV.UK PaaS)
    if ENV["VCAP_SERVICES"].present?
      vcap_services = VcapServices.new(ENV["VCAP_SERVICES"])

      config.redis_queue_url = vcap_services.named_service_url(:redis, "queue")
      config.redis_cache_url = vcap_services.named_service_url(:redis, "cache")
    else
      redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")

      config.redis_queue_url = "#{redis_url}/0"
      config.redis_cache_url = "#{redis_url}/1"
    end

    config.ab_tests = config_for(:ab_tests)

    config.allowed_local_authorities = config_for(:allowed_local_authorities)

    config.analytics = config_for(:analytics)
    config.analytics_pii = config_for(:analytics_pii)

    config.enforce_local_authority_allowlist = ActiveModel::Type::Boolean.new.cast(ENV["ENFORCE_LOCAL_AUTHORITY_ALLOWLIST"])

    config.algolia_index_prefix = ENV.fetch("ALGOLIA_INDEX_PREFIX", nil)

    config.geocoder_lookup = :default

    config.view_component.preview_paths << "#{Rails.root}/app/components"
    config.view_component.preview_route = "/previews"
    config.view_component.preview_controller = "PreviewController"
  end
end
