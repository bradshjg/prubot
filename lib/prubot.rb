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
      @dispatcher = Dispatcher.new @config, @registry
      @app = Rack::Builder.new
      setup_routing
    end

    def configured?
      @config.configured?
    end

    def run!
      Rack::Handler::WEBrick.run(app)
    end

    def run?
      $0 == 'app.rb' # HACK HACK HACK need to decide how we want to handle this.
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

  module DSL
    @@app = Prubot::Application.new

    ##
    # Supports both +on 'event' 'description' do...+ and +on 'action', 'event', 'description' do...+
    # based on the number of arguments passed. We are careful to flip the arguments around based
    # on the signature of the event registration method.
    def on(*args, &block)
      case args.length
      when 2
        @@app.register_event(args[1], args[0], &block)
      when 3
        @@app.register_event(args[2], args[1], args[0], &block)
      else
        raise Prubot::Error 'on supports either "on <event> <description> do..." or "on <action> <event> <description> do..."'
      end
    end

    at_exit { @@app.run! if @@app.run? }
  end
end

extend Prubot::DSL
