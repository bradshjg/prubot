# frozen_string_literal: true

require 'json'
require 'set'

require 'rack'

require 'prubot/config'
require 'prubot/dispatcher'
require 'prubot/handler'
require 'prubot/registry'
require 'prubot/version'

# Prubot is a Ruby Probot (https://github.com/probot/probot) clone.
# Probot is a framework for building GitHub Apps to automate and improve your workflow.
module Prubot
  class Error < StandardError; end

  # Prubot application
  class Application
    attr_reader :app, :config

    def initialize
      @config = Config.new
      @registry = Registry.new
      @configured = false
      @dispatcher = Dispatcher.new @config, @registry
      @app = Rack::Builder.new
      setup_routing
    end

    def configure(**kwds)
      @config.set(**kwds)
    end

    def configured?
      @config.configured?
    end

    def register_event(name, event, action = nil, &block)
      raise Error 'block required' unless block

      @registry.add(event, action, Handler.new(name, block))
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
