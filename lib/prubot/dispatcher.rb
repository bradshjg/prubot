# frozen_string_literal: true

module Prubot
  # Prubot event dispatcher
  class Dispatcher
    EVENT_HEADER = 'HTTP_X_GITHUB_EVENT'

    def initialize
      @registry = {}
    end

    def register(event, block)
      if @registry.key? event
        @registry[event] << Handler.new(block)
      else
        @registry[event] = [Handler.new(block)]
      end
    end

    def call(env)
      request = Rack::Request.new(env)

      event, action, payload = validate request

      hit, result = call_handlers event, action, payload

      generate_response hit, result
    end

    private

    def validate_json_header(request)
      err_message = 'Invalid Content-Type HTTP header (must be application/json)'
      raise Error, err_message unless request.content_type == 'application/json'
    end

    def validate_payload(request)
      JSON.parse(request.body.read)
    rescue JSON::JSONError
      raise Error, 'Invalid HTTP body (must be JSON)'
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

    def call_event_handlers(event_key, payload)
      if @registry.key? event_key
        result = @registry[event_key].map { |handler| handler.run payload }
        hit = true
      else
        hit = false
        result = 'no matching handlers'
      end

      [hit, result]
    end

    def call_handlers(event, action, payload)
      result = {}

      event_hit, event_result = call_event_handlers event, payload
      result[event] = event_result

      if action
        event_action = [event, action].join('.')
        action_hit, action_result = call_event_handlers event_action, payload
        result[event_action] = action_result
      end

      hit = event_hit || action_hit

      [hit, result]
    end

    def generate_response(hit, result)
      if hit == true
        response_body = JSON.generate({ status: 'OK', description: result })
        status = 200
      else
        response_body = JSON.generate({ status: 'MISS', description: result })
        status = 404
      end

      [status, { 'Content-Type' => 'application/json' }, [response_body]]
    end
  end
end
