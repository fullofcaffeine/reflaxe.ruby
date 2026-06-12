class LegacyController < ActionController::Base
  def home
    render template: "legacy/home", layout: "application"
  end
end
