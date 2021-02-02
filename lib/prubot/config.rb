# frozen_string_literal: true
require 'dotenv'

module Prubot
  ##
  # Holds GitHub App config.
  #
  # On initialization, it will attempt to read dotenv files. It is considered +configured?+
  # when all required environment variables are set (the app id and private key).
  #
  # In order to support the GitHub App Manifest Flow, +set+ can be used to dynamically update the
  # config, and +dump+ can be used to create a +.env+ file of the current config in the current
  # working directory.

  class Config
    ID = 'PRUBOT_ID'
    KEY = 'PRUBOT_KEY'
    SECRET = 'PRUBOT_SECRET'

    def initialize
      Dotenv.load
    end

    def id
      ENV.fetch(ID).to_i
    end

    def key
      ENV.fetch(KEY)
    end

    def secret
      ENV.fetch(SECRET, false)
    end


    def set(**kwds)
      valid = Set[:id, :key, :secret]
      required = Set[:id, :key]
      kwds_key_set = kwds.keys.to_set
      raise Error, "Valid config keys are #{valid}" unless kwds_key_set.subset?(valid)
      raise Error, "Required config keys are #{required}" unless required.subset?(kwds_key_set)
      ENV[ID] = kwds[:id].to_s
      ENV[KEY] = kwds[:key]
      ENV[SECRET] = kwds[:secret]
    end

    def dump
      raise Error, "App configuration must be set before it can be dumped" unless configured?

      File.open(".env", "w") do |env_file|
        env_file.puts "#{ID}=#{id}"
        env_file.puts "#{KEY}=#{key}"
        env_file.puts "#{SECRET}=#{secret}"
      end
    end

    def configured?
      id
      key
      secret
    rescue
      false
    else
      true
    end
  end
end
