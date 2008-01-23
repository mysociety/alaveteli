# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 26) do

  create_table "incoming_messages", :force => true do |t|
    t.integer  "info_request_id"
    t.text     "raw_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "user_classified",      :default => false
    t.boolean  "contains_information"
    t.boolean  "is_bounce",            :default => false
  end

  create_table "info_request_events", :force => true do |t|
    t.integer  "info_request_id"
    t.text     "event_type"
    t.text     "params_yaml"
    t.datetime "created_at"
  end

  create_table "info_requests", :force => true do |t|
    t.text     "title"
    t.integer  "user_id"
    t.integer  "public_body_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "outgoing_messages", :force => true do |t|
    t.integer  "info_request_id"
    t.text     "body"
    t.string   "status"
    t.string   "message_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_sent_at"
    t.integer  "incoming_message_followup_id"
  end

  create_table "post_redirects", :force => true do |t|
    t.text     "token"
    t.text     "uri"
    t.text     "post_params_yaml"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "email_token"
    t.text     "reason_params_yaml"
    t.integer  "user_id"
  end

  create_table "public_bodies", :force => true do |t|
    t.text     "name"
    t.text     "short_name"
    t.text     "request_email"
    t.text     "complaint_email"
    t.integer  "version"
    t.string   "last_edit_editor"
    t.string   "last_edit_comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "public_body_versions", :force => true do |t|
    t.integer  "public_body_id"
    t.integer  "version"
    t.text     "name"
    t.text     "short_name"
    t.text     "request_email"
    t.text     "complaint_email"
    t.datetime "updated_at"
    t.string   "last_edit_editor"
    t.string   "last_edit_comment"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "email",                              :null => false
    t.string   "name",                               :null => false
    t.string   "hashed_password",                    :null => false
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "email_confirmed", :default => false
  end

end
