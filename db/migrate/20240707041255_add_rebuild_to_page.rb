class AddRebuildToPage < ActiveRecord::Migration[7.1]
  def change
    add_column :pages, :rebuild, :boolean
  end
end
