# frozen_string_literal: true

require 'rack/test'

RSpec.describe Prubot do
  include Rack::Test::Methods

  def test_key
    File.read("#{File.dirname(__FILE__)}/fixtures/test.pkey")
  end

  it 'has a version number' do
    expect(Prubot::VERSION).not_to be nil
  end

  context 'when handling synthetic events with no config' do
    subject(:app) do
      app_container = Prubot::Application.new
      app_container.config.set(id: 1, key: test_key)
      app_container.register_event 'foo handler', 'foo' do
        'foo event handled'
      end
      app_container.register_event 'bar handler', 'bar' do
        'bar event handled'
      end
      app_container.register_event 'foo qux handler', 'foo', 'qux' do
        'qux action for foo event handled'
      end
      app_container.app
    end

    let(:json_response) { JSON.parse(last_response.body) }

    def event(event, payload = {})
      header 'Content-Type', 'application/json'
      header 'X-GitHub-Event', event
      post '/', JSON.generate(payload)
    end

    before do
      header 'Content-Type', 'application/json'
    end

    it 'requires json Content-Type header' do
      header 'Content-Type', nil
      header 'X-GitHub-Event', 'foo'
      expect { post '/', '{}' }.to raise_error(Prubot::Error)
    end

    it 'requires json body' do
      header 'X-GitHub-Event', 'foo'
      expect { post '/', 'not json body' }.to raise_error(Prubot::Error)
    end

    it 'returns 200 for foo event' do
      event 'foo'
      expect(last_response.ok?).to be(true)
    end

    it 'returns 200 for bar event' do
      event 'bar'
      expect(last_response.ok?).to be(true)
    end

    it 'returns 404 for unknown event' do
      event 'unknown'
      expect(last_response.not_found?).to be(true)
    end

    it 'returns response for foo event' do
      expected_response = { 'event' => 'foo', 'action' => nil,
                            'result' => { 'foo handler' => 'foo event handled' } }
      event 'foo'
      expect(json_response).to eq expected_response
    end

    it 'returns response for bar event' do
      expected_response = { 'event' => 'bar', 'action' => nil,
                            'result' => { 'bar handler' => 'bar event handled' } }
      event 'bar'
      expect(json_response).to eq expected_response
    end

    it 'returns response for foo event with qux action' do
      handler_responses = { 'foo handler' => 'foo event handled',
                            'foo qux handler' => 'qux action for foo event handled' }
      expected_response = { 'event' => 'foo', 'action' => 'qux', 'result' => handler_responses }

      event 'foo', { action: 'qux' }
      expect(json_response).to eq expected_response
    end

    it 'returns response for unknown event' do
      expected_response = { 'action' => nil, 'event' => 'unknown', 'result' => {} }
      event 'unknown'

      expect(json_response).to eq expected_response
    end

    it 'returns response for unkown event with unknown action' do
      expected_response = { 'action' => 'unknown', 'event' => 'unknown', 'result' => {} }
      event 'unknown', { action: 'unknown' }

      expect(json_response).to eq expected_response
    end
  end

  context 'when handling event fixtures' do
    subject(:app) do
      app_container = Prubot::Application.new
      app_container.config.set(id: 1, key: test_key, secret: 'secret')
      app_container.register_event 'handle issue', 'issues' do
        'issue handled'
      end
      app_container.app
    end

    def event_fixture(fname)
      event_fname = File.join(File.dirname(__FILE__), 'fixtures', fname)
      event_fp = File.open(event_fname)
      event = event_fp.read
      event_fp.close
      event
    end

    def event(event, fixture, digest)
      header 'Content-Type', 'application/json'
      header 'X-GitHub-Event', event
      header 'X-Hub-Signature-256', "sha256=#{digest}"
      post '/', event_fixture(fixture)
    end

    it 'returns 200 for issues event' do
      event 'issues', 'issues_hook.json',
            '5700c0515bec05804df657c3ebbf5f9585701a9f0a2a5633ca2d6dbd375a63a2'
      expect(last_response.ok?).to be(true)
    end

    it 'raises error for invalid signature' do
      expect { event 'issues', 'issues_hook.json', 'bad-signature' }.to raise_error(Prubot::Error)
    end
  end
end
