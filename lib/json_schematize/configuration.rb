# frozen_string_literal: true

module JsonSchematize
  class Configuration
    DEFAULT_ONE_MIN = 60 * 60
    DEFAULT_ONE_HOUR = DEFAULT_ONE_MIN * 60
    DEFAULT_ONE_DAY = DEFAULT_ONE_HOUR * 24
    DEFAULT_CACHE_OPTIONS = {
      cache_client: nil,
      cache_key: ->(val, _custom_key) { val.hash },
      cache_namespace: nil,
      cache_stochastic_bust: 0.8,
      cache_ttl: DEFAULT_ONE_DAY,
      cache_update_on_change: true,
    }

    attr_accessor *DEFAULT_CACHE_OPTIONS.keys

    def initialize
      @cache_client = DEFAULT_CACHE_OPTIONS[:cache_client]
      @cache_key = DEFAULT_CACHE_OPTIONS[:cache_key]
      @cache_namespace = DEFAULT_CACHE_OPTIONS[:cache_namespace]
      @cache_stochastic_bust = DEFAULT_CACHE_OPTIONS[:cache_stochastic_bust]
      @cache_ttl = DEFAULT_CACHE_OPTIONS[:cache_ttl]
      @cache_update_on_change = DEFAULT_CACHE_OPTIONS[:cache_update_on_change]
    end

    def cache_hash
      DEFAULT_CACHE_OPTIONS.map do |key, value|
        val = public_send(key)
        [key, val]
      end.to_h
    end

    def cache_key=(value)
      if value.is_a? Proc
        @key = value
        return @key
      end

      assign = _assign_msg_("cache_key", "->(val, cusom_key) { val.hash }", "Default proc to assign cache key")
      msg = "cache_key must be a proc. \n#{assign}"
      raise JsonSchematize::ConfigError, msg
    end

    def cache_client=(client)
      min_required = [:read, :write, :delete_multi, :read_multi]
      min_required.each do |meth|
        next if client.methods.include?(meth)

        assign = _assign_msg_("cache_client", "_initialized_client_", "Preferably an ActiveSupport::Cache::Store supported client")
        msg = "Passed in client does not accept minimum values. #{min_required} are required methods \n#{assign}"
        raise JsonSchematize::ConfigError, msg
      end


      @cache_client = client
    end

    def cache_client
      return @cache_client unless @cache_client.nil?

      begin
        Kernel.require 'active_support'
      rescue LoadError
        assign = _assign_msg_("cache_client", "ActiveSupport::Cache::MemoryStore.new", "A ActiveSupport::Cache::Store supported client")
        msg = "Default client missing. Attempted to use 'active_support/cache' but not loaded. \n#{assign}"
        raise JsonSchematize::ConfigError, msg
      end

      @cache_client = ActiveSupport::Cache::MemoryStore.new
      @cache_client
    end

    private

    def _assign_msg_(key, assignment, comment)
      config =
        if assignment.is_a?(Array)
          assignment.map do |assign|
            "  config.#{key} = #{assign} # #{comment}"
          end.join("\n")
        else
          "  config.#{key} = #{assignment} # #{comment}"
        end
      "\n\n# Initializer for json_schematize\n" \
      "JsonSchematize.configure do |config|\n" \
      "#{config}\n" \
      "end\n\n"
    end
  end
end
