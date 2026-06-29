class ApiCorsMiddleware
  DEFAULT_ALLOWED_ORIGINS = "http://localhost:3000,http://127.0.0.1:3000"
  ALLOW_METHODS = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  ALLOW_HEADERS = "Authorization, Content-Type, X-Device-Id, X-Device-Name"

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    api_request = api_request?(request)

    if api_request && request.options?
      return [204, self.class.headers_for(request), []]
    end

    status, headers, body = @app.call(env)
    self.class.headers_for(request).each { |key, value| headers[key] = value } if api_request

    [status, headers, body]
  end

  def self.headers_for(request)
    origin = request.get_header("HTTP_ORIGIN").to_s
    return {} unless allowed_origins.include?(origin)

    {
      "Access-Control-Allow-Origin" => origin,
      "Access-Control-Allow-Methods" => ALLOW_METHODS,
      "Access-Control-Allow-Headers" => ALLOW_HEADERS,
      "Access-Control-Expose-Headers" => "Authorization",
      "Access-Control-Max-Age" => "7200",
      "Vary" => "Origin"
    }
  end

  def self.allowed_origins
    origins = ENV.fetch("FRONTEND_ORIGINS", DEFAULT_ALLOWED_ORIGINS)
    origins = DEFAULT_ALLOWED_ORIGINS if origins.blank?

    origins
       .split(",")
       .map(&:strip)
       .reject(&:empty?)
  end

  private

  def api_request?(request)
    request.path.start_with?("/api/")
  end
end
