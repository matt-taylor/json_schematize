module JsonSchematize
  module Cache
    module ClassMethods
      DEFAULT_ONE_MIN = 60 * 60
      DEFAULT_ONE_HOUR = DEFAULT_ONE_MIN * 60
      DEFAULT_ONE_DAY = DEFAULT_ONE_HOUR * 24
      DEFAULTS = {
        redis_url: ENV["CACHE_LAYER_REDIS_URL"] || ENV["REDIS_URL"],
        ttl: DEFAULT_ONE_DAY,
        key: ->(val) { val.hash },
        update_on_change: true,
        update_on_assignment: true,
        update_on_assignment: true,
      }

      def cache_options(key: nil, redis_url: nil, redis_client: nil, cache_namespace: nil, ttl: nil, update_on_change: nil, update_on_assignment: nil)
        cache_configuration[:key] = key if key
        cache_configuration[:ttl] = ttl if ttl
        cache_configuration[:update_on_change] = update_on_change if update_on_change
        cache_configuration[:update_on_assignment] = update_on_assignment if update_on_assignment
        cache_namespace = cache_configuration[:cache_namespace] = cache_namespace if cache_namespace

        redis_client = cache_configuration[:redis_client] = redis_client if redis_client
        redis_url = cache_configuration[:redis_url] = redis_url if redis_url
      end

      def cache_namespace
        @cache_namespace ||= "jss:#{self.name.downcase}"
      end

      def cache_namespace=(namespace)
        @cache_namespace ||= namespace
      end

      def cache_configuration
        @cache_configuration ||= DEFAULTS
      end

      def redis_client=(client)
        @redis_client = client
      end

      def redis_url=(url)
        redis_client = ::Redis.new(url: url)
      end

      def redis_client
        @redis_client ||= begin
          ::Redis.new(url: DEFAULTS[:redis_url])
        end
      end

      def cached_keys
        max_length = Time.now.to_i + cache_configuration[:ttl].to_i + 10
        redis_client.zrangebyscore(cache_namespace, Time.now.to_i, "+inf")
      end

      def cached_items
        clear_unscored_items! if rand >0.8

        cached_keys.map do |key|
          stringed = redis_client.get(key)
          string_key_hash = JSON.parse(stringed)
          new(string_key_hash, skip_cache_update: true)
        end
      end

      def clear_cache!
        redis_client.unlink(*cached_keys) if cached_keys.length > 0
        redis_client.unlink(cache_namespace)
      end

      def clear_unscored_items!
        redis_client.zremrangebyscore(cache_namespace, "-inf", Time.now.to_i)
      end
    end
  end
end
