# Stolen from https://raw.github.com/mysociety/fixmytransport/fa9b014eb2628c300693e055f129cb8959772082/config/initializers/strip_nil_parameters_patch.rb

# Monkey patch for CVE-2012-2660 on Rails 2.3.14

# Strip [nil] from parameters hash
# based on a pull request from @sebbacon
# https://github.com/rails/rails/pull/6580

module ActionController
  class Request < Rack::Request
    protected
      def deep_munge(hash)
        hash.each_value do |v|
          case v
          when Array
            v.grep(Hash) { |x| deep_munge(x) }
          when Hash
            deep_munge(v)
          end
        end

        keys = hash.keys.find_all { |k| hash[k] == [nil] }
        keys.each { |k| hash[k] = nil }
        hash
      end

    private

      def normalize_parameters(value)
        case value
        when Hash
          if value.has_key?(:tempfile)
            upload = value[:tempfile]
            upload.extend(UploadedFile)
            upload.original_path = value[:filename]
            upload.content_type = value[:type]
            upload
          else
            h = {}
            value.each { |k, v| h[k] = normalize_parameters(v) }
            deep_munge(h.with_indifferent_access)
          end
        when Array
          value.map { |e| normalize_parameters(e) }
        else
          value
        end
      end

  end
end
