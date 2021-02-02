# frozen_string_literal: true

RSpec.describe Prubot::Config do
  def dotenv_fixture(fname)
    File.dirname(__FILE__) + "/../fixtures/#{fname}"
  end

  it 'loads dotenv file on initialization' do
    Dir.chdir(File.expand_path('../fixtures', __dir__)) do
      config = described_class.new
      expect(config.id).to eq 1
    end
    # HACK: HACK HACK need to clear out ENV
    ENV.delete_if { |k, _v| k.start_with?('PRUBOT') }
  end

  it 'is unconfigured if dotenv files missing' do
    config = described_class.new
    expect(config.configured?).to eq false
  end
end
