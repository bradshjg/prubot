# frozen_string_literal: true

module Prubot
  # Prubot event registry
  class Registry
    def initialize
      @registry = {}
    end

    def add(event, action, handler)
      if @registry.key? [event, action]
        @registry[[event, action]] << handler
      else
        @registry[[event, action]] = [handler]
      end
    end

    def resolve(event, action)
      handlers = []

      handlers.concat @registry[[event, nil]] if @registry.key? [event, nil]

      handlers.concat @registry[[event, action]] if action && @registry.key?([event, action])

      handlers
    end
  end
end
