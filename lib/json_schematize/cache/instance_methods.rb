# frozen_string_literal: true

module JsonSchematize
  module Cache
    module InstanceMethods
      def initialize(stringified_params = nil, cache_key: nil, skip_cache_update: false, raise_on_error: true, **params)
        super(stringified_params, raise_on_error: raise_on_error, **params)

        @__incoming_cache_key__ = cache_key
        if @values_assigned
          __update_cache_item__(with_delete: false) unless skip_cache_update
        end
      end

      def __update_cache_item__(with_delete: true)
        __clear_entry__! if with_delete # needs to get done first in the event the cache_key changes
        client = self.class.cache_client
        ttl = self.class.cache_configuration[:ttl].to_i
        score = Time.now.to_i + ttl
        self.class.__update_record_keeper__!(expire: score, cache_key: __cache_key__)

        client.write(__cache_key__, Marshal.dump(self), expires_in: ttl)
      end

      def __clear_entry__!
        self.class.cache_client.delete(__cache_key__)
        self.class.__delete_record__!(__cache_key__)
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
