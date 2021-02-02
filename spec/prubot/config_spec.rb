RSpec.describe Prubot::Config do
  def dotenv_fixture(fname)
    File.dirname(__FILE__) + "/../fixtures/#{fname}"
  end

  context 'when loading dotenv files' do
    it 'loads complete dotenv file' do
      config = described_class.new
      dotenv = dotenv_fixture('.env.complete')
      config.load dotenv
      expect(config.id).to eq 1
    end

    it 'allows overriding' do
      config = described_class.new
      dotenv = dotenv_fixture('.env.complete')
      override = dotenv_fixture('.env.partial')
      config.load dotenv, override
      expect(config.id).to eq 2
    end
  end
end