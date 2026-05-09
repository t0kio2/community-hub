class ApiCorsMiddleware
  DEFAULT_ALLOWED_ORIGINS = "http://localhost:3000,http://127.0.0.1:3000"
  ALLOW_METHODS = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  ALLOW_HEADERS = "Authorization, Content-Type, X-Device-Id, X-Device-Name"

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if api_request?(request) && request.options?
      return [204, cors_headers(request), []]
    end

    status, headers, body = @app.call(env)
    cors_headers(request).each { |key, value| headers[key] = value } if api_request?(request)

    [status, headers, body]
  end

  private

  def api_request?(request)
    request.path.start_with?("/api/")
  end

  def cors_headers(request)
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

  def allowed_origins
    ENV.fetch("FRONTEND_ORIGINS", DEFAULT_ALLOWED_ORIGINS)
       .split(",")
       .map(&:strip)
       .reject(&:empty?)
  end
end
