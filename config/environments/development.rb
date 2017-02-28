Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Application config

  config.action_mailer.default_url_options = {host: 'localhost'}
  config.action_mailer.delivery_method = :letter_opener

  config.default_from_mail = 'root@localhost'

  config.swagger_docs_base_path = 'http://localhost:3000/'
  config.api_contact_email = 'tech@mapotempo.com'
  config.api_contact_url = 'https://github.com/Mapotempo/mapotempo-web'

  def cache_factory(namespace, expires_in)
    ActiveSupport::Cache::FileStore.new(File.join('/home/nicolas/tmp/mapotempo/', namespace), namespace: namespace, expires_in: expires_in)
  end

  # config.optimize = Ort.new(
  #   cache_factory('optimizer', 60*60*24*10),
  #   'http://localhost:4567/0.1/optimize_tsptw'
  # )
  config.optimize = OptimizerWrapper.new(
    cache_factory('optimizer_wrapper', 60*60*24*10),
    'http://localhost:1791/0.1',
    'demo'
  )
  config.optimize_time = 600
  config.optimize_time_force = nil
  config.optimize_cluster_size = 0
  config.optimize_stop_soft_upper_bound = 0.3
  config.optimize_vehicle_soft_upper_bound = 0.3
  config.optimize_overload_multiplier = 0

  config.geocode_code_cache = cache_factory('geocode', 60*60*24*10)
  config.geocode_reverse_cache = cache_factory('geocode_reverse', 60*60*24*10)
  config.geocode_complete_cache = cache_factory('geocode_complete', 60*60*24*10)
  config.geocode_complete = false # Build time setting

  require 'geocode_addok_wrapper'
  config.geocode_geocoder = GeocodeAddokWrapper.new('http://geocode.beta.mapotempo.com/0.1', 'mapotempo-1-URIs98jpsSPNE6WAuocwqzDMzkljcX4A+yKSwinlM7w')

  config.router_osrm = Routers::Osrm.new(
    cache_factory('osrm_request', 60*60*24*1),
    cache_factory('osrm_result', 60*60*24*1)
  )
  config.router_otp = Routers::Otp.new(
    cache_factory('otp_request', 60*60*24*1),
    cache_factory('otp_result', 60*60*24*1)
  )
  config.router_here = Routers::Here.new(
    cache_factory('here_request', 60*60*24*1),
    cache_factory('here_result', 60*60*24*1),
    'https://route.api.here.com/routing',
    'https://matrix.route.api.here.com/routing',
    'https://isoline.route.api.here.com/routing',
    'yihiGwg1ibLi0q6BfBOa',
    '5GEGWZnjPAA-ZIwc7DF3Mw'
  )
  config.router_wrapper = Routers::RouterWrapper.new(
    cache_factory('router_wrapper_request', 60*60*24*1),
    cache_factory('router_wrapper_result', 60*60*24*1),
    'mapotempo-web-beta-d701e4a905fbd3c8d0600a2af433db8b'
  )

  config.devices.alyacom.api_url = 'http://partners.alyacom.fr/ws'
  config.devices.masternaut.api_url = 'http://ws.webservices.masternaut.fr/MasterWS/services'
  config.devices.orange.api_url = 'https://m2m-services.ft-dm.com'
  config.devices.tomtom.api_url = 'https://soap.business.tomtom.com/v1.30'
  config.devices.tomtom.api_key = '23ca1c50-2458-46f7-829f-27d476c30686'
  config.devices.trimble.api_url = 'https://soap.box.trimbletl.com/jboss-net/services'
  config.devices.cache_object = cache_factory('devices', 30)

  config.delayed_job_use = false

  config.self_care = false # Allow subscription and resiliation by the user himself

  config.max_destinations = 3000

  config.max_destinations_editable = 500
  config.manage_vehicles_only_admin = true

  config.enable_references = false
  config.enable_multi_visits = false

  # N 1 Queries: display only in log or console
  config.after_initialize do
    Bullet.enable               = true
    Bullet.alert                = false
    Bullet.bullet_logger        = false
    Bullet.console              = false
    Bullet.rails_logger         = true
    Bullet.add_footer           = false
    Bullet.counter_cache_enable = true
  end

end

Mapotempo::Application.config.default_from_mail = 'robot@mapotempo.com'

Devise.setup do |config|
  config.mailer_sender = 'robot@mapotempo.com'
end
