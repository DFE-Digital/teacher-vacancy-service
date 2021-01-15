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

ActiveRecord::Schema.define(version: 2021_01_15_164522) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "account_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rating"
    t.text "suggestions"
    t.uuid "jobseeker_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["jobseeker_id"], name: "index_account_feedbacks_on_jobseeker_id"
  end

  create_table "activities", force: :cascade do |t|
    t.uuid "trackable_id"
    t.string "trackable_type"
    t.string "session_id"
    t.string "key"
    t.text "parameters"
    t.uuid "owner_id"
    t.string "owner_type"
    t.uuid "recipient_id"
    t.string "recipient_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
  end

  create_table "alert_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id"
    t.date "run_on"
    t.string "job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.index ["subscription_id"], name: "index_alert_runs_on_subscription_id"
  end

  create_table "audit_data", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.integer "size", null: false
    t.string "content_type", null: false
    t.string "download_url", null: false
    t.string "google_drive_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "vacancy_id"
    t.index ["vacancy_id"], name: "index_documents_on_vacancy_id"
  end

  create_table "dsi_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id", null: false
    t.uuid "publisher_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organisation_id"], name: "index_dsi_memberships_on_organisation_id"
    t.index ["publisher_id"], name: "index_dsi_memberships_on_publisher_id"
  end

  create_table "emergency_login_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "not_valid_after", null: false
    t.uuid "publisher_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publisher_id"], name: "index_emergency_login_keys_on_publisher_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.uuid "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "general_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rating"
    t.text "comment"
    t.integer "visit_purpose"
    t.text "visit_purpose_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.integer "user_participation_response"
    t.float "recaptcha_score"
  end

  create_table "job_alert_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "relevant_to_user"
    t.text "comment"
    t.jsonb "search_criteria"
    t.uuid "vacancy_ids", array: true
    t.uuid "subscription_id", null: false
    t.float "recaptcha_score"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["subscription_id"], name: "index_job_alert_feedbacks_on_subscription_id"
  end

  create_table "job_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "jobseekers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_jobseekers_on_confirmation_token", unique: true
    t.index ["email"], name: "index_jobseekers_on_email", unique: true
    t.index ["reset_password_token"], name: "index_jobseekers_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_jobseekers_on_unlock_token", unique: true
  end

  create_table "location_polygons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "location_type"
    t.float "boundary", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "buffers"
  end

  create_table "organisation_vacancies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id"
    t.uuid "vacancy_id"
  end

  create_table "organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.string "urn"
    t.string "uid"
    t.integer "phase"
    t.string "url"
    t.integer "minimum_age"
    t.integer "maximum_age"
    t.string "address"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.text "locality"
    t.text "address3"
    t.text "easting"
    t.text "northing"
    t.point "geolocation"
    t.json "gias_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "readable_phases", array: true
    t.string "website"
    t.string "region"
    t.string "detailed_school_type"
    t.string "school_type"
    t.string "local_authority_code"
    t.string "group_type"
    t.string "local_authority_within"
    t.string "establishment_status"
    t.index ["local_authority_code"], name: "index_organisations_on_local_authority_code"
    t.index ["uid"], name: "index_organisations_on_uid"
    t.index ["urn"], name: "index_organisations_on_urn"
  end

  create_table "publisher_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "managed_organisations"
    t.uuid "publisher_id"
    t.uuid "school_group_id"
    t.string "managed_school_ids", array: true
    t.index ["publisher_id"], name: "index_publisher_preferences_on_publisher_id"
    t.index ["school_group_id"], name: "index_publisher_preferences_on_school_group_id"
  end

  create_table "publishers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "oid"
    t.datetime "accepted_terms_at"
    t.string "email"
    t.jsonb "dsi_data"
    t.datetime "last_activity_at"
    t.string "family_name"
    t.string "given_name"
    t.index ["oid"], name: "index_publishers_on_oid", unique: true
  end

  create_table "saved_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "jobseeker_id"
    t.uuid "vacancy_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "school_group_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id"
    t.uuid "school_group_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.integer "frequency"
    t.jsonb "search_criteria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "recaptcha_score"
    t.boolean "active", default: true
    t.datetime "unsubscribed_at"
  end

  create_table "transaction_auditors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "task"
    t.boolean "success"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task", "date"], name: "index_transaction_auditors_on_task_and_date", unique: true
  end

  create_table "unsubscribe_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "reason"
    t.string "other_reason"
    t.text "additional_info"
    t.uuid "subscription_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["subscription_id"], name: "index_unsubscribe_feedbacks_on_subscription_id"
  end

  create_table "vacancies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "job_title"
    t.string "slug", null: false
    t.text "job_summary"
    t.text "benefits"
    t.date "starts_on"
    t.date "ends_on"
    t.text "education"
    t.text "qualifications"
    t.text "experience"
    t.string "contact_email"
    t.integer "status"
    t.date "expires_on"
    t.date "publish_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "reference", default: -> { "gen_random_uuid()" }, null: false
    t.string "application_link"
    t.integer "weekly_pageviews"
    t.integer "total_pageviews"
    t.datetime "weekly_pageviews_updated_at"
    t.datetime "total_pageviews_updated_at"
    t.integer "total_get_more_info_clicks"
    t.datetime "total_get_more_info_clicks_updated_at"
    t.integer "working_patterns", array: true
    t.integer "listed_elsewhere"
    t.integer "hired_status"
    t.datetime "stats_updated_at"
    t.uuid "publisher_id"
    t.datetime "expires_at"
    t.string "salary"
    t.integer "completed_step"
    t.string "legacy_job_roles", array: true
    t.text "about_school"
    t.string "state", default: "create"
    t.string "subjects", array: true
    t.text "school_visits"
    t.text "how_to_apply"
    t.boolean "initially_indexed", default: false
    t.integer "job_location"
    t.string "readable_job_location"
    t.string "suitable_for_nqt"
    t.integer "job_roles", array: true
    t.string "contact_number"
    t.uuid "publisher_organisation_id"
    t.boolean "starts_asap", default: false
    t.integer "contract_type"
    t.string "contract_type_duration"
    t.index ["expires_at"], name: "index_vacancies_on_expires_at"
    t.index ["expires_on"], name: "index_vacancies_on_expires_on"
    t.index ["initially_indexed"], name: "index_vacancies_on_initially_indexed"
    t.index ["publisher_id"], name: "index_vacancies_on_publisher_id"
    t.index ["publisher_organisation_id"], name: "index_vacancies_on_publisher_organisation_id"
  end

  create_table "vacancy_publish_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "vacancy_id"
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "publisher_id"
    t.string "email"
    t.integer "user_participation_response"
    t.index ["publisher_id"], name: "index_vacancy_publish_feedbacks_on_publisher_id"
    t.index ["vacancy_id"], name: "index_vacancy_publish_feedbacks_on_vacancy_id", unique: true
  end

  add_foreign_key "account_feedbacks", "jobseekers"
  add_foreign_key "documents", "vacancies"
  add_foreign_key "dsi_memberships", "organisations"
  add_foreign_key "dsi_memberships", "publishers"
  add_foreign_key "emergency_login_keys", "publishers"
  add_foreign_key "job_alert_feedbacks", "subscriptions"
  add_foreign_key "publisher_preferences", "publishers"
  add_foreign_key "unsubscribe_feedbacks", "subscriptions"
  add_foreign_key "vacancies", "organisations", column: "publisher_organisation_id"
  add_foreign_key "vacancies", "publishers"
end
