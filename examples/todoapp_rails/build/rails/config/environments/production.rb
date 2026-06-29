Rails.application.configure do
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = true
  config.assets.compile = false
  config.active_support.report_deprecations = false
end
