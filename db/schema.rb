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

ActiveRecord::Schema.define(version: 20160405143148) do

  create_table "answers", force: :cascade do |t|
    t.string   "text",       null: false
    t.integer  "problem_id", null: false
    t.integer  "score_id"
    t.integer  "team_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.string   "text",                             null: false
    t.boolean  "required_reply",   default: false, null: false
    t.integer  "member_id",                        null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "commentable_id",                   null: false
    t.string   "commentable_type",                 null: false
  end

  add_index "comments", ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"

  create_table "issues", force: :cascade do |t|
    t.string   "title",                      null: false
    t.boolean  "closed",     default: false, null: false
    t.integer  "problem_id",                 null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "team_id",                    null: false
  end

  create_table "members", force: :cascade do |t|
    t.boolean  "admin",           default: false, null: false
    t.string   "name",                            null: false
    t.string   "login",                           null: false
    t.string   "hashed_password",                 null: false
    t.integer  "team_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "problems", force: :cascade do |t|
    t.string   "title",      null: false
    t.string   "text",       null: false
    t.datetime "opened_at",  null: false
    t.datetime "closed_at",  null: false
    t.integer  "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scores", force: :cascade do |t|
    t.integer  "point",      null: false
    t.integer  "answer_id",  null: false
    t.integer  "marker_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",         null: false
    t.string   "organization"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

end
