# frozen_string_literal: true

module Prubot
  # Prubot config
  class Config
    attr_reader :id, :key, :secret

    def initialize
      @configured = false
    end

    def set(**kwds)
      config_attrs = Set[:id, :key, :secret]
      raise Error, "Valid config keys are #{config_attrs}" unless kwds.keys.to_set == config_attrs

      @id = kwds[:id]
      @key = kwds[:key]
      @secret = kwds[:secret]
      @configured = true
    end

    def configured?
      @configured
    end
  end
end
