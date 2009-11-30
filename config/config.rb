require 'rubygems'
require 'yaml'
require 'schema_hash'

module Config
  
  class ValidationError < RuntimeError; end
  
  CONFIG_FILE = 'config.yaml'
  
  SCHEMA = {
    "api" => {
      "api_key"    => true,
      "base_uri"   => true,
      "time_delay" => true,
    }
  }
  
  def self.setup
    # Application setup goes here...
  end

  def self.environment_config
    env_config = config[environment]
    unless env_config
      raise "Environment config not found for #{environment.inspect}"
    end
    env_config
  end

  def self.environment
    if @environment
      @environment
    else
      ENV['RACK_ENV'] || 'development'
    end
  end
  
  def self.environment=(env)
    @environment = env
  end

  def self.environments
    config.keys
  end
  
  def self.config
    if @config
      @config
    else
      file = File.join(File.dirname(__FILE__), CONFIG_FILE)
      @config = YAML.load_file(file)
    end
  end
  
  def self.validate
    actual = environment_config
    actual.schema = SCHEMA
    raise ValidationError, "Invalid #{CONFIG_FILE}" unless actual.valid?
  end
  
  def self.verbose_validate
    validate
    puts "Configuration is ok"
  end

end
