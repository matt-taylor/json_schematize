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
      expect(klass.redis_client.keys).to include(instance.__cache_key__)
      expect(klass.cached_keys).to include(instance.__cache_key__)

      instance.__clear_entry__!

      expect(klass.redis_client.keys).to_not include(instance.__cache_key__)
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

    it 'does not update redis cache on retrieval' do
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
      expect(klass.redis_client.keys).to include(*keys)
      sleep(2) # redis keeps it's own time. No way to simulate this
      expect(klass.redis_client.keys).to_not include(*keys)
    end

    it 'clears unscored items from primary' do
      keys
      sleep(2)
      expect(klass.clear_unscored_items!).to eq(times)
    end

    it 'does not update redis cache on retrieval' do
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

    it 'updates redis on change' do
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

  context 'with redis_client set' do
    let(:klass) do
      class CacheRedisClientDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options redis_client: Redis.new(url: "#{ENV['REDIS_URL']}/15")

        add_field name: :id, type: String
      end
      CacheRedisClientDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.redis_client.inspect).to include("/15") }
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

  context 'with redis_url set' do
    let(:klass) do
      class CacheRedisClientDefault < JsonSchematize::Generator
        include JsonSchematize::Cache

        cache_options redis_url: "#{ENV['REDIS_URL']}/15"

        add_field name: :id, type: String
      end
      CacheRedisClientDefault
    end
    let(:params) { { id: id } }
    let(:id) { "cool_beans_yo" }

    it { expect(klass.redis_client.inspect).to include("/15") }
    it { expect(klass.cache_configuration[:redis_url]).to eq("#{ENV['REDIS_URL']}/15") }
  end
end
