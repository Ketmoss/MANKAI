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

ActiveRecord::Schema[7.1].define(version: 2025_06_12_091109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chats", force: :cascade do |t|
    t.string "title"
    t.string "model_id"
    t.bigint "exchange_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_id"], name: "index_chats_on_exchange_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "db_mangas", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.integer "volume"
    t.integer "chapter"
    t.string "synopsis"
    t.string "image_url"
    t.string "genre"
    t.string "status"
    t.integer "jikan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exchanges", force: :cascade do |t|
    t.string "status"
    t.bigint "user_id", null: false
    t.bigint "owned_manga_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owned_manga_id"], name: "index_exchanges_on_owned_manga_id"
    t.index ["user_id"], name: "index_exchanges_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "role"
    t.text "content"
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "owned_mangas", force: :cascade do |t|
    t.boolean "available", default: true
    t.string "state"
    t.bigint "user_collection_id", null: false
    t.bigint "db_manga_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["db_manga_id"], name: "index_owned_mangas_on_db_manga_id"
    t.index ["user_collection_id"], name: "index_owned_mangas_on_user_collection_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "content"
    t.float "score"
    t.bigint "db_manga_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["db_manga_id"], name: "index_reviews_on_db_manga_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "user_collections", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_collections_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
    t.string "zip_code"
    t.string "username"
    t.float "rating"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chats", "exchanges"
  add_foreign_key "chats", "users"
  add_foreign_key "exchanges", "owned_mangas"
  add_foreign_key "exchanges", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "owned_mangas", "db_mangas"
  add_foreign_key "owned_mangas", "user_collections"
  add_foreign_key "reviews", "db_mangas"
  add_foreign_key "reviews", "users"
  add_foreign_key "user_collections", "users"
end
