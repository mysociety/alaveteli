class EnableVectorExtension < ActiveRecord::Migration[7.0]
  def change
    enable_extension "vector"
  end
end
