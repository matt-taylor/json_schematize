# frozen_string_literal: true

class JsonSchematize::Boolean
  FALSE_VALUES = ["false", "f", "0", false]
  TRUE_VALUES = ["true", "t", "1", true]

  def self.new(val)
    return false if FALSE_VALUES.include?(val)
    return true if TRUE_VALUES.include?(val)

    raise JsonSchematize::UndefinedBoolean, "#{val} is not a valid #{self.class}"
  end
end
