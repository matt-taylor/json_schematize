# frozen_string_literal: true

RSpec.describe "Testing the Cache Layer Modules" do
  let(:instance) { klass.new(**params) }
  before { klass.clear_cache! }

  let(:klass) do
    class CacheDefault < JsonSchematize::Generator
      include JsonSchematize::Cache

      schema_default option: :dig_type, value: :string
      cache_options key: ->(val, _custom_val) { val.id }

      add_field name: :id, type: String
    end
    CacheDefault
  end
  let(:params) { { id: 'id' } }

  describe ".cached_keys" do
    subject { klass.cached_keys }

    it { expect { instance }.to change { klass.cached_keys.length }.by(1) }

    it do
      instance
      expect(subject).to include(instance.__cache_key__)
    end

    context "when deserialization fails" do
      before do
        instance

        allow(klass).to receive(:__marshalize__).and_raise(StandardError)
      end

      it { is_expected.to eq([]) }

      it do
        expect(::Kernel).to receive(:warn).with(/Yikes!!/).and_call_original

        subject
      end
    end
  end

  describe ".clear_cache!" do
    before { instance }
    subject { klass.clear_cache! }

    it do
      expect(klass.cached_keys.length).to eq(1)

      expect { subject }.to change { klass.cached_keys.length }.to(0)
    end
  end

  describe "#clear_entry!" do
    before { instance }

    it 'clears cache' do
      expect(klass.cache_client.instance_variable_get(:@data).keys).to include(instance.__cache_key__)
      expect(klass.cached_keys).to include(instance.__cache_key__)

      instance.__clear_entry__!

      expect(klass.cache_client.instance_variable_get(:@data).keys).to_not include(instance.__cache_key__)
      expect(klass.cached_keys).to_not include(instance.__cache_key__)
    end
  end

  describe ".cached_items" do
    before do
      times.times.each { |k| klass.new({'id'=>k}) }
    end
    subject { klass.clear_cache! }
    let(:times) { 10 }

    it do
      expect(klass.cached_items).to all(be_a(klass))
    end

    it 'does not update cache on retrieval' do
      klass.cached_items

      expect_any_instance_of(klass).to_not receive(:__update_cache_item__)
    end
  end

  describe ".clear_unscored_items!" do
    let(:klass) do
      class CacheDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        schema_default option: :dig_type, value: :string
        cache_options key: ->(val, _custom_val) { val.id }
        cache_options ttl: 2

        add_field name: :id, type: String
      end
      CacheDefault
    end

    let(:keys) do
      arr = []
      times.times.each { |k| arr << klass.new({'id'=>k}).__cache_key__ }
      arr
    end

    subject { klass.clear_cache! }
    let(:times) { 10 }

    it 'cached_items returns no items' do
      keys
      expect(klass.cache_client.instance_variable_get(:@data).keys).to include(*keys)
      sleep(2)
      klass.cache_client.cleanup # Explicitly clean up expired items, code does this automagically
      expect(klass.cache_client.instance_variable_get(:@data).keys).to_not include(*keys)
    end

    it 'clears unscored items from primary' do
      keys
      sleep(2)
      expect(klass.clear_unscored_items!).to eq(times)
    end

    it 'does not update cache on retrieval' do
      klass.cached_items

      expect_any_instance_of(klass).to_not receive(:__update_cache_item__)
    end
  end

  context 'with custom cache_key' do
    let(:klass) do
      class CacheKeyDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options key: ->(val, _custom_val) { val.id }

        add_field name: :id, type: String
      end
      CacheKeyDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.cache_configuration[:key]).to be_a(Proc) }
    it { expect(klass.cache_configuration[:key].call(instance, nil)).to eq(id) }
  end

  context 'with custom ttl' do
    let(:klass) do
      class CacheTtlDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options ttl: 60

        add_field name: :id, type: String
      end
      CacheTtlDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.cache_configuration[:ttl]).to eq(60) }
  end

  context 'with update_on_change set' do
    let(:klass) do
      class CacheTtlDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options update_on_change: true

        add_field name: :id, type: String
      end
      CacheTtlDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.cache_configuration[:update_on_change]).to be(true) }

    it 'updates cache on change' do
      instance
      expect(instance).to receive(:__update_cache_item__)

      instance.id = "Some String"
    end
  end

  context 'with update_on_change set' do
    let(:klass) do
      class CacheNamespaceDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options cache_namespace: "some_bogus_namespace"

        add_field name: :id, type: String
      end
      CacheNamespaceDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.cache_configuration[:cache_namespace]).to eq("some_bogus_namespace") }
    it { expect(klass.cache_namespace).to eq("some_bogus_namespace") }

    context 'when setting equals' do
      before { klass.cache_namespace = "some_random_name" }

      it { expect(klass.cache_configuration[:cache_namespace]).to eq("some_random_name") }
      it { expect(klass.cache_namespace).to eq("some_random_name") }
    end
  end

  context 'with cache_client set' do
    let(:klass) do
      class CacheRedisClientDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options cache_client: ::ActiveSupport::Cache::MemoryStore.new(size: 2048, compress: true)

        add_field name: :id, type: String
      end
      CacheRedisClientDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.cache_client.instance_variable_get(:@options)).to eq({size: 2048, compress: true, compress_threshold: 1024}) }
  end

  context 'with stochastic_cache_bust set' do
    let(:klass) do
      class CacheRedisClientDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options stochastic_cache_bust: 0.123

        add_field name: :id, type: String
      end
      CacheRedisClientDefault
    end

    it { expect(klass.cache_configuration[:stochastic_cache_bust]).to eq(0.123) }
  end
end
