# frozen_string_literal: true

require "json_schematize/generator"

class JsonSchematize::EmptyValue < ::JsonSchematize::Generator
  def initialize(*)
    super
  end
end
