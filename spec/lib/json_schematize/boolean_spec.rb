# frozen_string_literal: true

RSpec.describe JsonSchematize::Boolean do
  let(:instance) { described_class.new(input) }

  describe ".initialize" do
    shared_examples "basic" do
    end

    context 'with true' do
      let(:expected) { true }
      described_class::TRUE_VALUES.each do |val|
        context "when #{val}" do
          let(:input) { val }

          it { expect(instance).to eq(expected) }
        end
      end
    end

    context 'when false' do
      let(:expected) { false }
      described_class::FALSE_VALUES.each do |val|
        context "when #{val}" do
          let(:input) { val }

          it { expect(instance).to eq(expected) }
        end
      end
    end

    context 'when not valid value' do
      let(:input) { nil }

      it { expect { instance }.to raise_error(JsonSchematize::UndefinedBoolean) }
    end
  end
end
