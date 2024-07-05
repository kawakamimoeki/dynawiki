class AddLanguageToPage < ActiveRecord::Migration[7.1]
  def change
    add_reference :pages, :language, null: true, foreign_key: true
  end
end
