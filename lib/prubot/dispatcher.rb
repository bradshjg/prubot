# frozen_string_literal: true

require 'jwt'
require 'octokit'
require 'openssl'
require 'rack'

module Prubot
  # Prubot event dispatcher
  class Dispatcher
    EVENT_HEADER = 'HTTP_X_GITHUB_EVENT'

    def initialize(config, registry)
      @config = config
      @registry = registry
    end

    def call(env)
      request = Rack::Request.new(env)

      @config.configured? ? handle_event(request) : register_app(request)
    end

    private

    def register_app(request)
      [200, { 'Content-Type' => 'text/html' }, ['howdy']]
    end

    def handle_event(request)
      event, action, payload = validate request

      result = call_handlers event, action, payload, new_client

      generate_response event, action, result
    end


    def skip_verify?
      @config.secret == false
    end

    def validate_json_header(request)
      err_message = 'Invalid Content-Type HTTP header (must be application/json)'
      raise Error, err_message unless request.content_type == 'application/json'
    end

    def verify_signature(request)
      signature = request.env['HTTP_X_HUB_SIGNATURE_256']
      request.body.rewind
      payload_body = request.body.read
      digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @config.secret, payload_body)
      payload_digest = "sha256=#{digest}"
      raise Error, "Signatures didn't match!" unless Rack::Utils.secure_compare(payload_digest,
                                                                                signature)
    end

    def validate_payload(request)
      begin
        payload = JSON.parse(request.body.read)
      rescue JSON::JSONError
        raise Error, 'Invalid HTTP body (must be JSON)'
      end

      verify_signature request unless skip_verify?

      payload
    end

    def validate_event(request)
      request.get_header EVENT_HEADER
    rescue KeyError
      raise Error, 'Missing GitHub event HTTP header'
    end

    def validate(request)
      validate_json_header request

      payload = validate_payload request

      event = validate_event request

      action = payload['action']

      [event, action, payload]
    end

    def new_client
      Octokit::Client.new(bearer_token: new_jwt_token) # TODO: think about caching
    end

    def new_jwt_token
      private_key = OpenSSL::PKey::RSA.new(@config.key)

      payload = {}.tap do |opts|
        opts[:iat] = Time.now.to_i           # Issued at time.
        opts[:exp] = opts[:iat] + 600        # JWT expiration time is 10 minutes from issued time.
        opts[:iss] = @config.id # Integration's GitHub identifier.
      end

      JWT.encode(payload, private_key, 'RS256')
    end

    def call_handlers(event, action, payload, client)
      handlers = @registry.resolve event, action

      handlers.map { |handler| [handler.name, handler.run(payload, client)] }.to_h
    end

    def generate_response(event, action, result)
      status = result.empty? ? 404 : 200

      response_body = JSON.generate({ event: event, action: action, result: result })

      [status, { 'Content-Type' => 'application/json' }, [response_body]]
    end
  end
end
