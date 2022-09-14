BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "schema_version" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"version"	INTEGER NOT NULL,
	"upgraded"	BOOL NOT NULL,
	CHECK("Lock" = 'X')
);
CREATE TABLE IF NOT EXISTS "schema_compat_version" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"compat_version"	INTEGER NOT NULL,
	CHECK("Lock" = 'X')
);
CREATE TABLE IF NOT EXISTS "applied_schema_deltas" (
	"version"	INTEGER NOT NULL,
	"file"	TEXT NOT NULL,
	UNIQUE("version","file")
);
CREATE TABLE IF NOT EXISTS "applied_module_schemas" (
	"module_name"	TEXT NOT NULL,
	"file"	TEXT NOT NULL,
	UNIQUE("module_name","file")
);
CREATE TABLE IF NOT EXISTS "background_updates" (
	"update_name"	text NOT NULL,
	"progress_json"	text NOT NULL,
	"depends_on"	text,
	"ordering"	INT NOT NULL DEFAULT 0,
	CONSTRAINT "background_updates_uniqueness" UNIQUE("update_name")
);
CREATE TABLE IF NOT EXISTS "state_groups" (
	"id"	BIGINT,
	"room_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "state_groups_state" (
	"state_group"	BIGINT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"type"	TEXT NOT NULL,
	"state_key"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "state_group_edges" (
	"state_group"	BIGINT NOT NULL,
	"prev_state_group"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "application_services_txns" (
	"as_id"	TEXT NOT NULL,
	"txn_id"	INTEGER NOT NULL,
	"event_ids"	TEXT NOT NULL,
	UNIQUE("as_id","txn_id")
);
CREATE TABLE IF NOT EXISTS "presence" (
	"user_id"	TEXT NOT NULL,
	"state"	VARCHAR(20),
	"status_msg"	TEXT,
	"mtime"	BIGINT,
	UNIQUE("user_id")
);
CREATE TABLE IF NOT EXISTS "users" (
	"name"	TEXT,
	"password_hash"	TEXT,
	"creation_ts"	BIGINT,
	"admin"	SMALLINT NOT NULL DEFAULT 0,
	"upgrade_ts"	BIGINT,
	"is_guest"	SMALLINT NOT NULL DEFAULT 0,
	"appservice_id"	TEXT,
	"consent_version"	TEXT,
	"consent_server_notice_sent"	TEXT,
	"user_type"	TEXT DEFAULT NULL,
	"deactivated"	SMALLINT NOT NULL DEFAULT 0,
	"shadow_banned"	BOOLEAN,
	UNIQUE("name")
);
CREATE TABLE IF NOT EXISTS "user_ips" (
	"user_id"	TEXT NOT NULL,
	"access_token"	TEXT NOT NULL,
	"device_id"	TEXT,
	"ip"	TEXT NOT NULL,
	"user_agent"	TEXT NOT NULL,
	"last_seen"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "profiles" (
	"user_id"	TEXT NOT NULL,
	"displayname"	TEXT,
	"avatar_url"	TEXT,
	UNIQUE("user_id")
);
CREATE TABLE IF NOT EXISTS "received_transactions" (
	"transaction_id"	TEXT,
	"origin"	TEXT,
	"ts"	BIGINT,
	"response_code"	INTEGER,
	"response_json"	bytea,
	"has_been_referenced"	smallint DEFAULT 0,
	UNIQUE("transaction_id","origin")
);
CREATE TABLE IF NOT EXISTS "destinations" (
	"destination"	TEXT,
	"retry_last_ts"	BIGINT,
	"retry_interval"	INTEGER,
	"failure_ts"	BIGINT,
	"last_successful_stream_ordering"	BIGINT,
	PRIMARY KEY("destination")
);
CREATE TABLE IF NOT EXISTS "events" (
	"stream_ordering"	INTEGER,
	"topological_ordering"	BIGINT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"type"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"content"	TEXT,
	"unrecognized_keys"	TEXT,
	"processed"	BOOL NOT NULL,
	"outlier"	BOOL NOT NULL,
	"depth"	BIGINT NOT NULL DEFAULT 0,
	"origin_server_ts"	BIGINT,
	"received_ts"	BIGINT,
	"sender"	TEXT,
	"contains_url"	BOOLEAN,
	"instance_name"	TEXT,
	"state_key"	TEXT DEFAULT NULL,
	"rejection_reason"	TEXT DEFAULT NULL,
	PRIMARY KEY("stream_ordering"),
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "event_json" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"internal_metadata"	TEXT NOT NULL,
	"json"	TEXT NOT NULL,
	"format_version"	INTEGER,
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "state_events" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"type"	TEXT NOT NULL,
	"state_key"	TEXT NOT NULL,
	"prev_state"	TEXT,
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "current_state_events" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"type"	TEXT NOT NULL,
	"state_key"	TEXT NOT NULL,
	"membership"	TEXT,
	UNIQUE("event_id"),
	UNIQUE("room_id","type","state_key")
);
CREATE TABLE IF NOT EXISTS "room_memberships" (
	"event_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"sender"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"membership"	TEXT NOT NULL,
	"forgotten"	INTEGER DEFAULT 0,
	"display_name"	TEXT,
	"avatar_url"	TEXT,
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "rooms" (
	"room_id"	TEXT NOT NULL,
	"is_public"	BOOL,
	"creator"	TEXT,
	"room_version"	TEXT,
	"has_auth_chain_index"	BOOLEAN,
	PRIMARY KEY("room_id")
);
CREATE TABLE IF NOT EXISTS "server_signature_keys" (
	"server_name"	TEXT,
	"key_id"	TEXT,
	"from_server"	TEXT,
	"ts_added_ms"	BIGINT,
	"verify_key"	bytea,
	"ts_valid_until_ms"	BIGINT,
	UNIQUE("server_name","key_id")
);
CREATE TABLE IF NOT EXISTS "rejections" (
	"event_id"	TEXT NOT NULL,
	"reason"	TEXT NOT NULL,
	"last_check"	TEXT NOT NULL,
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "push_rules" (
	"id"	BIGINT,
	"user_name"	TEXT NOT NULL,
	"rule_id"	TEXT NOT NULL,
	"priority_class"	SMALLINT NOT NULL,
	"priority"	INTEGER NOT NULL DEFAULT 0,
	"conditions"	TEXT NOT NULL,
	"actions"	TEXT NOT NULL,
	PRIMARY KEY("id"),
	UNIQUE("user_name","rule_id")
);
CREATE TABLE IF NOT EXISTS "push_rules_enable" (
	"id"	BIGINT,
	"user_name"	TEXT NOT NULL,
	"rule_id"	TEXT NOT NULL,
	"enabled"	SMALLINT,
	PRIMARY KEY("id"),
	UNIQUE("user_name","rule_id")
);
CREATE TABLE IF NOT EXISTS "event_forward_extremities" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	UNIQUE("event_id","room_id")
);
CREATE TABLE IF NOT EXISTS "event_backward_extremities" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	UNIQUE("event_id","room_id")
);
CREATE TABLE IF NOT EXISTS "room_depth" (
	"room_id"	TEXT NOT NULL,
	"min_depth"	INTEGER NOT NULL,
	UNIQUE("room_id")
);
CREATE TABLE IF NOT EXISTS "event_to_state_groups" (
	"event_id"	TEXT NOT NULL,
	"state_group"	BIGINT NOT NULL,
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "local_media_repository" (
	"media_id"	TEXT,
	"media_type"	TEXT,
	"media_length"	INTEGER,
	"created_ts"	BIGINT,
	"upload_name"	TEXT,
	"user_id"	TEXT,
	"quarantined_by"	TEXT,
	"url_cache"	TEXT,
	"last_access_ts"	BIGINT,
	"safe_from_quarantine"	BOOLEAN NOT NULL DEFAULT 0,
	UNIQUE("media_id")
);
CREATE TABLE IF NOT EXISTS "remote_media_cache" (
	"media_origin"	TEXT,
	"media_id"	TEXT,
	"media_type"	TEXT,
	"created_ts"	BIGINT,
	"upload_name"	TEXT,
	"media_length"	INTEGER,
	"filesystem_id"	TEXT,
	"last_access_ts"	BIGINT,
	"quarantined_by"	TEXT,
	UNIQUE("media_origin","media_id")
);
CREATE TABLE IF NOT EXISTS "redactions" (
	"event_id"	TEXT NOT NULL,
	"redacts"	TEXT NOT NULL,
	"have_censored"	BOOL NOT NULL DEFAULT false,
	"received_ts"	BIGINT,
	UNIQUE("event_id")
);
CREATE TABLE IF NOT EXISTS "room_aliases" (
	"room_alias"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"creator"	TEXT,
	UNIQUE("room_alias")
);
CREATE TABLE IF NOT EXISTS "room_alias_servers" (
	"room_alias"	TEXT NOT NULL,
	"server"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "server_keys_json" (
	"server_name"	TEXT NOT NULL,
	"key_id"	TEXT NOT NULL,
	"from_server"	TEXT NOT NULL,
	"ts_added_ms"	BIGINT NOT NULL,
	"ts_valid_until_ms"	BIGINT NOT NULL,
	"key_json"	bytea NOT NULL,
	CONSTRAINT "server_keys_json_uniqueness" UNIQUE("server_name","key_id","from_server")
);
CREATE TABLE IF NOT EXISTS "e2e_device_keys_json" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"ts_added_ms"	BIGINT NOT NULL,
	"key_json"	TEXT NOT NULL,
	CONSTRAINT "e2e_device_keys_json_uniqueness" UNIQUE("user_id","device_id")
);
CREATE TABLE IF NOT EXISTS "e2e_one_time_keys_json" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"algorithm"	TEXT NOT NULL,
	"key_id"	TEXT NOT NULL,
	"ts_added_ms"	BIGINT NOT NULL,
	"key_json"	TEXT NOT NULL,
	CONSTRAINT "e2e_one_time_keys_json_uniqueness" UNIQUE("user_id","device_id","algorithm","key_id")
);
CREATE TABLE IF NOT EXISTS "receipts_graph" (
	"room_id"	TEXT NOT NULL,
	"receipt_type"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"event_ids"	TEXT NOT NULL,
	"data"	TEXT NOT NULL,
	CONSTRAINT "receipts_graph_uniqueness" UNIQUE("room_id","receipt_type","user_id")
);
CREATE TABLE IF NOT EXISTS "receipts_linearized" (
	"stream_id"	BIGINT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"receipt_type"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"data"	TEXT NOT NULL,
	"instance_name"	TEXT,
	CONSTRAINT "receipts_linearized_uniqueness" UNIQUE("room_id","receipt_type","user_id")
);
CREATE TABLE IF NOT EXISTS "user_threepids" (
	"user_id"	TEXT NOT NULL,
	"medium"	TEXT NOT NULL,
	"address"	TEXT NOT NULL,
	"validated_at"	BIGINT NOT NULL,
	"added_at"	BIGINT NOT NULL,
	CONSTRAINT "medium_address" UNIQUE("medium","address")
);
CREATE VIRTUAL TABLE event_search USING fts4 ( event_id, room_id, sender, key, value );
CREATE TABLE IF NOT EXISTS "event_search_content" (
	"docid"	INTEGER,
	"c0event_id"	,
	"c1room_id"	,
	"c2sender"	,
	"c3key"	,
	"c4value"	,
	PRIMARY KEY("docid")
);
CREATE TABLE IF NOT EXISTS "event_search_segments" (
	"blockid"	INTEGER,
	"block"	BLOB,
	PRIMARY KEY("blockid")
);
CREATE TABLE IF NOT EXISTS "event_search_segdir" (
	"level"	INTEGER,
	"idx"	INTEGER,
	"start_block"	INTEGER,
	"leaves_end_block"	INTEGER,
	"end_block"	INTEGER,
	"root"	BLOB,
	PRIMARY KEY("level","idx")
);
CREATE TABLE IF NOT EXISTS "event_search_docsize" (
	"docid"	INTEGER,
	"size"	BLOB,
	PRIMARY KEY("docid")
);
CREATE TABLE IF NOT EXISTS "event_search_stat" (
	"id"	INTEGER,
	"value"	BLOB,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "room_tags" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"tag"	TEXT NOT NULL,
	"content"	TEXT NOT NULL,
	CONSTRAINT "room_tag_uniqueness" UNIQUE("user_id","room_id","tag")
);
CREATE TABLE IF NOT EXISTS "room_tags_revisions" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"instance_name"	TEXT,
	CONSTRAINT "room_tag_revisions_uniqueness" UNIQUE("user_id","room_id")
);
CREATE TABLE IF NOT EXISTS "account_data" (
	"user_id"	TEXT NOT NULL,
	"account_data_type"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"content"	TEXT NOT NULL,
	"instance_name"	TEXT,
	CONSTRAINT "account_data_uniqueness" UNIQUE("user_id","account_data_type")
);
CREATE TABLE IF NOT EXISTS "room_account_data" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"account_data_type"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"content"	TEXT NOT NULL,
	"instance_name"	TEXT,
	CONSTRAINT "room_account_data_uniqueness" UNIQUE("user_id","room_id","account_data_type")
);
CREATE TABLE IF NOT EXISTS "event_push_actions" (
	"room_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"profile_tag"	VARCHAR(32),
	"actions"	TEXT NOT NULL,
	"topological_ordering"	BIGINT,
	"stream_ordering"	BIGINT,
	"notif"	SMALLINT,
	"highlight"	SMALLINT,
	"unread"	SMALLINT,
	CONSTRAINT "event_id_user_id_profile_tag_uniqueness" UNIQUE("room_id","event_id","user_id","profile_tag")
);
CREATE TABLE IF NOT EXISTS "presence_stream" (
	"stream_id"	BIGINT,
	"user_id"	TEXT,
	"state"	TEXT,
	"last_active_ts"	BIGINT,
	"last_federation_update_ts"	BIGINT,
	"last_user_sync_ts"	BIGINT,
	"status_msg"	TEXT,
	"currently_active"	BOOLEAN,
	"instance_name"	TEXT
);
CREATE TABLE IF NOT EXISTS "push_rules_stream" (
	"stream_id"	BIGINT NOT NULL,
	"event_stream_ordering"	BIGINT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"rule_id"	TEXT NOT NULL,
	"op"	TEXT NOT NULL,
	"priority_class"	SMALLINT,
	"priority"	INTEGER,
	"conditions"	TEXT,
	"actions"	TEXT
);
CREATE TABLE IF NOT EXISTS "ex_outlier_stream" (
	"event_stream_ordering"	BIGINT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"state_group"	BIGINT NOT NULL,
	"instance_name"	TEXT,
	PRIMARY KEY("event_stream_ordering")
);
CREATE TABLE IF NOT EXISTS "threepid_guest_access_tokens" (
	"medium"	TEXT,
	"address"	TEXT,
	"guest_access_token"	TEXT,
	"first_inviter"	TEXT
);
CREATE TABLE IF NOT EXISTS "open_id_tokens" (
	"token"	TEXT NOT NULL,
	"ts_valid_until_ms"	bigint NOT NULL,
	"user_id"	TEXT NOT NULL,
	PRIMARY KEY("token"),
	UNIQUE("token")
);
CREATE TABLE IF NOT EXISTS "pusher_throttle" (
	"pusher"	BIGINT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"last_sent_ts"	BIGINT,
	"throttle_ms"	BIGINT,
	PRIMARY KEY("pusher","room_id")
);
CREATE TABLE IF NOT EXISTS "event_reports" (
	"id"	BIGINT NOT NULL,
	"received_ts"	BIGINT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"reason"	TEXT,
	"content"	TEXT,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "appservice_stream_position" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"stream_ordering"	BIGINT,
	CHECK("Lock" = 'X')
);
CREATE TABLE IF NOT EXISTS "device_inbox" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"message_json"	TEXT NOT NULL,
	"instance_name"	TEXT
);
CREATE TABLE IF NOT EXISTS "device_federation_outbox" (
	"destination"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"queued_ts"	BIGINT NOT NULL,
	"messages_json"	TEXT NOT NULL,
	"instance_name"	TEXT
);
CREATE TABLE IF NOT EXISTS "device_federation_inbox" (
	"origin"	TEXT NOT NULL,
	"message_id"	TEXT NOT NULL,
	"received_ts"	BIGINT NOT NULL,
	"instance_name"	TEXT
);
CREATE TABLE IF NOT EXISTS "stream_ordering_to_exterm" (
	"stream_ordering"	BIGINT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "event_auth" (
	"event_id"	TEXT NOT NULL,
	"auth_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "appservice_room_list" (
	"appservice_id"	TEXT NOT NULL,
	"network_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "federation_stream_position" (
	"type"	TEXT NOT NULL,
	"stream_id"	INTEGER NOT NULL,
	"instance_name"	TEXT NOT NULL DEFAULT 'master'
);
CREATE TABLE IF NOT EXISTS "device_lists_remote_cache" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"content"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "device_lists_remote_extremeties" (
	"user_id"	TEXT NOT NULL,
	"stream_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "device_lists_stream" (
	"stream_id"	BIGINT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "device_lists_outbound_pokes" (
	"destination"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"sent"	BOOLEAN NOT NULL,
	"ts"	BIGINT NOT NULL,
	"opentracing_context"	TEXT
);
CREATE TABLE IF NOT EXISTS "event_push_summary" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"notif_count"	BIGINT NOT NULL,
	"stream_ordering"	BIGINT NOT NULL,
	"unread_count"	BIGINT,
	"last_receipt_stream_ordering"	BIGINT
);
CREATE TABLE IF NOT EXISTS "event_push_summary_stream_ordering" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"stream_ordering"	BIGINT NOT NULL,
	CHECK("Lock" = 'X')
);
CREATE TABLE IF NOT EXISTS "pushers" (
	"id"	BIGINT,
	"user_name"	TEXT NOT NULL,
	"access_token"	BIGINT DEFAULT NULL,
	"profile_tag"	TEXT NOT NULL,
	"kind"	TEXT NOT NULL,
	"app_id"	TEXT NOT NULL,
	"app_display_name"	TEXT NOT NULL,
	"device_display_name"	TEXT NOT NULL,
	"pushkey"	TEXT NOT NULL,
	"ts"	BIGINT NOT NULL,
	"lang"	TEXT,
	"data"	TEXT,
	"last_stream_ordering"	INTEGER,
	"last_success"	BIGINT,
	"failing_since"	BIGINT,
	PRIMARY KEY("id"),
	UNIQUE("app_id","pushkey","user_name")
);
CREATE TABLE IF NOT EXISTS "ratelimit_override" (
	"user_id"	TEXT NOT NULL,
	"messages_per_second"	BIGINT,
	"burst_count"	BIGINT
);
CREATE TABLE IF NOT EXISTS "current_state_delta_stream" (
	"stream_id"	BIGINT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"type"	TEXT NOT NULL,
	"state_key"	TEXT NOT NULL,
	"event_id"	TEXT,
	"prev_event_id"	TEXT,
	"instance_name"	TEXT
);
CREATE TABLE IF NOT EXISTS "user_directory_stream_pos" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"stream_id"	BIGINT,
	CHECK("Lock" = 'X')
);
CREATE VIRTUAL TABLE user_directory_search USING fts4 ( user_id, value );
CREATE TABLE IF NOT EXISTS "user_directory_search_content" (
	"docid"	INTEGER,
	"c0user_id"	,
	"c1value"	,
	PRIMARY KEY("docid")
);
CREATE TABLE IF NOT EXISTS "user_directory_search_segments" (
	"blockid"	INTEGER,
	"block"	BLOB,
	PRIMARY KEY("blockid")
);
CREATE TABLE IF NOT EXISTS "user_directory_search_segdir" (
	"level"	INTEGER,
	"idx"	INTEGER,
	"start_block"	INTEGER,
	"leaves_end_block"	INTEGER,
	"end_block"	INTEGER,
	"root"	BLOB,
	PRIMARY KEY("level","idx")
);
CREATE TABLE IF NOT EXISTS "user_directory_search_docsize" (
	"docid"	INTEGER,
	"size"	BLOB,
	PRIMARY KEY("docid")
);
CREATE TABLE IF NOT EXISTS "user_directory_search_stat" (
	"id"	INTEGER,
	"value"	BLOB,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "blocked_rooms" (
	"room_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "local_media_repository_url_cache" (
	"url"	TEXT,
	"response_code"	INTEGER,
	"etag"	TEXT,
	"expires_ts"	BIGINT,
	"og"	TEXT,
	"media_id"	TEXT,
	"download_ts"	BIGINT
);
CREATE TABLE IF NOT EXISTS "deleted_pushers" (
	"stream_id"	BIGINT NOT NULL,
	"app_id"	TEXT NOT NULL,
	"pushkey"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "user_directory" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT,
	"display_name"	TEXT,
	"avatar_url"	TEXT
);
CREATE TABLE IF NOT EXISTS "event_push_actions_staging" (
	"event_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"actions"	TEXT NOT NULL,
	"notif"	SMALLINT NOT NULL,
	"highlight"	SMALLINT NOT NULL,
	"unread"	SMALLINT
);
CREATE TABLE IF NOT EXISTS "users_pending_deactivation" (
	"user_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "user_daily_visits" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT,
	"timestamp"	BIGINT NOT NULL,
	"user_agent"	TEXT
);
CREATE TABLE IF NOT EXISTS "erased_users" (
	"user_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "monthly_active_users" (
	"user_id"	TEXT NOT NULL,
	"timestamp"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "e2e_room_keys_versions" (
	"user_id"	TEXT NOT NULL,
	"version"	BIGINT NOT NULL,
	"algorithm"	TEXT NOT NULL,
	"auth_data"	TEXT NOT NULL,
	"deleted"	SMALLINT NOT NULL DEFAULT 0,
	"etag"	BIGINT
);
CREATE TABLE IF NOT EXISTS "e2e_room_keys" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"session_id"	TEXT NOT NULL,
	"version"	BIGINT NOT NULL,
	"first_message_index"	INT,
	"forwarded_count"	INT,
	"is_verified"	BOOLEAN,
	"session_data"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "users_who_share_private_rooms" (
	"user_id"	TEXT NOT NULL,
	"other_user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "user_threepid_id_server" (
	"user_id"	TEXT NOT NULL,
	"medium"	TEXT NOT NULL,
	"address"	TEXT NOT NULL,
	"id_server"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "users_in_public_rooms" (
	"user_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "account_validity" (
	"user_id"	TEXT,
	"expiration_ts_ms"	BIGINT NOT NULL,
	"email_sent"	BOOLEAN NOT NULL,
	"renewal_token"	TEXT,
	"token_used_ts_ms"	BIGINT,
	PRIMARY KEY("user_id")
);
CREATE TABLE IF NOT EXISTS "event_relations" (
	"event_id"	TEXT NOT NULL,
	"relates_to_id"	TEXT NOT NULL,
	"relation_type"	TEXT NOT NULL,
	"aggregation_key"	TEXT
);
CREATE TABLE IF NOT EXISTS "room_stats_earliest_token" (
	"room_id"	TEXT NOT NULL,
	"token"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "threepid_validation_session" (
	"session_id"	TEXT,
	"medium"	TEXT NOT NULL,
	"address"	TEXT NOT NULL,
	"client_secret"	TEXT NOT NULL,
	"last_send_attempt"	BIGINT NOT NULL,
	"validated_at"	BIGINT,
	PRIMARY KEY("session_id")
);
CREATE TABLE IF NOT EXISTS "threepid_validation_token" (
	"token"	TEXT,
	"session_id"	TEXT NOT NULL,
	"next_link"	TEXT,
	"expires"	BIGINT NOT NULL,
	PRIMARY KEY("token")
);
CREATE TABLE IF NOT EXISTS "event_expiry" (
	"event_id"	TEXT,
	"expiry_ts"	BIGINT NOT NULL,
	PRIMARY KEY("event_id")
);
CREATE TABLE IF NOT EXISTS "event_labels" (
	"event_id"	TEXT,
	"label"	TEXT,
	"room_id"	TEXT NOT NULL,
	"topological_ordering"	BIGINT NOT NULL,
	PRIMARY KEY("event_id","label")
);
CREATE TABLE IF NOT EXISTS "devices" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"display_name"	TEXT,
	"last_seen"	BIGINT,
	"ip"	TEXT,
	"user_agent"	TEXT,
	"hidden"	BOOLEAN DEFAULT 0,
	CONSTRAINT "device_uniqueness" UNIQUE("user_id","device_id")
);
CREATE TABLE IF NOT EXISTS "room_retention" (
	"room_id"	TEXT,
	"event_id"	TEXT,
	"min_lifetime"	BIGINT,
	"max_lifetime"	BIGINT,
	PRIMARY KEY("room_id","event_id")
);
CREATE TABLE IF NOT EXISTS "e2e_cross_signing_keys" (
	"user_id"	TEXT NOT NULL,
	"keytype"	TEXT NOT NULL,
	"keydata"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "e2e_cross_signing_signatures" (
	"user_id"	TEXT NOT NULL,
	"key_id"	TEXT NOT NULL,
	"target_user_id"	TEXT NOT NULL,
	"target_device_id"	TEXT NOT NULL,
	"signature"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "user_signature_stream" (
	"stream_id"	BIGINT NOT NULL,
	"from_user_id"	TEXT NOT NULL,
	"user_ids"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "stats_incremental_position" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"stream_id"	BIGINT NOT NULL,
	CHECK("Lock" = 'X')
);
CREATE TABLE IF NOT EXISTS "room_stats_current" (
	"room_id"	TEXT NOT NULL,
	"current_state_events"	INT NOT NULL,
	"joined_members"	INT NOT NULL,
	"invited_members"	INT NOT NULL,
	"left_members"	INT NOT NULL,
	"banned_members"	INT NOT NULL,
	"local_users_in_room"	INT NOT NULL,
	"completed_delta_stream_id"	BIGINT NOT NULL,
	"knocked_members"	INT,
	PRIMARY KEY("room_id")
);
CREATE TABLE IF NOT EXISTS "user_stats_current" (
	"user_id"	TEXT NOT NULL,
	"joined_rooms"	BIGINT NOT NULL,
	"completed_delta_stream_id"	BIGINT NOT NULL,
	PRIMARY KEY("user_id")
);
CREATE TABLE IF NOT EXISTS "room_stats_state" (
	"room_id"	TEXT NOT NULL,
	"name"	TEXT,
	"canonical_alias"	TEXT,
	"join_rules"	TEXT,
	"history_visibility"	TEXT,
	"encryption"	TEXT,
	"avatar"	TEXT,
	"guest_access"	TEXT,
	"is_federatable"	BOOLEAN,
	"topic"	TEXT,
	"room_type"	TEXT
);
CREATE TABLE IF NOT EXISTS "user_filters" (
	"user_id"	TEXT NOT NULL,
	"filter_id"	BIGINT NOT NULL,
	"filter_json"	BYTEA NOT NULL
);
CREATE TABLE IF NOT EXISTS "user_external_ids" (
	"auth_provider"	TEXT NOT NULL,
	"external_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	UNIQUE("auth_provider","external_id")
);
CREATE TABLE IF NOT EXISTS "device_lists_remote_resync" (
	"user_id"	TEXT NOT NULL,
	"added_ts"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "local_current_membership" (
	"room_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"membership"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "ui_auth_sessions" (
	"session_id"	TEXT NOT NULL,
	"creation_time"	BIGINT NOT NULL,
	"serverdict"	TEXT NOT NULL,
	"clientdict"	TEXT NOT NULL,
	"uri"	TEXT NOT NULL,
	"method"	TEXT NOT NULL,
	"description"	TEXT NOT NULL,
	UNIQUE("session_id")
);
CREATE TABLE IF NOT EXISTS "ui_auth_sessions_credentials" (
	"session_id"	TEXT NOT NULL,
	"stage_type"	TEXT NOT NULL,
	"result"	TEXT NOT NULL,
	FOREIGN KEY("session_id") REFERENCES "ui_auth_sessions"("session_id"),
	UNIQUE("session_id","stage_type")
);
CREATE TABLE IF NOT EXISTS "device_lists_outbound_last_success" (
	"destination"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "local_media_repository_thumbnails" (
	"media_id"	TEXT,
	"thumbnail_width"	INTEGER,
	"thumbnail_height"	INTEGER,
	"thumbnail_type"	TEXT,
	"thumbnail_method"	TEXT,
	"thumbnail_length"	INTEGER,
	UNIQUE("media_id","thumbnail_width","thumbnail_height","thumbnail_type","thumbnail_method")
);
CREATE TABLE IF NOT EXISTS "remote_media_cache_thumbnails" (
	"media_origin"	TEXT,
	"media_id"	TEXT,
	"thumbnail_width"	INTEGER,
	"thumbnail_height"	INTEGER,
	"thumbnail_method"	TEXT,
	"thumbnail_type"	TEXT,
	"thumbnail_length"	INTEGER,
	"filesystem_id"	TEXT,
	UNIQUE("media_origin","media_id","thumbnail_width","thumbnail_height","thumbnail_type","thumbnail_method")
);
CREATE TABLE IF NOT EXISTS "ui_auth_sessions_ips" (
	"session_id"	TEXT NOT NULL,
	"ip"	TEXT NOT NULL,
	"user_agent"	TEXT NOT NULL,
	FOREIGN KEY("session_id") REFERENCES "ui_auth_sessions"("session_id"),
	UNIQUE("session_id","ip","user_agent")
);
CREATE TABLE IF NOT EXISTS "dehydrated_devices" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"device_data"	TEXT NOT NULL,
	PRIMARY KEY("user_id")
);
CREATE TABLE IF NOT EXISTS "e2e_fallback_keys_json" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"algorithm"	TEXT NOT NULL,
	"key_id"	TEXT NOT NULL,
	"key_json"	TEXT NOT NULL,
	"used"	BOOLEAN NOT NULL DEFAULT FALSE,
	CONSTRAINT "e2e_fallback_keys_json_uniqueness" UNIQUE("user_id","device_id","algorithm")
);
CREATE TABLE IF NOT EXISTS "destination_rooms" (
	"destination"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"stream_ordering"	BIGINT NOT NULL,
	PRIMARY KEY("destination","room_id"),
	FOREIGN KEY("destination") REFERENCES "destinations"("destination"),
	FOREIGN KEY("room_id") REFERENCES "rooms"("room_id")
);
CREATE TABLE IF NOT EXISTS "stream_positions" (
	"stream_name"	TEXT NOT NULL,
	"instance_name"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "access_tokens" (
	"id"	BIGINT,
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT,
	"token"	TEXT NOT NULL,
	"valid_until_ms"	BIGINT,
	"puppets_user_id"	TEXT,
	"last_validated"	BIGINT,
	"refresh_token_id"	BIGINT,
	"used"	BOOLEAN,
	UNIQUE("token"),
	PRIMARY KEY("id"),
	FOREIGN KEY("refresh_token_id") REFERENCES "refresh_tokens"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "event_txn_id" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"user_id"	TEXT NOT NULL,
	"token_id"	BIGINT NOT NULL,
	"txn_id"	TEXT NOT NULL,
	"inserted_ts"	BIGINT NOT NULL,
	FOREIGN KEY("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE,
	FOREIGN KEY("token_id") REFERENCES "access_tokens"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "ignored_users" (
	"ignorer_user_id"	TEXT NOT NULL,
	"ignored_user_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "event_auth_chains" (
	"event_id"	TEXT,
	"chain_id"	BIGINT NOT NULL,
	"sequence_number"	BIGINT NOT NULL,
	PRIMARY KEY("event_id")
);
CREATE TABLE IF NOT EXISTS "event_auth_chain_links" (
	"origin_chain_id"	BIGINT NOT NULL,
	"origin_sequence_number"	BIGINT NOT NULL,
	"target_chain_id"	BIGINT NOT NULL,
	"target_sequence_number"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "event_auth_chain_to_calculate" (
	"event_id"	TEXT,
	"room_id"	TEXT NOT NULL,
	"type"	TEXT NOT NULL,
	"state_key"	TEXT NOT NULL,
	PRIMARY KEY("event_id")
);
CREATE TABLE IF NOT EXISTS "users_to_send_full_presence_to" (
	"user_id"	TEXT,
	"presence_stream_id"	BIGINT,
	PRIMARY KEY("user_id"),
	FOREIGN KEY("user_id") REFERENCES "users"("name")
);
CREATE TABLE IF NOT EXISTS "refresh_tokens" (
	"id"	BIGINT,
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"token"	TEXT NOT NULL,
	"next_token_id"	BIGINT,
	"expiry_ts"	BIGINT DEFAULT NULL,
	"ultimate_session_expiry_ts"	BIGINT DEFAULT NULL,
	FOREIGN KEY("next_token_id") REFERENCES "refresh_tokens"("id") ON DELETE CASCADE,
	PRIMARY KEY("id"),
	UNIQUE("token")
);
CREATE TABLE IF NOT EXISTS "worker_locks" (
	"lock_name"	TEXT NOT NULL,
	"lock_key"	TEXT NOT NULL,
	"instance_name"	TEXT NOT NULL,
	"token"	TEXT NOT NULL,
	"last_renewed_ts"	BIGINT NOT NULL
);
CREATE TABLE IF NOT EXISTS "federation_inbound_events_staging" (
	"origin"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	"received_ts"	BIGINT NOT NULL,
	"event_json"	TEXT NOT NULL,
	"internal_metadata"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "insertion_event_edges" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"insertion_prev_event_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "insertion_event_extremities" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "registration_tokens" (
	"token"	TEXT NOT NULL,
	"uses_allowed"	INT,
	"pending"	INT NOT NULL,
	"completed"	INT NOT NULL,
	"expiry_time"	BIGINT,
	UNIQUE("token")
);
CREATE TABLE IF NOT EXISTS "sessions" (
	"session_type"	TEXT NOT NULL,
	"session_id"	TEXT NOT NULL,
	"value"	TEXT NOT NULL,
	"expiry_time_ms"	BIGINT NOT NULL,
	UNIQUE("session_type","session_id")
);
CREATE TABLE IF NOT EXISTS "insertion_events" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"next_batch_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "batch_events" (
	"event_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"batch_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "device_auth_providers" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"auth_provider_id"	TEXT NOT NULL,
	"auth_provider_session_id"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "partial_state_rooms" (
	"room_id"	TEXT,
	PRIMARY KEY("room_id"),
	FOREIGN KEY("room_id") REFERENCES "rooms"("room_id")
);
CREATE TABLE IF NOT EXISTS "partial_state_rooms_servers" (
	"room_id"	TEXT NOT NULL,
	"server_name"	TEXT NOT NULL,
	UNIQUE("room_id","server_name"),
	FOREIGN KEY("room_id") REFERENCES "partial_state_rooms"("room_id")
);
CREATE TABLE IF NOT EXISTS "partial_state_events" (
	"room_id"	TEXT NOT NULL,
	"event_id"	TEXT NOT NULL,
	UNIQUE("event_id"),
	FOREIGN KEY("room_id") REFERENCES "partial_state_rooms"("room_id"),
	FOREIGN KEY("event_id") REFERENCES "events"("event_id")
);
CREATE TABLE IF NOT EXISTS "device_lists_changes_in_room" (
	"user_id"	TEXT NOT NULL,
	"device_id"	TEXT NOT NULL,
	"room_id"	TEXT NOT NULL,
	"stream_id"	BIGINT NOT NULL,
	"converted_to_destinations"	BOOLEAN NOT NULL,
	"opentracing_context"	TEXT
);
CREATE TABLE IF NOT EXISTS "event_edges" (
	"event_id"	TEXT NOT NULL,
	"prev_event_id"	TEXT NOT NULL,
	"room_id"	TEXT,
	"is_state"	BOOL NOT NULL DEFAULT 0,
	FOREIGN KEY("event_id") REFERENCES "events"("event_id")
);
CREATE TABLE IF NOT EXISTS "event_push_summary_last_receipt_stream_id" (
	"Lock"	CHAR(1) NOT NULL DEFAULT 'X' UNIQUE,
	"stream_id"	BIGINT NOT NULL,
	CHECK("Lock" = 'X')
);
CREATE TABLE IF NOT EXISTS "application_services_state" (
	"as_id"	TEXT NOT NULL,
	"state"	VARCHAR(5),
	"read_receipt_stream_id"	BIGINT,
	"presence_stream_id"	BIGINT,
	"to_device_stream_id"	BIGINT,
	"device_list_stream_id"	BIGINT,
	PRIMARY KEY("as_id")
);
INSERT INTO "schema_version" VALUES ('X',72,1);
INSERT INTO "schema_compat_version" VALUES ('X',72);
INSERT INTO "applied_schema_deltas" VALUES (55,'55/access_token_expiry.sql');
INSERT INTO "applied_schema_deltas" VALUES (55,'55/track_threepid_validations.sql');
INSERT INTO "applied_schema_deltas" VALUES (55,'55/users_alter_deactivated.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/add_spans_to_device_lists.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/current_state_events_membership.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/current_state_events_membership_mk2.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/delete_keys_from_deleted_backups.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/destinations_failure_ts.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/device_stream_id_insert.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/devices_last_seen.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/drop_unused_event_tables.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/event_expiry.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/event_labels.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/event_labels_background_update.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/fix_room_keys_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/hidden_devices.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/hidden_devices_fix.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/nuke_empty_communities_from_db.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/public_room_list_idx.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/redaction_censor.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/redaction_censor2.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/redaction_censor4.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/remove_tombstoned_rooms_from_directory.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/room_key_etag.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/room_membership_idx.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/room_retention.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/signing_keys.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/signing_keys_nonunique_signatures.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/state_group_room_idx.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/stats_separated.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/unique_user_filter_index.py');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/user_external_ids.sql');
INSERT INTO "applied_schema_deltas" VALUES (56,'56/users_in_public_rooms_idx.sql');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/delete_old_current_state_events.sql');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/device_list_remote_cache_stale.sql');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/local_current_membership.py');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/remove_sent_outbound_pokes.sql');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/rooms_version_column.sql');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/rooms_version_column_2.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (57,'57/rooms_version_column_3.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/00background_update_ordering.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/02remove_dup_outbound_pokes.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/03persist_ui_auth.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/06dlols_unique_idx.py');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/07add_method_to_thumbnail_constraint.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/07persist_ui_auth_ips.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/08_media_safe_from_quarantine.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/09shadow_ban.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/10_pushrules_enabled_delete_obsolete.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/10drop_local_rejections_stream.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/10federation_pos_instance_name.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/11dehydration.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/11fallback.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/11user_id_seq.py');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/12room_stats.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/13remove_presence_allow_inbound.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/14events_instance_name.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/15_catchup_destination_rooms.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/15unread_count.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/16populate_stats_process_rooms_fix.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/17_catchup_last_successful.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/18stream_positions.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/19txn_id.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/20instance_name_event_tables.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/20user_daily_visits.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/21as_device_stream.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/21drop_device_max_stream_id.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/22puppet_token.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/22users_have_local_media.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/23e2e_cross_signing_keys_idx.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/24drop_event_json_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/25user_external_ids_user_id_idx.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/26access_token_last_validated.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/27local_invites.sql');
INSERT INTO "applied_schema_deltas" VALUES (58,'58/28drop_last_used_column.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/01ignored_user.py');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/02shard_send_to_device.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/04_event_auth_chains.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/04drop_account_data.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/05cache_invalidation.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/06chain_cover_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/06shard_account_data.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/07shard_account_data_fix.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/08delete_pushers_for_deactivated_accounts.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/08delete_stale_pushers.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/09rejected_events_metadata.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/10delete_purged_chain_cover.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/11add_knock_members_to_stats.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/12account_validity_token_used_ts_ms.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/12presence_stream_instance.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/13users_to_send_full_presence_to.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/14refresh_tokens.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/15locks.sql');
INSERT INTO "applied_schema_deltas" VALUES (59,'59/16federation_inbound_staging.sql');
INSERT INTO "applied_schema_deltas" VALUES (61,'61/01insertion_event_lookups.sql');
INSERT INTO "applied_schema_deltas" VALUES (61,'61/02drop_redundant_room_depth_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (61,'61/03recreate_min_depth.py');
INSERT INTO "applied_schema_deltas" VALUES (62,'62/01insertion_event_extremities.sql');
INSERT INTO "applied_schema_deltas" VALUES (63,'63/01create_registration_tokens.sql');
INSERT INTO "applied_schema_deltas" VALUES (63,'63/02delete_unlinked_email_pushers.sql');
INSERT INTO "applied_schema_deltas" VALUES (63,'63/02populate-rooms-creator.sql');
INSERT INTO "applied_schema_deltas" VALUES (63,'63/03session_store.sql');
INSERT INTO "applied_schema_deltas" VALUES (63,'63/04add_presence_stream_not_offline_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (64,'64/01msc2716_chunk_to_batch_rename.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/01msc2716_insertion_event_edges.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/03remove_hidden_devices_from_device_inbox.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/04_local_group_updates.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/05_remove_room_stats_historical_and_user_stats_historical.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/06remove_deleted_devices_from_device_inbox.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/07_arbitrary_relations.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/08_device_inbox_background_updates.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/10_expirable_refresh_tokens.sql');
INSERT INTO "applied_schema_deltas" VALUES (65,'65/11_devices_auth_provider_session.sql');
INSERT INTO "applied_schema_deltas" VALUES (67,'67/01drop_public_room_list_stream.sql');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/01event_columns.sql');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/02_msc2409_add_device_id_appservice_stream_type.sql');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/03_delete_account_data_for_deactivated_accounts.sql');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/04_refresh_tokens_index_next_token_id.sql');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/04partial_state_rooms.sql');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/05_delete_non_strings_from_event_search.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/05partial_state_rooms_triggers.py');
INSERT INTO "applied_schema_deltas" VALUES (68,'68/06_msc3202_add_device_list_appservice_stream_type.sql');
INSERT INTO "applied_schema_deltas" VALUES (69,'69/01as_txn_seq.py');
INSERT INTO "applied_schema_deltas" VALUES (69,'69/01device_list_oubound_by_room.sql');
INSERT INTO "applied_schema_deltas" VALUES (69,'69/02cache_invalidation_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (70,'70/01clean_table_purged_rooms.sql');
INSERT INTO "applied_schema_deltas" VALUES (70,'70/08_state_group_edges_unique.sql');
INSERT INTO "applied_schema_deltas" VALUES (71,'71/01rebuild_event_edges.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (71,'71/01remove_noop_background_updates.sql');
INSERT INTO "applied_schema_deltas" VALUES (71,'71/02event_push_summary_unique.sql');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/01add_room_type_to_state_stats.sql');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/01event_push_summary_receipt.sql');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/02event_push_actions_index.sql');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/03bg_populate_events_columns.py');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/03drop_event_reference_hashes.sql');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/03remove_groups.sql');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/04drop_column_application_services_state_last_txn.sql.sqlite');
INSERT INTO "applied_schema_deltas" VALUES (72,'72/05remove_unstable_private_read_receipts.sql');
INSERT INTO "state_groups" VALUES (1,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM');
INSERT INTO "state_groups" VALUES (2,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM');
INSERT INTO "state_groups" VALUES (3,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w');
INSERT INTO "state_groups" VALUES (4,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM');
INSERT INTO "state_groups" VALUES (5,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM');
INSERT INTO "state_groups" VALUES (6,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4');
INSERT INTO "state_groups" VALUES (7,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY');
INSERT INTO "state_groups" VALUES (8,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E');
INSERT INTO "state_groups_state" VALUES (2,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.create','','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM');
INSERT INTO "state_groups_state" VALUES (3,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.member','@bob:matrix.digitalmedcare.de','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w');
INSERT INTO "state_groups_state" VALUES (4,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.power_levels','','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM');
INSERT INTO "state_groups_state" VALUES (5,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.canonical_alias','','$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM');
INSERT INTO "state_groups_state" VALUES (6,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.join_rules','','$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4');
INSERT INTO "state_groups_state" VALUES (7,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.history_visibility','','$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY');
INSERT INTO "state_groups_state" VALUES (8,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.name','','$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E');
INSERT INTO "state_group_edges" VALUES (2,1);
INSERT INTO "state_group_edges" VALUES (3,2);
INSERT INTO "state_group_edges" VALUES (4,3);
INSERT INTO "state_group_edges" VALUES (5,4);
INSERT INTO "state_group_edges" VALUES (6,5);
INSERT INTO "state_group_edges" VALUES (7,6);
INSERT INTO "state_group_edges" VALUES (8,7);
INSERT INTO "users" VALUES ('@bob:matrix.digitalmedcare.de','$2b$12$b0F/z1jpby4Vx/AmAjO0xuzmeSdKUmzdB9qR3S1yrsYuy2hC1biW6',1663084632,0,NULL,0,NULL,NULL,NULL,NULL,0,0);
INSERT INTO "user_ips" VALUES ('@bob:matrix.digitalmedcare.de','syt_Ym9i_oowlWjnmhDSSSFLVWaKw_0307wY','WTWNFTOZVM','93.236.236.173','Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0',1663085334079);
INSERT INTO "user_ips" VALUES ('@bob:matrix.digitalmedcare.de','syt_Ym9i_MFWOpdadcXYRJaAlQvjF_3v7PwY','VLNNCVZHMQ','93.236.236.173','Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0',1663085623837);
INSERT INTO "user_ips" VALUES ('@bob:matrix.digitalmedcare.de','syt_Ym9i_nRTSyYHVNHDdUGlFWhNB_1El1II','LHXCHFEPBN','93.236.236.173','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',1663085623833);
INSERT INTO "profiles" VALUES ('bob','bob',NULL);
INSERT INTO "events" VALUES (2,1,'$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','m.room.create','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,1,1663085101022,1663085101042,'@bob:matrix.digitalmedcare.de',0,'master','',NULL);
INSERT INTO "events" VALUES (3,2,'$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','m.room.member','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,2,1663085101079,1663085101089,'@bob:matrix.digitalmedcare.de',0,'master','@bob:matrix.digitalmedcare.de',NULL);
INSERT INTO "events" VALUES (4,2,'$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','m.room.power_levels','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,2,1663085101120,1663085101157,'@bob:matrix.digitalmedcare.de',0,'master','',NULL);
INSERT INTO "events" VALUES (5,3,'$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','m.room.canonical_alias','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,3,1663085101188,1663085101210,'@bob:matrix.digitalmedcare.de',0,'master','',NULL);
INSERT INTO "events" VALUES (6,4,'$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','m.room.join_rules','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,4,1663085101250,1663085101285,'@bob:matrix.digitalmedcare.de',0,'master','',NULL);
INSERT INTO "events" VALUES (7,5,'$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','m.room.history_visibility','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,5,1663085101315,1663085101363,'@bob:matrix.digitalmedcare.de',0,'master','',NULL);
INSERT INTO "events" VALUES (8,6,'$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','m.room.name','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,6,1663085101399,1663085101428,'@bob:matrix.digitalmedcare.de',0,'master','',NULL);
INSERT INTO "events" VALUES (9,7,'$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y','m.room.message','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,7,1663085104997,1663085105005,'@bob:matrix.digitalmedcare.de',0,'master',NULL,NULL);
INSERT INTO "events" VALUES (10,8,'$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU','m.room.message','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,NULL,1,0,8,1663085110823,1663085110829,'@bob:matrix.digitalmedcare.de',0,'master',NULL,NULL);
INSERT INTO "event_json" VALUES ('$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":[],"prev_events":[],"type":"m.room.create","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"room_version":"9","creator":"@bob:matrix.digitalmedcare.de"},"depth":1,"prev_state":[],"state_key":"","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101022,"hashes":{"sha256":"M3pU8AvbrFKzysWlK1Eh4CJn1WoqZQX3PJQ81jiwkUA"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"f55jcu87OkNeSNS7S5nG2Bey7TcYSGsbPuEperwbVMnofFwEE0jwg1qO3qTrg/ZRlVPTVa+QKJYpFB01bt6vCw"}},"unsigned":{"age_ts":1663085101022}}',3);
INSERT INTO "event_json" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":["$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"type":"m.room.member","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"membership":"join","displayname":"bob"},"depth":2,"prev_state":[],"state_key":"@bob:matrix.digitalmedcare.de","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101079,"hashes":{"sha256":"teE3fbCHPaWLLAqm/ylg7G2yVkI/OVD/47mx7JVJBls"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"w2cfBalfYhNi4lOfPS2IcySeJ4Wfv0cW2LIRRSJ5JGelWY/kt8SfNTaWQKFbd4agr9o1/Pl31DP0A06cNmKnCw"}},"unsigned":{"age_ts":1663085101079}}',3);
INSERT INTO "event_json" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":["$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w"],"type":"m.room.power_levels","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"users":{"@bob:matrix.digitalmedcare.de":100},"users_default":0,"events":{"m.room.name":50,"m.room.power_levels":100,"m.room.history_visibility":100,"m.room.canonical_alias":50,"m.room.avatar":50,"m.room.tombstone":100,"m.room.server_acl":100,"m.room.encryption":100},"events_default":0,"state_default":50,"ban":50,"kick":50,"redact":50,"invite":50,"historical":100},"depth":2,"prev_state":[],"state_key":"","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101120,"hashes":{"sha256":"oTdrL6hm50Jr0LsrZGhkM1sTFRjhNQyyBpPF1i2v3Wc"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"sYl16aB6vUta04P3BTdWy4LvrbRLAQF1PA2Ia6h1Uy5n9XTq5rqBMp67lX6zNpGOZJ+4bAGrUFaR4vONP4N3Dg"}},"unsigned":{"age_ts":1663085101120}}',3);
INSERT INTO "event_json" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM","$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM"],"type":"m.room.canonical_alias","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"alias":"#bobsraum:matrix.digitalmedcare.de"},"depth":3,"prev_state":[],"state_key":"","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101188,"hashes":{"sha256":"MXDIfGpAuJXkoRAdfWhM7v/09qkR1M2RHjXF4F8h3Ek"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"YkWFn91pFxtEMh/he+VyPTGWZinWAr+bJPCSJXysCyiEDAXDRWygLOnx50CGRh8DXNsBPNHwc4aBDYr7n5yBBA"}},"unsigned":{"age_ts":1663085101188}}',3);
INSERT INTO "event_json" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM","$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM"],"type":"m.room.join_rules","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"join_rule":"public"},"depth":4,"prev_state":[],"state_key":"","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101250,"hashes":{"sha256":"Vx7ZmjClW1RkJ5f/n+ar/0t7sjLz0OhVEIrv6dVxIBc"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"QCY1rF4KHdJZfb70YPfhvZ82S9QIUyqgcvDWiVQKAJoq6yX8LJU7rCdmOUuDX1Z+KvV2h4F0CpKhahqDXBy5Cw"}},"unsigned":{"age_ts":1663085101250}}',3);
INSERT INTO "event_json" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM","$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4"],"type":"m.room.history_visibility","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"history_visibility":"shared"},"depth":5,"prev_state":[],"state_key":"","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101315,"hashes":{"sha256":"O4kYfGOXAf6yv7lAVBQvdV2v48hTbHsJxOv+IDOXU2U"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"k4BYJ157BskrgbYPjZZmDFx161GRAa0ji89C/J70SjqxWR2gM3iNjPcJimqfsmb+uLn6UB4jf7jOfLH77q45BA"}},"unsigned":{"age_ts":1663085101315}}',3);
INSERT INTO "event_json" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"historical":false}','{"auth_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM","$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY"],"type":"m.room.name","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"name":"Bobs Spielwiese"},"depth":6,"prev_state":[],"state_key":"","origin":"matrix.digitalmedcare.de","origin_server_ts":1663085101399,"hashes":{"sha256":"749QXcNiMBRJ8UW+mZiKcGLwTeDI+WKySVLaUMwnopo"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"3xK4RpOdRYzqkO+V6Y6B76+xsXUNZ/UMLhQBXpOTWvIr4fUO/75+fxq6rpKg+7pWEGK2voNmAZry8N3JnPlBDA"}},"unsigned":{"age_ts":1663085101399}}',3);
INSERT INTO "event_json" VALUES ('$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"txn_id":"m1663085104937.0","historical":false}','{"auth_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM","$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"prev_events":["$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E"],"type":"m.room.message","room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","content":{"org.matrix.msc1767.text":"hallo","body":"hallo","msgtype":"m.text"},"depth":7,"prev_state":[],"origin":"matrix.digitalmedcare.de","origin_server_ts":1663085104997,"hashes":{"sha256":"1rJx2RNzWpUphxrQP46aAJoAUIeMXTyRbCGfdy7lH10"},"signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"mjQFpvaM3ByFKebKg4j2EdufySF3meHcHTyUMMOuwqpAVs9ld/YKp2ognhl+98BSLoYZ+/CIczRJMsLHRMShAw"}},"unsigned":{"age_ts":1663085104997}}',3);
INSERT INTO "event_json" VALUES ('$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','{"token_id":3,"txn_id":"m1663085110764.1","historical":false}','{"auth_events":["$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM","$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w","$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM"],"content":{"body":"Deleted Message","msgtype":"m.text","org.matrix.msc1767.text":"Deleted Message"},"depth":8,"hashes":{"sha256":"p04SWLkWA/dxZki7eZ/fXv0E9fiW7fcjXz9h4fpkFNk"},"origin":"matrix.digitalmedcare.de","origin_server_ts":1663085110823,"prev_events":["$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y"],"prev_state":[],"room_id":"!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de","sender":"@bob:matrix.digitalmedcare.de","signatures":{"matrix.digitalmedcare.de":{"ed25519:a_AcbE":"b572vNO62DChGReglQVjON8v3OQ6/B1bmvxJ7Yw7n/z8SS+mpszQPYMC6z2+QtVoyjYNQTI3fW1lHoOvwO4RAw"}},"type":"m.room.message","unsigned":{"age_ts":1663085110823}}',3);
INSERT INTO "state_events" VALUES ('$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.create','',NULL);
INSERT INTO "state_events" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.member','@bob:matrix.digitalmedcare.de',NULL);
INSERT INTO "state_events" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.power_levels','',NULL);
INSERT INTO "state_events" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.canonical_alias','',NULL);
INSERT INTO "state_events" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.join_rules','',NULL);
INSERT INTO "state_events" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.history_visibility','',NULL);
INSERT INTO "state_events" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.name','',NULL);
INSERT INTO "current_state_events" VALUES ('$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.create','',NULL);
INSERT INTO "current_state_events" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.member','@bob:matrix.digitalmedcare.de','join');
INSERT INTO "current_state_events" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.power_levels','',NULL);
INSERT INTO "current_state_events" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.canonical_alias','',NULL);
INSERT INTO "current_state_events" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.join_rules','',NULL);
INSERT INTO "current_state_events" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.history_visibility','',NULL);
INSERT INTO "current_state_events" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.name','',NULL);
INSERT INTO "room_memberships" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','@bob:matrix.digitalmedcare.de','@bob:matrix.digitalmedcare.de','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','join',0,'bob',NULL);
INSERT INTO "rooms" VALUES ('!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',1,'@bob:matrix.digitalmedcare.de','9',1);
INSERT INTO "event_forward_extremities" VALUES ('$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "room_depth" VALUES ('!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',1);
INSERT INTO "event_to_state_groups" VALUES ('$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM',2);
INSERT INTO "event_to_state_groups" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w',3);
INSERT INTO "event_to_state_groups" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM',4);
INSERT INTO "event_to_state_groups" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM',5);
INSERT INTO "event_to_state_groups" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4',6);
INSERT INTO "event_to_state_groups" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY',7);
INSERT INTO "event_to_state_groups" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E',8);
INSERT INTO "event_to_state_groups" VALUES ('$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y',8);
INSERT INTO "event_to_state_groups" VALUES ('$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU',8);
INSERT INTO "room_aliases" VALUES ('#bobsraum:matrix.digitalmedcare.de','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','@bob:matrix.digitalmedcare.de');
INSERT INTO "room_alias_servers" VALUES ('#bobsraum:matrix.digitalmedcare.de','matrix.digitalmedcare.de');
INSERT INTO "e2e_device_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ',1663085363964,'{"algorithms":["m.olm.v1.curve25519-aes-sha2","m.megolm.v1.aes-sha2"],"device_id":"VLNNCVZHMQ","keys":{"curve25519:VLNNCVZHMQ":"S+XZx/ltsLH+OtmlKuUQNReCD7ibtu8TUsTWLr/ofVw","ed25519:VLNNCVZHMQ":"HpWIrofdpqSxTYPPLUgr0SmJ391DZlErUE6AhCIAN1I"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"RL8Ry4ClK+FQPwqbr6/HDqf+rvIncH/hJqFu2KcJC1reY7DehUlHvO3otMtg8gkbmI0MulRTMzW+0cIM6XU5Cg"}},"user_id":"@bob:matrix.digitalmedcare.de"}');
INSERT INTO "e2e_device_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN',1663085501809,'{"algorithms":["m.olm.v1.curve25519-aes-sha2","m.megolm.v1.aes-sha2"],"device_id":"LHXCHFEPBN","keys":{"curve25519:LHXCHFEPBN":"zKctqWa9uo9JjKo5iq6Ob2pr2o6+Lb05uXSGowGrFWE","ed25519:LHXCHFEPBN":"tGbuhYBDvxwjgYviR+Dm4aF07iiJunMyCD/bEQ2R7Hk"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"btl6vxS+YUwmuadukBJGpnzdMkqFZGn58jR6dXi+qDJT2zOwM7dknCdNeJXUuk0QVFy+zVAK+DRiKoxHVXsPAQ"}},"user_id":"@bob:matrix.digitalmedcare.de"}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAABQ',1663085364140,'{"key":"FNi4j8CjD2KILYOHi1XLTAY6px5CvYeyJwMSBz/eEQ0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"lGsX47dBvUEdK/inpQPofSd/TnU4KX2jJjA6tHkpdXKVxTdnM50ZkH0DDCDkh+u0t6jyc8TD7kMQfcl7yHGwDg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAABA',1663085364140,'{"key":"7Q/j6Aqx1+Njl1S1a8OIOIicMmpISfZQYA29GRuVyzo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"LcCFLfq+4x/DDBrBWcmLvtTz4X1xrVXDHPXmXJ/Ds61G85lIQ7mAxhwaRV3UR/DLGEWbc74rnvLPYutkNMAJDA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAAw',1663085364140,'{"key":"NYYj5+x7Mh0aE9FiGUWamgRBlSuMSEO9SidO8EeLw1M","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"0LcMxSVDo1IKLh0RX+yf9FZf4+eJ5+ZQmnz7vV+KWogwqBXVvl2gsQsReD895040HoxGquDPytXXwMk0RB+tDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAAg',1663085364140,'{"key":"Zc97DFILnJuCCjhRfRhKNM+2uF2afThBzG6cbiRWdAs","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"hzW93GsRnaxEIWMq0ue5Sr/GRiegsz2YfUMPyigepe7NqTyBZJ42YDH0IMfd81kiiqtCW6/aTIcveOwxcd1gCw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAAQ',1663085364140,'{"key":"LMnOqftHEX5Bv6kngeFPymfKFf7y/EVE4ZppZtHlowM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"L/wchSqlFdKXlFGxvdzgME0Xq/fSVfKA7OEXGxIWITxhvmRfdlMXeJAqi5zRvIr6fYHa2A7sEwd6a5dL3zdfBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAACw',1663085364187,'{"key":"TZ5xNEqg/heYihbvJZAWzpnINLw50gqEPTgonWYKB3U","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"dQyVRq+YbPTMyZiqzOP7sRHNrFkENrVxeQynNv5wpVj0GLVoiaLOaR0PijWu0wRAP/xupfhXCLDzF+3+0yC9Ag"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAACg',1663085364187,'{"key":"VESFJbgqoT8GDljeYTguRPPuC96+XOpR1EW8tDTcb2k","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"4zO08h8CZnF1uD+M949VpiwQ9gqGDXbo2WQt1wkzeYtcFWlMaE3vq21GW7KOzjFXfjk2DPWfsyGCiex2CSLcBg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAACQ',1663085364187,'{"key":"iY+V/vPJVZkWT/90SiJrHYus61aQHL4DoHSxQH+qVmo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"BwMXhilmlXP/RW/CA3BAf2sUBLyyzo0vojaOuG1LYywyZ1c6mH1wQLIz3/xZp8agFZfce+OO2dZUQft9FZvcCg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAACA',1663085364187,'{"key":"Ew5pdYiB98toRqVFtfpKWlJxeIenGpe8JT+iIQStyRk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"gxVLCdPeCYJqxOKlbtN8YDbYXJp+WuaDLugButKjxommPVdKM4OKtueYzspcTuDM2BGpIFKZEOfMH2nnJEykCw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAABw',1663085364187,'{"key":"y6uT1WXwMX0nzBWui1yURCzsEuSvNOD2vnKr2Oej/V0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"rgGTXGS6Qqv1TwnDmImoJcNVPxXXu9O53labeOfRyVKsxrOGbi2a0W+INEhOtdEXDbfPuFUD9D4JyEWUIlKZBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAEA',1663085364220,'{"key":"TAkLjdYJtVaXqog0ibGMfdC77RvptMzJzBoUa9taDkU","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"PQ4fzmpWKM9Rhqiw8VVV9d9jZcCudHDFUBR978j1rbw1t54Vk6D1hWgg8h6RgcuUipV750viQaM28f/AZ0sRBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAADw',1663085364220,'{"key":"ZZzwAMaSdopV2UUgq8LM9+YbM8Pd3WbiFvZPBxf0Xns","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"HhAf3HNz0rpM4X3H/4y63Tn/Y6cwqqVqoR4I/PaAfS8TaGH3HOEIu/qyfJ+lRX9eUN3kbCUlaxEqjBpugcOPAw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAADg',1663085364220,'{"key":"FULjz02xA4cQLCyafhii6x8rmhSPeDWow0lUvntAXF4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"daDIus2ceztX7UXNYDFx1uwW9Mb9Hvb0ddPWT91CDG5dk/VoIcTCZL7oIgMIV/9HjeBiaACNpyjJKaVuBQJTBg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAADQ',1663085364220,'{"key":"1uZs9DfIwwysMVwDzATzda0tHOqL7Wbb8Hw6PxrCTSM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"98O6Alx020y8ttEdCFMwwYk5vx9pMka2E4CrXVUu817jKpeMK8B/q0NAgZ07tBbvKiGeYsCgr1ZrmnQZDlifAg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAADA',1663085364220,'{"key":"zZnatngnsHz0BoU1NdGI3F4zh8eXVRQHPmaXgo3L/n8","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"kd+WANiGUQREForb1jG47WnCPhb1wG8RE6BIi98WJzi3HDewIRM7ixDT4RdzHHghco+1LqQ687eK28zO6eyQCg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAFQ',1663085364257,'{"key":"O6oslC6MXUI2Z2ql6AQPuIons8aLVF/50BtBb6BwJT4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"PeTx0WQ6i2mQbmcP5hZ19fVxu0bQLUaRl0UGz8w4xu/8E0eq4Sld0z7qn8yaF0DFxXoWxZ6jheC+FioxqFHMBQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAFA',1663085364257,'{"key":"4OOjIyfduFo9ijapWlnYIpkYppmIij63OlwqorQ4HCM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"6lsTKc7HBeJ12MAGiwRr57CL0cn9YwaJIZozIXBh51Hk7UrRIFGqVmh7obfv29swJtgvdrSCNKeqIKhuZGCLCQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAEw',1663085364257,'{"key":"P9FDmTOC+wtDCRgNKqWC4uYAoE0mUMq8BS/qUWz6mQc","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"N0GmzELgFRxkUy9/ZSRPiTOQLf3A4qFNbq21Ww1DmntQ5B76z5HwmsOEHQLyPd/JGu+6Z/zndyA1GLwrXYA3AQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAEg',1663085364257,'{"key":"NyQNnp8C3bimPUEtPmTfHpUAdrLstXiO//v6avRcTks","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"0PsDKwVQDwETcZdZufDtX6QSLIDG/bLbJFhTmu6oK6k02LWaLNATT7+L7P2+AN1SXPDWzSB2nOZaWomJklf8Ag"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAEQ',1663085364257,'{"key":"VNQphWqA5AmsD2KjyRMX8/EHzdusDMvHAnXnOFa3jU4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"Og7lx5YSbqycT5eSMdbSoApCUuaKwr6HmTdwLMfLKDPyRjxvUCRWgZIX28uWAQjjCguXTCzWZl8aGn3rYXCuBQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAGg',1663085364304,'{"key":"scpwMzrRP0Jb/2vDCZowAci5nlv6nYb+KLq4ciLd1XA","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"L8oK503ootwUGYGHmoKOEsUV/xmFLUMTG5tCudv57F29zgKW+mCRYELF+p0EypuxvpMjdZzusSvDjT12yqh8Aw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAGQ',1663085364304,'{"key":"MrfYvz5c5GcLFGAOnZFqF671H3NAAUefVTqbC91g+14","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"t7CbBPav4uUkkG9v+C31oNiJzR+dlzivP9vMgLkO7nMAuJYuFix0RSu4DHywIBlQ3toUTf4ZYwBFlW7acz76CQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAGA',1663085364304,'{"key":"0X3Kwod3EQg9uMcgs62gsBDtN6UXkt/JpJoIvIEJSGA","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"d8HjS+CDrfRyIDqzNgazmePmbYF1qYeyBdtcUZy2xGPXNEmW6is1YKf8FthNiBJ+bX3bL88dz4A+NcBhaeC6BQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAFw',1663085364304,'{"key":"p87K18URNI/DWRIL0pQYtUGOto5OeTci5bXdG2O7xBI","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"+xjwFNciqcCtuzi1wIdqMZMeO/LsyDCRYGbXE7bJonejV5DCVCAjkDt/rsPfKpNKPg1GZWAY1Kt5bRrhp4XdDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAFg',1663085364304,'{"key":"CwHgel7LcPayhPmk/xaGk5sT2p0XX4arQ6KHnhi/v2w","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"+Gs/mJwRE2m1EY/phzlfb1BNASZMwto4ItUIQiDJAF04alknjZ7i3EPOmIH4m3fQCu4WwzSVqudG12345BHQCQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAHw',1663085364351,'{"key":"4BtUc97LIH+ZGqHnUfal+OpcD4kzNVYU8FJEBgtW6HU","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"mGSVIX4R1js54yYmRrfET4UVk7cAIl3in0ZqUsPky9NWVqOfJe0DW2Q4fg1FlOQgN39z4vUsPaON1qnC65ZPBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAHg',1663085364351,'{"key":"T5orI4hHUoIfR+zg2RDbRDuVPIQLiUoQO6z0IhxkAQ4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"HDEv5srFYgDTJQS0np19HhK3lpb8n9eaK72di3VrGOHN6S5TtvsMSOPMNkeO7HjeOWIukVUhvEsxtYvDRTijDQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAHQ',1663085364351,'{"key":"nSA1lYDWCcZqQL8YCgueb9jmsIJ8Xg89z1VUndVrKSw","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"VWTyaaiQWxfQS3DLEbHlI646L+l/bGkXX6XFMVggKu/m1rwxfbFaQgWZ7oBGmKsy2MQnVZIK7CBIP0ZB3elBBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAHA',1663085364351,'{"key":"bJCv+1zD6XA35/52KMY11u0JMpB2Mp7dyecPEfKGkl0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"GDIt6EV661aadsZv15yg2AR6u4MYDoO4WfxHRXVy9oJO4jKLULSkup7h0WZVb/QG4LO78L0qhhkQgtLshg7oDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAGw',1663085364351,'{"key":"xkYLd/Kjldmp/5E/gO81tK6bOrad0ZmrsrVe+nhi810","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"jXUTHrb5mydqZ++7wmIv4roTrFcNRo2w9yWGKXjL0BrHOCWEQiRChNWsXEuWsGjsPa4lU7jRdhZuA2J4C4SSAQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAJA',1663085364403,'{"key":"iWo21OooRn7ZK/lSQ/GDFsKrlf7WDeLQ2W98egDyVBo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"WfRK/etFFO3wWdVwGfZ9MG0nvSekZLLJHgLzqWCANlFANhzzYlgYzKXRJgh1u/sA0V98545LDYWQRgVUfpRhBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAIw',1663085364403,'{"key":"tKRsDjs4EUGIdhX8qXnk00AGv4G4rrt4nGb9Xk1c2Q4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"cP/fvRLJm9b6Fi3+el4l7L73rbKnZaxVH6WAQGwpfhC+5BKfrHH/NmVyVL1kTP5rabXCadfUcdR5LsabfvivCw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAIg',1663085364403,'{"key":"rVNqrfK3FuEroX642wJd9fs1niRzoY9w+etuOjjB7Ck","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"AyD58ypC4jyK8W3gobsrlN7Nagoe1jOUkGY3NkxECZaH4B8SlwjHDHoNpP0S4+pCN5Dzs90O9IeOgGlyG4uJBg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAIQ',1663085364403,'{"key":"6rO4FwQ0fbrpKfrmaFGv05rTh5m7ap+A8JV2bWc+YlM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"V7QIYPvfacfL2g+c3xC6Tq7zs8tpJvAGjq5BsMf0NyqQNsmFTF+zAht+0hxwuxjYhRYKy5BKBuCsAn+mZqUeCA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAIA',1663085364403,'{"key":"5gLJGpJsPZHR0JfpjpSC9pELjV2umJYofSvKT8eY2Xk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"8jx9cr376OBmcdQ859MQwJwD5eKGFmt8KFnLX+xI6PksEr++utdtFIHODFJ9j8Fbooq1mOSmYTCJYTeg0bchBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAKQ',1663085364449,'{"key":"Qh7oa7xpyaqCetsh9kGrVbR6qh90YaSHWw/FWW2IMxA","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"NWye7eRH8e8muzteJ6bRnMf2I5Br4PjI9jMWFFrkgHBqQx7SK6gODvGjF69bsoRbwhmF4jvvyDObeXxEFFaGAQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAKA',1663085364449,'{"key":"VSUIITg63HRNYLS1X+vPpJtxOVG58gBINc5x/VYgxjk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"GnXuVcT0szoyl/K3gkdhyczE+AFk+WkkJZZfttWtij8+4bVmsZzr/tKuPPr7Yb7vLnq36iIjn6LAImf8kljgAw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAJw',1663085364449,'{"key":"/8J1TMCIqRLEJMZn1rBfQkA1b/VjRSBGewrsn1ICVlo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"TtFdUwl0kBcQCS/1qE6Ts8vm6E4muFHoBx20b0WxY31ubYwkUnEqfJmzg+/pLZgJvCSAmGaN6WAToL3yRALcBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAJg',1663085364449,'{"key":"XZ7/b+5UQscgEMp1+U3iyZvQ5kecvKz9TF5XjbtKo1Y","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"M7P+sXRKut3f7xPkaFzvtTVFUOKAiij5rBztHifoFtWX3VnHgwpVdbbzeQ4zBadz3ZdKVd09O325oNEqzhEnDg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAJQ',1663085364449,'{"key":"J4fPcq14CrCIAK6ze8RqFUoFVCwcsMlhEQ1qVxHsZR0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"KJFEzscRJeY69ay84OGkLgI2KK6gkmbZMyxERoN6fTr9gjwUgI7FsT03iTva0NjGOIQQz2TIdt+YHtjVdo7FCQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAALg',1663085364493,'{"key":"7tzNZOUhbdzqboo9Hi0vXXOmKFRaYlTj21TVkCZ6/VU","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"mBn6VlU6WDFMOq/7JUZHrnansXw1L+OlyUe3PO8XZfKMNdpCvX5KX++r/D9a42BXnVQllyIMuKMUGXxRrpklDA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAALQ',1663085364493,'{"key":"SqPm9mvVaA5ibF/bK/iSNy3y+4O8p3O2+gkfIBzlFls","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"DYGk0rc7ugXJldkIpeetoOiG7Tli4f4M7SfcWDspatGxNajk7/7aQWsCoaJIt6TuvygUMBuCaB9VMEi7jJ5gAg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAALA',1663085364493,'{"key":"QidPMP8MuKMu4B3dkHE3JN6asfhpJsrq+S42CkbM6XA","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"/qspaz7+h1akVwGEtJraULleKLnWdKsqlxoX2LNAk4q9Fel4QVnm+t3yXhXmt2puTQ/wjwyBkFmQQd24NEBlBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAKw',1663085364493,'{"key":"47fGqrIZKQ5L/RVQdPr6XzKrULt1xh+qHI1uvTiPRRE","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"IVOlvpBGJiJTjtt7UnbBSaund/vsEABIikhfpdkvy1EbrlQdATAn1/YvayPAk0RIjYMl1ViQLHvwtJiGQI3lBg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAKg',1663085364493,'{"key":"ceI+RnR4eHjCOXsq8dgKIRMdWRf++0LgXGgoD5W4uXk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"lA1GeTB477QgvoBM/yIE3SYRSibnDNRjHxYSAPOpPPM89eVELt6NFBky1Jcz/axeT+UPZfMTlbButLU1HXNNBQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAMw',1663085364531,'{"key":"Hf0i0nrYtmami4HLsloG7y9m5rjmRUwBYKjAy27TXh0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"l/P5VTU7mRaHnwHRYo/hqKSfJCR1yY04jzwPl+f54W67G/aKy3itZltty7/UpZ9CQhAQ+D1aa8dB+II74B7EDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAMg',1663085364531,'{"key":"GPxYT2kgrEPL2WhtSP4Ur645bcaZGtotL5RxPKOhrDE","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"kT80Hr3xG56yb/WI89Hs4MZl+/BYpj9j0P7sTdWUyyF7nUBE/r0OoiyvkITywr1EA1tLhJQOUtj3SYeHEAm9DA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAMQ',1663085364531,'{"key":"m2NyzmHa6F28frrBDQe5RUQyTXmsogDWGnDchJn3anA","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"yi9qD0lUT5ObTjaVd0rMa3o56ikoq52FIibXJcdJx71DKBAWhgF75eX0/M+Hi7IsLG1DvTVpKwJemtyzqic5Ag"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAAMA',1663085364531,'{"key":"+TK/bfUqYey0LWLmOBq/Za87qUTR/qVLb29z6OGdqSw","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"epbsZVXBrDHIVTff6OxzGbc8WsxUBK1tIIDfJibA9RSJY5dtiBcQp4zv+IWyGsg4q19p/SdNZmmBcP12uQwODg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAALw',1663085364531,'{"key":"Q8ivwsFIPvvsum9HYY0pZ4R59sK2/2hV5BB+guHzHxs","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"fUhuAtwni/+ifFsRNq7VhaVvJH2wVfn0LOw6UfLhM0nqylXPlgHC3qmUxiUin+ejng9T7OMprEhuuWy8zbLDAA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAABQ',1663085501985,'{"key":"zgtdXQUAadwrmYZLj9Gw01tEyGqRH1GWpkefEFpPegw","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"EDx5RziwjEtzdMUMeUHR1VAMt6/smkzLs8zcYR4P/Ti3/Wq8REkK5HfHBiHzxEUum4Jhqkavml5iozWbGl2BAw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAABA',1663085501985,'{"key":"ho1b8q4lZSS73poHi9KWZ5hZhGNXO0m1MyIi/RZUH18","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"cF8zS6ejhbmkoRv8QtVKErxYs4dwZbDAaM5dDKAj9g+W9AgbK0xld2LVn4JokHY7ei0ylffVOPGdhqyWmO+gDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAAw',1663085501985,'{"key":"JUNZpnP4bwWU7ppfYsYcU9/XsOvzqxlCbEUiIAHNPy8","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"1Kv64jvp00frWRdfDstwSfx7pkHuYITxFTzi0f5d/lJTsDLPVK8o8PRPWZNStP6zA/dIc7X2TZKGWjoR0W+/Aw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAAg',1663085501985,'{"key":"gEAIxkRCRBWBS4NkCd83fPfBrYvgPszmlr1vH7xMmzo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"fPPjK6jxhaxd+Jrn3taqKNev5+WULRDErKkDItHHtwHnD58mpgRyaFG+GnhbDSzHhXHfeUYFhHtfB5RLEyVLBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAAQ',1663085501985,'{"key":"ZhjRbwqEIL7nJujhlQ9OpvamMYi0Vr0pSO6chtHk/34","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"2s0EGa4Exf0IYBmL0EFEzNYUlGi0v54gQqeG8FS/utjY+fyE24QxFf0pfKTCaaOq0EQokRZJzmsqP8WIZ/H7CQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAACw',1663085502024,'{"key":"/M6wN8qPKTZQyO+RhoWtmQyEZ2ZFjAUmE8/p6CaFBiQ","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"bsceISq0sbfaP9sc2OT7vUlo/DwLBeseQFQw7gVDrNAluLw0oMTCQpYZipfPcfhlvd4v5dDXuwXBfm3P5aW6CQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAACg',1663085502024,'{"key":"E4hn+qxa5xnKwI+z9X1NlHaX7tAYiYe1wNKcgKa1Tjo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"lhAMqKPNpmVR59DIZDP+XWafFOfgDfzcVeJ5UDajMopRVq/4NFhTD4NmwQ+TQ/wB8GQ07ORWD+m0pbqbZjE5DA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAACQ',1663085502024,'{"key":"aIvXzMobdvNkLXIXT8JbrPKzeDZXKi3ri5kkuOVczy8","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"pUW4r0p1ie0B9LZ/Zwm99CBZ27wwngoLODMRB+Ch9PtJv+kKCCFrus3xs3DRy0Fc9V+5ZiRw10jqBPFjKLgRBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAACA',1663085502024,'{"key":"I9eZlVeZiaHc7lxnyFwvXQkjXZw3YM7Lt2VY/XYddBw","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"Ng2Q+0A55oYru5IpKiFozWVzqMAn9DNxyUiOQ6SJBRTzX7zeTuGcZTVVzOnGVzwV788gx175OfPYPq2sqgGLCQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAABw',1663085502024,'{"key":"FIW5FIR9pmH5McxNw6gkL1Wlsi3LGv4E+lAQuqBiKFI","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"07z7nBtQXyfQwobXWvSvVG/6btgeFAWB3X2E/QPMdRM9TA9P0c033xANEU+S93I42xIj2/UMpRZwmvN2Rtq3Aw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAEA',1663085502058,'{"key":"YuLKrYxcunoPzDxpDsgw/VeOaOWIg8UBGrVMnyCx8xo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"62+jPVgB9wAM+9C0uLDI+rSL1igEYQi6MHXMRX4o373uENYOCc9s8EZAGvpSWeWm98pVDRemqfFJOc4LqCnDBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAADw',1663085502058,'{"key":"0lk4wjS6HqMbhuC7Bilo3QUXFNfy3mZMua6KaJqCM28","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"1Nt1AKa8FvL/FhJZueolD+7h7SYxG8XmaoCf4XGHsVOh3pTOEhHKGe55/d3V99w06bCan1Y+1iP9utXIW4BnAw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAADg',1663085502058,'{"key":"6pob4qDCyoBYbyrINP0qbMvr53VGx444C/8dy5gonWo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"Dt86BoOVHjDpMkZ/NecVON658+q2Fgiad8sULv4Abd2LSUZxqdNeEIfFk04jZ4tNsr66lyRVw7koJVkRcJDvAQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAADQ',1663085502058,'{"key":"C5rInSxeiZ05lAoRy9EBTlQMS9Ey3nzRZ2QfPB2qtmE","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"Dts7kwF/qld1sVcE/uYlyj0426wPP6Um5io4TSJdY1QZvQdpO950yQ2ZMMk7RlmqGPnWOLx4Reb5ZZqmPkrJBg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAADA',1663085502058,'{"key":"mCoAoJ/bBFJ2xtIyqlBbvtXr/hW2Y3KiV/vwc2/Q8VM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"Fvwt53H5xxQhqFusSLHjhzUikpBliL6b6/8q+uD0+/LOnAQdTgiH10aNu9oVNWszQbLd+CC8BHzIdSX9K7bSAg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAFQ',1663085502095,'{"key":"yB1WjRSpUW3jT041HA7evHdukWmUvyrwAYel7wHOhys","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"OOxsbS78pOqlhAATYqmbx4olqmAioXujeYhfDHqkWH93ZE42POCf5wStKQ2MRABDnTMj805G7H8ar+vW/h3+Ag"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAFA',1663085502095,'{"key":"lq9ifTlhLe4BZ5cBkKXY7cVQEFyxsVA3uQ8RG8yjdCY","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"BQnphsC8UbgiDJbqQjMczx4NdbLJ5/KPN7V1LiNHmdXY6s9U9AoSZRcoCu9tA92fvcBUbV1VBDPeF4LAlJFkAQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAEw',1663085502095,'{"key":"f/G5iWzonKhqImwoCG2SOrapzvlj/JyUguwurDn4QGY","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"v2nqSYu4ctf3tLa0XPCSu/zpa+VriIFoawrxyluzI1xXaX/5QXEqrjPAm5mqQAGGGs0jpz3OmaniG1MEV8KvDg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAEg',1663085502095,'{"key":"sLErOWqVwsUN20WccILu3U8uKg6nvHKgJnRnujhWZyQ","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"CDXlWd2JBedhksUWKT31Qj/UpRNi4q4v+DNPrhH0+/5Qjek8IPuPNYJRtnWwlaV3B0ShMdQSZcc9EqiBDDuYBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAEQ',1663085502095,'{"key":"ooNrWGez65M7Xibt3/985wDjVY9/LcSjmgzGWR4h+wM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"DfLt5vTf8VG5cKxUpzkpwESZ1f1ocNv2OSHPkFk5qvvc/4HKUBVWGIzA5Pr1IL1rNt3haL0IIZh7NJ+hkIdNBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAGg',1663085502131,'{"key":"hbjS4U+JSGDbUNrN4o7vCXe2YKqjA6Q0PCQ974h3xUM","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"gOm9a8E7vCtYG2REGk9+bODftFMr52S5hd+2iHGkonY6MR6KkqUlkUlG+j/PJWSzdLr/UMQKpVvraoXYfVazAg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAGQ',1663085502131,'{"key":"7B232ecjJxkcdUwWvcRj82I50uDOYr6WV0iPuVrwdWY","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"IpQmtXGlQjKu+OmK3ROzZ7hxeqdT6DKDHk57VFTT/KZJEyJDATY3fGBMIKWyE49/FFskWzCneLlGU8Fa6CWtAA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAGA',1663085502131,'{"key":"DuAoWW/o4PYZAkIOibSrEaROq4/hmPW3D32OGsYxxSc","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"Ia1h4JluB9EREMnuaDyGt5mEgs14MozcDDTuoTy/T4x4x/8mYznIEUZFf/0tcfjYV5bhb5MUO+S/IkeqlBL4CQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAFw',1663085502131,'{"key":"1c6Vy4RPW6kSRs65ovxzNbvv4kufyf+XmSfC9vAflkk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"Bbl4pbQ6hcqLYKI2k9ODh7nt3nfzDojTbvX9vKXzVFcqjOIUQZB4Vjog89Ty4b/7o5SSrmp5rOGMQ7K6YZoZBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAFg',1663085502131,'{"key":"VLyhQU47bfrtl2h3t1rVCNa0isoUXqxb+GkLIqJ0U1k","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"J65I4T+kO+Ml7nSARnqBezYkvoIbdAwRrlAMUBrMfZuC+nwz8bhpJaZdu5c7e8pZgo7DVwdDDaBO2sYbKT1ABg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAHw',1663085502170,'{"key":"OXmi7Su/o2z99Hpkk9xtRvIrdExurHJqqF0Tfx02Hxo","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"ypPSdTxuXr2/GHEWnfsa/NuXCcaEigWG5VgdwJhQmuGVRLV/m8Ve1++EF0mV1DClXipybfVbZHPacI5Sf+aRBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAHg',1663085502170,'{"key":"bVuvyGiBLheGxfQLMty1mroNOrgHQgy3MC+OvEyfNQA","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"1Zn1ZqLMQAPIOPiDnwXLoEj89dDQKmCqDavlaFnvanAb7gIan+oZDPDMkeDR3NjbvXm8PbNZ0gZOmub8SbglBA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAHQ',1663085502170,'{"key":"tsFQa9+3SG+InUqFHrqJ4H3GQRNZUoxegDK0QcdPM3w","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"hF9E7pG35Ln9Flh4CefXXafTfZYj/pxznXXSfxadwxLslCr+liKtUWQYxS01C0Jh6mSWH0ywb2ZWTVVTo/b6DQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAHA',1663085502170,'{"key":"qjoW8hkpkngn1P1j0f9S5cT758K9GdunNamHdVUJdT4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"KqqaIybgD4v99xfZg5CLD8yVrgIPQRSslt9hxHh9HK87KNb47LUA8KaBcFNUXMD5glPo4Ne74Uc0jB+PB/cqCw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAGw',1663085502170,'{"key":"wqf6go6Wt2WHcpvrYG3vixDvSQj/huFi80l5dnBxvFg","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"jyRrhpcDxANgyNxYgrlNozR7u0U52QTp0zCDz6lDm4B8xGKCQ8bXNDfcVICRk711D3jIqwcMoINum8PCcRfFBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAJA',1663085502203,'{"key":"AdV2Bla5z0sgH4gjotDNVvakCVCh6KvOULhbbI5fgF0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"BDNO4huGSFRoF0fUkBEPFtY7G7yHQ1z+mW8X/Jq79FjM7tB1f7n8ull8qUJ4P/TDu7Fv4vCJ7N5NaE91cG+DAQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAIw',1663085502203,'{"key":"lKVAFB3yT+O7ztiogOCYZvrR744+qfvBQazV16MdOgg","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"nKnItbmHCspOIbKcWLunrC1w34kKZkOmmnZ2shjPsAlXYu+x4F5N9w0cEXGGgBT5YRMdcW2C5O+YbCBhcYKqAg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAIg',1663085502203,'{"key":"g771Blq0aAgZOXOZdT+/G9BPWNuOdpINOXNVhRsT02A","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"1CXYeQSbYGchuIbsNkMNrFMQlXO9orNgtS9tDGNTMn8gH1bisPDF2wLLH1Ooyq4+yDHIySUEfUx4Rq3xbNFODA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAIQ',1663085502203,'{"key":"IOyWInXYeGsXKZZBBB6WQvv+2zwEDSFi6Qc4HEVz1S0","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"2UxOdlbdfPU7GEVgTJLbDsqcra0O4K8TX1DE94fsamA2i3t188cr6H/0run5NqJEUoqnpvQ8wcu/BCuooJ/XCg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAIA',1663085502203,'{"key":"9OtUBVSfIx75Z9sy3oo5lsN71qon5BxEw4UoZsMKmWk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"guT12JrteIxtsLogz1fbUtx7DcTroqmKt6patJjf5UNYkJnJg0Ag4tbuLzGES+NilePsuZ8X8r2pQ9yYuERtDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAKQ',1663085502247,'{"key":"GfFk8Uz6J4MIMpHoFdCGrd0Ho8yuykLK8JBWwxiwzHY","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"VHuZXrEfRxBRM71M6RZ2VGXf3u1BP7/tk7E4chTvgd1Iut+Bp9aRv//aqz7F+/f2JYBB7QBLwXh9o98f6i6/AA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAKA',1663085502247,'{"key":"MH3pC4LUxfcTiCLnRTnDTd9A5tHn5P1RhSzzBp8+WTs","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"XaPnbAd0yC82sW1oszUjNbxCg45zfubuV+zrrilyPFLspiDJUvx4+m6k3arHgPfVz72YQ8Tk0gFbLQI3LsRWBg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAJw',1663085502247,'{"key":"yXTPqfYdQ5uHb14zsQCR9fhMgdtUQ6CxhThW4tZC5V8","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"GRpH35/cgYCABlRDZA31pHOwxMCLKNP/00xVbMtk8Lu7MIcAa4put5M/QshPzeRacEGP9vM+JfuJ+KanipqiAw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAJg',1663085502247,'{"key":"S/BEQurMAdKUNdKSSwr/NGWLlEo0OctP028DN5apKhk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"+VaPmVE9hnFIHUjmxLQshFNF4hbviciPms9wGoRzvAWxaLfK7pp7tUUzsyCbyW4bkfkvej5O3i3nmCewKzj0DQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAJQ',1663085502247,'{"key":"nF3NeE4D067r3SAEPHaSLwlLr0cLrwn9coPtC5colCw","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"IbxpY4XaaePGn0Ul1X4AKRcpGvXK6ML1r9Zgk5BxgMSbmumtJH0X77azgY4IesZxgM2DiA1I/+wa+JkRsrHEDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAALg',1663085502291,'{"key":"A4e6sVMJ9/cU1FQxUGQPz+vZGvv9SdOc7y7iy02unW4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"A7eop4A/7GXYHNVeTcXavwnSH5L+miD9mSFqBI/kR8xX8C1QgS/zfwcHsmNVgZfErI9VHnn0yOV2iBwJib8vAA"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAALQ',1663085502291,'{"key":"1aCMLc+LUtVxJFq/YUzbZPNQ6fDgnB30EZv85Pim2Xc","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"WbhPWv8435vNm3nvQG9SiaG+tvI/y3a7b1Cdviq61YEpLAWiK677Q8j9Q++mfBopLJjRI1tJtMxgDUt6PMIFAg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAALA',1663085502291,'{"key":"5dpd69+q0cY/mWRXX+Fb8x54d+uGpE+T5uBhIJbTyUg","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"2d6V8/yZbpDScJEiTBpLPJ4zU1GaBosRhn9iJOwP11Zau4qg1g+zhZAxSDPhJxJXzN2ePRLAoX3z0BscLYRYDw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAKw',1663085502291,'{"key":"skKjO1Vyoo9a+j1dIj1kZ5SqZzbVOT1mADaRZqq6JRs","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"VKsFXa0Nn+vWh552Z4Gosmo4hAyisRNOf8uWE82pIfhHJxqAgNzUaDpX7Jsy+2NdhmfW9Y/Sl+MdUrKLn0AlAQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAKg',1663085502291,'{"key":"6CbH62N1tvFtGZQ30YBi9fdkw6X84nR6Q/Kg3QWMRRI","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"rSwCKoXRXsL0dsaKEZN422k0mQP0iV3z6lCjHSZETsS7u2Psq2p5Vkdz0lHRaxdngrTMYEIKunbR8x20mREaBw"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAMw',1663085502337,'{"key":"stwkWpAM2Wv94p0iD3gsKXJrJQExsUnHiOvYsevzVU4","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"xv7DCW4U0AmLO7lxeLdUoiC5Q5T+5jN/sjA8V2Q9oX1+lFApKnWE1txhUL9g7ifFmnL5sLewTAEauBzZw62LDg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAMg',1663085502337,'{"key":"GXf1ZBVwd5J5mTtacvGc4qu0moESMFcufsWX3MbNBjI","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"bZdIVSGt0CpQDAwPmiZVpujS0DrO7Y5ZCoEIu1wLo7AN2yNknZJtKCT4MVjsjMinFJGqvmUDEYGxEbKvvf9LCQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAMQ',1663085502337,'{"key":"X7eTSKCWtQEnDAJtt5Pay8JjE/hmB7res2RWDPn2jhs","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"OvW8rq7I0zWYdU2IQCgWNeutzuLkQczTSGz4ikKgOkT9n4Bp3d2lRZypHZfYI0uufR4nkrEiwu22/fRXJrj4CQ"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAAMA',1663085502337,'{"key":"faPPKhOj0OMEbO78xRVjbjqM2oMlbct0MjWMAVe4rzE","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"+vCaXnrYJ3+aPL9hNCKTuAY9+GQPXA3W03+UHJgSGn3qecDNWzG6oj0adLD4BDBxYfmn8xOOYtehWiiWuiQ2Bg"}}}');
INSERT INTO "e2e_one_time_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAALw',1663085502337,'{"key":"ldefRtgzWpaHHyY+Nvlcp/mU3IkPLgwQq8S6NJUuzzk","signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"2VdjZ+8TCoMi2bngQoZ7b1IF8adInhaWUWKPI/TZl/4chS5y855ZP7iFJFelsKJzu99DoB05NjWQqb55D78cCQ"}}}');
INSERT INTO "event_search" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,'content.name','Bobs Spielwiese');
INSERT INTO "event_search" VALUES ('$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,'content.body','hallo');
INSERT INTO "event_search" VALUES ('$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,'content.body','voll viel los hier');
INSERT INTO "event_search_content" VALUES (1,'$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,'content.name','Bobs Spielwiese');
INSERT INTO "event_search_content" VALUES (2,'$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,'content.body','hallo');
INSERT INTO "event_search_content" VALUES (3,'$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',NULL,'content.body','voll viel los hier');
INSERT INTO "event_search_segdir" VALUES (0,0,0,0,'0 181',X'0004626f62730501010402000007636f6e74656e7405010103020000026465050101010500010d69676974616c6d65646361726505010101040000126a6478757164647569796d666f6b61746d6c05010101020000116d303871783130767a64336877367a7361030102000105617472697805010101030000046e616d6505010103030000196f7835756a31626566346666637670796866336b756a65386503010300000a737069656c7769657365050101040300');
INSERT INTO "event_search_segdir" VALUES (0,1,0,0,'0 165',X'0004626f64790502010303000007636f6e74656e7405020103020000026465050201010500010d69676974616c6d656463617265050201010400000568616c6c6f05020104020000126a6478757164647569796d666f6b61746d6c05020101020000056b766a39790302030000066d617472697805020101030000257479316362656f69777172707a75796b693769326c627933693468386e6833626f746d6b6503020200');
INSERT INTO "event_search_segdir" VALUES (0,2,0,0,'0 200',X'0004626f64790503010303000007636f6e74656e74050301030200001f6464393179626630636166706c74726f6e6773386e31356a3177656f63797503030400010165050301010500010d69676974616c6d65646361726505030101040000076869626c767576030303000202657205030104050000126a6478757164647569796d666f6b61746d6c05030101020000036c6f7305030104040000066d617472697805030101030000047669656c05030104030001036f6c6c050301040200000378346803030200');
INSERT INTO "event_search_docsize" VALUES (1,X'0204000202');
INSERT INTO "event_search_docsize" VALUES (2,X'0204000201');
INSERT INTO "event_search_docsize" VALUES (3,X'0304000204');
INSERT INTO "event_search_stat" VALUES (0,X'03070c000607d202');
INSERT INTO "account_data" VALUES ('@bob:matrix.digitalmedcare.de','im.vector.analytics',2,'{"pseudonymousAnalyticsOptIn":false}',NULL);
INSERT INTO "account_data" VALUES ('@bob:matrix.digitalmedcare.de','im.vector.setting.breadcrumbs',3,'{"recent_rooms":["!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de"]}',NULL);
INSERT INTO "room_account_data" VALUES ('@bob:matrix.digitalmedcare.de','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.fully_read',6,'{"event_id":"$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU"}',NULL);
INSERT INTO "presence_stream" VALUES (19,'@bob:matrix.digitalmedcare.de','online',1663085718001,1663085718001,1663085717957,NULL,1,'master');
INSERT INTO "appservice_stream_position" VALUES ('X',0);
INSERT INTO "stream_ordering_to_exterm" VALUES (2,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM');
INSERT INTO "stream_ordering_to_exterm" VALUES (3,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w');
INSERT INTO "stream_ordering_to_exterm" VALUES (4,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM');
INSERT INTO "stream_ordering_to_exterm" VALUES (5,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM');
INSERT INTO "stream_ordering_to_exterm" VALUES (6,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4');
INSERT INTO "stream_ordering_to_exterm" VALUES (7,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY');
INSERT INTO "stream_ordering_to_exterm" VALUES (8,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E');
INSERT INTO "stream_ordering_to_exterm" VALUES (9,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y');
INSERT INTO "stream_ordering_to_exterm" VALUES (10,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU');
INSERT INTO "event_auth" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "event_auth" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "federation_stream_position" VALUES ('federation',-1,'master');
INSERT INTO "federation_stream_position" VALUES ('events',10,'master');
INSERT INTO "device_lists_stream" VALUES (2,'@bob:matrix.digitalmedcare.de','NHZJZJAWJL');
INSERT INTO "device_lists_stream" VALUES (6,'@bob:matrix.digitalmedcare.de','pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY');
INSERT INTO "device_lists_stream" VALUES (7,'@bob:matrix.digitalmedcare.de','A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s');
INSERT INTO "device_lists_stream" VALUES (9,'@bob:matrix.digitalmedcare.de','WTWNFTOZVM');
INSERT INTO "device_lists_stream" VALUES (11,'@bob:matrix.digitalmedcare.de','VLNNCVZHMQ');
INSERT INTO "device_lists_stream" VALUES (13,'@bob:matrix.digitalmedcare.de','LHXCHFEPBN');
INSERT INTO "event_push_summary_stream_ordering" VALUES ('X',10);
INSERT INTO "current_state_delta_stream" VALUES (2,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.create','','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM',NULL,'master');
INSERT INTO "current_state_delta_stream" VALUES (3,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.member','@bob:matrix.digitalmedcare.de','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w',NULL,'master');
INSERT INTO "current_state_delta_stream" VALUES (4,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.power_levels','','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM',NULL,'master');
INSERT INTO "current_state_delta_stream" VALUES (5,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.canonical_alias','','$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM',NULL,'master');
INSERT INTO "current_state_delta_stream" VALUES (6,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.join_rules','','$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4',NULL,'master');
INSERT INTO "current_state_delta_stream" VALUES (7,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.history_visibility','','$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY',NULL,'master');
INSERT INTO "current_state_delta_stream" VALUES (8,'!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','m.room.name','','$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E',NULL,'master');
INSERT INTO "user_directory_stream_pos" VALUES ('X',10);
INSERT INTO "user_directory_search" VALUES ('@bob:matrix.digitalmedcare.de','@bob:matrix.digitalmedcare.de bob');
INSERT INTO "user_directory_search_content" VALUES (1,'@bob:matrix.digitalmedcare.de','@bob:matrix.digitalmedcare.de bob');
INSERT INTO "user_directory_search_segdir" VALUES (0,0,0,0,'0 61',X'0003626f6207010201010206000002646506010501010500010d69676974616c6d6564636172650601040101040000066d617472697806010301010300');
INSERT INTO "user_directory_search_docsize" VALUES (1,'');
INSERT INTO "user_directory_search_stat" VALUES (0,'>');
INSERT INTO "user_directory" VALUES ('@bob:matrix.digitalmedcare.de',NULL,'bob',NULL);
INSERT INTO "user_daily_visits" VALUES ('@bob:matrix.digitalmedcare.de','WTWNFTOZVM',1663027200000,'Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0');
INSERT INTO "user_daily_visits" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN',1663027200000,'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36');
INSERT INTO "user_daily_visits" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ',1663027200000,'Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0');
INSERT INTO "users_in_public_rooms" VALUES ('@bob:matrix.digitalmedcare.de','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de');
INSERT INTO "devices" VALUES ('@bob:matrix.digitalmedcare.de','NHZJZJAWJL',NULL,NULL,NULL,NULL,0);
INSERT INTO "devices" VALUES ('@bob:matrix.digitalmedcare.de','pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY','master signing key',NULL,NULL,NULL,1);
INSERT INTO "devices" VALUES ('@bob:matrix.digitalmedcare.de','A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s','self_signing signing key',NULL,NULL,NULL,1);
INSERT INTO "devices" VALUES ('@bob:matrix.digitalmedcare.de','bluxh67OgPmW5uxJXAnWgYU7Xn+ef4gcytfwBXvqZOQ','user_signing signing key',NULL,NULL,NULL,1);
INSERT INTO "devices" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','app.element.io (Firefox, Linux)',1663085623837,'93.236.236.173','Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0',0);
INSERT INTO "devices" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','app.element.io (Chrome, Linux)',1663085623833,'93.236.236.173','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',0);
INSERT INTO "e2e_cross_signing_keys" VALUES ('@bob:matrix.digitalmedcare.de','master','{"user_id":"@bob:matrix.digitalmedcare.de","usage":["master"],"keys":{"ed25519:pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY":"pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:WTWNFTOZVM":"k1jzlKiGG/GlRoRemXpY2lrl1bdMVevQbRAsY9I1bhawnjuRkVHCYH9ergWZAEN/cQPUNnBlogaJKLEQvUkjBQ"}}}',2);
INSERT INTO "e2e_cross_signing_keys" VALUES ('@bob:matrix.digitalmedcare.de','self_signing','{"user_id":"@bob:matrix.digitalmedcare.de","usage":["self_signing"],"keys":{"ed25519:A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s":"A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY":"7mtYOB9CAtfuhn54LQ2J8jd0DYFjhyCGVhpuQuHvKRVT1I4PlC4L+WYeu+A77bch56IwQOdrchDPyUBczKloAg"}}}',3);
INSERT INTO "e2e_cross_signing_keys" VALUES ('@bob:matrix.digitalmedcare.de','user_signing','{"user_id":"@bob:matrix.digitalmedcare.de","usage":["user_signing"],"keys":{"ed25519:bluxh67OgPmW5uxJXAnWgYU7Xn+ef4gcytfwBXvqZOQ":"bluxh67OgPmW5uxJXAnWgYU7Xn+ef4gcytfwBXvqZOQ"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY":"l2xSATgOu/XdlUMTGDaDan5+Q6XEZUE0I2AollRn7j8are1llPgJt94Gi49ruvAiK9wEQzyt9xejKuXxrsxtAA"}}}',4);
INSERT INTO "e2e_cross_signing_signatures" VALUES ('@bob:matrix.digitalmedcare.de','ed25519:A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s','@bob:matrix.digitalmedcare.de','WTWNFTOZVM','cX8NgV5dInaJRsOKNIoPbjGGTAw836eVK+afTi9exbShsnkJllfiePj5vHCftvDncrrIbz+j5UtH8NkB8Zr9BQ');
INSERT INTO "user_signature_stream" VALUES (5,'@bob:matrix.digitalmedcare.de','["@bob:matrix.digitalmedcare.de"]');
INSERT INTO "stats_incremental_position" VALUES ('X',10);
INSERT INTO "room_stats_current" VALUES ('!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',7,1,0,0,0,1,8,0);
INSERT INTO "user_stats_current" VALUES ('@bob:matrix.digitalmedcare.de',1,3);
INSERT INTO "room_stats_state" VALUES ('!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','Bobs Spielwiese','#bobsraum:matrix.digitalmedcare.de','public','shared',NULL,NULL,NULL,1,NULL,NULL);
INSERT INTO "user_filters" VALUES ('bob',0,'{"room":{"state":{"lazy_load_members":true}}}');
INSERT INTO "local_current_membership" VALUES ('!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de','@bob:matrix.digitalmedcare.de','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','join');
INSERT INTO "ui_auth_sessions" VALUES ('JEJmnTqCVKvSkqjhIgvAgRqT',1663085076663,'{"request_user_id":"@bob:matrix.digitalmedcare.de"}','{"master_key":{"user_id":"@bob:matrix.digitalmedcare.de","usage":["master"],"keys":{"ed25519:pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY":"pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:WTWNFTOZVM":"k1jzlKiGG/GlRoRemXpY2lrl1bdMVevQbRAsY9I1bhawnjuRkVHCYH9ergWZAEN/cQPUNnBlogaJKLEQvUkjBQ"}}},"self_signing_key":{"user_id":"@bob:matrix.digitalmedcare.de","usage":["self_signing"],"keys":{"ed25519:A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s":"A2hpCN5qyb2Aza27r+/KKqOXFphd1pdbRV+wQcQb+1s"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY":"7mtYOB9CAtfuhn54LQ2J8jd0DYFjhyCGVhpuQuHvKRVT1I4PlC4L+WYeu+A77bch56IwQOdrchDPyUBczKloAg"}}},"user_signing_key":{"user_id":"@bob:matrix.digitalmedcare.de","usage":["user_signing"],"keys":{"ed25519:bluxh67OgPmW5uxJXAnWgYU7Xn+ef4gcytfwBXvqZOQ":"bluxh67OgPmW5uxJXAnWgYU7Xn+ef4gcytfwBXvqZOQ"},"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:pQzHkADHSV3GjJDC3tSUZ8zy9IpvDBDDR7zAm6us/cY":"l2xSATgOu/XdlUMTGDaDan5+Q6XEZUE0I2AollRn7j8are1llPgJt94Gi49ruvAiK9wEQzyt9xejKuXxrsxtAA"}}}}','/_matrix/client/unstable/keys/device_signing/upload','POST','add a device signing key to your account');
INSERT INTO "ui_auth_sessions" VALUES ('xLmkTsaQyCDHeJPXCwhJciUF',1663085367145,'{"request_user_id":"@bob:matrix.digitalmedcare.de"}','{}','/_matrix/client/unstable/keys/device_signing/upload','POST','add a device signing key to your account');
INSERT INTO "ui_auth_sessions" VALUES ('BWheDqdMMZiJdZYbyDCtgKnh',1663085503224,'{"request_user_id":"@bob:matrix.digitalmedcare.de"}','{}','/_matrix/client/unstable/keys/device_signing/upload','POST','add a device signing key to your account');
INSERT INTO "ui_auth_sessions_credentials" VALUES ('JEJmnTqCVKvSkqjhIgvAgRqT','m.login.password','"@bob:matrix.digitalmedcare.de"');
INSERT INTO "ui_auth_sessions_ips" VALUES ('JEJmnTqCVKvSkqjhIgvAgRqT','93.236.236.173','Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0');
INSERT INTO "ui_auth_sessions_ips" VALUES ('xLmkTsaQyCDHeJPXCwhJciUF','93.236.236.173','Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0');
INSERT INTO "ui_auth_sessions_ips" VALUES ('BWheDqdMMZiJdZYbyDCtgKnh','93.236.236.173','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36');
INSERT INTO "e2e_fallback_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','signed_curve25519','AAAABg','{"key":"LwGQtgMJvtjmE7It1PiXYT1UpI1ljvf5C5QCmeOMJmQ","fallback":true,"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:VLNNCVZHMQ":"tzHyXDUi0LYM+1oIbvtarx1EAnNKdVuXXh4KgUAaw8wSAXh3x+ulimJuZzNfarTDjgTYrGc/AZKME5cw/0DCBQ"}}}',0);
INSERT INTO "e2e_fallback_keys_json" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','signed_curve25519','AAAABg','{"key":"O6ca3lQaew/ki2wEaGpH+ts+oKbvB/QG8boLqgk1qCg","fallback":true,"signatures":{"@bob:matrix.digitalmedcare.de":{"ed25519:LHXCHFEPBN":"BeKnLr2maiTmCgtfuwo13F60ULP+c+Xoh9Rb2QB0SxBoaovfXRJKVQJReU2N0AvtdIYsoTXbPf5AZ564LA2VDA"}}}',0);
INSERT INTO "access_tokens" VALUES (2,'@bob:matrix.digitalmedcare.de','NHZJZJAWJL','syt_Ym9i_EBqTdJHCNvikpnrTheok_1O6WKB',NULL,NULL,1663084632521,NULL,0);
INSERT INTO "access_tokens" VALUES (4,'@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','syt_Ym9i_MFWOpdadcXYRJaAlQvjF_3v7PwY',NULL,NULL,1663085363632,NULL,1);
INSERT INTO "access_tokens" VALUES (5,'@bob:matrix.digitalmedcare.de','LHXCHFEPBN','syt_Ym9i_nRTSyYHVNHDdUGlFWhNB_1El1II',NULL,NULL,1663085501673,NULL,1);
INSERT INTO "event_auth_chains" VALUES ('$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM',1,1);
INSERT INTO "event_auth_chains" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w',2,1);
INSERT INTO "event_auth_chains" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM',3,1);
INSERT INTO "event_auth_chains" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM',4,1);
INSERT INTO "event_auth_chains" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4',5,1);
INSERT INTO "event_auth_chains" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY',6,1);
INSERT INTO "event_auth_chains" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E',7,1);
INSERT INTO "event_auth_chain_links" VALUES (2,1,1,1);
INSERT INTO "event_auth_chain_links" VALUES (3,1,1,1);
INSERT INTO "event_auth_chain_links" VALUES (3,1,2,1);
INSERT INTO "event_auth_chain_links" VALUES (4,1,2,1);
INSERT INTO "event_auth_chain_links" VALUES (4,1,3,1);
INSERT INTO "event_auth_chain_links" VALUES (4,1,1,1);
INSERT INTO "event_auth_chain_links" VALUES (5,1,3,1);
INSERT INTO "event_auth_chain_links" VALUES (5,1,1,1);
INSERT INTO "event_auth_chain_links" VALUES (5,1,2,1);
INSERT INTO "event_auth_chain_links" VALUES (6,1,2,1);
INSERT INTO "event_auth_chain_links" VALUES (6,1,3,1);
INSERT INTO "event_auth_chain_links" VALUES (6,1,1,1);
INSERT INTO "event_auth_chain_links" VALUES (7,1,3,1);
INSERT INTO "event_auth_chain_links" VALUES (7,1,1,1);
INSERT INTO "event_auth_chain_links" VALUES (7,1,2,1);
INSERT INTO "device_lists_changes_in_room" VALUES ('@bob:matrix.digitalmedcare.de','WTWNFTOZVM','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',9,1,'{}');
INSERT INTO "device_lists_changes_in_room" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',10,1,'{}');
INSERT INTO "device_lists_changes_in_room" VALUES ('@bob:matrix.digitalmedcare.de','VLNNCVZHMQ','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',11,1,'{}');
INSERT INTO "device_lists_changes_in_room" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',12,1,'{}');
INSERT INTO "device_lists_changes_in_room" VALUES ('@bob:matrix.digitalmedcare.de','LHXCHFEPBN','!jDxuqdduiYmFOkaTmL:matrix.digitalmedcare.de',13,1,'{}');
INSERT INTO "event_edges" VALUES ('$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w','$4C2TVcpYzpdbcxLLNUq1yeKG8PVRP8CDib3IyDQ48UM',NULL,0);
INSERT INTO "event_edges" VALUES ('$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM','$keocc7OKm3lBHjJpV7ZdD52umbSc-cPb5EeEFz7iE-w',NULL,0);
INSERT INTO "event_edges" VALUES ('$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM','$MbeqmSTgT5NCO-rFKs-Z8Y-h_2L0TFEnQJowyUKqNoM',NULL,0);
INSERT INTO "event_edges" VALUES ('$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4','$2LG8BazCzAGFSw5jxH6fQkd8CyQzo2kxQl3nlozWAZM',NULL,0);
INSERT INTO "event_edges" VALUES ('$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY','$ugoI0UwDJZEAna5FWuqIYeF0z9KnHUzfYrrsHkJ6Yn4',NULL,0);
INSERT INTO "event_edges" VALUES ('$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E','$5qC_OH7MMSzO7bzJYLtKEOLoBmFz3JxxKJJdylAnXlY',NULL,0);
INSERT INTO "event_edges" VALUES ('$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y','$m08QX10VzD3hW6ZSA-oX5Uj1BEF4FfcvPyHf3kujE8E',NULL,0);
INSERT INTO "event_edges" VALUES ('$X4H-hIblVUV_Dd91YBF0caFPltrongS8N15j1weOCyU','$TY1cBEoIWQrpzuYki7I2lby3i4h8NH3bOtMKE_KvJ9Y',NULL,0);
INSERT INTO "event_push_summary_last_receipt_stream_id" VALUES ('X',1);
CREATE INDEX IF NOT EXISTS "state_group_edges_prev_idx" ON "state_group_edges" (
	"prev_state_group"
);
CREATE INDEX IF NOT EXISTS "state_groups_state_type_idx" ON "state_groups_state" (
	"state_group",
	"type",
	"state_key"
);
CREATE INDEX IF NOT EXISTS "application_services_txns_id" ON "application_services_txns" (
	"as_id"
);
CREATE INDEX IF NOT EXISTS "events_order_room" ON "events" (
	"room_id",
	"topological_ordering",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "room_memberships_room_id" ON "room_memberships" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "room_memberships_user_id" ON "room_memberships" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "push_rules_user_name" ON "push_rules" (
	"user_name"
);
CREATE INDEX IF NOT EXISTS "push_rules_enable_user_name" ON "push_rules_enable" (
	"user_name"
);
CREATE INDEX IF NOT EXISTS "ev_extrem_room" ON "event_forward_extremities" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "ev_extrem_id" ON "event_forward_extremities" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "ev_b_extrem_room" ON "event_backward_extremities" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "ev_b_extrem_id" ON "event_backward_extremities" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "redactions_redacts" ON "redactions" (
	"redacts"
);
CREATE INDEX IF NOT EXISTS "room_aliases_id" ON "room_aliases" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "room_alias_servers_alias" ON "room_alias_servers" (
	"room_alias"
);
CREATE INDEX IF NOT EXISTS "receipts_linearized_id" ON "receipts_linearized" (
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "receipts_linearized_room_stream" ON "receipts_linearized" (
	"room_id",
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "user_threepids_user_id" ON "user_threepids" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "account_data_stream_id" ON "account_data" (
	"user_id",
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "room_account_data_stream_id" ON "room_account_data" (
	"user_id",
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "events_ts" ON "events" (
	"origin_server_ts",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "event_push_actions_room_id_user_id" ON "event_push_actions" (
	"room_id",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "events_room_stream" ON "events" (
	"room_id",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "public_room_index" ON "rooms" (
	"is_public"
);
CREATE INDEX IF NOT EXISTS "receipts_linearized_user" ON "receipts_linearized" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "event_push_actions_rm_tokens" ON "event_push_actions" (
	"user_id",
	"room_id",
	"topological_ordering",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "presence_stream_id" ON "presence_stream" (
	"stream_id",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "presence_stream_user_id" ON "presence_stream" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "push_rules_stream_id" ON "push_rules_stream" (
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "push_rules_stream_user_stream_id" ON "push_rules_stream" (
	"user_id",
	"stream_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "threepid_guest_access_tokens_index" ON "threepid_guest_access_tokens" (
	"medium",
	"address"
);
CREATE INDEX IF NOT EXISTS "event_push_actions_stream_ordering" ON "event_push_actions" (
	"stream_ordering",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "open_id_tokens_ts_valid_until_ms" ON "open_id_tokens" (
	"ts_valid_until_ms"
);
CREATE INDEX IF NOT EXISTS "device_inbox_user_stream_id" ON "device_inbox" (
	"user_id",
	"device_id",
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "received_transactions_ts" ON "received_transactions" (
	"ts"
);
CREATE INDEX IF NOT EXISTS "device_federation_outbox_destination_id" ON "device_federation_outbox" (
	"destination",
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "device_federation_inbox_sender_id" ON "device_federation_inbox" (
	"origin",
	"message_id"
);
CREATE INDEX IF NOT EXISTS "stream_ordering_to_exterm_idx" ON "stream_ordering_to_exterm" (
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "stream_ordering_to_exterm_rm_idx" ON "stream_ordering_to_exterm" (
	"room_id",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "evauth_edges_id" ON "event_auth" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "user_threepids_medium_address" ON "user_threepids" (
	"medium",
	"address"
);
CREATE UNIQUE INDEX IF NOT EXISTS "appservice_room_list_idx" ON "appservice_room_list" (
	"appservice_id",
	"network_id",
	"room_id"
);
CREATE INDEX IF NOT EXISTS "device_federation_outbox_id" ON "device_federation_outbox" (
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_stream_id" ON "device_lists_stream" (
	"stream_id",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_outbound_pokes_id" ON "device_lists_outbound_pokes" (
	"destination",
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_outbound_pokes_user" ON "device_lists_outbound_pokes" (
	"destination",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_outbound_pokes_stream" ON "device_lists_outbound_pokes" (
	"stream_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "ratelimit_override_idx" ON "ratelimit_override" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "current_state_delta_stream_idx" ON "current_state_delta_stream" (
	"stream_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "blocked_rooms_idx" ON "blocked_rooms" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "local_media_repository_url_cache_expires_idx" ON "local_media_repository_url_cache" (
	"expires_ts"
);
CREATE INDEX IF NOT EXISTS "local_media_repository_url_cache_by_url_download_ts" ON "local_media_repository_url_cache" (
	"url",
	"download_ts"
);
CREATE INDEX IF NOT EXISTS "local_media_repository_url_cache_media_idx" ON "local_media_repository_url_cache" (
	"media_id"
);
CREATE INDEX IF NOT EXISTS "deleted_pushers_stream_id" ON "deleted_pushers" (
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "user_directory_room_idx" ON "user_directory" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_directory_user_idx" ON "user_directory" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "event_push_actions_staging_id" ON "event_push_actions_staging" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "user_daily_visits_uts_idx" ON "user_daily_visits" (
	"user_id",
	"timestamp"
);
CREATE INDEX IF NOT EXISTS "user_daily_visits_ts_idx" ON "user_daily_visits" (
	"timestamp"
);
CREATE UNIQUE INDEX IF NOT EXISTS "erased_users_user" ON "erased_users" (
	"user_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "monthly_active_users_users" ON "monthly_active_users" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "monthly_active_users_time_stamp" ON "monthly_active_users" (
	"timestamp"
);
CREATE UNIQUE INDEX IF NOT EXISTS "e2e_room_keys_versions_idx" ON "e2e_room_keys_versions" (
	"user_id",
	"version"
);
CREATE UNIQUE INDEX IF NOT EXISTS "users_who_share_private_rooms_u_idx" ON "users_who_share_private_rooms" (
	"user_id",
	"other_user_id",
	"room_id"
);
CREATE INDEX IF NOT EXISTS "users_who_share_private_rooms_r_idx" ON "users_who_share_private_rooms" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "users_who_share_private_rooms_o_idx" ON "users_who_share_private_rooms" (
	"other_user_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_threepid_id_server_idx" ON "user_threepid_id_server" (
	"user_id",
	"medium",
	"address",
	"id_server"
);
CREATE UNIQUE INDEX IF NOT EXISTS "users_in_public_rooms_u_idx" ON "users_in_public_rooms" (
	"user_id",
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "event_relations_id" ON "event_relations" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "event_relations_relates" ON "event_relations" (
	"relates_to_id",
	"relation_type",
	"aggregation_key"
);
CREATE UNIQUE INDEX IF NOT EXISTS "room_stats_earliest_token_idx" ON "room_stats_earliest_token" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "user_ips_device_id" ON "user_ips" (
	"user_id",
	"device_id",
	"last_seen"
);
CREATE INDEX IF NOT EXISTS "event_contains_url_index" ON "events" (
	"room_id",
	"topological_ordering",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "event_push_actions_u_highlight" ON "event_push_actions" (
	"user_id",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "event_push_actions_highlights_index" ON "event_push_actions" (
	"user_id",
	"room_id",
	"topological_ordering",
	"stream_ordering"
);
CREATE INDEX IF NOT EXISTS "current_state_events_member_index" ON "current_state_events" (
	"state_key"
);
CREATE INDEX IF NOT EXISTS "device_inbox_stream_id_user_id" ON "device_inbox" (
	"stream_id",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_stream_user_id" ON "device_lists_stream" (
	"user_id",
	"device_id"
);
CREATE INDEX IF NOT EXISTS "local_media_repository_url_idx" ON "local_media_repository" (
	"created_ts"
);
CREATE INDEX IF NOT EXISTS "user_ips_last_seen" ON "user_ips" (
	"user_id",
	"last_seen"
);
CREATE INDEX IF NOT EXISTS "user_ips_last_seen_only" ON "user_ips" (
	"last_seen"
);
CREATE INDEX IF NOT EXISTS "users_creation_ts" ON "users" (
	"creation_ts"
);
CREATE INDEX IF NOT EXISTS "event_to_state_groups_sg_index" ON "event_to_state_groups" (
	"state_group"
);
CREATE UNIQUE INDEX IF NOT EXISTS "device_lists_remote_cache_unique_id" ON "device_lists_remote_cache" (
	"user_id",
	"device_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "device_lists_remote_extremeties_unique_idx" ON "device_lists_remote_extremeties" (
	"user_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_ips_user_token_ip_unique_index" ON "user_ips" (
	"user_id",
	"access_token",
	"ip"
);
CREATE INDEX IF NOT EXISTS "threepid_validation_token_session_id" ON "threepid_validation_token" (
	"session_id"
);
CREATE INDEX IF NOT EXISTS "event_expiry_expiry_ts_idx" ON "event_expiry" (
	"expiry_ts"
);
CREATE INDEX IF NOT EXISTS "event_labels_room_id_label_idx" ON "event_labels" (
	"room_id",
	"label",
	"topological_ordering"
);
CREATE UNIQUE INDEX IF NOT EXISTS "e2e_room_keys_with_version_idx" ON "e2e_room_keys" (
	"user_id",
	"version",
	"room_id",
	"session_id"
);
CREATE INDEX IF NOT EXISTS "room_retention_max_lifetime_idx" ON "room_retention" (
	"max_lifetime"
);
CREATE UNIQUE INDEX IF NOT EXISTS "e2e_cross_signing_keys_idx" ON "e2e_cross_signing_keys" (
	"user_id",
	"keytype",
	"stream_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_signature_stream_idx" ON "user_signature_stream" (
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "e2e_cross_signing_signatures2_idx" ON "e2e_cross_signing_signatures" (
	"user_id",
	"target_user_id",
	"target_device_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "room_stats_state_room" ON "room_stats_state" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_filters_unique" ON "user_filters" (
	"user_id",
	"filter_id"
);
CREATE INDEX IF NOT EXISTS "users_in_public_rooms_r_idx" ON "users_in_public_rooms" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "device_lists_remote_resync_idx" ON "device_lists_remote_resync" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_remote_resync_ts_idx" ON "device_lists_remote_resync" (
	"added_ts"
);
CREATE UNIQUE INDEX IF NOT EXISTS "local_current_membership_idx" ON "local_current_membership" (
	"user_id",
	"room_id"
);
CREATE INDEX IF NOT EXISTS "local_current_membership_room_idx" ON "local_current_membership" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "device_lists_outbound_last_success_unique_idx" ON "device_lists_outbound_last_success" (
	"destination",
	"user_id"
);
CREATE INDEX IF NOT EXISTS "local_media_repository_thumbnails_media_id" ON "local_media_repository_thumbnails" (
	"media_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "federation_stream_position_instance" ON "federation_stream_position" (
	"type",
	"instance_name"
);
CREATE INDEX IF NOT EXISTS "destination_rooms_room_id" ON "destination_rooms" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "stream_positions_idx" ON "stream_positions" (
	"stream_name",
	"instance_name"
);
CREATE INDEX IF NOT EXISTS "access_tokens_device_id" ON "access_tokens" (
	"user_id",
	"device_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "event_txn_id_event_id" ON "event_txn_id" (
	"event_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "event_txn_id_txn_id" ON "event_txn_id" (
	"room_id",
	"user_id",
	"token_id",
	"txn_id"
);
CREATE INDEX IF NOT EXISTS "event_txn_id_ts" ON "event_txn_id" (
	"inserted_ts"
);
CREATE UNIQUE INDEX IF NOT EXISTS "ignored_users_uniqueness" ON "ignored_users" (
	"ignorer_user_id",
	"ignored_user_id"
);
CREATE INDEX IF NOT EXISTS "ignored_users_ignored_user_id" ON "ignored_users" (
	"ignored_user_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "event_auth_chains_c_seq_index" ON "event_auth_chains" (
	"chain_id",
	"sequence_number"
);
CREATE INDEX IF NOT EXISTS "event_auth_chain_links_idx" ON "event_auth_chain_links" (
	"origin_chain_id",
	"target_chain_id"
);
CREATE INDEX IF NOT EXISTS "event_auth_chain_to_calculate_rm_id" ON "event_auth_chain_to_calculate" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "worker_locks_key" ON "worker_locks" (
	"lock_name",
	"lock_key"
);
CREATE INDEX IF NOT EXISTS "federation_inbound_events_staging_room" ON "federation_inbound_events_staging" (
	"room_id",
	"received_ts"
);
CREATE UNIQUE INDEX IF NOT EXISTS "federation_inbound_events_staging_instance_event" ON "federation_inbound_events_staging" (
	"origin",
	"event_id"
);
CREATE INDEX IF NOT EXISTS "insertion_event_edges_insertion_room_id" ON "insertion_event_edges" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "insertion_event_edges_insertion_prev_event_id" ON "insertion_event_edges" (
	"insertion_prev_event_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "insertion_event_extremities_event_id" ON "insertion_event_extremities" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "insertion_event_extremities_room_id" ON "insertion_event_extremities" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "insertion_events_event_id" ON "insertion_events" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "insertion_events_next_batch_id" ON "insertion_events" (
	"next_batch_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "batch_events_event_id" ON "batch_events" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "batch_events_batch_id" ON "batch_events" (
	"batch_id"
);
CREATE INDEX IF NOT EXISTS "insertion_event_edges_event_id" ON "insertion_event_edges" (
	"event_id"
);
CREATE INDEX IF NOT EXISTS "device_auth_providers_devices" ON "device_auth_providers" (
	"user_id",
	"device_id"
);
CREATE INDEX IF NOT EXISTS "device_auth_providers_sessions" ON "device_auth_providers" (
	"auth_provider_id",
	"auth_provider_session_id"
);
CREATE INDEX IF NOT EXISTS "refresh_tokens_next_token_id" ON "refresh_tokens" (
	"next_token_id"
) WHERE "next_token_id" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "partial_state_events_room_id_idx" ON "partial_state_events" (
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "device_lists_changes_in_stream_id" ON "device_lists_changes_in_room" (
	"stream_id",
	"room_id"
);
CREATE INDEX IF NOT EXISTS "device_lists_changes_in_stream_id_unconverted" ON "device_lists_changes_in_room" (
	"stream_id"
) WHERE NOT "converted_to_destinations";
CREATE UNIQUE INDEX IF NOT EXISTS "event_edges_event_id_prev_event_id_idx" ON "event_edges" (
	"event_id",
	"prev_event_id"
);
CREATE INDEX IF NOT EXISTS "ev_edges_prev_id" ON "event_edges" (
	"prev_event_id"
);
CREATE INDEX IF NOT EXISTS "redactions_have_censored_ts" ON "redactions" (
	"received_ts"
);
CREATE INDEX IF NOT EXISTS "room_memberships_user_room_forgotten" ON "room_memberships" (
	"user_id",
	"room_id"
);
CREATE INDEX IF NOT EXISTS "state_groups_room_id_idx" ON "state_groups" (
	"room_id"
);
CREATE INDEX IF NOT EXISTS "users_have_local_media" ON "local_media_repository" (
	"user_id",
	"created_ts"
);
CREATE UNIQUE INDEX IF NOT EXISTS "e2e_cross_signing_keys_stream_idx" ON "e2e_cross_signing_keys" (
	"stream_id"
);
CREATE INDEX IF NOT EXISTS "user_external_ids_user_id_idx" ON "user_external_ids" (
	"user_id"
);
CREATE INDEX IF NOT EXISTS "presence_stream_state_not_offline_idx" ON "presence_stream" (
	"state"
);
CREATE UNIQUE INDEX IF NOT EXISTS "event_push_summary_unique_index" ON "event_push_summary" (
	"user_id",
	"room_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "state_group_edges_unique_idx" ON "state_group_edges" (
	"state_group",
	"prev_state_group"
);
CREATE TRIGGER partial_state_events_bad_room_id
            BEFORE INSERT ON partial_state_events
            FOR EACH ROW
            BEGIN
                SELECT RAISE(ABORT, 'Incorrect room_id in partial_state_events')
                WHERE EXISTS (
                    SELECT 1 FROM events
                    WHERE events.event_id = NEW.event_id
                       AND events.room_id != NEW.room_id
                );
            END;
COMMIT;
