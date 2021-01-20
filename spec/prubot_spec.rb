# frozen_string_literal: true

require 'rack/test'

require 'prubot'

RSpec.describe Prubot do
  include Rack::Test::Methods

  it 'has a version number' do
    expect(Prubot::VERSION).not_to be nil
  end

  it 'is instantiated unconfigured' do
    app = Prubot::Application.new
    expect(app.configured?).to eq false
  end

  it 'will hold valid configuration' do
    app = Prubot::Application.new
    expected_config = { id: 1, key: 'testkey', secret: 'testsecret' }
    app.configure(**expected_config)
    expect(app.config).to eq expected_config
  end

  it 'will set the configured flag once configured' do
    app = Prubot::Application.new
    app.configure(id: 1, key: 'testkey', secret: 'testsecret')
    expect(app.configured?).to eq true
  end

  it 'raises an error on unknown config' do
    app = Prubot::Application.new
    expect { app.configure(foo: 'bar') }.to raise_error(Prubot::Error)
  end

  it 'raises an error on missing config' do
    app = Prubot::Application.new
    expect { app.configure(id: 1) }.to raise_error(Prubot::Error)
  end

  context 'when handling events' do
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

    let(:app) do
      app_container.app
    end

    before do
      header 'Content-Type', 'application/json'
    end

    it 'foo event returns 200' do
      expect_status 'foo', '{}', 200
    end

    it 'bar event returns 200' do
      expect_status 'bar', '{}', 200
    end

    it 'unknown event returns 404' do
      expect_status 'unkonwn', '{}', 404
    end

    it 'foo event returns foo response' do
      expected_body = { 'status' => 'OK', 'description' => { 'foo' => ['foo event handled'] } }
      expect_body 'foo', '{}', expected_body
    end

    it 'bar event returns bar response' do
      expected_body = { 'status' => 'OK', 'description' => { 'bar' => ['bar event handled'] } }
      expect_body 'bar', '{}', expected_body
    end

    it 'foo event with qux action returns foo and foo.qux response' do
      handler_responses = { 'foo' => ['foo event handled'],
                            'foo.qux' => ['qux action for foo event handled'] }
      expected_body = { 'status' => 'OK', 'description' => handler_responses }
      expect_body 'foo', '{"action":"qux"}', expected_body
    end

    it 'unkown event returns unknown response' do
      expect_body 'unknown', '{}', { 'status' => 'MISS',
                                     'description' => { 'unknown' => 'no matching handlers' } }
    end
  end
end
