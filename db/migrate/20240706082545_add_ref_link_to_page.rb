class AddRefLinkToPage < ActiveRecord::Migration[7.1]
  def change
    add_column :pages, :ref_link, :string
  end
end
