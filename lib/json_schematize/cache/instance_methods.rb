module JsonSchematize
  module Cache
    module InstanceMethods
      def initialize(stringified_params = nil, skip_cache_update: false, raise_on_error: true, **params)
        super(stringified_params, raise_on_error: raise_on_error, **params)

        if @values_assigned
          __update_cache_item__ unless skip_cache_update
        end
      end

      def __update_cache_item__
        client = self.class.redis_client
        ttl = self.class.cache_configuration[:ttl].to_i
        score = Time.now.to_i + ttl
        client.zadd(__cache_namespace__, score, __cache_key__)
        client.set(__cache_key__, self.to_h.to_json, ex: ttl)
      end

      def __cache_key__
        "#{__cache_namespace__}:#{self.class.cache_configuration[:key].call(self)}"
      end

      def __cache_namespace__
        self.class.cache_namespace
      end
    end
  end
end
