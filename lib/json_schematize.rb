# frozen_string_literal: true

require "json_schematize/version"
require "json_schematize/generator"
require "json_schematize/boolean"

module JsonSchematize
  class Error < StandardError; end
  class FieldError < Error; end
  class InvalidField < Error; end
  class InvalidFieldByValidator < InvalidField; end
  class InvalidFieldByType < InvalidField; end
  class InvalidFieldByArrayOfTypes < InvalidField; end

  ## Customized class errors
  class UndefinedBoolean < Error; end
end
