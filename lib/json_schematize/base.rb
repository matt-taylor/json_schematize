# frozen_string_literal: true

module JsonSchematize
  class Base
    def self.acceptable_types
      raise NoMethodError, "Expected acceptable_values to be defined in parent class"
    end
  end
end
