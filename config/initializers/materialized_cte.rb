# Taken from https://github.com/rails/rails/pull/54322
# to allow ActiveRecord::QueryMethods.with to accept a CTE as well
# as a Hash. This allows creating materialized CTEs, which makes
# search a lot faster by putting an "optimisation fence" up, so
# postgres does not try to inline the search query.
ActiveRecord::QueryMethods.module_eval do

    private
      def build_with(arel)
        return if with_values.empty?

        with_statements = with_values.map do |with_value|
          case with_value
          when Arel::Nodes::Cte then with_value
          when Hash then build_with_value_from_hash(with_value)
          else
            raise ArgumentError, "Unsupported argument type: #{with_value} #{with_value.class}"
          end
        end

        @with_is_recursive ? arel.with(:recursive, with_statements) : arel.with(with_statements)
      end

      def build_with_value_from_hash(hash)
        hash.map do |name, value|
          Arel::Nodes::TableAlias.new(build_with_expression_from_value(value), name)
          Arel::Nodes::Cte.new(name, build_with_expression_from_value(value))
        end
      end

      def process_with_args(args)
        args.flat_map do |arg|
          case arg
          when Hash then arg.map { |k, v| { k => v } }
          when Arel::Nodes::Cte then arg
          else raise ArgumentError, "Unsupported argument type: #{arg} #{arg.class}"
          end
        end
      end
end
