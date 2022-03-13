# frozen_string_literal: true

module JsonSchematize::FieldValidators

  def validations!
    validate_type!(t: @type)
    validate_types!
    validate_name!
    validate_validator!
    validate_required!
    validate_dig_type!
    validate_dig!
    validate_converter!
  end

  def validate_converter!
    return if validate_converter_nil!

    return if validate_converter_proc!

    return if validate_converter_hash!

   raise JsonSchematize::FieldError, ":converter passed unexpected type. Expected [Hash, Proc, nil]. Given [#{@converter.class}]"
  end

  def validate_converter_nil!
    return false unless @converter.nil?

    return true if @acceptable_types.length == 1

    raise JsonSchematize::FieldError, ":converter expected to be populated with multiple accepted types [#{@acceptable_types}]"
  end

  def validate_converter_proc!
    @converter.is_a?(Proc)
  end

  def validate_converter_hash!
    return false unless converter.is_a?(Hash)

    if @converter.keys.map(&:name).sort != @acceptable_types.map(&:name).sort
      raise JsonSchematize::FieldError, ":converter given a hash. Keys of hash do not match klass types of accepted types. Given [#{converter.keys}]. Expected [#{@acceptable_types}]"
    end

    return true if @converter.values.all? { |klass| klass.is_a?(Proc) }

    raise JsonSchematize::FieldError, ":converter given a hash. Values of proc must all be of type Proc"
  end

  def validate_required!
    raise JsonSchematize::FieldError, ":required expected to be an boolean" unless [true, false].include?(@required)
  end

  def validate_dig_type!
    values = JsonSchematize::Field::EXPECTED_DIG_TYPE
    raise JsonSchematize::FieldError, ":dig_type expected to be an #{values}" unless values.include?(@dig_type)
  end

  def validate_validator!
    raise JsonSchematize::FieldError, ":validator expected to be an proc" unless @validator.is_a?(Proc)
  end

  def validate_dig!
    raise JsonSchematize::FieldError, ":dig expected to be an Array" unless @dig.is_a?(Array)
  end

  def validate_name!
    raise JsonSchematize::FieldError, ":name expected to be symbol" unless @name.is_a?(Symbol)
  end

  def validate_type!(t:, message: ":type expected to be a Class object")
    raise JsonSchematize::FieldError, message unless t.class == Class

    return if @acceptable_types.include?(t)

    @acceptable_types << t
  end

  def validate_types!
    raise JsonSchematize::FieldError, ":types expected to be an array" unless @types.is_a?(Array)
    @types.each do |t|
       validate_type!(t: t, message: ":types expected to be an array with class Objects")
    end
  end
end
