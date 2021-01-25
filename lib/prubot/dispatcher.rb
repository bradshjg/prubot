# frozen_string_literal: true

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

      event, action, payload = validate request

      result = call_handlers event, action, payload

      generate_response event, action, result
    end

    private

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

    def call_handlers(event, action, payload)
      handlers = @registry.resolve event, action

      handlers.map { |handler| [handler.name, handler.run(payload)] }.to_h
    end

    def generate_response(event, action, result)
      status = result.empty? ? 404 : 200

      response_body = JSON.generate({ event: event, action: action, result: result })

      [status, { 'Content-Type' => 'application/json' }, [response_body]]
    end
  end
end
