# frozen_string_literal: true

require 'json'
require 'set'

require 'rack'

require 'prubot/dispatcher'
require 'prubot/handler'
require 'prubot/version'

# Prubot is a Ruby Probot (https://github.com/probot/probot) clone.
# Probot is a framework for building GitHub Apps to automate and improve your workflow.
module Prubot
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

    def configure(**kwds)
      config_attrs = Set[:id, :key, :secret]
      raise Error, "Valid config keys are #{config_attrs}" unless kwds.keys.to_set == config_attrs

      @config = kwds
      @configured = true
    end

    def configured?
      @configured
    end

    def register_event(event, &block)
      @dispatcher.register(event, block)
    end

    private

    def setup_routing
      dispatcher = @dispatcher
      @app.map '/' do
        run dispatcher
      end
    end
  end
end
