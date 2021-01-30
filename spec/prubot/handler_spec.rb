# frozen_string_literal: true

RSpec.describe Prubot::Handler do
  def fixture(event)
    fname = File.dirname(__FILE__) + "/../event_fixtures/#{event}_hook.json"
    JSON.parse(File.read(fname))
  end

  it 'extracts repo data' do
    handler = described_class.new 'test repo', proc { repo }
    expected = { owner: 'Codertocat', repo: 'Hello-World' }
    expect(handler.run(fixture('issues'))).to eq expected
  end

  it 'extracts issue data' do
    handler = described_class.new 'test issue', proc { issue }
    expected = { issue_number: 1, owner: 'Codertocat', repo: 'Hello-World' }
    expect(handler.run(fixture('issues'))).to eq expected
  end

  it 'extracts pull_request data' do
    handler = described_class.new 'test pull_request', proc { pull_request }
    expected = { pull_number: 2, owner: 'Codertocat', repo: 'Hello-World' }
    expect(handler.run(fixture('pull_request'))).to eq expected
  end

  it 'raises if missing repo data requested' do
    handler = described_class.new 'test repo', proc { repo }
    expect { handler.run(fixture('organization')) }.to raise_error(Prubot::Error)
  end
end
