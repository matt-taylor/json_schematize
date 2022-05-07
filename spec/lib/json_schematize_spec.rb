# frozen_string_literal: true

RSpec.describe JsonSchematize do
  describe '.configure' do
    it 'configures' do
      described_class.configure

      expect(described_class.configuration).to be_a(JsonSchematize::Configuration)
    end

    context 'with block' do
      it 'sends config to block' do
        expect{ |b| described_class.configure(&b) }.to yield_with_args(described_class.configuration)
      end

      it 'configures' do
        described_class.configure

        expect(described_class.configuration).to be_a(JsonSchematize::Configuration)
      end
    end
  end

  describe '.configuration' do
     subject { described_class.configuration }

     it { is_expected.to be_a(JsonSchematize::Configuration) }
  end

  describe '.configuration=' do
    subject { described_class.configuration = config }

    let(:config) { JsonSchematize::Configuration.new }

    it { is_expected.to be_a(JsonSchematize::Configuration) }

    context "when not correct type" do
      let(:config) { "incorrect" }

      it do
        expect { subject }.to raise_error(JsonSchematize::ConfigError, /Expected configuration/)
      end
    end
  end
end
