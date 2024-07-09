class CreateReferences < ActiveRecord::Migration[7.1]
  def change
    create_table :references do |t|
      t.string :title
      t.string :link
      t.string :baseurl
      t.references :page, null: false, foreign_key: true
      t.string :imageurl

      t.timestamps
    end
  end
end
