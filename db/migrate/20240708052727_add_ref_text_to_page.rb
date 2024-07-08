class AddRefTextToPage < ActiveRecord::Migration[7.1]
  def change
    add_column :pages, :ref_text, :text
  end
end
