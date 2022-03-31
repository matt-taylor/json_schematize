module JsonSchematize
  module Cache
    module ClassMethods
      DEFAULT_ONE_MIN = 60 * 60
      DEFAULT_ONE_HOUR = DEFAULT_ONE_MIN * 60
      DEFAULT_ONE_DAY = DEFAULT_ONE_HOUR * 24
      DEFAULT_URL = ENV["CACHE_LAYER_REDIS_URL"] || ENV["REDIS_URL"]
      DEFAULTS = {
        redis_url: DEFAULT_URL,
        ttl: DEFAULT_ONE_DAY,
        key: ->(val, _custom_key) { val.hash },
        update_on_change: true,
        redis_client: ->() { ::Redis.new(url: DEFAULT_URL) },
      }

      def cache_options(key: nil, redis_url: nil, redis_client: nil, cache_namespace: nil, ttl: nil, update_on_change: nil)
        cache_configuration[:key] = key if key
        cache_configuration[:ttl] = ttl if ttl
        cache_configuration[:update_on_change] = update_on_change if update_on_change
        cache_namespace = cache_configuration[:cache_namespace] = cache_namespace if cache_namespace

        self.redis_client = cache_configuration[:redis_client] = redis_client if redis_client
        self.redis_url = cache_configuration[:redis_url] = redis_url if redis_url
      end

      def cache_namespace
         cache_configuration[:cache_namespace] ||= "jss:#{self.name.downcase}"
      end

      def cache_namespace=(namespace)
        cache_configuration[:cache_namespace] = namespace
      end

      def cache_configuration
        @cache_configuration ||= DEFAULTS
      end

      def redis_client=(client)
        cache_configuration[:redis_client] = client
      end

      def redis_url=(url)
        cache_configuration[:redis_url] = url
        cache_configuration[:redis_client] = ::Redis.new(url: url)
      end

      def redis_client
        cache_configuration[:redis_client].is_a?(Proc) ? cache_configuration[:redis_client].call : cache_configuration[:redis_client]
      end

      def cached_keys
        max_length = Time.now.to_i + cache_configuration[:ttl].to_i + 10
        redis_client.zrangebyscore(cache_namespace, Time.now.to_i, "+inf")
      end

      def cached_items
        clear_unscored_items! if rand >0.8

        cached_keys.map do |key|
          serialized_string = redis_client.get(key)
          Marshal.load(serialized_string)
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
