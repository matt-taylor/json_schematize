module JsonSchematize
  module Cache
    module InstanceMethods
      def initialize(stringified_params = nil, skip_cache_update: false, raise_on_error: true, **params)
        super(stringified_params, raise_on_error: raise_on_error, **params)

        if @values_assigned
          __update_cache_item__(with_delete: false) unless skip_cache_update
        end
      end

      def __update_cache_item__(with_delete: true)
        __clear_entry__! if with_delete # needs to get done first in the event the cache_key changes
        client = self.class.redis_client
        ttl = self.class.cache_configuration[:ttl].to_i
        score = Time.now.to_i + ttl
        client.zadd(__cache_namespace__, score, __cache_key__)
        client.set(__cache_key__, Marshal.dump(self), ex: ttl)
      end

      def __clear_entry__!
        self.class.redis_client.zrem(__cache_namespace__, __cache_key__)
        self.class.redis_client.unlink(__cache_key__)
      end

      def __cache_key__
        "#{__cache_namespace__}:#{self.class.cache_configuration[:key].call(self, @__incoming_cache_key__)}"
      end

      def __cache_namespace__
        self.class.cache_namespace
      end
    end
  end
end
