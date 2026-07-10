require 'tempfile'

describe Fastlane::Helper::CharlesHelper do
  def write_yaml(content)
    file = Tempfile.new(['charles', '.yml'])
    file.write(content)
    file.close
    file.path
  end

  describe '.generate_config_xml' do
    it 'includes the serialisation processing instruction' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          enable_socks: true
          ssl: []
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).to include("<?charles serialisation-version='2.0' ?>")
    end

    it 'defaults enableSOCKSProxy to true when omitted' do
      xml = described_class.generate_config_xml(write_yaml("proxy:\n  ssl: []\n"))

      expect(xml).to include('<enableSOCKSProxy>true</enableSOCKSProxy>')
    end

    it 'renders bare ssl host entries with the default port' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl:
            - "*.example.com"
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).to include('<host>*.example.com</host>')
      expect(xml).to include('<port>443</port>')
    end

    it 'renders ssl host entries with a custom port' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl:
            - host: "internal.example.com"
              port: 8443
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).to include('<host>internal.example.com</host>')
      expect(xml).to include('<port>8443</port>')
    end

    it 'omits sslExcludeLocations when proxy.ssl is a plain include-only list' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl:
            - "*.example.com"
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).not_to include('sslExcludeLocations')
    end

    it 'renders both sslLocations and sslExcludeLocations from the expanded ssl form' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl:
            include:
              - "*.example.com"
            exclude:
              - "exclude-ssl-host.com"
      YAML

      xml = described_class.generate_config_xml(yaml_path)
      include_section = xml[%r{<sslLocations>.*?</sslLocations>}m]
      exclude_section = xml[%r{<sslExcludeLocations>.*?</sslExcludeLocations>}m]

      expect(include_section).to include('<host>*.example.com</host>')
      expect(exclude_section).to include('<host>exclude-ssl-host.com</host>')
    end

    it 'omits sslExcludeLocations when the expanded ssl form has no exclude entries' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl:
            include:
              - "*.example.com"
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).not_to include('sslExcludeLocations')
    end

    it 'renders recording hosts without a port' do
      yaml_path = write_yaml(<<~YAML)
        recording:
          hosts:
            - "some-plain-http-host.example.com"
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).to include('<host>some-plain-http-host.example.com</host>')
      expect(xml.scan('<port>')).to be_empty
    end

    it 'renders a full recording location with protocol/port/path/query' do
      yaml_path = write_yaml(<<~YAML)
        recording:
          hosts:
            - protocol: https
              host: "scoped.example.com"
              port: 8443
              path: "/debug"
              query: "verbose=true"
      YAML

      xml = described_class.generate_config_xml(yaml_path)

      expect(xml).to include('<protocol>https</protocol>')
      expect(xml).to include('<host>scoped.example.com</host>')
      expect(xml).to include('<port>8443</port>')
      expect(xml).to include('<path>/debug</path>')
      expect(xml).to include('<query>verbose=true</query>')
    end

    it 'omits protocol/port/path/query for a recording location that only specifies a host' do
      yaml_path = write_yaml(<<~YAML)
        recording:
          hosts:
            - host: "scoped.example.com"
      YAML

      xml = described_class.generate_config_xml(yaml_path)
      location_section = xml[%r{<location>.*?</location>}m]

      expect(location_section).to include('<host>scoped.example.com</host>')
      %w[protocol port path query].each do |field|
        expect(location_section).not_to include("<#{field}>")
      end
    end

    it 'omits recordingConfiguration when no hosts are configured' do
      xml = described_class.generate_config_xml(write_yaml("proxy:\n  ssl: []\n"))

      expect(xml).not_to include('recordingConfiguration')
    end

    it 'always includes the accepted EULA version in startupConfiguration' do
      xml = described_class.generate_config_xml(write_yaml("proxy:\n  ssl: []\n"))

      expect(xml).to include('<acceptedEulaVersion>20240608</acceptedEulaVersion>')
    end

    it 'omits registrationConfiguration when no registration is given' do
      xml = described_class.generate_config_xml(write_yaml("proxy:\n  ssl: []\n"))

      expect(xml).not_to include('registrationConfiguration')
    end

    it 'renders registrationConfiguration when both name and key are given' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      xml = described_class.generate_config_xml(yaml_path, registered_name: 'Jane Doe', registered_key: 'abc123')

      expect(xml).to include('<name>Jane Doe</name>')
      expect(xml).to include('<key>abc123</key>')
    end

    it 'raises if only one of registered_name/registered_key is given' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      expect do
        described_class.generate_config_xml(yaml_path, registered_name: 'Jane Doe')
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    it 'omits accessControlConfiguration when no ip_ranges are given' do
      xml = described_class.generate_config_xml(write_yaml("proxy:\n  ssl: []\n"))

      expect(xml).not_to include('accessControlConfiguration')
    end

    it 'converts CIDR ip_ranges into ip/mask octets' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      xml = described_class.generate_config_xml(yaml_path, ip_ranges: ['10.0.1.20/32'])

      expect(xml).to include('<int>10</int>')
      expect(xml).to include('<int>0</int>')
      expect(xml).to include('<int>1</int>')
      expect(xml).to include('<int>20</int>')
      expect(xml.scan('<int>255</int>').length).to eq(4)
    end

    it 'treats a bare IP with no prefix as /32' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      xml = described_class.generate_config_xml(yaml_path, ip_ranges: ['10.0.1.20'])
      mask_section = xml[%r{<mask>.*?</mask>}m]

      expect(mask_section.scan('<int>255</int>').length).to eq(4)
    end

    it 'converts an open CIDR range (0.0.0.0/0) into an all-zero mask' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      xml = described_class.generate_config_xml(yaml_path, ip_ranges: ['0.0.0.0/0'])
      mask_section = xml[%r{<mask>.*?</mask>}m]

      expect(mask_section.scan('<int>0</int>').length).to eq(4)
    end

    it 'merges access_control.ip_ranges from the YAML with runtime ip_ranges' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl: []
        access_control:
          ip_ranges:
            - "10.0.0.0/8"
      YAML

      xml = described_class.generate_config_xml(yaml_path, ip_ranges: ['10.0.1.20/32'])

      expect(xml.scan('<ipRange>').length).to eq(2)
    end

    it 'treats "all" in access_control.ip_ranges as shorthand for 0.0.0.0/0' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl: []
        access_control:
          ip_ranges:
            - "all"
      YAML

      xml = described_class.generate_config_xml(yaml_path)
      mask_section = xml[%r{<mask>.*?</mask>}m]

      expect(mask_section.scan('<int>0</int>').length).to eq(4)
    end

    it 'deduplicates identical ranges from the YAML and runtime' do
      yaml_path = write_yaml(<<~YAML)
        proxy:
          ssl: []
        access_control:
          ip_ranges:
            - "10.0.1.20/32"
      YAML

      xml = described_class.generate_config_xml(yaml_path, ip_ranges: ['10.0.1.20/32'])

      expect(xml.scan('<ipRange>').length).to eq(1)
    end

    it 'raises a clear error when the YAML config file does not exist' do
      expect do
        described_class.generate_config_xml('/nonexistent/path/charles.yml')
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /not found/)
    end

    it 'raises a clear error for invalid YAML syntax' do
      yaml_path = write_yaml("proxy:\n  ssl: [\n")

      expect do
        described_class.generate_config_xml(yaml_path)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /not valid YAML/)
    end

    it 'raises a clear error when the YAML is not a mapping at the top level' do
      yaml_path = write_yaml("- one\n- two\n")

      expect do
        described_class.generate_config_xml(yaml_path)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /must be a mapping/)
    end

    it 'raises a clear error for a malformed CIDR ip_ranges entry' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      expect do
        described_class.generate_config_xml(yaml_path, ip_ranges: ['10.0.1'])
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid ip_ranges entry/)
    end

    it 'raises a clear error for an out-of-range octet in ip_ranges' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      expect do
        described_class.generate_config_xml(yaml_path, ip_ranges: ['999.0.1.20'])
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /octet must be 0-255/)
    end

    it 'raises a clear error for an invalid prefix length in ip_ranges' do
      yaml_path = write_yaml("proxy:\n  ssl: []\n")

      expect do
        described_class.generate_config_xml(yaml_path, ip_ranges: ['10.0.1.20/99'])
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /prefix must be 0-32/)
    end
  end

  describe '.build_launch_command' do
    it 'builds the base launch argv' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config')

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config'])
    end

    it 'appends --debug when debug is true' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', debug: true)

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config', '--debug'])
    end

    it 'omits --debug when debug is false' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', debug: false)

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config'])
    end

    it 'appends --data and its path when data_path is set' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', data_path: '/tmp/charles-data')

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config', '--data', '/tmp/charles-data'])
    end

    it 'omits --data when data_path is nil or empty' do
      expect(described_class.build_launch_command('/Charles', '/tmp/charles.config')).to eq(
        ['/Charles', '--config', '/tmp/charles.config']
      )
      expect(described_class.build_launch_command('/Charles', '/tmp/charles.config', data_path: '')).to eq(
        ['/Charles', '--config', '/tmp/charles.config']
      )
    end

    it 'places --data before --debug when both are set' do
      command = described_class.build_launch_command(
        '/Charles',
        '/tmp/charles.config',
        data_path: '/tmp/charles-data',
        debug: true
      )

      expect(command).to eq([
                              '/Charles',
                              '--config',
                              '/tmp/charles.config',
                              '--data',
                              '/tmp/charles-data',
                              '--debug'
                            ])
    end

    it 'appends --headless when headless is true' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', headless: true)

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config', '--headless'])
    end

    it 'omits --headless when headless is false' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', headless: false)

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config'])
    end

    it 'appends --throttling when throttling is true' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', throttling: true)

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config', '--throttling'])
    end

    it 'omits --throttling when throttling is false' do
      command = described_class.build_launch_command('/Charles', '/tmp/charles.config', throttling: false)

      expect(command).to eq(['/Charles', '--config', '/tmp/charles.config'])
    end

    it 'orders optional flags as --data, --debug, --headless, --throttling' do
      command = described_class.build_launch_command(
        '/Charles',
        '/tmp/charles.config',
        data_path: '/tmp/charles-data',
        debug: true,
        headless: true,
        throttling: true
      )

      expect(command).to eq([
                              '/Charles',
                              '--config',
                              '/tmp/charles.config',
                              '--data',
                              '/tmp/charles-data',
                              '--debug',
                              '--headless',
                              '--throttling'
                            ])
    end
  end

  describe '.build_version_command' do
    it 'builds the --version argv' do
      expect(described_class.build_version_command('/Charles')).to eq(['/Charles', '--version'])
    end
  end

  describe '.parse_version_output' do
    it 'extracts the version token from Charles output' do
      expect(described_class.parse_version_output("Charles Proxy 5.2\n")).to eq('5.2')
    end

    it 'extracts the version when diagnostic lines precede it' do
      output = <<~OUTPUT
        SEVERE   com.charlesproxy.CharlesContext Error Accessing Application Data
        Charles Proxy 5.2
      OUTPUT

      expect(described_class.parse_version_output(output)).to eq('5.2')
    end

    it 'raises a clear error when the output is unrecognizable' do
      expect do
        described_class.parse_version_output('unexpected output')
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Unable to parse Charles version/)
    end
  end
end
