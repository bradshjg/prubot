# frozen_string_literal: true

require 'rack/test'

RSpec.describe Prubot do
  include Rack::Test::Methods

  it 'has a version number' do
    expect(Prubot::VERSION).not_to be nil
  end

  describe '#configured?' do
    subject(:app_container) { Prubot::Application.new }

    it 'is instantiated unconfigured' do
      expect(app_container.configured?).to eq false
    end

    it 'is configured once configure is called' do
      app_container.configure(id: 1, key: 'testkey', secret: 'testsecret')
      expect(app_container.configured?).to eq true
    end
  end

  describe '#configure' do
    subject(:app_container) { Prubot::Application.new }

    it 'will hold valid configuration' do
      expected_config = { id: 1, key: 'testkey', secret: 'testsecret' }
      app_container.configure(**expected_config)
      expect(app_container.config).to eq expected_config
    end

    it 'raises an error on unknown config' do
      expect { app_container.configure(foo: 'bar') }.to raise_error(Prubot::Error)
    end

    it 'raises an error on missing config' do
      expect { app_container.configure(id: 1) }.to raise_error(Prubot::Error)
    end
  end

  context 'when handling events' do
    subject(:app) do
      app_container = Prubot::Application.new
      app_container.register_event 'foo' do
        'foo event handled'
      end
      app_container.register_event 'bar' do
        'bar event handled'
      end
      app_container.register_event 'foo.qux' do
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
      expect(last_response.status).to eq 404
    end

    it 'returns foo response for foo event' do
      expected_response = { 'status' => 'OK', 'description' => { 'foo' => ['foo event handled'] } }
      event 'foo'
      expect(json_response).to eq expected_response
    end

    it 'bar event returns bar response' do
      expected_response = { 'status' => 'OK', 'description' => { 'bar' => ['bar event handled'] } }
      event 'bar'
      expect(json_response).to eq expected_response
    end

    it 'foo event with qux action returns foo and foo.qux response' do
      handler_responses = { 'foo' => ['foo event handled'],
                            'foo.qux' => ['qux action for foo event handled'] }
      expected_response = { 'status' => 'OK', 'description' => handler_responses }

      event 'foo', { action: 'qux' }
      expect(json_response).to eq expected_response
    end

    it 'unkown event returns unknown response' do
      expected_response = { 'status' => 'MISS',
                            'description' => { 'unknown' => 'no matching handlers' } }
      event 'unknown'

      expect(json_response).to eq expected_response
    end
  end
end
