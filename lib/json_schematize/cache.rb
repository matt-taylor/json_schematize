# frozen_string_literal: true

require "json_schematize/cache/instance_methods"
require "json_schematize/cache/class_methods/client"
require "json_schematize/cache/class_methods/configuration"

module JsonSchematize
  module Cache
    module ClassMethods; end

    def self.included(base)
      base.include(JsonSchematize::Cache::InstanceMethods)
      base.extend(JsonSchematize::Cache::ClassMethods::Client)
      base.extend(JsonSchematize::Cache::ClassMethods::Configuration)
    end
  end
end
