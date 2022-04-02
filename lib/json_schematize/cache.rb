# frozen_string_literal: true

require "json_schematize/cache/instance_methods"
require "json_schematize/cache/class_methods"

module JsonSchematize
  module Cache
    def self.included(base)
      raise StandardError, "Yikes! JsonSchematize::Cache Needs Redis to work. Include it as a gem" unless defined?(Redis)

      base.include(JsonSchematize::Cache::InstanceMethods)
      base.extend(JsonSchematize::Cache::ClassMethods)
    end
  end
end
