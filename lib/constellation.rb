module Constellation

  class ParseError < StandardError
    def initialize(file)
      super("Could not parse #{file}. Try overriding #parse_config_file")
    end
  end

  module ActsAs
    def acts_as_constellation
      extend Constellation::ClassMethods
      self.env_params = {}
      include Constellation::InstanceMethods
    end
  end

  module ClassMethods
    attr_accessor :env_params, :config_file, :load_from_gems
  end

  module InstanceMethods

    def initialize(data = nil)
      @data = {}
      reverse_merge(data || {})
      fall_back_on_env
      fall_back_on_file(Dir.pwd)
      fall_back_on_file(ENV['HOME'])
      fall_back_on_gems
    end

    def method_missing(name, *arguments, &block)
      if data.has_key?(name.to_s)
        data[name.to_s]
      else
        super
      end
    end

    def respond_to?(name)
      data.has_key?(name.to_s) || super
    end

    private

    attr_reader :data

    def fall_back_on_env
      env_values = self.class.env_params.inject({}) do |sum, (prop, env_prop)|
        sum[prop] = ENV[env_prop] if ENV.has_key?(env_prop)
        sum
      end
      reverse_merge(env_values)
    end

    def fall_back_on_file(dir)
      return if relative_config_file.nil?
      f = File.expand_path(relative_config_file, dir)
      cfg = load_config_file(f)
      return unless cfg.respond_to?(:each) && cfg.respond_to?(:[])
      reverse_merge(cfg)
    end

    def fall_back_on_gems
      return unless self.class.load_from_gems
      gem_paths.each { |p| fall_back_on_file(p) }
    end

    def reverse_merge(hash)
      hash.each do |prop, value|
        data[prop.to_s] ||= value
      end
    end

    def relative_config_file
      self.class.config_file
    end

    def load_config_file(full_path)
      return unless File.exists?(full_path)

      contents = File.read(full_path)

      parsed = parse_config_file(contents)
      return parsed if parsed

      case full_path
      when /\.ya?ml$/
        require 'yaml'
        YAML.load(contents)
      when /\.json$/
        require 'multi_json'
        MultiJson.decode(File.read(full_path))
      else
        raise Constellation::ParseError.new(full_path)
      end
    end

    def parse_config_file(contents)
    end

    def gem_paths
      Gem.loaded_specs.values.map(&:gem_dir)
    end

  end

end

Class.send :include, Constellation::ActsAs