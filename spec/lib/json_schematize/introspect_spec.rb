# frozen_string_literal: true

RSpec.describe "Introspection" do

  let(:instance) { klass.new(**params) }
  let(:klass) { Class.new(JsonSchematize::Generator) }
  let(:secondary_class) { Class.new(JsonSchematize::Generator) }
  before do
    klass.add_field name: :id, type: Integer
    klass.add_field name: :count, type: Integer
    klass.add_field name: :style, type: Symbol
    klass.add_field name: :something, type: String
    klass.add_field name: :danger, type: Symbol
    klass.add_field name: :zone, type: Symbol
  end

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

    it { is_expected.to eq(params) }

    context "with deep nested generator" do
      before do
        secondary_class.add_field name: :id, type: Integer
        klass.add_field name: :nested, type: secondary_class
      end

      let(:secondary_params) { { id: 12 } }
      let(:params) { super().merge(nested: secondary_params) }

      it { is_expected.to eq(params) }
    end

    context "with array deep nested generator" do
      before do
        secondary_class.add_field name: :id, type: Integer
        klass.add_field name: :nested, array_of_types: true, type: secondary_class
      end

      let(:secondary_params) { [{ id: 12 }, { id: 14 }] }
      let(:params) { super().merge(nested: secondary_params) }

      it { is_expected.to eq(params) }
    end
  end

  describe "#deep_inspect" do
    subject(:deep_inspect) { instance.deep_inspect(with_raw_params: with_raw_params, with_field: with_field) }

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

    let(:expected) { "#<#{klass} - required fields: #{params.keys}; #{instance.to_h.map { |k, v| "#{k}:#{v}" }.join(", ")}>" }
    it { is_expected.to eq(expected) }
  end

end
