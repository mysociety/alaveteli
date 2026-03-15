class AddTsvectorColumnToPublicBody < ActiveRecord::Migration[8.0]
  def up
    add_column(:public_bodies, :name_tsv, :tsvector)
    # this index is used by search_with_pg, but not pg_search_with_scope
    add_index(:public_bodies, :name_tsv, using: :gin)

    execute <<-SQL
-- function to calculate the name_tsv column from translations
CREATE OR REPLACE FUNCTION update_public_body_name_tsv()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public_bodies
  SET name_tsv = (
    SELECT to_tsvector('french', coalesce(unaccent(string_agg(name, short_name)), ''))
    FROM public_body_translations
    WHERE public_body_id = NEW.id
  )
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- use the above as a trigger then public_bodies is modified
CREATE TRIGGER public_body_name_tsv_trigger
AFTER INSERT OR UPDATE ON public_body_translations
FOR EACH ROW
EXECUTE FUNCTION update_public_body_name_tsv();
SQL
  end

  def down
    # skip for now
  end
end

# run the below update once to backfill the entire column (~2s)
# UPDATE public_bodies pb
# SET name_tsv = (
#   SELECT to_tsvector('french', coalesce(unaccent(string_agg(name, short_name)), ''))
#   FROM public_body_translations
#   WHERE public_body_id = pb.id
# );
