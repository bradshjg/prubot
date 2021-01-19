# frozen_string_literal: true

module Helpers
  def expect_body(event, payload, expected)
    header 'X-GitHub-Event', event
    post '/', payload
    expect(JSON.parse(last_response.body)).to eq expected
  end

  def expect_status(event, payload, expected)
    header 'X-GitHub-Event', event
    post '/', payload
    expect(last_response.status).to eq expected
  end
end
