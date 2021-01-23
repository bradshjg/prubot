# frozen_string_literal: true

module Prubot
  # Prubot event registry
  class Registry
    def initialize
      @registry = {}
    end

    def add(event, block)
      if @registry.key? event
        @registry[event] << Handler.new(block)
      else
        @registry[event] = [Handler.new(block)]
      end
    end

    def get_handlers(event_key)
      @registry[event_key]
    end
  end
end
