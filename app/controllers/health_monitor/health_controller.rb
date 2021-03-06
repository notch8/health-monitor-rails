module HealthMonitor
  class IntentionalException < StandardError; end

  class HealthController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :set_cache_control_headers

    if Rails.version.starts_with? '3'
      before_filter :authenticate_with_basic_auth
    else
      before_action :authenticate_with_basic_auth
    end

    def check
      @statuses = statuses

      respond_to do |format|
        format.html
        format.json do
          render json: statuses.to_json, status: statuses[:status]
        end
        format.xml do
          render xml: statuses.to_xml, status: statuses[:status]
        end
      end
    end

    def fail
      raise IntentionalException.new("This route always fails to enable testing 500 pages and exception tracking")
    end

    private
    def set_cache_control_headers
      response.headers["Cache-Control"] = "public, no-cache"
    end

    def statuses
      res = HealthMonitor.check(request: request, params: providers_params)
      res.merge(env_vars)
    end

    def env_vars
      v = HealthMonitor.configuration.environment_variables || {}
      v.empty? ? {} : { environment_variables: v }
    end

    def authenticate_with_basic_auth
      return true unless HealthMonitor.configuration.basic_auth_credentials

      credentials = HealthMonitor.configuration.basic_auth_credentials
      authenticate_or_request_with_http_basic do |name, password|
        name == credentials[:username] && password == credentials[:password]
      end
    end

    def providers_params
      params.permit(providers: [])
    end
  end
end
