class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.references :source, null: false, foreign_key: { to_table: :pages }
      t.references :destination, null: false, foreign_key: { to_table: :pages }

      t.timestamps
    end

    add_index :links, [:source_id, :destination_id], unique: true
  end
end
