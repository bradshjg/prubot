# frozen_string_literal: true

module Prubot
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
