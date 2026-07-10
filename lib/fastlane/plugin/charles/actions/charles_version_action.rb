require 'fastlane/action'
require 'fastlane_core/configuration/config_item'
require_relative '../helper/charles_helper'

module Fastlane
  module Actions
    class CharlesVersionAction < Action
      def self.run(params)
        output = Actions.sh(
          *Helper::CharlesHelper.build_version_command(params[:app_path]),
          log: false
        )
        Helper::CharlesHelper.parse_version_output(output)
      end

      def self.description
        'Query the installed Charles Proxy version'
      end

      def self.authors
        ['jakekrog']
      end

      def self.return_value
        'Charles Proxy version string (e.g. "5.2")'
      end

      def self.details
        'Runs Charles with --version and returns the parsed version string. Useful in lanes that need to verify Charles is installed or guard against unsupported versions before launching the proxy.'
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
          )
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'charles_version',
          'version = charles_version # e.g. "5.2"',
          'UI.user_error!("Charles 5.x required") unless charles_version.start_with?("5.")'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
