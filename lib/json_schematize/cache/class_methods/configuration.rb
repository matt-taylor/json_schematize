# frozen_string_literal: true

module JsonSchematize::Cache::ClassMethods
  module Configuration
    def cache_options(key: nil, cache_client: nil, cache_namespace: nil, ttl: nil, update_on_change: nil, stochastic_cache_bust: nil)
      cache_configuration[:key] = key if key
      cache_configuration[:ttl] = ttl if ttl
      cache_configuration[:stochastic_cache_bust] = stochastic_cache_bust if stochastic_cache_bust
      cache_configuration[:update_on_change] = update_on_change if update_on_change
      cache_namespace = cache_configuration[:cache_namespace] = cache_namespace if cache_namespace

      self.cache_client = cache_configuration[:cache_client] = cache_client if cache_client
    end

    def cache_namespace
       cache_configuration[:cache_namespace] ||= "jss:#{self.name.downcase}"
    end

    def cache_namespace=(namespace)
      cache_configuration[:cache_namespace] = namespace
    end

    def cache_configuration
      @cache_configuration ||= begin
        {
          cache_client: JsonSchematize.configuration.cache_client,
          cache_namespace: JsonSchematize.configuration.cache_namespace,
          key: JsonSchematize.configuration.cache_key,
          stochastic_cache_bust: JsonSchematize.configuration.cache_stochastic_bust,
          ttl: JsonSchematize.configuration.cache_ttl,
          update_on_change: JsonSchematize.configuration.cache_update_on_change,
        }
      end
    end

    def cache_client=(client)
      cache_configuration[:cache_client] = client
    end

    def cache_client
      cache_configuration[:cache_client].is_a?(Proc) ? cache_configuration[:cache_client].call : cache_configuration[:cache_client]
    end
  end
end
