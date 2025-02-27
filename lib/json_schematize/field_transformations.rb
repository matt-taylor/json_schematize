# frozen_string_literal: true

module JsonSchematize::FieldTransformations
  DEFAULT_CONVERTERS = {
    Float => ->(val) { val.to_f },
    Integer => ->(val) { val.to_i },
    String => ->(val) { val.to_s },
    Symbol => ->(val) { val.to_sym },
  }

  def transformations!
    transform_converter_type!
    transform_dig_type!
  end

  def transform_converter_type!
    return unless @converter.nil?

    # validations have already happened -- We know @acceptable types is a single klass

    @converter = DEFAULT_CONVERTERS[@acceptable_types[0]]
    if @converter.nil?
      @converter = Proc.new do |val|
        if @acceptable_types[0] < JsonSchematize::Generator && @acceptable_types[0] === val
          val
        else
          @acceptable_types[0].new(val)
        end
      end
    end
  end

  def transform_dig_type!
    case @dig_type
    when JsonSchematize::Field::DIG_SYMBOL
      @dig = @dig.map(&:to_sym)
    when JsonSchematize::Field::DIG_STRING
      @dig = @dig.map(&:to_s)
    when JsonSchematize::Field::DIG_NONE
      @dig
    end
  end
end
