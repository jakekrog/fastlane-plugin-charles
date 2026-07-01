require 'fastlane/action'
require 'fastlane_core/configuration/config_item'
require 'tmpdir'
require_relative '../helper/charles_helper'

module Fastlane
  module Actions
    class CharlesAction < Action
      def self.run(params)
        charles_app_path = params[:app_path]
        yaml_config_path = params[:config_path]
        config_xml = Helper::CharlesHelper.generate_config_xml(
          yaml_config_path,
          registered_name: params[:registered_name],
          registered_key: params[:registered_key],
          ip_ranges: params[:ip_ranges]
        )

        Dir.mktmpdir('fastlane-charles-') do |tmp_dir|
          charles_config_path = File.join(tmp_dir, 'charles.config')
          File.write(charles_config_path, config_xml)

          Actions.sh(charles_app_path, '-config', charles_config_path)
        end
      end

      def self.description
        'Run Charles HTTP proxy'
      end

      def self.authors
        ['jakekrog']
      end

      def self.return_value
      end

      def self.details
        'This action starts Charles Proxy, generating its .config file at runtime from a simplified YAML config (see example/charles.yml). You can specify the path to the Charles application and the YAML config either through command-line arguments or environment variables.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :app_path,
            env_name: 'FL_CHARLES_APP_PATH',
            description: 'Path to Charles application executable',
            default_value: '/Applications/Charles.app/Contents/MacOS/Charles',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :config_path,
            env_name: 'FL_CHARLES_CONFIG_PATH',
            description: 'Path to a simplified Charles YAML config (see example/charles.yml), used to generate a Charles .config file at runtime',
            default_value: 'charles.yml',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :registered_name,
            env_name: 'FL_CHARLES_REGISTERED_NAME',
            description: 'Registered name for your Charles Proxy license',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :registered_key,
            env_name: 'FL_CHARLES_REGISTERED_KEY',
            description: 'License key for your Charles Proxy registration',
            optional: true,
            sensitive: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :ip_ranges,
            env_name: 'FL_CHARLES_IP_RANGES',
            description: 'IP ranges permitted to access the proxy, in CIDR notation or as bare IPs (treated as /32)',
            optional: true,
            type: Array,
            default_value: []
          )
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'charles # Use default paths',
          'charles(app_path: "/path/to/Charles.app/Contents/MacOS/Charles")',
          'charles(config_path: "/path/to/charles.yml")',
          'charles(app_path: "/custom/path/to/Charles", config_path: "/custom/path/to/charles.yml")'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
