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
      expect(Fastlane::Actions).to receive(:sh) do |app_path, flag, config_path|
        expect(app_path).to eq(params[:app_path])
        expect(flag).to eq('-config')
        expect(File.read(config_path)).to eq(generated_xml)
        written_config_path = config_path
      end

      Fastlane::Actions::CharlesAction.run(params)

      expect(File.exist?(written_config_path)).to be(false)
    end
  end
end
