describe Fastlane::Actions::CharlesVersionAction do
  describe '#run' do
    it 'runs Charles with --version and returns the parsed version' do
      params = { app_path: '/Applications/Charles.app/Contents/MacOS/Charles' }

      expect(Fastlane::Actions).to receive(:sh).with(
        params[:app_path],
        '--version',
        log: false
      ).and_return("Charles Proxy 5.2\n")

      expect(Fastlane::Actions::CharlesVersionAction.run(params)).to eq('5.2')
    end

    it 'parses version when Charles also emits diagnostic lines' do
      params = { app_path: '/Applications/Charles.app/Contents/MacOS/Charles' }
      output = <<~OUTPUT
        SEVERE   com.charlesproxy.CharlesContext Error Accessing Application Data
        Charles Proxy 5.2
      OUTPUT

      expect(Fastlane::Actions).to receive(:sh).and_return(output)

      expect(Fastlane::Actions::CharlesVersionAction.run(params)).to eq('5.2')
    end
  end
end
