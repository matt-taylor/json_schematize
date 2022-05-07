# frozen_string_literal: true

module JsonSchematize::Cache::ClassMethods
  module Client

    def __deserialize_keys__(key_hash_bytes)
      return [{}, 0] if key_hash_bytes.nil?

      min_expire = Time.now.to_i
      key_hash =  Marshal.load(key_hash_bytes)
      keys_removed = 0
      key_hash.each do |key, expire|
        next if expire.to_i > min_expire

        key_hash.delete(key)
        keys_removed += 1
      end

      [key_hash, keys_removed]
    rescue StandardError => e
      ::Kernel.warn("Yikes!! Failed to parse. Returning empty. #{e.message}")
      [{}, 0]
    end

    def __update_record_keeper__!(expire:, cache_key:, delete_key: false)
      record_of_truth = cached_keys(with_expire: true)
      if delete_key
        record_of_truth.delete(cache_key)
      else
        record_of_truth[cache_key] = expire
      end
      serialized_string = Marshal.dump(record_of_truth)

      cache_client.write(cache_namespace, serialized_string)
    end

    def __delete_record__!(key)
      __update_record_keeper__!(expire: nil, cache_key: key, delete_key: true)
    end

    def cached_keys(with_expire: false, count_removed: false)
      raw_string = cache_client.read(cache_namespace)
      key_hash, keys_removed = __deserialize_keys__(raw_string)
      return key_hash if with_expire
      return keys_removed if count_removed

      key_hash.keys
    end

    def cached_items(key_includes: nil)
      clear_unscored_items! if rand > cache_configuration[:stochastic_cache_bust]

      cached_keys.map do |key|
        if key_includes
          next unless key.include?(key_includes)
        end

        serialized_string = cache_client.read(key)
        Marshal.load(serialized_string)
      end.compact
    end

    def clear_cache!
      cache_client.delete_multi(([cache_namespace] + cached_keys))
    end

    def clear_unscored_items!
      cached_keys(count_removed: true)
    end
  end
end
