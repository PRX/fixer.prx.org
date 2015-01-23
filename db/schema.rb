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

ActiveRecord::Schema.define(version: 20150114201902) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "jobs", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.string   "job_type"
    t.text     "original"
    t.integer  "status"
    t.integer  "client_application_id"
    t.text     "call_back"
    t.string   "priority"
    t.integer  "retry_max",             default: 0
    t.integer  "retry_count",           default: 0
    t.integer  "retry_delay",           default: 0
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "task_logs", force: :cascade do |t|
    t.uuid     "task_id"
    t.string   "status"
    t.string   "message"
    t.text     "info"
    t.datetime "logged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "task_logs", ["task_id"], name: "index_task_logs_on_task_id", using: :btree

  create_table "tasks", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.uuid     "job_id"
    t.uuid     "sequence_id"
    t.integer  "status"
    t.integer  "position"
    t.string   "type"
    t.string   "task_type"
    t.string   "label"
    t.text     "options"
    t.text     "call_back"
    t.text     "result"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "tasks", ["job_id"], name: "index_tasks_on_job_id", using: :btree
  add_index "tasks", ["position", "sequence_id"], name: "index_tasks_on_position_and_sequence_id", using: :btree
  add_index "tasks", ["sequence_id"], name: "index_tasks_on_sequence_id", using: :btree

  create_table "web_hooks", force: :cascade do |t|
    t.uuid     "informer_id"
    t.string   "informer_type"
    t.string   "url"
    t.text     "message"
    t.datetime "completed_at"
    t.integer  "retry_max",     default: 0
    t.integer  "retry_count",   default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "web_hooks", ["informer_id", "informer_type"], name: "index_web_hooks_on_informer_id_and_informer_type", using: :btree

end
