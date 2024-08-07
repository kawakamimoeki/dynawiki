# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_07_09_003450) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "links", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "destination_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_links_on_destination_id"
    t.index ["source_id", "destination_id"], name: "index_links_on_source_id_and_destination_id", unique: true
    t.index ["source_id"], name: "index_links_on_source_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "lang"
    t.bigint "language_id"
    t.string "ref_link"
    t.boolean "rebuild"
    t.text "ref_text"
    t.index ["language_id"], name: "index_pages_on_language_id"
  end

  create_table "references", force: :cascade do |t|
    t.string "title"
    t.string "link"
    t.string "baseurl"
    t.bigint "page_id", null: false
    t.string "imageurl"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_references_on_page_id"
  end

  add_foreign_key "links", "pages", column: "destination_id"
  add_foreign_key "links", "pages", column: "source_id"
  add_foreign_key "pages", "languages"
  add_foreign_key "references", "pages"
end
