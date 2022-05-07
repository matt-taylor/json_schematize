# frozen_string_literal: true

RSpec.describe JsonSchematize::Configuration do
  let(:instance) { described_class.new }

  describe "#cache_hash" do
    it { expect(instance.cache_hash).to be_a(Hash) }
  end

  describe "#cache_key=" do
    subject { instance.cache_key = value }

    let(:value) { ->(_,_) { "badaboom" } }
    it { expect { subject }.to_not raise_error }

    context "when incorrect value" do
      let(:value) { "string" }

      it { expect { subject }.to raise_error(JsonSchematize::ConfigError) }
    end
  end

  describe "#cache_client=" do
    subject { instance.cache_client = cache_client }

    let(:cache_client) { ActiveSupport::Cache::MemoryStore.new }
    it { expect { subject }.to_not raise_error }

    context "when incorrect value" do
      let(:cache_client) { "string" }

      it { expect { subject }.to raise_error(JsonSchematize::ConfigError) }
    end
  end

  describe "#cache_client" do
    subject { instance.cache_client }

    it { is_expected.to be_a(ActiveSupport::Cache::MemoryStore) }

    context "when ActiveSupport not available" do
      before { allow(Kernel).to receive(:require).with("active_support").and_raise(LoadError) }

      it { expect { subject }.to raise_error(JsonSchematize::ConfigError) }
    end
  end
end
