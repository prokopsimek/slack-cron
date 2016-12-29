# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161229200727) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "standups", force: :cascade do |t|
    t.string   "name"
    t.string   "slack_api_token"
    t.string   "channel_read_from"
    t.string   "cron"
    t.boolean  "is_active"
    t.string   "bot_icon_url"
    t.string   "bot_icon_happy_url"
    t.string   "message_all_wrote"
    t.string   "message_to_notified"
    t.string   "message_to_user"
    t.string   "message_to_user_count_not_written"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "slack_id",                              null: false
    t.integer  "standup_counter",       default: 0
    t.integer  "standup_id"
    t.boolean  "standup_notifications", default: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "name"
  end

  add_index "users", ["slack_id"], name: "index_users_on_slack_id", unique: true, using: :btree
  add_index "users", ["standup_id"], name: "index_users_on_standup_id", using: :btree

  add_foreign_key "users", "standups"
end
