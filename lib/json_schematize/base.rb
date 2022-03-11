# frozen_string_literal: true

class JsonSchematize::Base
  def self.acceptable_types
    raise NoMethodError, "Expected acceptable_values to be defined in parent class"
  end
end
