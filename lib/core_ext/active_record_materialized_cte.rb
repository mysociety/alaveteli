##
# Rails builds every CTE as an Arel::Nodes::TableAlias, which has no way
# to say MATERIALIZED. Let the value passed to `with` be an
# Arel::Nodes::Cte instead, which does.
#
# Based on https://github.com/rails/rails/pull/54322. Drop this once the
# Rails PR lands.
#
module ActiveRecord::MaterializedCte
  private

  def build_with_value_from_hash(hash)
    hash.flat_map do |name, value|
      next super({ name => value }) unless value.is_a?(Arel::Nodes::Cte)

      Arel::Nodes::Cte.new(name, value.relation,
                           materialized: value.materialized)
    end
  end
end

ActiveRecord::Relation.prepend(ActiveRecord::MaterializedCte)
