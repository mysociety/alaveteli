class AddCountryToUserSignIns < ActiveRecord::Migration[6.1]
  def change
    add_column :user_sign_ins, :country, :string
  end
end
