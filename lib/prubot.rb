# frozen_string_literal: true

require 'json'
require 'set'

require 'rack'

require 'prubot/version'

# Prubot is a Ruby Probot (https://github.com/probot/probot) clone.
# Probot is a framework for building GitHub Apps to automate and improve your workflow.
module Prubot
  EVENT_HEADER = 'HTTP_X_GITHUB_EVENT'

  class Error < StandardError; end

  # Prubot application
  class Application
    attr_reader :app, :config

    def initialize
      @configured = false
      @dispatcher = Dispatcher.new
      @app = Rack::Builder.new
      setup_routing
    end

    def setup_routing
      dispatcher = @dispatcher
      @app.map '/' do
        run dispatcher
      end
    end

    def configured?
      @configured
    end

    def configure(**kwds)
      config_attrs = Set[:id, :key, :secret]
      raise Error, "Valid config keys are #{config_attrs}" unless kwds.keys.to_set == config_attrs

      @config = kwds
      @configured = true
    end

    def register_event(event, &block)
      @dispatcher.register(event, block)
    end
  end

  # Prubot event dispatcher
  class Dispatcher
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

    def validate_json_header(request)
      err_message = 'Invalid Content-Type HTTP header (must be application/json)'
      raise Error, err_message unless request.content_type == 'application/json'
    end

    def validate_json_body(request)
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

      payload = validate_json_body request

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

    def call(env)
      request = Rack::Request.new(env)

      event, action, payload = validate request

      hit, result = call_handlers event, action, payload

      generate_response hit, result
    end
  end

  # Prubot event handler boilerplate
  class Handler
    attr_reader :payload

    def initialize(block)
      @block = block
      @payload = nil
    end

    def run(payload)
      @payload = payload
      instance_eval(&@block)
    end
  end
end
