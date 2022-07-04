# frozen_string_literal: true

module JsonSchematize
  class Error < StandardError; end
  class ConfigError < Error; end
  class FieldError < Error; end

  class InvalidField < Error; end
  class InvalidFieldByValidator < InvalidField; end
  class InvalidFieldByType < InvalidField; end
  class InvalidFieldByArrayOfTypes < InvalidField; end

  ## Customized class errors
  class UndefinedBoolean < Error; end
end
