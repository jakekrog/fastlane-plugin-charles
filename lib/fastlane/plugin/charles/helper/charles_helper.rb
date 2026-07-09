require 'fastlane_core/ui/ui'
require 'yaml'
require 'rexml/document'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class CharlesHelper
      SERIALISATION_VERSION = '2.0'.freeze
      ACCEPTED_EULA_VERSION = '20240608'.freeze
      DEFAULT_SSL_PORT = 443
      DEFAULT_CIDR_PREFIX = 32
      ALL_IP_RANGES_ALIAS = 'all'.freeze
      ALL_IP_RANGES_CIDR = '0.0.0.0/0'.freeze
      CIDR_PATTERN = %r{\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?:/(\d{1,2}))?\z}

      # Builds the argv array for launching Charles. Optional flags are
      # appended only when enabled so callers can splat straight into
      # Actions.sh(*build_launch_command(...)).
      def self.build_launch_command(app_path, config_path, debug: false)
        command = [app_path, '-config', config_path]
        command << '--debug' if debug
        command
      end

      # Charles's standard location matcher (used by recording, and future
      # tools like block/allow lists) supports protocol/host/port/path/query,
      # each optional — Charles treats a blank field as "match all values".
      # A YAML entry is either a bare hostname string, shorthand for
      # `{host: <string>}`, or a Hash with any subset of those keys, e.g.:
      #   - protocol: https
      #     host: "api.example.com"
      #     path: "/debug"
      LOCATION_FIELDS = %i[protocol host port path query].freeze

      # Reads a simplified Charles YAML config (see example/charles.yml) and
      # returns the equivalent Charles `.config` XML as a String.
      #
      # `registered_name`/`registered_key` (a Charles Proxy license) are
      # per-developer secrets, not part of the committed YAML — they're
      # passed in separately so they can be sourced from env vars instead.
      #
      # `ip_ranges` are runtime/per-developer CIDR ranges (e.g. a developer's
      # own machine), merged with any `access_control.ip_ranges` committed in
      # the YAML (e.g. a shared corporate subnet, or "all" for 0.0.0.0/0).
      def self.generate_config_xml(yaml_path, registered_name: nil, registered_key: nil, ip_ranges: [])
        config = load_config(yaml_path)
        root = build_configuration_element(config)
        combined_ip_ranges = merge_ip_ranges(config['access_control'] || {}, ip_ranges)
        build_access_control_configuration(root, combined_ip_ranges)
        build_startup_configuration(root)
        build_registration_configuration(root, registered_name, registered_key)
        xml_header + format_element(root)
      end

      # Loads and validates the YAML config, raising a clear UI.user_error!
      # (instead of a raw Ruby exception) for the ways a hand-edited
      # charles.yml commonly goes wrong: missing file, invalid YAML syntax,
      # or valid YAML that isn't a Hash at the top level (e.g. a bare list).
      def self.load_config(yaml_path)
        UI.user_error!("Charles YAML config not found at #{yaml_path.inspect}") unless File.exist?(yaml_path)

        config = begin
          YAML.load_file(yaml_path)
        rescue Psych::SyntaxError => e
          UI.user_error!("Charles YAML config at #{yaml_path.inspect} is not valid YAML: #{e.message}")
        end

        config ||= {}
        unless config.kind_of?(Hash)
          UI.user_error!("Charles YAML config at #{yaml_path.inspect} must be a mapping (Hash) at the top level, got #{config.class}")
        end

        config
      end

      def self.xml_header
        "<?xml version='1.0' encoding='UTF-8' ?>\n<?charles serialisation-version='#{SERIALISATION_VERSION}' ?>\n"
      end

      def self.build_configuration_element(config)
        root = REXML::Element.new('configuration')
        build_proxy_configuration(root, config['proxy'] || {})
        build_recording_configuration(root, config['recording'] || {})
        root
      end

      def self.format_element(element)
        output = ''
        formatter = REXML::Formatters::Pretty.new(2)
        formatter.compact = true
        formatter.write(element, output)
        output
      end

      def self.build_proxy_configuration(root, proxy)
        proxy_el = root.add_element('proxyConfiguration')
        proxy_el.add_element('enableSOCKSProxy').text = proxy.fetch('enable_socks', true).to_s

        ssl_includes, ssl_excludes = normalize_ssl_config(proxy['ssl'])
        build_ssl_locations(proxy_el, 'sslLocations', ssl_includes)
        build_ssl_locations(proxy_el, 'sslExcludeLocations', ssl_excludes)
      end

      def self.build_ssl_locations(proxy_el, element_name, entries)
        return if entries.empty?

        patterns_el = proxy_el.add_element(element_name).add_element('locationPatterns')
        entries.each do |entry|
          host, port = normalize_ssl_entry(entry)
          location_el = patterns_el.add_element('locationMatch').add_element('location')
          location_el.add_element('host').text = host
          location_el.add_element('port').text = port.to_s
        end
      end

      def self.build_recording_configuration(root, recording)
        record_hosts = Array(recording['hosts'])
        return if record_hosts.empty?

        patterns_el = root.add_element('recordingConfiguration')
                          .add_element('recordHosts')
                          .add_element('locationPatterns')
        record_hosts.each do |entry|
          match_el = patterns_el.add_element('locationMatch')
          build_location_element(match_el, normalize_location_entry(entry))
        end
      end

      def self.build_access_control_configuration(root, ip_ranges)
        ip_ranges = Array(ip_ranges)
        return if ip_ranges.empty?

        ip_ranges_el = root.add_element('accessControlConfiguration').add_element('ipRanges')
        ip_ranges.each do |cidr|
          ip_octets, mask_octets = parse_cidr(cidr)
          range_el = ip_ranges_el.add_element('ipRange')
          ip_el = range_el.add_element('ip')
          ip_octets.each { |octet| ip_el.add_element('int').text = octet.to_s }
          mask_el = range_el.add_element('mask')
          mask_octets.each { |octet| mask_el.add_element('int').text = octet.to_s }
        end
      end

      def self.build_startup_configuration(root)
        root.add_element('startupConfiguration').add_element('acceptedEulaVersion').text = ACCEPTED_EULA_VERSION
      end

      def self.build_registration_configuration(root, registered_name, registered_key)
        return if registered_name.nil? && registered_key.nil?

        if registered_name.nil? || registered_key.nil?
          UI.user_error!('Both registered_name and registered_key must be provided to register Charles')
        end

        registration_el = root.add_element('registrationConfiguration')
        registration_el.add_element('name').text = registered_name
        registration_el.add_element('key').text = registered_key
      end

      # `proxy.ssl` is either a plain list (shorthand for an include-only
      # list, matching Charles's own default), or a Hash with `include`/
      # `exclude` keys for the rarer case where some hosts need to be
      # carved out of SSL decryption, e.g.:
      #   ssl:
      #     include:
      #       - "*.example.com"
      #     exclude:
      #       - "exclude-ssl-host.com"
      def self.normalize_ssl_config(ssl)
        if ssl.kind_of?(Hash)
          [Array(ssl['include']), Array(ssl['exclude'])]
        else
          [Array(ssl), []]
        end
      end

      # Each `proxy.ssl` (include/exclude) entry is either a bare hostname
      # string (assumed to use the default SSL port), or a `{host:, port:}`
      # Hash for the rare case where a host needs a non-standard port, e.g.:
      #   - host: "internal.example.com"
      #     port: 8443
      def self.normalize_ssl_entry(entry)
        if entry.kind_of?(Hash)
          [entry['host'] || entry[:host], entry['port'] || entry[:port] || DEFAULT_SSL_PORT]
        else
          [entry, DEFAULT_SSL_PORT]
        end
      end

      def self.normalize_location_entry(entry)
        return { host: entry } unless entry.kind_of?(Hash)

        LOCATION_FIELDS.each_with_object({}) do |field, attrs|
          value = entry[field.to_s] || entry[field]
          attrs[field] = value unless value.nil?
        end
      end

      # Only emits the sub-elements a location entry actually specifies,
      # matching how Charles itself omits blank ("match all") fields.
      def self.build_location_element(parent, attrs)
        location_el = parent.add_element('location')
        LOCATION_FIELDS.each do |field|
          value = attrs[field]
          next if value.nil?

          location_el.add_element(field.to_s).text = value.to_s
        end
        location_el
      end

      # Combines `access_control.ip_ranges` committed in the YAML with
      # `ip_ranges` passed in at runtime, normalizing the "all" alias to
      # 0.0.0.0/0 and removing duplicates.
      def self.merge_ip_ranges(access_control, runtime_ip_ranges)
        committed = Array(access_control['ip_ranges'])
        (committed + Array(runtime_ip_ranges)).map { |entry| normalize_ip_range(entry) }.uniq
      end

      def self.normalize_ip_range(entry)
        entry.to_s.strip.downcase == ALL_IP_RANGES_ALIAS ? ALL_IP_RANGES_CIDR : entry
      end

      # Converts a CIDR string (e.g. "10.0.1.20/32") into the ip/mask octet
      # arrays Charles's accessControlConfiguration expects. A bare IP with
      # no "/prefix" (e.g. "10.0.1.20") is treated as /32, i.e. that single
      # host.
      def self.parse_cidr(cidr)
        ip_octets, prefix_length = validate_cidr!(cidr)

        mask_int = prefix_length.zero? ? 0 : (0xFFFFFFFF << (32 - prefix_length)) & 0xFFFFFFFF
        mask_octets = [24, 16, 8, 0].map { |shift| (mask_int >> shift) & 0xFF }

        [ip_octets, mask_octets]
      end

      # Matches `cidr` against CIDR_PATTERN and returns the [ip_octets,
      # prefix_length], raising a clear UI.user_error! for any of the ways
      # a hand-typed ip_ranges entry commonly goes wrong.
      def self.validate_cidr!(cidr)
        match = CIDR_PATTERN.match(cidr.to_s)
        UI.user_error!("Invalid ip_ranges entry #{cidr.inspect}: expected CIDR notation (e.g. \"10.0.1.20/32\") or a bare IP") unless match

        ip_octets = match.captures[0, 4].map(&:to_i)
        UI.user_error!("Invalid ip_ranges entry #{cidr.inspect}: each octet must be 0-255") if ip_octets.any? { |octet| octet > 255 }

        prefix_length = (match[5] || DEFAULT_CIDR_PREFIX.to_s).to_i
        UI.user_error!("Invalid ip_ranges entry #{cidr.inspect}: prefix must be 0-32") if prefix_length > 32

        [ip_octets, prefix_length]
      end
    end
  end
end
