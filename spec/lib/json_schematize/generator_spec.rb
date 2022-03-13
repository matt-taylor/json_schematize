# frozen_string_literal: true

RSpec.describe JsonSchematize::Generator do

  describe ".add_field" do
    subject(:add_field) { klass.add_field(**field_params) }

    let(:klass) { class KlassAddField < described_class; end; KlassAddField }
    let(:field_params) do
      {
        name: name,
        type: type,
        types: types,
        dig_type: dig_type,
        dig: dig,
        validator: validator,
        required: required,
        converter: converter
      }.compact
    end
    let(:name) { Faker::Name.name.delete(" ").to_sym }
    let(:type) { Integer }
    let(:types) { nil }
    let(:dig_type) { nil }
    let(:dig) { nil }
    let(:validator) { nil }
    let(:converter) { nil }

    context "when required is true" do
      let(:required) { true }

      it do
        expect { subject }.to change { klass.required_fields.length }.by(1)
      end

      it do
        expect { subject }.to change { klass.fields.length }.by(1)
      end
    end

    context "when required is true" do
      let(:required) { false }

      it do
        expect { subject }.to change { klass.fields.length }.by(1)
      end

      it do
        expect { subject }.to change { klass.optional_fields.length }.by(1)
      end
    end
  end

  describe ".schema_default" do
    let(:instance) { klass.new(**params) }
    let(:klass) do
      class SchemaDefault < described_class
        schema_default option: :dig_type, value: :string

        add_field name: :count, type: Integer
        add_field name: :status, type: Symbol, dig: [:l1, :status]
        add_field name: :something, type: Symbol, required: false
      end
      SchemaDefault
    end
    let(:raise_on_error) { true }
    let(:params) do
      {
        "count" => count,
        "l1" => { "status" => status },
        "something" => something,
      }
    end
    let(:count) { 5 }
    let(:status) { "status" }
    let(:something) { "something" }

    it "sets correct default value" do
      expect(klass.fields.all? { |f| f.dig_type == :string }).to eq(true)
    end

    it "gets correct value" do
      expect(instance.status).to eq(status.to_sym)
    end
  end

  describe ".initialize" do
    subject { instance }
    let(:instance) { klass.new(raise_on_error: raise_on_error, **params) }
    let(:klass) do
      class KlassInit < described_class
        add_field name: :count, type: Integer, validator: ->(val, raw) { val >= 5}
        add_field name: :status, type: Symbol, dig: [:l1, :status]
        add_field name: :something, type: Symbol, required: false, validator: ->(val, raw) { val.to_s == "something" }
      end
      KlassInit
    end
    let(:raise_on_error) { true }
    let(:params) do
      {
        count: count,
        l1: { status: status },
        something: something,
      }
    end
    let(:count) { 5 }
    let(:status) { "status" }
    let(:something) { "something" }

    context 'with invalid required' do
      let(:count) { "does not pass validator" }

      it do
        expect { subject }.to raise_error(JsonSchematize::InvalidFieldByValidator, /:count is an invalid/)
      end
    end

    context 'with invalid optional' do
      let(:something) { "something_else" }

      it do
        expect { subject }.to raise_error(JsonSchematize::InvalidFieldByValidator, /:something is an invalid/)
      end
    end

    it 'creates convenience methods' do
      subject

      expect(instance.count).to eq(count)
      expect(instance.status).to eq(status.to_sym)
      expect(instance.something).to eq(something.to_sym)
    end
  end

  describe "introspection" do
    let(:instance) { klass.new(**params) }

    let(:params) do
      {
        id: 6457,
        count: 9145,
        style: :symbol,
        something: "danger",
        danger: :count,
        zone: :zone,
      }
    end

    describe "#to_h" do
      subject(:to_h) { instance.to_h }

      let(:klass) do
        class IntrospectKlassToH < described_class
          add_field name: :id, type: Integer
          add_field name: :count, type: Integer
          add_field name: :style, type: Symbol
          add_field name: :something, type: String
          add_field name: :danger, type: Symbol
          add_field name: :zone, type: Symbol
        end
        IntrospectKlassToH
      end
      it { is_expected.to eq(params) }
    end

    describe "#deep_inspect" do
      subject(:deep_inspect) { instance.deep_inspect(with_raw_params: with_raw_params, with_field: with_field) }

      let(:klass) do
        class IntrospectKlassDeepInspect < described_class
          add_field name: :id, type: Integer
          add_field name: :count, type: Integer
          add_field name: :style, type: Symbol
          add_field name: :something, type: String
          add_field name: :danger, type: Symbol
          add_field name: :zone, type: Symbol
        end
        IntrospectKlassDeepInspect
      end
      let(:with_raw_params) { false }
      let(:with_field) { false }
      let(:enumerate_expected) do
        klass.fields.map do |field|
          value = {
            required: field.required,
            acceptable_types: field.acceptable_types,
            value: params[field.name],
          }
          value[:field] = field if with_field
          value[:raw_params] = params if with_raw_params
          [field.name, value]
        end.to_h
      end

      it { is_expected.to eq(enumerate_expected) }

      context 'when with_raw_params' do
        let(:with_raw_params) { true }
        it { is_expected.to eq(enumerate_expected) }
      end

      context 'when with_field' do
        let(:with_field) { true }

        it { is_expected.to eq(enumerate_expected) }
      end
    end

    describe "#inspect" do
      subject(:inspect) { instance.inspect }

      let(:klass) do
        class IntrospectKlassInspect < described_class
          add_field name: :id, type: Integer
          add_field name: :count, type: Integer
          add_field name: :style, type: Symbol
          add_field name: :something, type: String
          add_field name: :danger, type: Symbol
          add_field name: :zone, type: Symbol
        end
        IntrospectKlassInspect
      end
      let(:expected) { "#<#{klass} - required fields: #{params.keys}; #{instance.to_h.map { |k, v| "#{k}:#{v}" }.join(", ")}>" }
      it { is_expected.to eq(expected) }
    end
  end

  context "when modifying values" do
    let(:instance) { klass.new(raise_on_error: raise_on_error, **params) }
    let(:klass) do
      class KlassInit < described_class
        add_field name: :count, type: Integer, validator: ->(val, raw) { val >= 5}
      end
      KlassInit
    end
    let(:raise_on_error) { true }
    let(:params) do
      {
        count: count,
        l1: { status: :status },
        something: "something",
      }
    end
    let(:count) { 5 }

    context "with valid values" do
      subject { instance.count = new_count }

      let(:new_count) { 10 }
      it { expect { instance.count }.to_not raise_error }
      it do
        subject

        expect(instance.count).to eq(new_count)
      end
    end

    context "with invalid values" do
      subject { instance.count = new_count }

      let(:new_count) { 5 }
      it { expect { instance.count }.to_not raise_error }
    end
  end
end
