# frozen_string_literal: true

RSpec.describe JsonSchematize::Field do
  let(:instance) { described_class.new(**params) }
  let(:params) do
    {
      name: name,
      types: types,
      type: type,
      dig: dig,
      dig_type: dig_type,
      required: required,
      validator: validator_proc,
      converter: converter,
      array_of_types: array_of_types,
    }
  end
  let(:name) { Faker::Name.name.delete(" ").to_sym }
  let(:types) { [] }
  let(:type) { Integer }
  let(:dig) { nil }
  let(:dig_type) { nil }
  let(:required) { true }
  let(:converter) { nil }
  let(:array_of_types) { false }
  let(:validator_proc) { ->(_val, _raw_val) { true } }

  describe "#setup!" do
    subject(:setup) { instance.setup! }

    context 'with invalid inputs' do
      context 'when types is invalid' do
        let(:types) { "not an array" }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:types expected to be an array/) }

        context 'when array has invalid values' do
          let(:types) { ["not an array"] }

          it { expect { subject }.to raise_error(JsonSchematize::FieldError, /:types expected to be an array with class Objects/) }
        end
      end

      context 'when type is invalid' do
        let(:type) { "raise an error" }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:type expected to be a Class object/) }
      end

      context 'when name is invalid' do
        let(:name) { "not an accepted value" }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:name expected to be symbol/) }
      end

      context 'when validator is invalid' do
        let(:validator_proc) { "not a proc" }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:validator expected to be an proc/) }
      end

      context 'when required is invalid' do
        let(:required) { "not a bool" }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:required expected to be an boolean/) }
      end

      context 'when dig_type is invalid' do
        let(:dig_type) { :not_expected_sym }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:dig_type expected to be an/) }
      end

      context 'when dig is invalid' do
        let(:dig) { "not an array" }

        it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:dig expected to be an Array/) }
      end

      context 'when converter is invalid' do
        context 'when given converter is nil' do
          context 'when acceptable_types length is more than 1' do
            let(:types) { [Integer, String, Symbol] }

            it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:converter expected to be populated with multiple/) }
          end
        end

        context 'when given converter is a Hash' do
          let(:types) { [Integer, String, Symbol] }

          context 'when keys do not match acceptable_types' do
            let(:converter) do
              {
                Integer => ->(val) { 5 },
                String => ->(val) { "yes" },
                Float => ->(val) { 5.01 },
              }
            end

            it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:converter given a hash. Keys of hash/) }
          end

          context 'when values are not all procs' do
            let(:converter) do
              {
                Integer => "not a proc",
                String => ->(val) { "yes" },
                Symbol => ->(val) { val.to_sym },
              }
            end
            it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:converter given a hash. Values of proc/) }
          end
        end

        context 'when given converter is not an acceptable type' do
          let(:converter) { [] }

          it { expect { subject}.to raise_error(JsonSchematize::FieldError, /:converter passed unexpected type/) }
        end
      end
    end

    context 'with multiple type/types' do
      let(:types) { [Integer, String, Symbol] }
      let(:converter) do
        {
          Integer => ->(val) { val.to_i },
          String => ->(val) { val.to_s },
          Symbol => ->(val) { val.to_sym },
        }
      end

      it do
        subject

        expect(instance.acceptable_types.map(&:name).sort).to eq(converter.keys.map(&:name).sort)
      end
    end

    context 'with different dig types' do
      context 'when dig_type is a string' do
        let(:dig_type) { JsonSchematize::Field::DIG_STRING }
        let(:dig) { [:symbol, "string", :"symbol"] }

        it do
          subject

          expect(instance.dig).to eq(dig.map(&:to_s))
        end
      end

      context 'when dig is a symbol' do
        let(:dig_type) { JsonSchematize::Field::DIG_SYMBOL }
        let(:dig) { [:symbol, "string", :"symbol"] }

        it do
          subject

          expect(instance.dig).to eq(dig.map(&:to_sym))
        end
      end

      context 'when dig type is none (mixed values)' do
        let(:dig) { [:symbol, "string", :"symbol"] }

        it do
          subject

          expect(instance.dig).to eq(dig)
        end
      end
    end

    context 'when default converters' do
      context 'with Integer' do
        let(:type) { Integer }
        let(:val) { "5" }

        it do
          subject

          expect(instance.converter.call(val)).to eq(val.to_i)
        end
      end

      context 'with Symbol' do
        let(:type) { Symbol }
        let(:val) { "symbol" }

        it do
          subject

          expect(instance.converter.call(val)).to eq(val.to_sym)
        end
      end

      context 'with String' do
        let(:type) { String }
        let(:val) { "string" }

        it do
          subject

          expect(instance.converter.call(val)).to eq(val)
        end
      end

      context 'with Float' do
        let(:type) { Float }
        let(:val) { "1234.234" }

        it do
          subject

          expect(instance.converter.call(val)).to eq(val.to_f)
        end
      end

      context 'when undefined' do
        let(:type) { Time }
        let(:val) { Time.now.to_s }

        it do
          subject

          expect(instance.converter.call(val)).to eq(Time.new(val))
        end
      end
    end
  end

  describe "#acceptable_value?" do
    subject(:acceptable_value) { instance.acceptable_value?(transformed_value: value, raise_on_error: raise_on_error) }

    before { instance.setup! }

    context 'when raise_on_error is true' do
      let(:raise_on_error) { true }

      context 'when value is acceptable' do
        let(:value) { 5 }
        it { is_expected.to eq(true) }

        context "with array_of_types true" do
          let(:array_of_types) { true }
          let(:value) { [1,2,3,4,5] }

          it { is_expected.to eq(true) }
        end
      end

      context 'when value is not acceptable' do
        let(:value) { "5" }
        it { expect { subject }.to raise_error(JsonSchematize::InvalidFieldByType, /:#{name} is an invalid option based on acceptable/) }

        context "with array_of_types true" do
          let(:array_of_types) { true }
          let(:value) { [1,2,3,4,"5"] }

          it { expect { subject }.to raise_error(JsonSchematize::InvalidFieldByType, /array_of_types/) }
        end
      end
    end

    context 'when raise_on_error is false' do
      let(:raise_on_error) { false }

      context 'when value is acceptable' do
        let(:value) { 5 }
        it { is_expected.to eq(true) }
      end

      context 'when value is not acceptable' do
        let(:value) { "5" }
        it { is_expected.to eq(false) }
      end
    end
  end

  describe "#acceptable_value_by_validator?" do
    subject(:acceptable_value_by_validator) { instance.acceptable_value_by_validator?(transformed_value: transformed_value, raw_value: raw_value, raise_on_error: raise_on_error) }
    before { instance.setup! }

    let(:transformed_value) { 5 }
    let(:raw_value) { "5" }
    context 'when raise_on_error is true' do
      let(:raise_on_error) { true }

      context 'when value is acceptable' do
        it { is_expected.to eq(true) }

        context "with array_of_types true" do
          let(:array_of_types) { true }
          let(:transformed_value) { [1,2,3,4,5] }

          it { is_expected.to eq(true) }
        end
      end

      context 'when value is not acceptable' do
        let(:validator_proc) { ->(_val, _raw_val) { false } }

        it { expect { subject }.to raise_error(JsonSchematize::InvalidFieldByValidator, /:#{name} is an invalid option based on validator :proc option/) }

        context "with array_of_types true" do
          let(:validator_proc) { ->(val, _raw_val) { val.is_a?(Integer) } }
          let(:array_of_types) { true }
          let(:transformed_value) { [1,2,3,4,"5"] }

          it { expect { subject }.to raise_error(JsonSchematize::InvalidFieldByValidator, /array_of_types/) }
        end
      end
    end

    context 'when raise_on_error is false' do
      let(:raise_on_error) { false }

      context 'when value is acceptable' do
        it { is_expected.to eq(true) }
      end

      context 'when value is not acceptable' do
        let(:validator_proc) { ->(_val, _raw_val) { false } }
        it { is_expected.to eq(false) }
      end
    end
  end

  describe "#value_from_field" do
    subject(:value_from_field) { instance.value_from_field(raw_params) }

    before { instance.setup! }

    let(:dig) { ["something", :none, "special"] }
    let(:raw_params) do
      { "something" => { none: { "special" => "#{value}" } } }
    end
    let(:value) { "5" }

    it { is_expected.to eq({raw_value: value, transformed_value: value.to_i}) }

    context 'when value is not found' do
      let(:dig) { super() + ["not_found"] }

      it { is_expected.to eq(nil) }
    end
  end

  describe "#value_transform" do
    subject(:value_transform) { instance.value_transform(value: value) }
    let(:value) { "5" }

    before { instance.setup! }
    it { is_expected.to eq(value.to_i) }

    context 'when array_of_types is true' do
      let(:array_of_types) { true }

      context 'when value is an array' do
        let(:value) { ["1","2","3","4","5"] }

        it { is_expected.to eq([1,2,3,4,5])}
      end

      context 'when value is not array' do
        it { expect { subject }.to raise_error(JsonSchematize::InvalidFieldByArrayOfTypes, /expected to be an array based on :array_of_types flag/) }
      end
    end
  end
end
