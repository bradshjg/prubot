# frozen_string_literal: true

module Prubot
  # Prubot event handler boilerplate
  class Handler
    attr_reader :name, :payload

    def initialize(name, block)
      @name = name
      @block = block
      @payload = nil
    end

    def run(payload)
      @payload = payload
      instance_eval(&@block)
    end

    private

    def repo(to_merge = {})
      repo = @payload['repository'] || raise(Error, 'repo is not supported for the event.')
      {
        owner: repo['owner']['login'] || repo['owner']['name'],
        repo: repo['name']
      }.merge(to_merge)
    end

    def issue(to_merge = {})
      {
        issue_number: (payload['issue'] || payload['pull_request'] || payload)['number']
      }.merge(repo(to_merge))
    end

    def pull_request(to_merge = {})
      {
        pull_number: (payload['issue'] || payload['pull_request'] || payload)['number']
      }.merge(repo(to_merge))
    end
  end
end
