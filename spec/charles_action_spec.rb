describe Fastlane::Actions::CharlesAction do
  describe '#run' do
    it 'generates a Charles config from YAML, runs Charles against it, then cleans up' do
      params = {
        app_path: '/Applications/Charles.app/Contents/MacOS/Charles',
        config_path: 'charles.yml',
        registered_name: 'Jane Doe',
        registered_key: 'abc123',
        ip_ranges: ['10.0.1.20/32']
      }
      generated_xml = '<configuration></configuration>'
      written_config_path = nil

      expect(Fastlane::Helper::CharlesHelper).to receive(:generate_config_xml).with(
        'charles.yml',
        registered_name: 'Jane Doe',
        registered_key: 'abc123',
        ip_ranges: ['10.0.1.20/32']
      ).and_return(generated_xml)
      expect(Fastlane::Actions).to receive(:sh) do |*args|
        app_path, flag, config_path = args
        expect(app_path).to eq(params[:app_path])
        expect(flag).to eq('-config')
        expect(args).not_to include('--debug')
        expect(File.read(config_path)).to eq(generated_xml)
        written_config_path = config_path
      end

      Fastlane::Actions::CharlesAction.run(params)

      expect(File.exist?(written_config_path)).to be(false)
    end

    it 'passes --debug when debug is true' do
      params = {
        app_path: '/Applications/Charles.app/Contents/MacOS/Charles',
        config_path: 'charles.yml',
        registered_name: nil,
        registered_key: nil,
        ip_ranges: [],
        debug: true
      }

      expect(Fastlane::Helper::CharlesHelper).to receive(:generate_config_xml).and_return('<configuration></configuration>')
      expect(Fastlane::Actions).to receive(:sh) do |*args|
        expect(args[0]).to eq(params[:app_path])
        expect(args[1]).to eq('-config')
        expect(args[2]).to be_a(String)
        expect(args[3]).to eq('--debug')
      end

      Fastlane::Actions::CharlesAction.run(params)
    end
  end
end
