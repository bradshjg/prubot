# frozen_string_literal: true

RSpec.describe Prubot::Handler do
  def fixture(event)
    fname = File.dirname(__FILE__) + "/../event_fixtures/#{event}_hook.json"
    JSON.parse(File.read(fname))
  end

  context 'when extracting repo data' do
    it 'extracts data' do
      handler = described_class.new 'test repo', proc { repo }
      expected = { owner: 'Codertocat', repo: 'Hello-World' }
      expect(handler.run(fixture('issues'))).to eq expected
    end

    it 'merges passed data' do
      handler = described_class.new 'test repo', proc { repo({ body: 'howdy' }) }
      expected = { owner: 'Codertocat', repo: 'Hello-World', body: 'howdy' }
      expect(handler.run(fixture('issues'))).to eq expected
    end

    it 'raises if non-repo payload' do
      handler = described_class.new 'test repo', proc { repo }
      expect { handler.run(fixture('organization')) }.to raise_error(Prubot::Error)
    end
  end

  context 'when extracting issue data' do
    it 'extracts data' do
      handler = described_class.new 'test issue', proc { issue }
      expected = { issue_number: 1, owner: 'Codertocat', repo: 'Hello-World' }
      expect(handler.run(fixture('issues'))).to eq expected
    end

    it 'merges passed data' do
      handler = described_class.new 'test issue', proc { issue({ body: 'howdy' }) }
      expected = { issue_number: 1, owner: 'Codertocat', repo: 'Hello-World', body: 'howdy' }
      expect(handler.run(fixture('issues'))).to eq expected
    end
  end

  context 'when extracting pull request data' do
    it 'extracts data' do
      handler = described_class.new 'test pull_request', proc { pull_request }
      expected = { pull_number: 2, owner: 'Codertocat', repo: 'Hello-World' }
      expect(handler.run(fixture('pull_request'))).to eq expected
    end

    it 'merges passed data' do
      handler = described_class.new 'test pull_request', proc { pull_request({ body: 'howdy' }) }
      expected = { pull_number: 2, owner: 'Codertocat', repo: 'Hello-World', body: 'howdy' }
      expect(handler.run(fixture('pull_request'))).to eq expected
    end
  end
end
