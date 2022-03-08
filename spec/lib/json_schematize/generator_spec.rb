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
