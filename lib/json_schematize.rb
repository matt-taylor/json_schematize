# frozen_string_literal: true


require "json_schematize/base"
require "json_schematize/boolean"
require "json_schematize/configuration"
require "json_schematize/empty_value"
require "json_schematize/errors"
require "json_schematize/generator"
require "json_schematize/version"

module JsonSchematize
  ## Customized class errors
  class UndefinedBoolean < Error; end

  def self.configure
    yield configuration if block_given?
  end

  def self.configuration
    @configuration ||= JsonSchematize::Configuration.new
  end

  def self.configuration=(object)
    raise ConfigError, "Expected configuration to be a JsonSchematize::Configuration" unless object.is_a?(JsonSchematize::Configuration)

    @configuration = object
  end

  def self.cache_client
    configuration.cache_client
  end
end
