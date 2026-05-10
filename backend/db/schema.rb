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

ActiveRecord::Schema[8.1].define(version: 2026_05_10_210338) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "matchups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "played_at", null: false
    t.bigint "ranking_id", null: false
    t.bigint "song_a_id", null: false
    t.bigint "song_b_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "winner_id", null: false
    t.index ["ranking_id", "played_at"], name: "index_matchups_on_ranking_id_and_played_at"
    t.index ["ranking_id"], name: "index_matchups_on_ranking_id"
    t.index ["song_a_id"], name: "index_matchups_on_song_a_id"
    t.index ["song_b_id"], name: "index_matchups_on_song_b_id"
    t.index ["winner_id"], name: "index_matchups_on_winner_id"
  end

  create_table "ranking_songs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "elo_score", default: 1000.0, null: false
    t.integer "matchup_count", default: 0, null: false
    t.bigint "ranking_id", null: false
    t.bigint "song_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ranking_id", "song_id"], name: "index_ranking_songs_on_ranking_id_and_song_id", unique: true
    t.index ["ranking_id"], name: "index_ranking_songs_on_ranking_id"
    t.index ["song_id"], name: "index_ranking_songs_on_song_id"
  end

  create_table "rankings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_rankings_on_user_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "album_art_url"
    t.string "album_name"
    t.string "artist_name", null: false
    t.datetime "created_at", null: false
    t.string "release_date"
    t.string "spotify_track_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_track_id"], name: "index_songs_on_spotify_track_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "refresh_token"
    t.string "spotify_id", null: false
    t.string "spotify_market"
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.index ["spotify_id"], name: "index_users_on_spotify_id", unique: true
  end

  add_foreign_key "matchups", "rankings", on_delete: :cascade
  add_foreign_key "matchups", "songs", column: "song_a_id"
  add_foreign_key "matchups", "songs", column: "song_b_id"
  add_foreign_key "matchups", "songs", column: "winner_id"
  add_foreign_key "ranking_songs", "rankings", on_delete: :cascade
  add_foreign_key "ranking_songs", "songs", on_delete: :cascade
  add_foreign_key "rankings", "users", on_delete: :cascade
end
