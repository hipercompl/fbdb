// ignore_for_file: type=lint

/// Various Firebird constants, extracted from the header files.
abstract class FbConsts {
  /// Old SQL dialect (1).
  static const sqlDialectV5 = 1;

  /// Transitional SQL dialect (2).
  static const sqlDialectV6Transition = 2;

  /// The new SQL dialect (3).
  static const sqlDialectV6 = 3;

  /// The current SQL dialect is dialect 3.
  static const sqlDialectCurrent = sqlDialectV6;

  static const int isc_dpb_version1 = 1;
  static const int isc_dpb_version2 = 2;
  static const int isc_dpb_cdd_pathname = 1;
  static const int isc_dpb_allocation = 2;
  static const int isc_dpb_journal = 3;
  static const int isc_dpb_page_size = 4;
  static const int isc_dpb_num_buffers = 5;
  static const int isc_dpb_buffer_length = 6;
  static const int isc_dpb_debug = 7;
  static const int isc_dpb_garbage_collect = 8;
  static const int isc_dpb_verify = 9;
  static const int isc_dpb_sweep = 10;
  static const int isc_dpb_enable_journal = 11;
  static const int isc_dpb_disable_journal = 12;
  static const int isc_dpb_dbkey_scope = 13;
  static const int isc_dpb_number_of_users = 14;
  static const int isc_dpb_trace = 15;
  static const int isc_dpb_no_garbage_collect = 16;
  static const int isc_dpb_damaged = 17;
  static const int isc_dpb_license = 18;
  static const int isc_dpb_sys_user_name = 19;
  static const int isc_dpb_encrypt_key = 20;
  static const int isc_dpb_activate_shadow = 21;
  static const int isc_dpb_sweep_interval = 22;
  static const int isc_dpb_delete_shadow = 23;
  static const int isc_dpb_force_write = 24;
  static const int isc_dpb_begin_log = 25;
  static const int isc_dpb_quit_log = 26;
  static const int isc_dpb_no_reserve = 27;
  static const int isc_dpb_user_name = 28;
  static const int isc_dpb_password = 29;
  static const int isc_dpb_password_enc = 30;
  static const int isc_dpb_sys_user_name_enc = 31;
  static const int isc_dpb_interp = 32;
  static const int isc_dpb_online_dump = 33;
  static const int isc_dpb_old_file_size = 34;
  static const int isc_dpb_old_num_files = 35;
  static const int isc_dpb_old_file = 36;
  static const int isc_dpb_old_start_page = 37;
  static const int isc_dpb_old_start_seqno = 38;
  static const int isc_dpb_old_start_file = 39;
  static const int isc_dpb_drop_walfile = 40;
  static const int isc_dpb_old_dump_id = 41;
  static const int isc_dpb_wal_backup_dir = 42;
  static const int isc_dpb_wal_chkptlen = 43;
  static const int isc_dpb_wal_numbufs = 44;
  static const int isc_dpb_wal_bufsize = 45;
  static const int isc_dpb_wal_grp_cmt_wait = 46;
  static const int isc_dpb_lc_messages = 47;
  static const int isc_dpb_lc_ctype = 48;
  static const int isc_dpb_cache_manager = 49;
  static const int isc_dpb_shutdown = 50;
  static const int isc_dpb_online = 51;
  static const int isc_dpb_shutdown_delay = 52;
  static const int isc_dpb_reserved = 53;
  static const int isc_dpb_overwrite = 54;
  static const int isc_dpb_sec_attach = 55;
  static const int isc_dpb_disable_wal = 56;
  static const int isc_dpb_connect_timeout = 57;
  static const int isc_dpb_dummy_packet_interval = 58;
  static const int isc_dpb_gbak_attach = 59;
  static const int isc_dpb_sql_role_name = 60;
  static const int isc_dpb_set_page_buffers = 61;
  static const int isc_dpb_working_directory = 62;
  static const int isc_dpb_sql_dialect = 63;
  static const int isc_dpb_set_db_readonly = 64;
  static const int isc_dpb_set_db_sql_dialect = 65;
  static const int isc_dpb_gfix_attach = 66;
  static const int isc_dpb_gstat_attach = 67;
  static const int isc_dpb_set_db_charset = 68;
  static const int isc_dpb_gsec_attach = 69;
  static const int isc_dpb_address_path = 70;
  static const int isc_dpb_process_id = 71;
  static const int isc_dpb_no_db_triggers = 72;
  static const int isc_dpb_trusted_auth = 73;
  static const int isc_dpb_process_name = 74;
  static const int isc_dpb_trusted_role = 75;
  static const int isc_dpb_org_filename = 76;
  static const int isc_dpb_utf8_filename = 77;
  static const int isc_dpb_ext_call_depth = 78;
  static const int isc_dpb_auth_block = 79;
  static const int isc_dpb_client_version = 80;
  static const int isc_dpb_remote_protocol = 81;
  static const int isc_dpb_host_name = 82;
  static const int isc_dpb_os_user = 83;
  static const int isc_dpb_specific_auth_data = 84;
  static const int isc_dpb_auth_plugin_list = 85;
  static const int isc_dpb_auth_plugin_name = 86;
  static const int isc_dpb_config = 87;
  static const int isc_dpb_nolinger = 88;
  static const int isc_dpb_reset_icu = 89;
  static const int isc_dpb_map_attach = 90;
  static const int isc_dpb_session_time_zone = 91;
  static const int isc_dpb_set_db_replica = 92;
  static const int isc_dpb_set_bind = 93;
  static const int isc_dpb_decfloat_round = 94;
  static const int isc_dpb_decfloat_traps = 95;
  static const int isc_dpb_clear_map = 96;
  static const int isc_dpb_address = 1;
  static const int isc_dpb_addr_protocol = 1;
  static const int isc_dpb_addr_endpoint = 2;
  static const int isc_dpb_addr_flags = 3;
  static const int isc_dpb_addr_crypt = 4;
  static const int isc_dpb_addr_flag_conn_compressed = 1;
  static const int isc_dpb_addr_flag_conn_encrypted = 2;
  static const int isc_dpb_pages = 1;
  static const int isc_dpb_records = 2;
  static const int isc_dpb_indices = 4;
  static const int isc_dpb_transactions = 8;
  static const int isc_dpb_no_update = 16;
  static const int isc_dpb_repair = 32;
  static const int isc_dpb_ignore = 64;
  static const int isc_dpb_shut_cache = 1;
  static const int isc_dpb_shut_attachment = 2;
  static const int isc_dpb_shut_transaction = 4;
  static const int isc_dpb_shut_force = 8;
  static const int isc_dpb_shut_mode_mask = 112;
  static const int isc_dpb_shut_default = 0;
  static const int isc_dpb_shut_normal = 16;
  static const int isc_dpb_shut_multi = 32;
  static const int isc_dpb_shut_single = 48;
  static const int isc_dpb_shut_full = 64;
  static const int isc_dpb_replica_none = 0;
  static const int isc_dpb_replica_read_only = 1;
  static const int isc_dpb_replica_read_write = 2;

  static const int isc_spb_version1 = 1;
  static const int isc_spb_current_version = 2;
  static const int isc_spb_version = 2;
  static const int isc_spb_version3 = 3;
  static const int isc_spb_user_name = 28;
  static const int isc_spb_sys_user_name = 19;
  static const int isc_spb_sys_user_name_enc = 31;
  static const int isc_spb_password = 29;
  static const int isc_spb_password_enc = 30;
  static const int isc_spb_command_line = 105;
  static const int isc_spb_dbname = 106;
  static const int isc_spb_verbose = 107;
  static const int isc_spb_options = 108;
  static const int isc_spb_address_path = 109;
  static const int isc_spb_process_id = 110;
  static const int isc_spb_trusted_auth = 111;
  static const int isc_spb_process_name = 112;
  static const int isc_spb_trusted_role = 113;
  static const int isc_spb_verbint = 114;
  static const int isc_spb_auth_block = 115;
  static const int isc_spb_auth_plugin_name = 116;
  static const int isc_spb_auth_plugin_list = 117;
  static const int isc_spb_utf8_filename = 118;
  static const int isc_spb_client_version = 119;
  static const int isc_spb_remote_protocol = 120;
  static const int isc_spb_host_name = 121;
  static const int isc_spb_os_user = 122;
  static const int isc_spb_config = 123;
  static const int isc_spb_expected_db = 124;
  static const int isc_spb_connect_timeout = 57;
  static const int isc_spb_dummy_packet_interval = 58;
  static const int isc_spb_sql_role_name = 60;
  static const int isc_spb_specific_auth_data = 111;
  static const int isc_spb_sec_userid = 5;
  static const int isc_spb_sec_groupid = 6;
  static const int isc_spb_sec_username = 7;
  static const int isc_spb_sec_password = 8;
  static const int isc_spb_sec_groupname = 9;
  static const int isc_spb_sec_firstname = 10;
  static const int isc_spb_sec_middlename = 11;
  static const int isc_spb_sec_lastname = 12;
  static const int isc_spb_sec_admin = 13;
  static const int isc_spb_lic_key = 5;
  static const int isc_spb_lic_id = 6;
  static const int isc_spb_lic_desc = 7;
  static const int isc_spb_bkp_file = 5;
  static const int isc_spb_bkp_factor = 6;
  static const int isc_spb_bkp_length = 7;
  static const int isc_spb_bkp_skip_data = 8;
  static const int isc_spb_bkp_stat = 15;
  static const int isc_spb_bkp_keyholder = 16;
  static const int isc_spb_bkp_keyname = 17;
  static const int isc_spb_bkp_crypt = 18;
  static const int isc_spb_bkp_include_data = 19;
  static const int isc_spb_bkp_ignore_checksums = 1;
  static const int isc_spb_bkp_ignore_limbo = 2;
  static const int isc_spb_bkp_metadata_only = 4;
  static const int isc_spb_bkp_no_garbage_collect = 8;
  static const int isc_spb_bkp_old_descriptions = 16;
  static const int isc_spb_bkp_non_transportable = 32;
  static const int isc_spb_bkp_convert = 64;
  static const int isc_spb_bkp_expand = 128;
  static const int isc_spb_bkp_no_triggers = 32768;
  static const int isc_spb_bkp_zip = 65536;
  static const int isc_spb_prp_page_buffers = 5;
  static const int isc_spb_prp_sweep_interval = 6;
  static const int isc_spb_prp_shutdown_db = 7;
  static const int isc_spb_prp_deny_new_attachments = 9;
  static const int isc_spb_prp_deny_new_transactions = 10;
  static const int isc_spb_prp_reserve_space = 11;
  static const int isc_spb_prp_write_mode = 12;
  static const int isc_spb_prp_access_mode = 13;
  static const int isc_spb_prp_set_sql_dialect = 14;
  static const int isc_spb_prp_activate = 256;
  static const int isc_spb_prp_db_online = 512;
  static const int isc_spb_prp_nolinger = 1024;
  static const int isc_spb_prp_force_shutdown = 41;
  static const int isc_spb_prp_attachments_shutdown = 42;
  static const int isc_spb_prp_transactions_shutdown = 43;
  static const int isc_spb_prp_shutdown_mode = 44;
  static const int isc_spb_prp_online_mode = 45;
  static const int isc_spb_prp_replica_mode = 46;
  static const int isc_spb_prp_sm_normal = 0;
  static const int isc_spb_prp_sm_multi = 1;
  static const int isc_spb_prp_sm_single = 2;
  static const int isc_spb_prp_sm_full = 3;
  static const int isc_spb_prp_res_use_full = 35;
  static const int isc_spb_prp_res = 36;
  static const int isc_spb_prp_wm_async = 37;
  static const int isc_spb_prp_wm_sync = 38;
  static const int isc_spb_prp_am_readonly = 39;
  static const int isc_spb_prp_am_readwrite = 40;
  static const int isc_spb_prp_rm_none = 0;
  static const int isc_spb_prp_rm_readonly = 1;
  static const int isc_spb_prp_rm_readwrite = 2;
  static const int isc_spb_rpr_commit_trans = 15;
  static const int isc_spb_rpr_rollback_trans = 34;
  static const int isc_spb_rpr_recover_two_phase = 17;
  static const int isc_spb_tra_id = 18;
  static const int isc_spb_single_tra_id = 19;
  static const int isc_spb_multi_tra_id = 20;
  static const int isc_spb_tra_state = 21;
  static const int isc_spb_tra_state_limbo = 22;
  static const int isc_spb_tra_state_commit = 23;
  static const int isc_spb_tra_state_rollback = 24;
  static const int isc_spb_tra_state_unknown = 25;
  static const int isc_spb_tra_host_site = 26;
  static const int isc_spb_tra_remote_site = 27;
  static const int isc_spb_tra_db_path = 28;
  static const int isc_spb_tra_advise = 29;
  static const int isc_spb_tra_advise_commit = 30;
  static const int isc_spb_tra_advise_rollback = 31;
  static const int isc_spb_tra_advise_unknown = 33;
  static const int isc_spb_tra_id_64 = 46;
  static const int isc_spb_single_tra_id_64 = 47;
  static const int isc_spb_multi_tra_id_64 = 48;
  static const int isc_spb_rpr_commit_trans_64 = 49;
  static const int isc_spb_rpr_rollback_trans_64 = 50;
  static const int isc_spb_rpr_recover_two_phase_64 = 51;
  static const int isc_spb_rpr_validate_db = 1;
  static const int isc_spb_rpr_sweep_db = 2;
  static const int isc_spb_rpr_mend_db = 4;
  static const int isc_spb_rpr_list_limbo_trans = 8;
  static const int isc_spb_rpr_check_db = 16;
  static const int isc_spb_rpr_ignore_checksum = 32;
  static const int isc_spb_rpr_kill_shadows = 64;
  static const int isc_spb_rpr_full = 128;
  static const int isc_spb_rpr_icu = 2048;
  static const int isc_spb_res_skip_data = 8;
  static const int isc_spb_res_include_data = 19;
  static const int isc_spb_res_buffers = 9;
  static const int isc_spb_res_page_size = 10;
  static const int isc_spb_res_length = 11;
  static const int isc_spb_res_access_mode = 12;
  static const int isc_spb_res_fix_fss_data = 13;
  static const int isc_spb_res_fix_fss_metadata = 14;
  static const int isc_spb_res_keyholder = 16;
  static const int isc_spb_res_keyname = 17;
  static const int isc_spb_res_crypt = 18;
  static const int isc_spb_res_stat = 15;
  static const int isc_spb_res_metadata_only = 4;
  static const int isc_spb_res_deactivate_idx = 256;
  static const int isc_spb_res_no_shadow = 512;
  static const int isc_spb_res_no_validity = 1024;
  static const int isc_spb_res_one_at_a_time = 2048;
  static const int isc_spb_res_replace = 4096;
  static const int isc_spb_res_create = 8192;
  static const int isc_spb_res_use_all_space = 16384;
  static const int isc_spb_res_replica_mode = 20;
  static const int isc_spb_val_tab_incl = 1;
  static const int isc_spb_val_tab_excl = 2;
  static const int isc_spb_val_idx_incl = 3;
  static const int isc_spb_val_idx_excl = 4;
  static const int isc_spb_val_lock_timeout = 5;
  static const int isc_spb_res_am_readonly = 39;
  static const int isc_spb_res_am_readwrite = 40;
  static const int isc_spb_res_rm_none = 0;
  static const int isc_spb_res_rm_readonly = 1;
  static const int isc_spb_res_rm_readwrite = 2;
  static const int isc_spb_num_att = 5;
  static const int isc_spb_num_db = 6;
  static const int isc_spb_sts_table = 64;
  static const int isc_spb_sts_data_pages = 1;
  static const int isc_spb_sts_db_log = 2;
  static const int isc_spb_sts_hdr_pages = 4;
  static const int isc_spb_sts_idx_pages = 8;
  static const int isc_spb_sts_sys_relations = 16;
  static const int isc_spb_sts_record_versions = 32;
  static const int isc_spb_sts_nocreation = 128;
  static const int isc_spb_sts_encryption = 256;
  static const int isc_spb_nbk_level = 5;
  static const int isc_spb_nbk_file = 6;
  static const int isc_spb_nbk_direct = 7;
  static const int isc_spb_nbk_guid = 8;
  static const int isc_spb_nbk_clean_history = 9;
  static const int isc_spb_nbk_keep_days = 10;
  static const int isc_spb_nbk_keep_rows = 11;
  static const int isc_spb_nbk_no_triggers = 1;
  static const int isc_spb_nbk_inplace = 2;
  static const int isc_spb_nbk_sequence = 4;
  static const int isc_spb_trc_id = 1;
  static const int isc_spb_trc_name = 2;
  static const int isc_spb_trc_cfg = 3;

  static const int isc_info_db_id = 4;
  static const int isc_info_reads = 5;
  static const int isc_info_writes = 6;
  static const int isc_info_fetches = 7;
  static const int isc_info_marks = 8;
  static const int isc_info_implementation = 11;
  static const int isc_info_isc_version = 12;
  static const int isc_info_base_level = 13;
  static const int isc_info_page_size = 14;
  static const int isc_info_num_buffers = 15;
  static const int isc_info_limbo = 16;
  static const int isc_info_current_memory = 17;
  static const int isc_info_max_memory = 18;
  static const int isc_info_window_turns = 19;
  static const int isc_info_license = 20;
  static const int isc_info_allocation = 21;
  static const int isc_info_attachment_id = 22;
  static const int isc_info_read_seq_count = 23;
  static const int isc_info_read_idx_count = 24;
  static const int isc_info_insert_count = 25;
  static const int isc_info_update_count = 26;
  static const int isc_info_delete_count = 27;
  static const int isc_info_backout_count = 28;
  static const int isc_info_purge_count = 29;
  static const int isc_info_expunge_count = 30;
  static const int isc_info_sweep_interval = 31;
  static const int isc_info_ods_version = 32;
  static const int isc_info_ods_minor_version = 33;
  static const int isc_info_no_reserve = 34;
  static const int isc_info_logfile = 35;
  static const int isc_info_cur_logfile_name = 36;
  static const int isc_info_cur_log_part_offset = 37;
  static const int isc_info_num_wal_buffers = 38;
  static const int isc_info_wal_buffer_size = 39;
  static const int isc_info_wal_ckpt_length = 40;
  static const int isc_info_wal_cur_ckpt_interval = 41;
  static const int isc_info_wal_prv_ckpt_fname = 42;
  static const int isc_info_wal_prv_ckpt_poffset = 43;
  static const int isc_info_wal_recv_ckpt_fname = 44;
  static const int isc_info_wal_recv_ckpt_poffset = 45;
  static const int isc_info_wal_grpc_wait_usecs = 47;
  static const int isc_info_wal_num_io = 48;
  static const int isc_info_wal_avg_io_size = 49;
  static const int isc_info_wal_num_commits = 50;
  static const int isc_info_wal_avg_grpc_size = 51;
  static const int isc_info_forced_writes = 52;
  static const int isc_info_user_names = 53;
  static const int isc_info_page_errors = 54;
  static const int isc_info_record_errors = 55;
  static const int isc_info_bpage_errors = 56;
  static const int isc_info_dpage_errors = 57;
  static const int isc_info_ipage_errors = 58;
  static const int isc_info_ppage_errors = 59;
  static const int isc_info_tpage_errors = 60;
  static const int isc_info_set_page_buffers = 61;
  static const int isc_info_db_sql_dialect = 62;
  static const int isc_info_db_read_only = 63;
  static const int isc_info_db_size_in_pages = 64;
  static const int frb_info_att_charset = 101;
  static const int isc_info_db_class = 102;
  static const int isc_info_firebird_version = 103;
  static const int isc_info_oldest_transaction = 104;
  static const int isc_info_oldest_active = 105;
  static const int isc_info_oldest_snapshot = 106;
  static const int isc_info_next_transaction = 107;
  static const int isc_info_db_provider = 108;
  static const int isc_info_active_transactions = 109;
  static const int isc_info_active_tran_count = 110;
  static const int isc_info_creation_date = 111;
  static const int isc_info_db_file_size = 112;
  static const int fb_info_page_contents = 113;
  static const int fb_info_implementation = 114;
  static const int fb_info_page_warns = 115;
  static const int fb_info_record_warns = 116;
  static const int fb_info_bpage_warns = 117;
  static const int fb_info_dpage_warns = 118;
  static const int fb_info_ipage_warns = 119;
  static const int fb_info_ppage_warns = 120;
  static const int fb_info_tpage_warns = 121;
  static const int fb_info_pip_errors = 122;
  static const int fb_info_pip_warns = 123;
  static const int fb_info_pages_used = 124;
  static const int fb_info_pages_free = 125;
  static const int fb_info_ses_idle_timeout_db = 129;
  static const int fb_info_ses_idle_timeout_att = 130;
  static const int fb_info_ses_idle_timeout_run = 131;
  static const int fb_info_conn_flags = 132;
  static const int fb_info_crypt_key = 133;
  static const int fb_info_crypt_state = 134;
  static const int fb_info_statement_timeout_db = 135;
  static const int fb_info_statement_timeout_att = 136;
  static const int fb_info_protocol_version = 137;
  static const int fb_info_crypt_plugin = 138;
  static const int fb_info_creation_timestamp_tz = 139;
  static const int fb_info_wire_crypt = 140;
  static const int fb_info_features = 141;
  static const int fb_info_next_attachment = 142;
  static const int fb_info_next_statement = 143;
  static const int fb_info_db_guid = 144;
  static const int fb_info_db_file_id = 145;
  static const int fb_info_replica_mode = 146;
  static const int fb_info_username = 147;
  static const int fb_info_sqlrole = 148;
  static const int isc_info_db_last_value = 149;

  static const int isc_info_svc_svr_db_info = 50;
  static const int isc_info_svc_get_license = 51;
  static const int isc_info_svc_get_license_mask = 52;
  static const int isc_info_svc_get_config = 53;
  static const int isc_info_svc_version = 54;
  static const int isc_info_svc_server_version = 55;
  static const int isc_info_svc_implementation = 56;
  static const int isc_info_svc_capabilities = 57;
  static const int isc_info_svc_user_dbpath = 58;
  static const int isc_info_svc_get_env = 59;
  static const int isc_info_svc_get_env_lock = 60;
  static const int isc_info_svc_get_env_msg = 61;
  static const int isc_info_svc_line = 62;
  static const int isc_info_svc_to_eof = 63;
  static const int isc_info_svc_timeout = 64;
  static const int isc_info_svc_get_licensed_users = 65;
  static const int isc_info_svc_limbo_trans = 66;
  static const int isc_info_svc_running = 67;
  static const int isc_info_svc_get_users = 68;
  static const int isc_info_svc_auth_block = 69;
  static const int isc_info_svc_stdin = 78;

  static const int isc_info_end = 1;
  static const int isc_info_truncated = 2;
  static const int isc_info_error = 3;
  static const int isc_info_data_not_ready = 4;
  static const int isc_info_length = 126;
  static const int isc_info_flag_end = 127;
  static const int isc_info_version = 12;
  static const int isc_info_number_messages = 4;
  static const int isc_info_max_message = 5;
  static const int isc_info_max_send = 6;
  static const int isc_info_max_receive = 7;
  static const int isc_info_state = 8;
  static const int isc_info_message_number = 9;
  static const int isc_info_message_size = 10;
  static const int isc_info_request_cost = 11;
  static const int isc_info_access_path = 12;
  static const int isc_info_req_select_count = 13;
  static const int isc_info_req_insert_count = 14;
  static const int isc_info_req_update_count = 15;
  static const int isc_info_req_delete_count = 16;
  static const int isc_info_rsb_end = 0;
  static const int isc_info_rsb_begin = 1;
  static const int isc_info_rsb_type = 2;
  static const int isc_info_rsb_relation = 3;
  static const int isc_info_rsb_plan = 4;
  static const int isc_info_rsb_unknown = 1;
  static const int isc_info_rsb_indexed = 2;
  static const int isc_info_rsb_navigate = 3;
  static const int isc_info_rsb_sequential = 4;
  static const int isc_info_rsb_cross = 5;
  static const int isc_info_rsb_sort = 6;
  static const int isc_info_rsb_first = 7;
  static const int isc_info_rsb_boolean = 8;
  static const int isc_info_rsb_union = 9;
  static const int isc_info_rsb_aggregate = 10;
  static const int isc_info_rsb_merge = 11;
  static const int isc_info_rsb_ext_sequential = 12;
  static const int isc_info_rsb_ext_indexed = 13;
  static const int isc_info_rsb_ext_dbkey = 14;
  static const int isc_info_rsb_left_cross = 15;
  static const int isc_info_rsb_select = 16;
  static const int isc_info_rsb_sql_join = 17;
  static const int isc_info_rsb_simulate = 18;
  static const int isc_info_rsb_sim_cross = 19;
  static const int isc_info_rsb_once = 20;
  static const int isc_info_rsb_procedure = 21;
  static const int isc_info_rsb_skip = 22;
  static const int isc_info_rsb_virt_sequential = 23;
  static const int isc_info_rsb_recursive = 24;
  static const int isc_info_rsb_window = 25;
  static const int isc_info_rsb_singular = 26;
  static const int isc_info_rsb_writelock = 27;
  static const int isc_info_rsb_buffer = 28;
  static const int isc_info_rsb_hash = 29;
  static const int isc_info_rsb_and = 1;
  static const int isc_info_rsb_or = 2;
  static const int isc_info_rsb_dbkey = 3;
  static const int isc_info_rsb_index = 4;
  static const int isc_info_req_active = 2;
  static const int isc_info_req_inactive = 3;
  static const int isc_info_req_send = 4;
  static const int isc_info_req_receive = 5;
  static const int isc_info_req_select = 6;
  static const int isc_info_req_sql_stall = 7;
  static const int isc_info_blob_num_segments = 4;
  static const int isc_info_blob_max_segment = 5;
  static const int isc_info_blob_total_length = 6;
  static const int isc_info_blob_type = 7;
  static const int isc_info_tra_id = 4;
  static const int isc_info_tra_oldest_interesting = 5;
  static const int isc_info_tra_oldest_snapshot = 6;
  static const int isc_info_tra_oldest_active = 7;
  static const int isc_info_tra_isolation = 8;
  static const int isc_info_tra_access = 9;
  static const int isc_info_tra_lock_timeout = 10;
  static const int fb_info_tra_dbpath = 11;
  static const int fb_info_tra_snapshot_number = 12;
  static const int isc_info_tra_consistency = 1;
  static const int isc_info_tra_concurrency = 2;
  static const int isc_info_tra_read_committed = 3;
  static const int isc_info_tra_no_rec_version = 0;
  static const int isc_info_tra_rec_version = 1;
  static const int isc_info_tra_read_consistency = 2;
  static const int isc_info_tra_readonly = 0;
  static const int isc_info_tra_readwrite = 1;
  static const int isc_info_sql_select = 4;
  static const int isc_info_sql_bind = 5;
  static const int isc_info_sql_num_variables = 6;
  static const int isc_info_sql_describe_vars = 7;
  static const int isc_info_sql_describe_end = 8;
  static const int isc_info_sql_sqlda_seq = 9;
  static const int isc_info_sql_message_seq = 10;
  static const int isc_info_sql_type = 11;
  static const int isc_info_sql_sub_type = 12;
  static const int isc_info_sql_scale = 13;
  static const int isc_info_sql_length = 14;
  static const int isc_info_sql_null_ind = 15;
  static const int isc_info_sql_field = 16;
  static const int isc_info_sql_relation = 17;
  static const int isc_info_sql_owner = 18;
  static const int isc_info_sql_alias = 19;
  static const int isc_info_sql_sqlda_start = 20;
  static const int isc_info_sql_stmt_type = 21;
  static const int isc_info_sql_get_plan = 22;
  static const int isc_info_sql_records = 23;
  static const int isc_info_sql_batch_fetch = 24;
  static const int isc_info_sql_relation_alias = 25;
  static const int isc_info_sql_explain_plan = 26;
  static const int isc_info_sql_stmt_flags = 27;
  static const int isc_info_sql_stmt_timeout_user = 28;
  static const int isc_info_sql_stmt_timeout_run = 29;
  static const int isc_info_sql_stmt_blob_align = 30;
  static const int isc_info_sql_exec_path_blr_bytes = 31;
  static const int isc_info_sql_exec_path_blr_text = 32;
  static const int isc_info_sql_stmt_select = 1;
  static const int isc_info_sql_stmt_insert = 2;
  static const int isc_info_sql_stmt_update = 3;
  static const int isc_info_sql_stmt_delete = 4;
  static const int isc_info_sql_stmt_ddl = 5;
  static const int isc_info_sql_stmt_get_segment = 6;
  static const int isc_info_sql_stmt_put_segment = 7;
  static const int isc_info_sql_stmt_exec_procedure = 8;
  static const int isc_info_sql_stmt_start_trans = 9;
  static const int isc_info_sql_stmt_commit = 10;
  static const int isc_info_sql_stmt_rollback = 11;
  static const int isc_info_sql_stmt_select_for_upd = 12;
  static const int isc_info_sql_stmt_set_generator = 13;
  static const int isc_info_sql_stmt_savepoint = 14;

  static const int isc_action_svc_backup = 1;
  static const int isc_action_svc_restore = 2;
  static const int isc_action_svc_repair = 3;
  static const int isc_action_svc_add_user = 4;
  static const int isc_action_svc_delete_user = 5;
  static const int isc_action_svc_modify_user = 6;
  static const int isc_action_svc_display_user = 7;
  static const int isc_action_svc_properties = 8;
  static const int isc_action_svc_add_license = 9;
  static const int isc_action_svc_remove_license = 10;
  static const int isc_action_svc_db_stats = 11;
  static const int isc_action_svc_get_ib_log = 12;
  static const int isc_action_svc_get_fb_log = 12;
  static const int isc_action_svc_nbak = 20;
  static const int isc_action_svc_nrest = 21;
  static const int isc_action_svc_trace_start = 22;
  static const int isc_action_svc_trace_stop = 23;
  static const int isc_action_svc_trace_suspend = 24;
  static const int isc_action_svc_trace_resume = 25;
  static const int isc_action_svc_trace_list = 26;
  static const int isc_action_svc_set_mapping = 27;
  static const int isc_action_svc_drop_mapping = 28;
  static const int isc_action_svc_display_user_adm = 29;
  static const int isc_action_svc_validate = 30;
  static const int isc_action_svc_nfix = 31;
  static const int isc_action_svc_last = 32;

  static const int isc_tpb_version1 = 1;
  static const int isc_tpb_version3 = 3;
  static const int isc_tpb_consistency = 1;
  static const int isc_tpb_concurrency = 2;
  static const int isc_tpb_shared = 3;
  static const int isc_tpb_protected = 4;
  static const int isc_tpb_exclusive = 5;
  static const int isc_tpb_wait = 6;
  static const int isc_tpb_nowait = 7;
  static const int isc_tpb_read = 8;
  static const int isc_tpb_write = 9;
  static const int isc_tpb_lock_read = 10;
  static const int isc_tpb_lock_write = 11;
  static const int isc_tpb_verb_time = 12;
  static const int isc_tpb_commit_time = 13;
  static const int isc_tpb_ignore_limbo = 14;
  static const int isc_tpb_read_committed = 15;
  static const int isc_tpb_autocommit = 16;
  static const int isc_tpb_rec_version = 17;
  static const int isc_tpb_no_rec_version = 18;
  static const int isc_tpb_restart_requests = 19;
  static const int isc_tpb_no_auto_undo = 20;
  static const int isc_tpb_lock_timeout = 21;
  static const int isc_tpb_read_consistency = 22;
  static const int isc_tpb_at_snapshot_number = 23;

  static const int SQLDA_VERSION1 = 1;
  static const int SQL_TEXT = 452;
  static const int SQL_VARYING = 448;
  static const int SQL_SHORT = 500;
  static const int SQL_LONG = 496;
  static const int SQL_FLOAT = 482;
  static const int SQL_DOUBLE = 480;
  static const int SQL_D_FLOAT = 530;
  static const int SQL_TIMESTAMP = 510;
  static const int SQL_BLOB = 520;
  static const int SQL_ARRAY = 540;
  static const int SQL_QUAD = 550;
  static const int SQL_TYPE_TIME = 560;
  static const int SQL_TYPE_DATE = 570;
  static const int SQL_INT64 = 580;
  static const int SQL_TIMESTAMP_TZ_EX = 32748;
  static const int SQL_TIME_TZ_EX = 32750;
  static const int SQL_INT128 = 32752;
  static const int SQL_TIMESTAMP_TZ = 32754;
  static const int SQL_TIME_TZ = 32756;
  static const int SQL_DEC16 = 32760;
  static const int SQL_DEC34 = 32762;
  static const int SQL_BOOLEAN = 32764;
  static const int SQL_NULL = 32766;
  static const int SQL_DATE = 510;

  static const int isc_blob_text = 1;
  static const int isc_blob_blr = 2;
  static const int isc_blob_acl = 3;
  static const int isc_blob_ranges = 4;
  static const int isc_blob_summary = 5;
  static const int isc_blob_format = 6;
  static const int isc_blob_tra = 7;
  static const int isc_blob_extfile = 8;
  static const int isc_blob_debug_info = 9;
  static const int isc_blob_max_predefined_subtype = 10;
}

/// ISC error codes.
abstract class FbErrorCodes {
  static const int isc_base = 335544320;

  /// arithmetic exception, numeric overflow, or string truncation
  static const int isc_arith_except = 335544321;

  /// invalid database key
  static const int isc_bad_dbkey = 335544322;

  /// file @1 is not a valid database
  static const int isc_bad_db_format = 335544323;

  /// invalid database handle (no active connection)
  static const int isc_bad_db_handle = 335544324;

  /// bad parameters on attach or create database
  static const int isc_bad_dpb_content = 335544325;

  /// unrecognized database parameter block
  static const int isc_bad_dpb_form = 335544326;

  /// invalid request handle
  static const int isc_bad_req_handle = 335544327;

  /// invalid BLOB handle
  static const int isc_bad_segstr_handle = 335544328;

  /// invalid BLOB ID
  static const int isc_bad_segstr_id = 335544329;

  /// invalid parameter in transaction parameter block
  static const int isc_bad_tpb_content = 335544330;

  /// invalid format for transaction parameter block
  static const int isc_bad_tpb_form = 335544331;

  /// invalid transaction handle (expecting explicit transaction start)
  static const int isc_bad_trans_handle = 335544332;

  /// internal Firebird consistency check (@1)
  static const int isc_bug_check = 335544333;

  /// conversion error from string "@1"
  static const int isc_convert_error = 335544334;

  /// database file appears corrupt (@1)
  static const int isc_db_corrupt = 335544335;

  /// deadlock
  static const int isc_deadlock = 335544336;

  /// attempt to start more than @1 transactions
  static const int isc_excess_trans = 335544337;

  /// no match for first value expression
  static const int isc_from_no_match = 335544338;

  /// information type inappropriate for object specified
  static const int isc_infinap = 335544339;

  /// no information of this type available for object specified
  static const int isc_infona = 335544340;

  /// unknown information item
  static const int isc_infunk = 335544341;

  /// action cancelled by trigger (@1) to preserve data integrity
  static const int isc_integ_fail = 335544342;

  /// invalid request BLR at offset @1
  static const int isc_invalid_blr = 335544343;

  /// I/O error during "@1" operation for file "@2"
  static const int isc_io_error = 335544344;

  /// lock conflict on no wait transaction
  static const int isc_lock_conflict = 335544345;

  /// corrupt system table
  static const int isc_metadata_corrupt = 335544346;

  /// validation error for column @1, value "@2"
  static const int isc_not_valid = 335544347;

  /// no current record for fetch operation
  static const int isc_no_cur_rec = 335544348;

  /// attempt to store duplicate value (visible to active transactions) in unique index "@1"
  static const int isc_no_dup = 335544349;

  /// program attempted to exit without finishing database
  static const int isc_no_finish = 335544350;

  /// unsuccessful metadata update
  static const int isc_no_meta_update = 335544351;

  /// no permission for @1 access to @2 @3
  static const int isc_no_priv = 335544352;

  /// transaction is not in limbo
  static const int isc_no_recon = 335544353;

  /// invalid database key
  static const int isc_no_record = 335544354;

  /// BLOB was not closed
  static const int isc_no_segstr_close = 335544355;

  /// metadata is obsolete
  static const int isc_obsolete_metadata = 335544356;

  /// cannot disconnect database with open transactions (@1 active)
  static const int isc_open_trans = 335544357;

  /// message length error (encountered @1, expected @2)
  static const int isc_port_len = 335544358;

  /// attempted update of read-only column @1
  static const int isc_read_only_field = 335544359;

  /// attempted update of read-only table
  static const int isc_read_only_rel = 335544360;

  /// attempted update during read-only transaction
  static const int isc_read_only_trans = 335544361;

  /// cannot update read-only view @1
  static const int isc_read_only_view = 335544362;

  /// no transaction for request
  static const int isc_req_no_trans = 335544363;

  /// request synchronization error
  static const int isc_req_sync = 335544364;

  /// request referenced an unavailable database
  static const int isc_req_wrong_db = 335544365;

  /// segment buffer length shorter than expected
  static const int isc_segment = 335544366;

  /// attempted retrieval of more segments than exist
  static const int isc_segstr_eof = 335544367;

  /// attempted invalid operation on a BLOB
  static const int isc_segstr_no_op = 335544368;

  /// attempted read of a new, open BLOB
  static const int isc_segstr_no_read = 335544369;

  /// attempted action on BLOB outside transaction
  static const int isc_segstr_no_trans = 335544370;

  /// attempted write to read-only BLOB
  static const int isc_segstr_no_write = 335544371;

  /// attempted reference to BLOB in unavailable database
  static const int isc_segstr_wrong_db = 335544372;

  /// operating system directive @1 failed
  static const int isc_sys_request = 335544373;

  /// attempt to fetch past the last record in a record stream
  static const int isc_stream_eof = 335544374;

  /// unavailable database
  static const int isc_unavailable = 335544375;

  /// table @1 was omitted from the transaction reserving list
  static const int isc_unres_rel = 335544376;

  /// request includes a DSRI extension not supported in this implementation
  static const int isc_uns_ext = 335544377;

  /// feature is not supported
  static const int isc_wish_list = 335544378;

  /// unsupported on-disk structure for file @1; found @2.@3, support @4.@5
  static const int isc_wrong_ods = 335544379;

  /// wrong number of arguments on call
  static const int isc_wronumarg = 335544380;

  /// Implementation limit exceeded
  static const int isc_imp_exc = 335544381;

  /// @1
  static const int isc_random = 335544382;

  /// unrecoverable conflict with limbo transaction @1
  static const int isc_fatal_conflict = 335544383;

  /// internal error
  static const int isc_badblk = 335544384;

  /// internal error
  static const int isc_invpoolcl = 335544385;

  /// too many requests
  static const int isc_nopoolids = 335544386;

  /// internal error
  static const int isc_relbadblk = 335544387;

  /// block size exceeds implementation restriction
  static const int isc_blktoobig = 335544388;

  /// buffer exhausted
  static const int isc_bufexh = 335544389;

  /// BLR syntax error: expected @1 at offset @2, encountered @3
  static const int isc_syntaxerr = 335544390;

  /// buffer in use
  static const int isc_bufinuse = 335544391;

  /// internal error
  static const int isc_bdbincon = 335544392;

  /// request in use
  static const int isc_reqinuse = 335544393;

  /// incompatible version of on-disk structure
  static const int isc_badodsver = 335544394;

  /// table @1 is not defined
  static const int isc_relnotdef = 335544395;

  /// column @1 is not defined in table @2
  static const int isc_fldnotdef = 335544396;

  /// internal error
  static const int isc_dirtypage = 335544397;

  /// internal error
  static const int isc_waifortra = 335544398;

  /// internal error
  static const int isc_doubleloc = 335544399;

  /// internal error
  static const int isc_nodnotfnd = 335544400;

  /// internal error
  static const int isc_dupnodfnd = 335544401;

  /// internal error
  static const int isc_locnotmar = 335544402;

  /// page @1 is of wrong type (expected @2, found @3)
  static const int isc_badpagtyp = 335544403;

  /// database corrupted
  static const int isc_corrupt = 335544404;

  /// checksum error on database page @1
  static const int isc_badpage = 335544405;

  /// index is broken
  static const int isc_badindex = 335544406;

  /// database handle not zero
  static const int isc_dbbnotzer = 335544407;

  /// transaction handle not zero
  static const int isc_tranotzer = 335544408;

  /// transaction-?request mismatch (synchronization error)
  static const int isc_trareqmis = 335544409;

  /// bad handle count
  static const int isc_badhndcnt = 335544410;

  /// wrong version of transaction parameter block
  static const int isc_wrotpbver = 335544411;

  /// unsupported BLR version (expected @1, encountered @2)
  static const int isc_wroblrver = 335544412;

  /// wrong version of database parameter block
  static const int isc_wrodpbver = 335544413;

  /// BLOB and array data types are not supported for @1 operation
  static const int isc_blobnotsup = 335544414;

  /// database corrupted
  static const int isc_badrelation = 335544415;

  /// internal error
  static const int isc_nodetach = 335544416;

  /// internal error
  static const int isc_notremote = 335544417;

  /// transaction in limbo
  static const int isc_trainlim = 335544418;

  /// transaction not in limbo
  static const int isc_notinlim = 335544419;

  /// transaction outstanding
  static const int isc_traoutsta = 335544420;

  /// connection rejected by remote interface
  static const int isc_connect_reject = 335544421;

  /// internal error
  static const int isc_dbfile = 335544422;

  /// internal error
  static const int isc_orphan = 335544423;

  /// no lock manager available
  static const int isc_no_lock_mgr = 335544424;

  /// context already in use (BLR error)
  static const int isc_ctxinuse = 335544425;

  /// context not defined (BLR error)
  static const int isc_ctxnotdef = 335544426;

  /// data operation not supported
  static const int isc_datnotsup = 335544427;

  /// undefined message number
  static const int isc_badmsgnum = 335544428;

  /// undefined parameter number
  static const int isc_badparnum = 335544429;

  /// unable to allocate memory from operating system
  static const int isc_virmemexh = 335544430;

  /// blocking signal has been received
  static const int isc_blocking_signal = 335544431;

  /// lock manager error
  static const int isc_lockmanerr = 335544432;

  /// communication error with journal "@1"
  static const int isc_journerr = 335544433;

  /// key size exceeds implementation restriction for index "@1"
  static const int isc_keytoobig = 335544434;

  /// null segment of UNIQUE KEY
  static const int isc_nullsegkey = 335544435;

  /// SQL error code = @1
  static const int isc_sqlerr = 335544436;

  /// wrong DYN version
  static const int isc_wrodynver = 335544437;

  /// function @1 is not defined
  static const int isc_funnotdef = 335544438;

  /// function @1 could not be matched
  static const int isc_funmismat = 335544439;
  static const int isc_bad_msg_vec = 335544440;

  /// database detach completed with errors
  static const int isc_bad_detach = 335544441;

  /// database system cannot read argument @1
  static const int isc_noargacc_read = 335544442;

  /// database system cannot write argument @1
  static const int isc_noargacc_write = 335544443;

  /// operation not supported
  static const int isc_read_only = 335544444;

  /// @1 extension error
  static const int isc_ext_err = 335544445;

  /// not updatable
  static const int isc_non_updatable = 335544446;

  /// no rollback performed
  static const int isc_no_rollback = 335544447;
  static const int isc_bad_sec_info = 335544448;
  static const int isc_invalid_sec_info = 335544449;

  /// @1
  static const int isc_misc_interpreted = 335544450;

  /// update conflicts with concurrent update
  static const int isc_update_conflict = 335544451;

  /// product @1 is not licensed
  static const int isc_unlicensed = 335544452;

  /// object @1 is in use
  static const int isc_obj_in_use = 335544453;

  /// filter not found to convert type @1 to type @2
  static const int isc_nofilter = 335544454;

  /// cannot attach active shadow file
  static const int isc_shadow_accessed = 335544455;

  /// invalid slice description language at offset @1
  static const int isc_invalid_sdl = 335544456;

  /// subscript out of bounds
  static const int isc_out_of_bounds = 335544457;

  /// column not array or invalid dimensions (expected @1, encountered @2)
  static const int isc_invalid_dimension = 335544458;

  /// record from transaction @1 is stuck in limbo
  static const int isc_rec_in_limbo = 335544459;

  /// a file in manual shadow @1 is unavailable
  static const int isc_shadow_missing = 335544460;

  /// secondary server attachments cannot validate databases
  static const int isc_cant_validate = 335544461;

  /// secondary server attachments cannot start journaling
  static const int isc_cant_start_journal = 335544462;

  /// generator @1 is not defined
  static const int isc_gennotdef = 335544463;

  /// secondary server attachments cannot start logging
  static const int isc_cant_start_logging = 335544464;

  /// invalid BLOB type for operation
  static const int isc_bad_segstr_type = 335544465;

  /// violation of FOREIGN KEY constraint "@1" on table "@2"
  static const int isc_foreign_key = 335544466;

  /// minor version too high found @1 expected @2
  static const int isc_high_minor = 335544467;

  /// transaction @1 is @2
  static const int isc_tra_state = 335544468;

  /// transaction marked invalid and cannot be committed
  static const int isc_trans_invalid = 335544469;

  /// cache buffer for page @1 invalid
  static const int isc_buf_invalid = 335544470;

  /// there is no index in table @1 with id @2
  static const int isc_indexnotdefined = 335544471;

  /// Your user name and password are not defined. Ask your database administrator to set up a Firebird login.
  static const int isc_login = 335544472;

  /// invalid bookmark handle
  static const int isc_invalid_bookmark = 335544473;

  /// invalid lock level @1
  static const int isc_bad_lock_level = 335544474;

  /// lock on table @1 conflicts with existing lock
  static const int isc_relation_lock = 335544475;

  /// requested record lock conflicts with existing lock
  static const int isc_record_lock = 335544476;

  /// maximum indexes per table (@1) exceeded
  static const int isc_max_idx = 335544477;

  /// enable journal for database before starting online dump
  static const int isc_jrn_enable = 335544478;

  /// online dump failure. Retry dump
  static const int isc_old_failure = 335544479;

  /// an online dump is already in progress
  static const int isc_old_in_progress = 335544480;

  /// no more disk/tape space. Cannot continue online dump
  static const int isc_old_no_space = 335544481;

  /// journaling allowed only if database has Write-ahead Log
  static const int isc_no_wal_no_jrn = 335544482;

  /// maximum number of online dump files that can be specified is 16
  static const int isc_num_old_files = 335544483;

  /// error in opening Write-ahead Log file during recovery
  static const int isc_wal_file_open = 335544484;

  /// invalid statement handle
  static const int isc_bad_stmt_handle = 335544485;

  /// Write-ahead log subsystem failure
  static const int isc_wal_failure = 335544486;

  /// WAL Writer error
  static const int isc_walw_err = 335544487;

  /// Log file header of @1 too small
  static const int isc_logh_small = 335544488;

  /// Invalid version of log file @1
  static const int isc_logh_inv_version = 335544489;

  /// Log file @1 not latest in the chain but open flag still set
  static const int isc_logh_open_flag = 335544490;

  /// Log file @1 not closed properly; database recovery may be required
  static const int isc_logh_open_flag2 = 335544491;

  /// Database name in the log file @1 is different
  static const int isc_logh_diff_dbname = 335544492;

  /// Unexpected end of log file @1 at offset @2
  static const int isc_logf_unexpected_eof = 335544493;

  /// Incomplete log record at offset @1 in log file @2
  static const int isc_logr_incomplete = 335544494;

  /// Log record header too small at offset @1 in log file @2
  static const int isc_logr_header_small = 335544495;

  /// Log block too small at offset @1 in log file @2
  static const int isc_logb_small = 335544496;

  /// Illegal attempt to attach to an uninitialized WAL segment for @1
  static const int isc_wal_illegal_attach = 335544497;

  /// Invalid WAL parameter block option @1
  static const int isc_wal_invalid_wpb = 335544498;

  /// Cannot roll over to the next log file @1
  static const int isc_wal_err_rollover = 335544499;

  /// database does not use Write-ahead Log
  static const int isc_no_wal = 335544500;

  /// cannot drop log file when journaling is enabled
  static const int isc_drop_wal = 335544501;

  /// reference to invalid stream number
  static const int isc_stream_not_defined = 335544502;

  /// WAL subsystem encountered error
  static const int isc_wal_subsys_error = 335544503;

  /// WAL subsystem corrupted
  static const int isc_wal_subsys_corrupt = 335544504;

  /// must specify archive file when enabling long term journal for databases with round-robin log files
  static const int isc_no_archive = 335544505;

  /// database @1 shutdown in progress
  static const int isc_shutinprog = 335544506;

  /// refresh range number @1 already in use
  static const int isc_range_in_use = 335544507;

  /// refresh range number @1 not found
  static const int isc_range_not_found = 335544508;

  /// CHARACTER SET @1 is not defined
  static const int isc_charset_not_found = 335544509;

  /// lock time-out on wait transaction
  static const int isc_lock_timeout = 335544510;

  /// procedure @1 is not defined
  static const int isc_prcnotdef = 335544511;

  /// Input parameter mismatch for procedure @1
  static const int isc_prcmismat = 335544512;

  /// Database @1: WAL subsystem bug for pid @2 @3
  static const int isc_wal_bugcheck = 335544513;

  /// Could not expand the WAL segment for database @1
  static const int isc_wal_cant_expand = 335544514;

  /// status code @1 unknown
  static const int isc_codnotdef = 335544515;

  /// exception @1 not defined
  static const int isc_xcpnotdef = 335544516;

  /// exception @1
  static const int isc_except = 335544517;

  /// restart shared cache manager
  static const int isc_cache_restart = 335544518;

  /// invalid lock handle
  static const int isc_bad_lock_handle = 335544519;

  /// long-term journaling already enabled
  static const int isc_jrn_present = 335544520;

  /// Unable to roll over please see Firebird log.
  static const int isc_wal_err_rollover2 = 335544521;

  /// WAL I/O error. Please see Firebird log.
  static const int isc_wal_err_logwrite = 335544522;

  /// WAL writer - Journal server communication error. Please see Firebird log.
  static const int isc_wal_err_jrn_comm = 335544523;

  /// WAL buffers cannot be increased. Please see Firebird log.
  static const int isc_wal_err_expansion = 335544524;

  /// WAL setup error. Please see Firebird log.
  static const int isc_wal_err_setup = 335544525;

  /// obsolete
  static const int isc_wal_err_ww_sync = 335544526;

  /// Cannot start WAL writer for the database @1
  static const int isc_wal_err_ww_start = 335544527;

  /// database @1 shutdown
  static const int isc_shutdown = 335544528;

  /// cannot modify an existing user privilege
  static const int isc_existing_priv_mod = 335544529;

  /// Cannot delete PRIMARY KEY being used in FOREIGN KEY definition.
  static const int isc_primary_key_ref = 335544530;

  /// Column used in a PRIMARY constraint must be NOT NULL.
  static const int isc_primary_key_notnull = 335544531;

  /// Name of Referential Constraint not defined in constraints table.
  static const int isc_ref_cnstrnt_notfound = 335544532;

  /// Non-existent PRIMARY or UNIQUE KEY specified for FOREIGN KEY.
  static const int isc_foreign_key_notfound = 335544533;

  /// Cannot update constraints (RDB$REF_CONSTRAINTS).
  static const int isc_ref_cnstrnt_update = 335544534;

  /// Cannot update constraints (RDB$CHECK_CONSTRAINTS).
  static const int isc_check_cnstrnt_update = 335544535;

  /// Cannot delete CHECK constraint entry (RDB$CHECK_CONSTRAINTS)
  static const int isc_check_cnstrnt_del = 335544536;

  /// Cannot delete index segment used by an Integrity Constraint
  static const int isc_integ_index_seg_del = 335544537;

  /// Cannot update index segment used by an Integrity Constraint
  static const int isc_integ_index_seg_mod = 335544538;

  /// Cannot delete index used by an Integrity Constraint
  static const int isc_integ_index_del = 335544539;

  /// Cannot modify index used by an Integrity Constraint
  static const int isc_integ_index_mod = 335544540;

  /// Cannot delete trigger used by a CHECK Constraint
  static const int isc_check_trig_del = 335544541;

  /// Cannot update trigger used by a CHECK Constraint
  static const int isc_check_trig_update = 335544542;

  /// Cannot delete column being used in an Integrity Constraint.
  static const int isc_cnstrnt_fld_del = 335544543;

  /// Cannot rename column being used in an Integrity Constraint.
  static const int isc_cnstrnt_fld_rename = 335544544;

  /// Cannot update constraints (RDB$RELATION_CONSTRAINTS).
  static const int isc_rel_cnstrnt_update = 335544545;

  /// Cannot define constraints on views
  static const int isc_constaint_on_view = 335544546;

  /// internal Firebird consistency check (invalid RDB$CONSTRAINT_TYPE)
  static const int isc_invld_cnstrnt_type = 335544547;

  /// Attempt to define a second PRIMARY KEY for the same table
  static const int isc_primary_key_exists = 335544548;

  /// cannot modify or erase a system trigger
  static const int isc_systrig_update = 335544549;

  /// only the owner of a table may reassign ownership
  static const int isc_not_rel_owner = 335544550;

  /// could not find object for GRANT
  static const int isc_grant_obj_notfound = 335544551;

  /// could not find column for GRANT
  static const int isc_grant_fld_notfound = 335544552;

  /// user does not have GRANT privileges for operation
  static const int isc_grant_nopriv = 335544553;

  /// object has non-SQL security class defined
  static const int isc_nonsql_security_rel = 335544554;

  /// column has non-SQL security class defined
  static const int isc_nonsql_security_fld = 335544555;

  /// Write-ahead Log without shared cache configuration not allowed
  static const int isc_wal_cache_err = 335544556;

  /// database shutdown unsuccessful
  static const int isc_shutfail = 335544557;

  /// Operation violates CHECK constraint @1 on view or table @2
  static const int isc_check_constraint = 335544558;

  /// invalid service handle
  static const int isc_bad_svc_handle = 335544559;

  /// database @1 shutdown in @2 seconds
  static const int isc_shutwarn = 335544560;

  /// wrong version of service parameter block
  static const int isc_wrospbver = 335544561;

  /// unrecognized service parameter block
  static const int isc_bad_spb_form = 335544562;

  /// service @1 is not defined
  static const int isc_svcnotdef = 335544563;

  /// long-term journaling not enabled
  static const int isc_no_jrn = 335544564;

  /// Cannot transliterate character between character sets
  static const int isc_transliteration_failed = 335544565;

  /// WAL defined; Cache Manager must be started first
  static const int isc_start_cm_for_wal = 335544566;

  /// Overflow log specification required for round-robin log
  static const int isc_wal_ovflow_log_required = 335544567;

  /// Implementation of text subtype @1 not located.
  static const int isc_text_subtype = 335544568;

  /// Dynamic SQL Error
  static const int isc_dsql_error = 335544569;

  /// Invalid command
  static const int isc_dsql_command_err = 335544570;

  /// Data type for constant unknown
  static const int isc_dsql_constant_err = 335544571;

  /// Invalid cursor reference
  static const int isc_dsql_cursor_err = 335544572;

  /// Data type unknown
  static const int isc_dsql_datatype_err = 335544573;

  /// Invalid cursor declaration
  static const int isc_dsql_decl_err = 335544574;

  /// Cursor @1 is not updatable
  static const int isc_dsql_cursor_update_err = 335544575;

  /// Attempt to reopen an open cursor
  static const int isc_dsql_cursor_open_err = 335544576;

  /// Attempt to reclose a closed cursor
  static const int isc_dsql_cursor_close_err = 335544577;

  /// Column unknown
  static const int isc_dsql_field_err = 335544578;

  /// Internal error
  static const int isc_dsql_internal_err = 335544579;

  /// Table unknown
  static const int isc_dsql_relation_err = 335544580;

  /// Procedure unknown
  static const int isc_dsql_procedure_err = 335544581;

  /// Request unknown
  static const int isc_dsql_request_err = 335544582;

  /// SQLDA error
  static const int isc_dsql_sqlda_err = 335544583;

  /// Count of read-write columns does not equal count of values
  static const int isc_dsql_var_count_err = 335544584;

  /// Invalid statement handle
  static const int isc_dsql_stmt_handle = 335544585;

  /// Function unknown
  static const int isc_dsql_function_err = 335544586;

  /// Column is not a BLOB
  static const int isc_dsql_blob_err = 335544587;

  /// COLLATION @1 for CHARACTER SET @2 is not defined
  static const int isc_collation_not_found = 335544588;

  /// COLLATION @1 is not valid for specified CHARACTER SET
  static const int isc_collation_not_for_charset = 335544589;

  /// Option specified more than once
  static const int isc_dsql_dup_option = 335544590;

  /// Unknown transaction option
  static const int isc_dsql_tran_err = 335544591;

  /// Invalid array reference
  static const int isc_dsql_invalid_array = 335544592;

  /// Array declared with too many dimensions
  static const int isc_dsql_max_arr_dim_exceeded = 335544593;

  /// Illegal array dimension range
  static const int isc_dsql_arr_range_error = 335544594;

  /// Trigger unknown
  static const int isc_dsql_trigger_err = 335544595;

  /// Subselect illegal in this context
  static const int isc_dsql_subselect_err = 335544596;

  /// Cannot prepare a CREATE DATABASE/SCHEMA statement
  static const int isc_dsql_crdb_prepare_err = 335544597;

  /// must specify column name for view select expression
  static const int isc_specify_field_err = 335544598;

  /// number of columns does not match select list
  static const int isc_num_field_err = 335544599;

  /// Only simple column names permitted for VIEW WITH CHECK OPTION
  static const int isc_col_name_err = 335544600;

  /// No WHERE clause for VIEW WITH CHECK OPTION
  static const int isc_where_err = 335544601;

  /// Only one table allowed for VIEW WITH CHECK OPTION
  static const int isc_table_view_err = 335544602;

  /// DISTINCT, GROUP or HAVING not permitted for VIEW WITH CHECK OPTION
  static const int isc_distinct_err = 335544603;

  /// FOREIGN KEY column count does not match PRIMARY KEY
  static const int isc_key_field_count_err = 335544604;

  /// No subqueries permitted for VIEW WITH CHECK OPTION
  static const int isc_subquery_err = 335544605;

  /// expression evaluation not supported
  static const int isc_expression_eval_err = 335544606;

  /// gen.c: node not supported
  static const int isc_node_err = 335544607;

  /// Unexpected end of command
  static const int isc_command_end_err = 335544608;

  /// INDEX @1
  static const int isc_index_name = 335544609;

  /// EXCEPTION @1
  static const int isc_exception_name = 335544610;

  /// COLUMN @1
  static const int isc_field_name = 335544611;

  /// Token unknown
  static const int isc_token_err = 335544612;

  /// union not supported
  static const int isc_union_err = 335544613;

  /// Unsupported DSQL construct
  static const int isc_dsql_construct_err = 335544614;

  /// column used with aggregate
  static const int isc_field_aggregate_err = 335544615;

  /// invalid column reference
  static const int isc_field_ref_err = 335544616;

  /// invalid ORDER BY clause
  static const int isc_order_by_err = 335544617;

  /// Return mode by value not allowed for this data type
  static const int isc_return_mode_err = 335544618;

  /// External functions cannot have more than 10 parameters
  static const int isc_extern_func_err = 335544619;

  /// alias @1 conflicts with an alias in the same statement
  static const int isc_alias_conflict_err = 335544620;

  /// alias @1 conflicts with a procedure in the same statement
  static const int isc_procedure_conflict_error = 335544621;

  /// alias @1 conflicts with a table in the same statement
  static const int isc_relation_conflict_err = 335544622;

  /// Illegal use of keyword VALUE
  static const int isc_dsql_domain_err = 335544623;

  /// segment count of 0 defined for index @1
  static const int isc_idx_seg_err = 335544624;

  /// A node name is not permitted in a secondary, shadow, cache or log file name
  static const int isc_node_name_err = 335544625;

  /// TABLE @1
  static const int isc_table_name = 335544626;

  /// PROCEDURE @1
  static const int isc_proc_name = 335544627;

  /// cannot create index @1
  static const int isc_idx_create_err = 335544628;

  /// Write-ahead Log with shadowing configuration not allowed
  static const int isc_wal_shadow_err = 335544629;

  /// there are @1 dependencies
  static const int isc_dependency = 335544630;

  /// too many keys defined for index @1
  static const int isc_idx_key_err = 335544631;

  /// Preceding file did not specify length, so @1 must include starting page number
  static const int isc_dsql_file_length_err = 335544632;

  /// Shadow number must be a positive integer
  static const int isc_dsql_shadow_number_err = 335544633;

  /// Token unknown - line @1, column @2
  static const int isc_dsql_token_unk_err = 335544634;

  /// there is no alias or table named @1 at this scope level
  static const int isc_dsql_no_relation_alias = 335544635;

  /// there is no index @1 for table @2
  static const int isc_indexname = 335544636;

  /// table or procedure @1 is not referenced in plan
  static const int isc_no_stream_plan = 335544637;

  /// table or procedure @1 is referenced more than once in plan; use aliases to distinguish
  static const int isc_stream_twice = 335544638;

  /// table or procedure @1 is referenced in the plan but not the from list
  static const int isc_stream_not_found = 335544639;

  /// Invalid use of CHARACTER SET or COLLATE
  static const int isc_collation_requires_text = 335544640;

  /// Specified domain or source column @1 does not exist
  static const int isc_dsql_domain_not_found = 335544641;

  /// index @1 cannot be used in the specified plan
  static const int isc_index_unused = 335544642;

  /// the table @1 is referenced twice; use aliases to differentiate
  static const int isc_dsql_self_join = 335544643;

  /// attempt to fetch before the first record in a record stream
  static const int isc_stream_bof = 335544644;

  /// the current position is on a crack
  static const int isc_stream_crack = 335544645;

  /// database or file exists
  static const int isc_db_or_file_exists = 335544646;

  /// invalid comparison operator for find operation
  static const int isc_invalid_operator = 335544647;

  /// Connection lost to pipe server
  static const int isc_conn_lost = 335544648;

  /// bad checksum
  static const int isc_bad_checksum = 335544649;

  /// wrong page type
  static const int isc_page_type_err = 335544650;

  /// Cannot insert because the file is readonly or is on a read only medium.
  static const int isc_ext_readonly_err = 335544651;

  /// multiple rows in singleton select
  static const int isc_sing_select_err = 335544652;

  /// cannot attach to password database
  static const int isc_psw_attach = 335544653;

  /// cannot start transaction for password database
  static const int isc_psw_start_trans = 335544654;

  /// invalid direction for find operation
  static const int isc_invalid_direction = 335544655;

  /// variable @1 conflicts with parameter in same procedure
  static const int isc_dsql_var_conflict = 335544656;

  /// Array/BLOB/DATE data types not allowed in arithmetic
  static const int isc_dsql_no_blob_array = 335544657;

  /// @1 is not a valid base table of the specified view
  static const int isc_dsql_base_table = 335544658;

  /// table or procedure @1 is referenced twice in view; use an alias to distinguish
  static const int isc_duplicate_base_table = 335544659;

  /// view @1 has more than one base table; use aliases to distinguish
  static const int isc_view_alias = 335544660;

  /// cannot add index, index root page is full.
  static const int isc_index_root_page_full = 335544661;

  /// BLOB SUB_TYPE @1 is not defined
  static const int isc_dsql_blob_type_unknown = 335544662;

  /// Too many concurrent executions of the same request
  static const int isc_req_max_clones_exceeded = 335544663;

  /// duplicate specification of @1 - not supported
  static const int isc_dsql_duplicate_spec = 335544664;

  /// violation of PRIMARY or UNIQUE KEY constraint "@1" on table "@2"
  static const int isc_unique_key_violation = 335544665;

  /// server version too old to support all CREATE DATABASE options
  static const int isc_srvr_version_too_old = 335544666;

  /// drop database completed with errors
  static const int isc_drdb_completed_with_errs = 335544667;

  /// procedure @1 does not return any values
  static const int isc_dsql_procedure_use_err = 335544668;

  /// count of column list and variable list do not match
  static const int isc_dsql_count_mismatch = 335544669;

  /// attempt to index BLOB column in index @1
  static const int isc_blob_idx_err = 335544670;

  /// attempt to index array column in index @1
  static const int isc_array_idx_err = 335544671;

  /// too few key columns found for index @1 (incorrect column name?)
  static const int isc_key_field_err = 335544672;

  /// cannot delete
  static const int isc_no_delete = 335544673;

  /// last column in a table cannot be deleted
  static const int isc_del_last_field = 335544674;

  /// sort error
  static const int isc_sort_err = 335544675;

  /// sort error: not enough memory
  static const int isc_sort_mem_err = 335544676;

  /// too many versions
  static const int isc_version_err = 335544677;

  /// invalid key position
  static const int isc_inval_key_posn = 335544678;

  /// segments not allowed in expression index @1
  static const int isc_no_segments_err = 335544679;

  /// sort error: corruption in data structure
  static const int isc_crrp_data_err = 335544680;

  /// new record size of @1 bytes is too big
  static const int isc_rec_size_err = 335544681;

  /// Inappropriate self-reference of column
  static const int isc_dsql_field_ref = 335544682;

  /// request depth exceeded. (Recursive definition?)
  static const int isc_req_depth_exceeded = 335544683;

  /// cannot access column @1 in view @2
  static const int isc_no_field_access = 335544684;

  /// dbkey not available for multi-table views
  static const int isc_no_dbkey = 335544685;

  /// journal file wrong format
  static const int isc_jrn_format_err = 335544686;

  /// intermediate journal file full
  static const int isc_jrn_file_full = 335544687;

  /// The prepare statement identifies a prepare statement with an open cursor
  static const int isc_dsql_open_cursor_request = 335544688;

  /// Firebird error
  static const int isc_ib_error = 335544689;

  /// Cache redefined
  static const int isc_cache_redef = 335544690;

  /// Insufficient memory to allocate page buffer cache
  static const int isc_cache_too_small = 335544691;

  /// Log redefined
  static const int isc_log_redef = 335544692;

  /// Log size too small
  static const int isc_log_too_small = 335544693;

  /// Log partition size too small
  static const int isc_partition_too_small = 335544694;

  /// Partitions not supported in series of log file specification
  static const int isc_partition_not_supp = 335544695;

  /// Total length of a partitioned log must be specified
  static const int isc_log_length_spec = 335544696;

  /// Precision must be from 1 to 18
  static const int isc_precision_err = 335544697;

  /// Scale must be between zero and precision
  static const int isc_scale_nogt = 335544698;

  /// Short integer expected
  static const int isc_expec_short = 335544699;

  /// Long integer expected
  static const int isc_expec_long = 335544700;

  /// Unsigned short integer expected
  static const int isc_expec_ushort = 335544701;

  /// Invalid ESCAPE sequence
  static const int isc_escape_invalid = 335544702;

  /// service @1 does not have an associated executable
  static const int isc_svcnoexe = 335544703;

  /// Failed to locate host machine.
  static const int isc_net_lookup_err = 335544704;

  /// Undefined service @1/@2.
  static const int isc_service_unknown = 335544705;

  /// The specified name was not found in the hosts file or Domain Name Services.
  static const int isc_host_unknown = 335544706;

  /// user does not have GRANT privileges on base table/view for operation
  static const int isc_grant_nopriv_on_base = 335544707;

  /// Ambiguous column reference.
  static const int isc_dyn_fld_ambiguous = 335544708;

  /// Invalid aggregate reference
  static const int isc_dsql_agg_ref_err = 335544709;

  /// navigational stream @1 references a view with more than one base table
  static const int isc_complex_view = 335544710;

  /// Attempt to execute an unprepared dynamic SQL statement.
  static const int isc_unprepared_stmt = 335544711;

  /// Positive value expected
  static const int isc_expec_positive = 335544712;

  /// Incorrect values within SQLDA structure
  static const int isc_dsql_sqlda_value_err = 335544713;

  /// invalid blob id
  static const int isc_invalid_array_id = 335544714;

  /// Operation not supported for EXTERNAL FILE table @1
  static const int isc_extfile_uns_op = 335544715;

  /// Service is currently busy: @1
  static const int isc_svc_in_use = 335544716;

  /// stack size insufficent to execute current request
  static const int isc_err_stack_limit = 335544717;

  /// Invalid key for find operation
  static const int isc_invalid_key = 335544718;

  /// Error initializing the network software.
  static const int isc_net_init_error = 335544719;

  /// Unable to load required library @1.
  static const int isc_loadlib_failure = 335544720;

  /// Unable to complete network request to host "@1".
  static const int isc_network_error = 335544721;

  /// Failed to establish a connection.
  static const int isc_net_connect_err = 335544722;

  /// Error while listening for an incoming connection.
  static const int isc_net_connect_listen_err = 335544723;

  /// Failed to establish a secondary connection for event processing.
  static const int isc_net_event_connect_err = 335544724;

  /// Error while listening for an incoming event connection request.
  static const int isc_net_event_listen_err = 335544725;

  /// Error reading data from the connection.
  static const int isc_net_read_err = 335544726;

  /// Error writing data to the connection.
  static const int isc_net_write_err = 335544727;

  /// Cannot deactivate index used by an integrity constraint
  static const int isc_integ_index_deactivate = 335544728;

  /// Cannot deactivate index used by a PRIMARY/UNIQUE constraint
  static const int isc_integ_deactivate_primary = 335544729;

  /// Client/Server Express not supported in this release
  static const int isc_cse_not_supported = 335544730;
  static const int isc_tra_must_sweep = 335544731;

  /// Access to databases on file servers is not supported.
  static const int isc_unsupported_network_drive = 335544732;

  /// Error while trying to create file
  static const int isc_io_create_err = 335544733;

  /// Error while trying to open file
  static const int isc_io_open_err = 335544734;

  /// Error while trying to close file
  static const int isc_io_close_err = 335544735;

  /// Error while trying to read from file
  static const int isc_io_read_err = 335544736;

  /// Error while trying to write to file
  static const int isc_io_write_err = 335544737;

  /// Error while trying to delete file
  static const int isc_io_delete_err = 335544738;

  /// Error while trying to access file
  static const int isc_io_access_err = 335544739;

  /// A fatal exception occurred during the execution of a user defined function.
  static const int isc_udf_exception = 335544740;

  /// connection lost to database
  static const int isc_lost_db_connection = 335544741;

  /// User cannot write to RDB$USER_PRIVILEGES
  static const int isc_no_write_user_priv = 335544742;

  /// token size exceeds limit
  static const int isc_token_too_long = 335544743;

  /// Maximum user count exceeded. Contact your database administrator.
  static const int isc_max_att_exceeded = 335544744;

  /// Your login @1 is same as one of the SQL role name. Ask your database administrator to set up a valid Firebird login.
  static const int isc_login_same_as_role_name = 335544745;

  /// "REFERENCES table" without "(column)" requires PRIMARY KEY on referenced table
  static const int isc_reftable_requires_pk = 335544746;

  /// The username entered is too long. Maximum length is 31 bytes.
  static const int isc_usrname_too_long = 335544747;

  /// The password specified is too long. Maximum length is 8 bytes.
  static const int isc_password_too_long = 335544748;

  /// A username is required for this operation.
  static const int isc_usrname_required = 335544749;

  /// A password is required for this operation
  static const int isc_password_required = 335544750;

  /// The network protocol specified is invalid
  static const int isc_bad_protocol = 335544751;

  /// A duplicate user name was found in the security database
  static const int isc_dup_usrname_found = 335544752;

  /// The user name specified was not found in the security database
  static const int isc_usrname_not_found = 335544753;

  /// An error occurred while attempting to add the user.
  static const int isc_error_adding_sec_record = 335544754;

  /// An error occurred while attempting to modify the user record.
  static const int isc_error_modifying_sec_record = 335544755;

  /// An error occurred while attempting to delete the user record.
  static const int isc_error_deleting_sec_record = 335544756;

  /// An error occurred while updating the security database.
  static const int isc_error_updating_sec_db = 335544757;

  /// sort record size of @1 bytes is too big
  static const int isc_sort_rec_size_err = 335544758;

  /// can not define a not null column with NULL as default value
  static const int isc_bad_default_value = 335544759;

  /// invalid clause --- '@1'
  static const int isc_invalid_clause = 335544760;

  /// too many open handles to database
  static const int isc_too_many_handles = 335544761;

  /// size of optimizer block exceeded
  static const int isc_optimizer_blk_exc = 335544762;

  /// a string constant is delimited by double quotes
  static const int isc_invalid_string_constant = 335544763;

  /// DATE must be changed to TIMESTAMP
  static const int isc_transitional_date = 335544764;

  /// attempted update on read-only database
  static const int isc_read_only_database = 335544765;

  /// SQL dialect @1 is not supported in this database
  static const int isc_must_be_dialect_2_and_up = 335544766;

  /// A fatal exception occurred during the execution of a blob filter.
  static const int isc_blob_filter_exception = 335544767;

  /// Access violation. The code attempted to access a virtual address without privilege to do so.
  static const int isc_exception_access_violation = 335544768;

  /// Datatype misalignment. The attempted to read or write a value that was not stored on a memory boundary.
  static const int isc_exception_datatype_missalignment = 335544769;

  /// Array bounds exceeded. The code attempted to access an array element that is out of bounds.
  static const int isc_exception_array_bounds_exceeded = 335544770;

  /// Float denormal operand. One of the floating-point operands is too small to represent a standard float value.
  static const int isc_exception_float_denormal_operand = 335544771;

  /// Floating-point divide by zero. The code attempted to divide a floating-point value by zero.
  static const int isc_exception_float_divide_by_zero = 335544772;

  /// Floating-point inexact result. The result of a floating-point operation cannot be represented as a decimal fraction.
  static const int isc_exception_float_inexact_result = 335544773;

  /// Floating-point invalid operand. An indeterminant error occurred during a floating-point operation.
  static const int isc_exception_float_invalid_operand = 335544774;

  /// Floating-point overflow. The exponent of a floating-point operation is greater than the magnitude allowed.
  static const int isc_exception_float_overflow = 335544775;

  /// Floating-point stack check. The stack overflowed or underflowed as the result of a floating-point operation.
  static const int isc_exception_float_stack_check = 335544776;

  /// Floating-point underflow. The exponent of a floating-point operation is less than the magnitude allowed.
  static const int isc_exception_float_underflow = 335544777;

  /// Integer divide by zero. The code attempted to divide an integer value by an integer divisor of zero.
  static const int isc_exception_integer_divide_by_zero = 335544778;

  /// Integer overflow. The result of an integer operation caused the most significant bit of the result to carry.
  static const int isc_exception_integer_overflow = 335544779;

  /// An exception occurred that does not have a description. Exception number @1.
  static const int isc_exception_unknown = 335544780;

  /// Stack overflow. The resource requirements of the runtime stack have exceeded the memory available to it.
  static const int isc_exception_stack_overflow = 335544781;

  /// Segmentation Fault. The code attempted to access memory without privileges.
  static const int isc_exception_sigsegv = 335544782;

  /// Illegal Instruction. The Code attempted to perform an illegal operation.
  static const int isc_exception_sigill = 335544783;

  /// Bus Error. The Code caused a system bus error.
  static const int isc_exception_sigbus = 335544784;

  /// Floating Point Error. The Code caused an Arithmetic Exception or a floating point exception.
  static const int isc_exception_sigfpe = 335544785;

  /// Cannot delete rows from external files.
  static const int isc_ext_file_delete = 335544786;

  /// Cannot update rows in external files.
  static const int isc_ext_file_modify = 335544787;

  /// Unable to perform operation
  static const int isc_adm_task_denied = 335544788;

  /// Specified EXTRACT part does not exist in input datatype
  static const int isc_extract_input_mismatch = 335544789;

  /// Service @1 requires SYSDBA permissions. Reattach to the Service Manager using the SYSDBA account.
  static const int isc_insufficient_svc_privileges = 335544790;

  /// The file @1 is currently in use by another process. Try again later.
  static const int isc_file_in_use = 335544791;

  /// Cannot attach to services manager
  static const int isc_service_att_err = 335544792;

  /// Metadata update statement is not allowed by the current database SQL dialect @1
  static const int isc_ddl_not_allowed_by_db_sql_dial = 335544793;

  /// operation was cancelled
  static const int isc_cancelled = 335544794;

  /// unexpected item in service parameter block, expected @1
  static const int isc_unexp_spb_form = 335544795;

  /// Client SQL dialect @1 does not support reference to @2 datatype
  static const int isc_sql_dialect_datatype_unsupport = 335544796;

  /// user name and password are required while attaching to the services manager
  static const int isc_svcnouser = 335544797;

  /// You created an indirect dependency on uncommitted metadata. You must roll back the current transaction.
  static const int isc_depend_on_uncommitted_rel = 335544798;

  /// The service name was not specified.
  static const int isc_svc_name_missing = 335544799;

  /// Too many Contexts of Relation/Procedure/Views. Maximum allowed is 256
  static const int isc_too_many_contexts = 335544800;

  /// data type not supported for arithmetic
  static const int isc_datype_notsup = 335544801;

  /// Database dialect being changed from 3 to 1
  static const int isc_dialect_reset_warning = 335544802;

  /// Database dialect not changed.
  static const int isc_dialect_not_changed = 335544803;

  /// Unable to create database @1
  static const int isc_database_create_failed = 335544804;

  /// Database dialect @1 is not a valid dialect.
  static const int isc_inv_dialect_specified = 335544805;

  /// Valid database dialects are @1.
  static const int isc_valid_db_dialects = 335544806;

  /// SQL warning code = @1
  static const int isc_sqlwarn = 335544807;

  /// DATE data type is now called TIMESTAMP
  static const int isc_dtype_renamed = 335544808;

  /// Function @1 is in @2, which is not in a permitted directory for external functions.
  static const int isc_extern_func_dir_error = 335544809;

  /// value exceeds the range for valid dates
  static const int isc_date_range_exceeded = 335544810;

  /// passed client dialect @1 is not a valid dialect.
  static const int isc_inv_client_dialect_specified = 335544811;

  /// Valid client dialects are @1.
  static const int isc_valid_client_dialects = 335544812;

  /// Unsupported field type specified in BETWEEN predicate.
  static const int isc_optimizer_between_err = 335544813;

  /// Services functionality will be supported in a later version of the product
  static const int isc_service_not_supported = 335544814;

  /// GENERATOR @1
  static const int isc_generator_name = 335544815;

  /// Function @1
  static const int isc_udf_name = 335544816;

  /// Invalid parameter to FETCH or FIRST. Only integers >= 0 are allowed.
  static const int isc_bad_limit_param = 335544817;

  /// Invalid parameter to OFFSET or SKIP. Only integers >= 0 are allowed.
  static const int isc_bad_skip_param = 335544818;

  /// File exceeded maximum size of 2GB. Add another database file or use a 64 bit I/O version of Firebird.
  static const int isc_io_32bit_exceeded_err = 335544819;

  /// Unable to find savepoint with name @1 in transaction context
  static const int isc_invalid_savepoint = 335544820;

  /// Invalid column position used in the @1 clause
  static const int isc_dsql_column_pos_err = 335544821;

  /// Cannot use an aggregate or window function in a WHERE clause, use HAVING (for aggregate only) instead
  static const int isc_dsql_agg_where_err = 335544822;

  /// Cannot use an aggregate or window function in a GROUP BY clause
  static const int isc_dsql_agg_group_err = 335544823;

  /// Invalid expression in the @1 (not contained in either an aggregate function or the GROUP BY clause)
  static const int isc_dsql_agg_column_err = 335544824;

  /// Invalid expression in the @1 (neither an aggregate function nor a part of the GROUP BY clause)
  static const int isc_dsql_agg_having_err = 335544825;

  /// Nested aggregate and window functions are not allowed
  static const int isc_dsql_agg_nested_err = 335544826;

  /// Invalid argument in EXECUTE STATEMENT - cannot convert to string
  static const int isc_exec_sql_invalid_arg = 335544827;

  /// Wrong request type in EXECUTE STATEMENT '@1'
  static const int isc_exec_sql_invalid_req = 335544828;

  /// Variable type (position @1) in EXECUTE STATEMENT '@2' INTO does not match returned column type
  static const int isc_exec_sql_invalid_var = 335544829;

  /// Too many recursion levels of EXECUTE STATEMENT
  static const int isc_exec_sql_max_call_exceeded = 335544830;

  /// Use of @1 at location @2 is not allowed by server configuration
  static const int isc_conf_access_denied = 335544831;

  /// Cannot change difference file name while database is in backup mode
  static const int isc_wrong_backup_state = 335544832;

  /// Physical backup is not allowed while Write-Ahead Log is in use
  static const int isc_wal_backup_err = 335544833;

  /// Cursor is not open
  static const int isc_cursor_not_open = 335544834;

  /// Target shutdown mode is invalid for database "@1"
  static const int isc_bad_shutdown_mode = 335544835;

  /// Concatenation overflow. Resulting string cannot exceed 32765 bytes in length.
  static const int isc_concat_overflow = 335544836;

  /// Invalid offset parameter @1 to SUBSTRING. Only positive integers are allowed.
  static const int isc_bad_substring_offset = 335544837;

  /// Foreign key reference target does not exist
  static const int isc_foreign_key_target_doesnt_exist = 335544838;

  /// Foreign key references are present for the record
  static const int isc_foreign_key_references_present = 335544839;

  /// cannot update
  static const int isc_no_update = 335544840;

  /// Cursor is already open
  static const int isc_cursor_already_open = 335544841;

  /// @1
  static const int isc_stack_trace = 335544842;

  /// Context variable '@1' is not found in namespace '@2'
  static const int isc_ctx_var_not_found = 335544843;

  /// Invalid namespace name '@1' passed to @2
  static const int isc_ctx_namespace_invalid = 335544844;

  /// Too many context variables
  static const int isc_ctx_too_big = 335544845;

  /// Invalid argument passed to @1
  static const int isc_ctx_bad_argument = 335544846;

  /// BLR syntax error. Identifier @1?? is too long
  static const int isc_identifier_too_long = 335544847;

  /// exception @1
  static const int isc_except2 = 335544848;

  /// Malformed string
  static const int isc_malformed_string = 335544849;

  /// Output parameter mismatch for procedure @1
  static const int isc_prc_out_param_mismatch = 335544850;

  /// Unexpected end of command - line @1, column @2
  static const int isc_command_end_err2 = 335544851;

  /// partner index segment no @1 has incompatible data type
  static const int isc_partner_idx_incompat_type = 335544852;

  /// Invalid length parameter @1 to SUBSTRING. Negative integers are not allowed.
  static const int isc_bad_substring_length = 335544853;

  /// CHARACTER SET @1 is not installed
  static const int isc_charset_not_installed = 335544854;

  /// COLLATION @1 for CHARACTER SET @2 is not installed
  static const int isc_collation_not_installed = 335544855;

  /// connection shutdown
  static const int isc_att_shutdown = 335544856;

  /// Maximum BLOB size exceeded
  static const int isc_blobtoobig = 335544857;

  /// Can't have relation with only computed fields or constraints
  static const int isc_must_have_phys_field = 335544858;

  /// Time precision exceeds allowed range (0-@1)
  static const int isc_invalid_time_precision = 335544859;

  /// Unsupported conversion to target type BLOB (subtype @1)
  static const int isc_blob_convert_error = 335544860;

  /// Unsupported conversion to target type ARRAY
  static const int isc_array_convert_error = 335544861;

  /// Stream does not support record locking
  static const int isc_record_lock_not_supp = 335544862;

  /// Cannot create foreign key constraint @1. Partner index does not exist or is inactive.
  static const int isc_partner_idx_not_found = 335544863;

  /// Transactions count exceeded. Perform backup and restore to make database operable again
  static const int isc_tra_num_exc = 335544864;

  /// Column has been unexpectedly deleted
  static const int isc_field_disappeared = 335544865;

  /// @1 cannot depend on @2
  static const int isc_met_wrong_gtt_scope = 335544866;

  /// Blob sub_types bigger than 1 (text) are for internal use only
  static const int isc_subtype_for_internal_use = 335544867;

  /// Procedure @1 is not selectable (it does not contain a SUSPEND statement)
  static const int isc_illegal_prc_type = 335544868;

  /// Datatype @1 is not supported for sorting operation
  static const int isc_invalid_sort_datatype = 335544869;

  /// COLLATION @1
  static const int isc_collation_name = 335544870;

  /// DOMAIN @1
  static const int isc_domain_name = 335544871;

  /// domain @1 is not defined
  static const int isc_domnotdef = 335544872;

  /// Array data type can use up to @1 dimensions
  static const int isc_array_max_dimensions = 335544873;

  /// A multi database transaction cannot span more than @1 databases
  static const int isc_max_db_per_trans_allowed = 335544874;

  /// Bad debug info format
  static const int isc_bad_debug_format = 335544875;

  /// Error while parsing procedure @1's BLR
  static const int isc_bad_proc_BLR = 335544876;

  /// index key too big
  static const int isc_key_too_big = 335544877;

  /// concurrent transaction number is @1
  static const int isc_concurrent_transaction = 335544878;

  /// validation error for variable @1, value "@2"
  static const int isc_not_valid_for_var = 335544879;

  /// validation error for @1, value "@2"
  static const int isc_not_valid_for = 335544880;

  /// Difference file name should be set explicitly for database on raw device
  static const int isc_need_difference = 335544881;

  /// Login name too long (@1 characters, maximum allowed @2)
  static const int isc_long_login = 335544882;

  /// column @1 is not defined in procedure @2
  static const int isc_fldnotdef2 = 335544883;

  /// Invalid SIMILAR TO pattern
  static const int isc_invalid_similar_pattern = 335544884;

  /// Invalid TEB format
  static const int isc_bad_teb_form = 335544885;

  /// Found more than one transaction isolation in TPB
  static const int isc_tpb_multiple_txn_isolation = 335544886;

  /// Table reservation lock type @1 requires table name before in TPB
  static const int isc_tpb_reserv_before_table = 335544887;

  /// Found more than one @1 specification in TPB
  static const int isc_tpb_multiple_spec = 335544888;

  /// Option @1 requires READ COMMITTED isolation in TPB
  static const int isc_tpb_option_without_rc = 335544889;

  /// Option @1 is not valid if @2 was used previously in TPB
  static const int isc_tpb_conflicting_options = 335544890;

  /// Table name length missing after table reservation @1 in TPB
  static const int isc_tpb_reserv_missing_tlen = 335544891;

  /// Table name length @1 is too long after table reservation @2 in TPB
  static const int isc_tpb_reserv_long_tlen = 335544892;

  /// Table name length @1 without table name after table reservation @2 in TPB
  static const int isc_tpb_reserv_missing_tname = 335544893;

  /// Table name length @1 goes beyond the remaining TPB size after table reservation @2
  static const int isc_tpb_reserv_corrup_tlen = 335544894;

  /// Table name length is zero after table reservation @1 in TPB
  static const int isc_tpb_reserv_null_tlen = 335544895;

  /// Table or view @1 not defined in system tables after table reservation @2 in TPB
  static const int isc_tpb_reserv_relnotfound = 335544896;

  /// Base table or view @1 for view @2 not defined in system tables after table reservation @3 in TPB
  static const int isc_tpb_reserv_baserelnotfound = 335544897;

  /// Option length missing after option @1 in TPB
  static const int isc_tpb_missing_len = 335544898;

  /// Option length @1 without value after option @2 in TPB
  static const int isc_tpb_missing_value = 335544899;

  /// Option length @1 goes beyond the remaining TPB size after option @2
  static const int isc_tpb_corrupt_len = 335544900;

  /// Option length is zero after table reservation @1 in TPB
  static const int isc_tpb_null_len = 335544901;

  /// Option length @1 exceeds the range for option @2 in TPB
  static const int isc_tpb_overflow_len = 335544902;

  /// Option value @1 is invalid for the option @2 in TPB
  static const int isc_tpb_invalid_value = 335544903;

  /// Preserving previous table reservation @1 for table @2, stronger than new @3 in TPB
  static const int isc_tpb_reserv_stronger_wng = 335544904;

  /// Table reservation @1 for table @2 already specified and is stronger than new @3 in TPB
  static const int isc_tpb_reserv_stronger = 335544905;

  /// Table reservation reached maximum recursion of @1 when expanding views in TPB
  static const int isc_tpb_reserv_max_recursion = 335544906;

  /// Table reservation in TPB cannot be applied to @1 because it's a virtual table
  static const int isc_tpb_reserv_virtualtbl = 335544907;

  /// Table reservation in TPB cannot be applied to @1 because it's a system table
  static const int isc_tpb_reserv_systbl = 335544908;

  /// Table reservation @1 or @2 in TPB cannot be applied to @3 because it's a temporary table
  static const int isc_tpb_reserv_temptbl = 335544909;

  /// Cannot set the transaction in read only mode after a table reservation isc_tpb_lock_write in TPB
  static const int isc_tpb_readtxn_after_writelock = 335544910;

  /// Cannot take a table reservation isc_tpb_lock_write in TPB because the transaction is in read only mode
  static const int isc_tpb_writelock_after_readtxn = 335544911;

  /// value exceeds the range for a valid time
  static const int isc_time_range_exceeded = 335544912;

  /// value exceeds the range for valid timestamps
  static const int isc_datetime_range_exceeded = 335544913;

  /// string right truncation
  static const int isc_string_truncation = 335544914;

  /// blob truncation when converting to a string: length limit exceeded
  static const int isc_blob_truncation = 335544915;

  /// numeric value is out of range
  static const int isc_numeric_out_of_range = 335544916;

  /// Firebird shutdown is still in progress after the specified timeout
  static const int isc_shutdown_timeout = 335544917;

  /// Attachment handle is busy
  static const int isc_att_handle_busy = 335544918;

  /// Bad written UDF detected: pointer returned in FREE_IT function was not allocated by ib_util_malloc
  static const int isc_bad_udf_freeit = 335544919;

  /// External Data Source provider '@1' not found
  static const int isc_eds_provider_not_found = 335544920;

  /// Execute statement error at @1 : @2Data source : @3
  static const int isc_eds_connection = 335544921;

  /// Execute statement preprocess SQL error
  static const int isc_eds_preprocess = 335544922;

  /// Statement expected
  static const int isc_eds_stmt_expected = 335544923;

  /// Parameter name expected
  static const int isc_eds_prm_name_expected = 335544924;

  /// Unclosed comment found near '@1'
  static const int isc_eds_unclosed_comment = 335544925;

  /// Execute statement error at @1 : @2Statement : @3 Data source : @4
  static const int isc_eds_statement = 335544926;

  /// Input parameters mismatch
  static const int isc_eds_input_prm_mismatch = 335544927;

  /// Output parameters mismatch
  static const int isc_eds_output_prm_mismatch = 335544928;

  /// Input parameter '@1' have no value set
  static const int isc_eds_input_prm_not_set = 335544929;

  /// BLR stream length @1 exceeds implementation limit @2
  static const int isc_too_big_blr = 335544930;

  /// Monitoring table space exhausted
  static const int isc_montabexh = 335544931;

  /// module name or entrypoint could not be found
  static const int isc_modnotfound = 335544932;

  /// nothing to cancel
  static const int isc_nothing_to_cancel = 335544933;

  /// ib_util library has not been loaded to deallocate memory returned by FREE_IT function
  static const int isc_ibutil_not_loaded = 335544934;

  /// Cannot have circular dependencies with computed fields
  static const int isc_circular_computed = 335544935;

  /// Security database error
  static const int isc_psw_db_error = 335544936;

  /// Invalid data type in DATE/TIME/TIMESTAMP addition or subtraction in add_datettime()
  static const int isc_invalid_type_datetime_op = 335544937;

  /// Only a TIME value can be added to a DATE value
  static const int isc_onlycan_add_timetodate = 335544938;

  /// Only a DATE value can be added to a TIME value
  static const int isc_onlycan_add_datetotime = 335544939;

  /// TIMESTAMP values can be subtracted only from another TIMESTAMP value
  static const int isc_onlycansub_tstampfromtstamp = 335544940;

  /// Only one operand can be of type TIMESTAMP
  static const int isc_onlyoneop_mustbe_tstamp = 335544941;

  /// Only HOUR, MINUTE, SECOND and MILLISECOND can be extracted from TIME values
  static const int isc_invalid_extractpart_time = 335544942;

  /// HOUR, MINUTE, SECOND and MILLISECOND cannot be extracted from DATE values
  static const int isc_invalid_extractpart_date = 335544943;

  /// Invalid argument for EXTRACT() not being of DATE/TIME/TIMESTAMP type
  static const int isc_invalidarg_extract = 335544944;

  /// Arguments for @1 must be integral types or NUMERIC/DECIMAL without scale
  static const int isc_sysf_argmustbe_exact = 335544945;

  /// First argument for @1 must be integral type or floating point type
  static const int isc_sysf_argmustbe_exact_or_fp = 335544946;

  /// Human readable UUID argument for @1 must be of string type
  static const int isc_sysf_argviolates_uuidtype = 335544947;

  /// Human readable UUID argument for @2 must be of exact length @1
  static const int isc_sysf_argviolates_uuidlen = 335544948;

  /// Human readable UUID argument for @3 must have "-" at position @2 instead of "@1"
  static const int isc_sysf_argviolates_uuidfmt = 335544949;

  /// Human readable UUID argument for @3 must have hex digit at position @2 instead of "@1"
  static const int isc_sysf_argviolates_guidigits = 335544950;

  /// Only HOUR, MINUTE, SECOND and MILLISECOND can be added to TIME values in @1
  static const int isc_sysf_invalid_addpart_time = 335544951;

  /// Invalid data type in addition of part to DATE/TIME/TIMESTAMP in @1
  static const int isc_sysf_invalid_add_datetime = 335544952;

  /// Invalid part @1 to be added to a DATE/TIME/TIMESTAMP value in @2
  static const int isc_sysf_invalid_addpart_dtime = 335544953;

  /// Expected DATE/TIME/TIMESTAMP type in evlDateAdd() result
  static const int isc_sysf_invalid_add_dtime_rc = 335544954;

  /// Expected DATE/TIME/TIMESTAMP type as first and second argument to @1
  static const int isc_sysf_invalid_diff_dtime = 335544955;

  /// The result of TIME-<value> in @1 cannot be expressed in YEAR, MONTH, DAY or WEEK
  static const int isc_sysf_invalid_timediff = 335544956;

  /// The result of TIME-TIMESTAMP or TIMESTAMP-TIME in @1 cannot be expressed in HOUR, MINUTE, SECOND or MILLISECOND
  static const int isc_sysf_invalid_tstamptimediff = 335544957;

  /// The result of DATE-TIME or TIME-DATE in @1 cannot be expressed in HOUR, MINUTE, SECOND and MILLISECOND
  static const int isc_sysf_invalid_datetimediff = 335544958;

  /// Invalid part @1 to express the difference between two DATE/TIME/TIMESTAMP values in @2
  static const int isc_sysf_invalid_diffpart = 335544959;

  /// Argument for @1 must be positive
  static const int isc_sysf_argmustbe_positive = 335544960;

  /// Base for @1 must be positive
  static const int isc_sysf_basemustbe_positive = 335544961;

  /// Argument #@1 for @2 must be zero or positive
  static const int isc_sysf_argnmustbe_nonneg = 335544962;

  /// Argument #@1 for @2 must be positive
  static const int isc_sysf_argnmustbe_positive = 335544963;

  /// Base for @1 cannot be zero if exponent is negative
  static const int isc_sysf_invalid_zeropowneg = 335544964;

  /// Base for @1 cannot be negative if exponent is not an integral value
  static const int isc_sysf_invalid_negpowfp = 335544965;

  /// The numeric scale must be between -128 and 127 in @1
  static const int isc_sysf_invalid_scale = 335544966;

  /// Argument for @1 must be zero or positive
  static const int isc_sysf_argmustbe_nonneg = 335544967;

  /// Binary UUID argument for @1 must be of string type
  static const int isc_sysf_binuuid_mustbe_str = 335544968;

  /// Binary UUID argument for @2 must use @1 bytes
  static const int isc_sysf_binuuid_wrongsize = 335544969;

  /// Missing required item @1 in service parameter block
  static const int isc_missing_required_spb = 335544970;

  /// @1 server is shutdown
  static const int isc_net_server_shutdown = 335544971;

  /// Invalid connection string
  static const int isc_bad_conn_str = 335544972;

  /// Unrecognized events block
  static const int isc_bad_epb_form = 335544973;

  /// Could not start first worker thread - shutdown server
  static const int isc_no_threads = 335544974;

  /// Timeout occurred while waiting for a secondary connection for event processing
  static const int isc_net_event_connect_timeout = 335544975;

  /// Argument for @1 must be different than zero
  static const int isc_sysf_argmustbe_nonzero = 335544976;

  /// Argument for @1 must be in the range -1, 1
  static const int isc_sysf_argmustbe_range_inc1_1 = 335544977;

  /// Argument for @1 must be greater or equal than one
  static const int isc_sysf_argmustbe_gteq_one = 335544978;

  /// Argument for @1 must be in the range -1, 1
  static const int isc_sysf_argmustbe_range_exc1_1 = 335544979;

  /// Incorrect parameters provided to internal function @1
  static const int isc_internal_rejected_params = 335544980;

  /// Floating point overflow in built-in function @1
  static const int isc_sysf_fp_overflow = 335544981;

  /// Floating point overflow in result from UDF @1
  static const int isc_udf_fp_overflow = 335544982;

  /// Invalid floating point value returned by UDF @1
  static const int isc_udf_fp_nan = 335544983;

  /// Shared memory area is probably already created by another engine instance in another Windows session
  static const int isc_instance_conflict = 335544984;

  /// No free space found in temporary directories
  static const int isc_out_of_temp_space = 335544985;

  /// Explicit transaction control is not allowed
  static const int isc_eds_expl_tran_ctrl = 335544986;

  /// Use of TRUSTED switches in spb_command_line is prohibited
  static const int isc_no_trusted_spb = 335544987;

  /// PACKAGE @1
  static const int isc_package_name = 335544988;

  /// Cannot make field @1 of table @2 NOT NULL because there are NULLs present
  static const int isc_cannot_make_not_null = 335544989;

  /// Feature @1 is not supported anymore
  static const int isc_feature_removed = 335544990;

  /// VIEW @1
  static const int isc_view_name = 335544991;

  /// Can not access lock files directory @1
  static const int isc_lock_dir_access = 335544992;

  /// Fetch option @1 is invalid for a non-scrollable cursor
  static const int isc_invalid_fetch_option = 335544993;

  /// Error while parsing function @1's BLR
  static const int isc_bad_fun_BLR = 335544994;

  /// Cannot execute function @1 of the unimplemented package @2
  static const int isc_func_pack_not_implemented = 335544995;

  /// Cannot execute procedure @1 of the unimplemented package @2
  static const int isc_proc_pack_not_implemented = 335544996;

  /// External function @1 not returned by the external engine plugin @2
  static const int isc_eem_func_not_returned = 335544997;

  /// External procedure @1 not returned by the external engine plugin @2
  static const int isc_eem_proc_not_returned = 335544998;

  /// External trigger @1 not returned by the external engine plugin @2
  static const int isc_eem_trig_not_returned = 335544999;

  /// Incompatible plugin version @1 for external engine @2
  static const int isc_eem_bad_plugin_ver = 335545000;

  /// External engine @1 not found
  static const int isc_eem_engine_notfound = 335545001;

  /// Attachment is in use
  static const int isc_attachment_in_use = 335545002;

  /// Transaction is in use
  static const int isc_transaction_in_use = 335545003;

  /// Error loading plugin @1
  static const int isc_pman_cannot_load_plugin = 335545004;

  /// Loadable module @1 not found
  static const int isc_pman_module_notfound = 335545005;

  /// Standard plugin entrypoint does not exist in module @1
  static const int isc_pman_entrypoint_notfound = 335545006;

  /// Module @1 exists but can not be loaded
  static const int isc_pman_module_bad = 335545007;

  /// Module @1 does not contain plugin @2 type @3
  static const int isc_pman_plugin_notfound = 335545008;

  /// Invalid usage of context namespace DDL_TRIGGER
  static const int isc_sysf_invalid_trig_namespace = 335545009;

  /// Value is NULL but isNull parameter was not informed
  static const int isc_unexpected_null = 335545010;

  /// Type @1 is incompatible with BLOB
  static const int isc_type_notcompat_blob = 335545011;

  /// Invalid date
  static const int isc_invalid_date_val = 335545012;

  /// Invalid time
  static const int isc_invalid_time_val = 335545013;

  /// Invalid timestamp
  static const int isc_invalid_timestamp_val = 335545014;

  /// Invalid index @1 in function @2
  static const int isc_invalid_index_val = 335545015;

  /// @1
  static const int isc_formatted_exception = 335545016;

  /// Asynchronous call is already running for this attachment
  static const int isc_async_active = 335545017;

  /// Function @1 is private to package @2
  static const int isc_private_function = 335545018;

  /// Procedure @1 is private to package @2
  static const int isc_private_procedure = 335545019;

  /// Request can't access new records in relation @1 and should be recompiled
  static const int isc_request_outdated = 335545020;

  /// invalid events id (handle)
  static const int isc_bad_events_handle = 335545021;

  /// Cannot copy statement @1
  static const int isc_cannot_copy_stmt = 335545022;

  /// Invalid usage of boolean expression
  static const int isc_invalid_boolean_usage = 335545023;

  /// Arguments for @1 cannot both be zero
  static const int isc_sysf_argscant_both_be_zero = 335545024;

  /// missing service ID in spb
  static const int isc_spb_no_id = 335545025;

  /// External BLR message mismatch: invalid null descriptor at field @1
  static const int isc_ee_blr_mismatch_null = 335545026;

  /// External BLR message mismatch: length = @1, expected @2
  static const int isc_ee_blr_mismatch_length = 335545027;

  /// Subscript @1 out of bounds @2, @3
  static const int isc_ss_out_of_bounds = 335545028;

  /// Install incomplete. To complete security database initialization please CREATE USER. For details read doc/README.security_database.txt.
  static const int isc_missing_data_structures = 335545029;

  /// @1 operation is not allowed for system table @2
  static const int isc_protect_sys_tab = 335545030;

  /// Libtommath error code @1 in function @2
  static const int isc_libtommath_generic = 335545031;

  /// unsupported BLR version (expected between @1 and @2, encountered @3)
  static const int isc_wroblrver2 = 335545032;

  /// expected length @1, actual @2
  static const int isc_trunc_limits = 335545033;

  /// Wrong info requested in isc_svc_query() for anonymous service
  static const int isc_info_access = 335545034;

  /// No isc_info_svc_stdin in user request, but service thread requested stdin data
  static const int isc_svc_no_stdin = 335545035;

  /// Start request for anonymous service is impossible
  static const int isc_svc_start_failed = 335545036;

  /// All services except for getting server log require switches
  static const int isc_svc_no_switches = 335545037;

  /// Size of stdin data is more than was requested from client
  static const int isc_svc_bad_size = 335545038;

  /// Crypt plugin @1 failed to load
  static const int isc_no_crypt_plugin = 335545039;

  /// Length of crypt plugin name should not exceed @1 bytes
  static const int isc_cp_name_too_long = 335545040;

  /// Crypt failed - already crypting database
  static const int isc_cp_process_active = 335545041;

  /// Crypt failed - database is already in requested state
  static const int isc_cp_already_crypted = 335545042;

  /// Missing crypt plugin, but page appears encrypted
  static const int isc_decrypt_error = 335545043;

  /// No providers loaded
  static const int isc_no_providers = 335545044;

  /// NULL data with non-zero SPB length
  static const int isc_null_spb = 335545045;

  /// Maximum (@1) number of arguments exceeded for function @2
  static const int isc_max_args_exceeded = 335545046;

  /// External BLR message mismatch: names count = @1, blr count = @2
  static const int isc_ee_blr_mismatch_names_count = 335545047;

  /// External BLR message mismatch: name @1 not found
  static const int isc_ee_blr_mismatch_name_not_found = 335545048;

  /// Invalid resultset interface
  static const int isc_bad_result_set = 335545049;

  /// Message length passed from user application does not match set of columns
  static const int isc_wrong_message_length = 335545050;

  /// Resultset is missing output format information
  static const int isc_no_output_format = 335545051;

  /// Message metadata not ready - item @1 is not finished
  static const int isc_item_finish = 335545052;

  /// Missing configuration file: @1
  static const int isc_miss_config = 335545053;

  /// @1: illegal line <@2>
  static const int isc_conf_line = 335545054;

  /// Invalid include operator in @1 for <@2>
  static const int isc_conf_include = 335545055;

  /// Include depth too big
  static const int isc_include_depth = 335545056;

  /// File to include not found
  static const int isc_include_miss = 335545057;

  /// Only the owner can change the ownership
  static const int isc_protect_ownership = 335545058;

  /// undefined variable number
  static const int isc_badvarnum = 335545059;

  /// Missing security context for @1
  static const int isc_sec_context = 335545060;

  /// Missing segment @1 in multisegment connect block parameter
  static const int isc_multi_segment = 335545061;

  /// Different logins in connect and attach packets - client library error
  static const int isc_login_changed = 335545062;

  /// Exceeded exchange limit during authentication handshake
  static const int isc_auth_handshake_limit = 335545063;

  /// Incompatible wire encryption levels requested on client and server
  static const int isc_wirecrypt_incompatible = 335545064;

  /// Client attempted to attach unencrypted but wire encryption is required
  static const int isc_miss_wirecrypt = 335545065;

  /// Client attempted to start wire encryption using unknown key @1
  static const int isc_wirecrypt_key = 335545066;

  /// Client attempted to start wire encryption using unsupported plugin @1
  static const int isc_wirecrypt_plugin = 335545067;

  /// Error getting security database name from configuration file
  static const int isc_secdb_name = 335545068;

  /// Client authentication plugin is missing required data from server
  static const int isc_auth_data = 335545069;

  /// Client authentication plugin expected @2 bytes of @3 from server, got @1
  static const int isc_auth_datalength = 335545070;

  /// Attempt to get information about an unprepared dynamic SQL statement.
  static const int isc_info_unprepared_stmt = 335545071;

  /// Problematic key value is @1
  static const int isc_idx_key_value = 335545072;

  /// Cannot select virtual table @1 for update WITH LOCK
  static const int isc_forupdate_virtualtbl = 335545073;

  /// Cannot select system table @1 for update WITH LOCK
  static const int isc_forupdate_systbl = 335545074;

  /// Cannot select temporary table @1 for update WITH LOCK
  static const int isc_forupdate_temptbl = 335545075;

  /// System @1 @2 cannot be modified
  static const int isc_cant_modify_sysobj = 335545076;

  /// Server misconfigured - contact administrator please
  static const int isc_server_misconfigured = 335545077;

  /// Deprecated backward compatibility ALTER ROLE ?? SET/DROP AUTO ADMIN mapping may be used only for RDB$ADMIN role
  static const int isc_alter_role = 335545078;

  /// Mapping @1 already exists
  static const int isc_map_already_exists = 335545079;

  /// Mapping @1 does not exist
  static const int isc_map_not_exists = 335545080;

  /// @1 failed when loading mapping cache
  static const int isc_map_load = 335545081;

  /// Invalid name <*> in authentication block
  static const int isc_map_aster = 335545082;

  /// Multiple maps found for @1
  static const int isc_map_multi = 335545083;

  /// Undefined mapping result - more than one different results found
  static const int isc_map_undefined = 335545084;

  /// Incompatible mode of attachment to damaged database
  static const int isc_baddpb_damaged_mode = 335545085;

  /// Attempt to set in database number of buffers which is out of acceptable range @1:@2
  static const int isc_baddpb_buffers_range = 335545086;

  /// Attempt to temporarily set number of buffers less than @1
  static const int isc_baddpb_temp_buffers = 335545087;

  /// Global mapping is not available when database @1 is not present
  static const int isc_map_nodb = 335545088;

  /// Global mapping is not available when table RDB$MAP is not present in database @1
  static const int isc_map_notable = 335545089;

  /// Your attachment has no trusted role
  static const int isc_miss_trusted_role = 335545090;

  /// Role @1 is invalid or unavailable
  static const int isc_set_invalid_role = 335545091;

  /// Cursor @1 is not positioned in a valid record
  static const int isc_cursor_not_positioned = 335545092;

  /// Duplicated user attribute @1
  static const int isc_dup_attribute = 335545093;

  /// There is no privilege for this operation
  static const int isc_dyn_no_priv = 335545094;

  /// Using GRANT OPTION on @1 not allowed
  static const int isc_dsql_cant_grant_option = 335545095;

  /// read conflicts with concurrent update
  static const int isc_read_conflict = 335545096;

  /// @1 failed when working with CREATE DATABASE grants
  static const int isc_crdb_load = 335545097;

  /// CREATE DATABASE grants check is not possible when database @1 is not present
  static const int isc_crdb_nodb = 335545098;

  /// CREATE DATABASE grants check is not possible when table RDB$DB_CREATORS is not present in database @1
  static const int isc_crdb_notable = 335545099;

  /// Interface @3 version too old: expected @1, found @2
  static const int isc_interface_version_too_old = 335545100;

  /// Input parameter mismatch for function @1
  static const int isc_fun_param_mismatch = 335545101;

  /// Error during savepoint backout - transaction invalidated
  static const int isc_savepoint_backout_err = 335545102;

  /// Domain used in the PRIMARY KEY constraint of table @1 must be NOT NULL
  static const int isc_domain_primary_key_notnull = 335545103;

  /// CHARACTER SET @1 cannot be used as a attachment character set
  static const int isc_invalid_attachment_charset = 335545104;

  /// Some database(s) were shutdown when trying to read mapping data
  static const int isc_map_down = 335545105;

  /// Error occurred during login, please check server firebird.log for details
  static const int isc_login_error = 335545106;

  /// Database already opened with engine instance, incompatible with current
  static const int isc_already_opened = 335545107;

  /// Invalid crypt key @1
  static const int isc_bad_crypt_key = 335545108;

  /// Page requires encryption but crypt plugin is missing
  static const int isc_encrypt_error = 335545109;

  /// Maximum index depth (@1 levels) is reached
  static const int isc_max_idx_depth = 335545110;

  /// System privilege @1 does not exist
  static const int isc_wrong_prvlg = 335545111;

  /// System privilege @1 is missing
  static const int isc_miss_prvlg = 335545112;

  /// Invalid or missing checksum of encrypted database
  static const int isc_crypt_checksum = 335545113;

  /// You must have SYSDBA rights at this server
  static const int isc_not_dba = 335545114;

  /// Cannot open cursor for non-SELECT statement
  static const int isc_no_cursor = 335545115;

  /// If <window frame bound 1> specifies @1, then <window frame bound 2> shall not specify @2
  static const int isc_dsql_window_incompat_frames = 335545116;

  /// RANGE based window with <expr> {PRECEDING | FOLLOWING} cannot have ORDER BY with more than one value
  static const int isc_dsql_window_range_multi_key = 335545117;

  /// RANGE based window with <offset> PRECEDING/FOLLOWING must have a single ORDER BY key of numerical, date, time or timestamp types
  static const int isc_dsql_window_range_inv_key_type = 335545118;

  /// Window RANGE/ROWS PRECEDING/FOLLOWING value must be of a numerical type
  static const int isc_dsql_window_frame_value_inv_type = 335545119;

  /// Invalid PRECEDING or FOLLOWING offset in window function: cannot be negative
  static const int isc_window_frame_value_invalid = 335545120;

  /// Window @1 not found
  static const int isc_dsql_window_not_found = 335545121;

  /// Cannot use PARTITION BY clause while overriding the window @1
  static const int isc_dsql_window_cant_overr_part = 335545122;

  /// Cannot use ORDER BY clause while overriding the window @1 which already has an ORDER BY clause
  static const int isc_dsql_window_cant_overr_order = 335545123;

  /// Cannot override the window @1 because it has a frame clause. Tip: it can be used without parenthesis in OVER
  static const int isc_dsql_window_cant_overr_frame = 335545124;

  /// Duplicate window definition for @1
  static const int isc_dsql_window_duplicate = 335545125;

  /// SQL statement is too long. Maximum size is @1 bytes.
  static const int isc_sql_too_long = 335545126;

  /// Config level timeout expired.
  static const int isc_cfg_stmt_timeout = 335545127;

  /// Attachment level timeout expired.
  static const int isc_att_stmt_timeout = 335545128;

  /// Statement level timeout expired.
  static const int isc_req_stmt_timeout = 335545129;

  /// Killed by database administrator.
  static const int isc_att_shut_killed = 335545130;

  /// Idle timeout expired.
  static const int isc_att_shut_idle = 335545131;

  /// Database is shutdown.
  static const int isc_att_shut_db_down = 335545132;

  /// Engine is shutdown.
  static const int isc_att_shut_engine = 335545133;

  /// OVERRIDING clause can be used only when an identity column is present in the INSERT's field list for table/view @1
  static const int isc_overriding_without_identity = 335545134;

  /// OVERRIDING SYSTEM VALUE can be used only for identity column defined as 'GENERATED ALWAYS' in INSERT for table/view @1
  static const int isc_overriding_system_invalid = 335545135;

  /// OVERRIDING USER VALUE can be used only for identity column defined as 'GENERATED BY DEFAULT' in INSERT for table/view @1
  static const int isc_overriding_user_invalid = 335545136;

  /// OVERRIDING SYSTEM VALUE should be used to override the value of an identity column defined as 'GENERATED ALWAYS' in table/view @1
  static const int isc_overriding_missing = 335545137;

  /// DecFloat precision must be 16 or 34
  static const int isc_decprecision_err = 335545138;

  /// Decimal float divide by zero. The code attempted to divide a DECFLOAT value by zero.
  static const int isc_decfloat_divide_by_zero = 335545139;

  /// Decimal float inexact result. The result of an operation cannot be represented as a decimal fraction.
  static const int isc_decfloat_inexact_result = 335545140;

  /// Decimal float invalid operation. An indeterminant error occurred during an operation.
  static const int isc_decfloat_invalid_operation = 335545141;

  /// Decimal float overflow. The exponent of a result is greater than the magnitude allowed.
  static const int isc_decfloat_overflow = 335545142;

  /// Decimal float underflow. The exponent of a result is less than the magnitude allowed.
  static const int isc_decfloat_underflow = 335545143;

  /// Sub-function @1 has not been defined
  static const int isc_subfunc_notdef = 335545144;

  /// Sub-procedure @1 has not been defined
  static const int isc_subproc_notdef = 335545145;

  /// Sub-function @1 has a signature mismatch with its forward declaration
  static const int isc_subfunc_signat = 335545146;

  /// Sub-procedure @1 has a signature mismatch with its forward declaration
  static const int isc_subproc_signat = 335545147;

  /// Default values for parameters are not allowed in definition of the previously declared sub-function @1
  static const int isc_subfunc_defvaldecl = 335545148;

  /// Default values for parameters are not allowed in definition of the previously declared sub-procedure @1
  static const int isc_subproc_defvaldecl = 335545149;

  /// Sub-function @1 was declared but not implemented
  static const int isc_subfunc_not_impl = 335545150;

  /// Sub-procedure @1 was declared but not implemented
  static const int isc_subproc_not_impl = 335545151;

  /// Invalid HASH algorithm @1
  static const int isc_sysf_invalid_hash_algorithm = 335545152;

  /// Expression evaluation error for index "@1" on table "@2"
  static const int isc_expression_eval_index = 335545153;

  /// Invalid decfloat trap state @1
  static const int isc_invalid_decfloat_trap = 335545154;

  /// Invalid decfloat rounding mode @1
  static const int isc_invalid_decfloat_round = 335545155;

  /// Invalid part @1 to calculate the @1 of a DATE/TIMESTAMP
  static const int isc_sysf_invalid_first_last_part = 335545156;

  /// Expected DATE/TIMESTAMP value in @1
  static const int isc_sysf_invalid_date_timestamp = 335545157;

  /// Precision must be from @1 to @2
  static const int isc_precision_err2 = 335545158;

  /// invalid batch handle
  static const int isc_bad_batch_handle = 335545159;

  /// Bad international character in tag @1
  static const int isc_intl_char = 335545160;

  /// Null data in parameters block with non-zero length
  static const int isc_null_block = 335545161;

  /// Items working with running service and getting generic server information should not be mixed in single info block
  static const int isc_mixed_info = 335545162;

  /// Unknown information item, code @1
  static const int isc_unknown_info = 335545163;

  /// Wrong version of blob parameters block @1, should be @2
  static const int isc_bpb_version = 335545164;

  /// User management plugin is missing or failed to load
  static const int isc_user_manager = 335545165;

  /// Missing entrypoint @1 in ICU library
  static const int isc_icu_entrypoint = 335545166;

  /// Could not find acceptable ICU library
  static const int isc_icu_library = 335545167;

  /// Name @1 not found in system MetadataBuilder
  static const int isc_metadata_name = 335545168;

  /// Parse to tokens error
  static const int isc_tokens_parse = 335545169;

  /// Error opening international conversion descriptor from @1 to @2
  static const int isc_iconv_open = 335545170;

  /// Message @1 is out of range, only @2 messages in batch
  static const int isc_batch_compl_range = 335545171;

  /// Detailed error info for message @1 is missing in batch
  static const int isc_batch_compl_detail = 335545172;

  /// Compression stream init error @1
  static const int isc_deflate_init = 335545173;

  /// Decompression stream init error @1
  static const int isc_inflate_init = 335545174;

  /// Segment size (@1) should not exceed 65535 (64K - 1) when using segmented blob
  static const int isc_big_segment = 335545175;

  /// Invalid blob policy in the batch for @1() call
  static const int isc_batch_policy = 335545176;

  /// Can't change default BPB after adding any data to batch
  static const int isc_batch_defbpb = 335545177;

  /// Unexpected info buffer structure querying for server batch parameters
  static const int isc_batch_align = 335545178;

  /// Duplicated segment @1 in multisegment connect block parameter
  static const int isc_multi_segment_dup = 335545179;

  /// Plugin not supported by network protocol
  static const int isc_non_plugin_protocol = 335545180;

  /// Error parsing message format
  static const int isc_message_format = 335545181;

  /// Wrong version of batch parameters block @1, should be @2
  static const int isc_batch_param_version = 335545182;

  /// Message size (@1) in batch exceeds internal buffer size (@2)
  static const int isc_batch_msg_long = 335545183;

  /// Batch already opened for this statement
  static const int isc_batch_open = 335545184;

  /// Invalid type of statement used in batch
  static const int isc_batch_type = 335545185;

  /// Statement used in batch must have parameters
  static const int isc_batch_param = 335545186;

  /// There are no blobs in associated with batch statement
  static const int isc_batch_blobs = 335545187;

  /// appendBlobData() is used to append data to last blob but no such blob was added to the batch
  static const int isc_batch_blob_append = 335545188;

  /// Portions of data, passed as blob stream, should have size multiple to the alignment required for blobs
  static const int isc_batch_stream_align = 335545189;

  /// Repeated blob id @1 in registerBlob()
  static const int isc_batch_rpt_blob = 335545190;

  /// Blob buffer format error
  static const int isc_batch_blob_buf = 335545191;

  /// Unusable (too small) data remained in @1 buffer
  static const int isc_batch_small_data = 335545192;

  /// Blob continuation should not contain BPB
  static const int isc_batch_cont_bpb = 335545193;

  /// Size of BPB (@1) greater than remaining data (@2)
  static const int isc_batch_big_bpb = 335545194;

  /// Size of segment (@1) greater than current BLOB data (@2)
  static const int isc_batch_big_segment = 335545195;

  /// Size of segment (@1) greater than available data (@2)
  static const int isc_batch_big_seg2 = 335545196;

  /// Unknown blob ID @1 in the batch message
  static const int isc_batch_blob_id = 335545197;

  /// Internal buffer overflow - batch too big
  static const int isc_batch_too_big = 335545198;

  /// Numeric literal too long
  static const int isc_num_literal = 335545199;

  /// Error using events in mapping shared memory: @1
  static const int isc_map_event = 335545200;

  /// Global mapping memory overflow
  static const int isc_map_overflow = 335545201;

  /// Header page overflow - too many clumplets on it
  static const int isc_hdr_overflow = 335545202;

  /// No matching client/server authentication plugins configured for execute statement in embedded datasource
  static const int isc_vld_plugins = 335545203;

  /// Missing database encryption key for your attachment
  static const int isc_db_crypt_key = 335545204;

  /// Key holder plugin @1 failed to load
  static const int isc_no_keyholder_plugin = 335545205;

  /// Cannot reset user session
  static const int isc_ses_reset_err = 335545206;

  /// There are open transactions (@1 active)
  static const int isc_ses_reset_open_trans = 335545207;

  /// Session was reset with warning(s)
  static const int isc_ses_reset_warn = 335545208;

  /// Transaction is rolled back due to session reset, all changes are lost
  static const int isc_ses_reset_tran_rollback = 335545209;

  /// Plugin @1:
  static const int isc_plugin_name = 335545210;

  /// PARAMETER @1
  static const int isc_parameter_name = 335545211;

  /// Starting page number for file @1 must be @2 or greater
  static const int isc_file_starting_page_err = 335545212;

  /// Invalid time zone offset: @1 - must use format +/-hours:minutes and be between -14:00 and +14:00
  static const int isc_invalid_timezone_offset = 335545213;

  /// Invalid time zone region: @1
  static const int isc_invalid_timezone_region = 335545214;

  /// Invalid time zone ID: @1
  static const int isc_invalid_timezone_id = 335545215;

  /// Wrong base64 text length @1, should be multiple of 4
  static const int isc_tom_decode64len = 335545216;

  /// Invalid first parameter datatype - need string or blob
  static const int isc_tom_strblob = 335545217;

  /// Error registering @1 - probably bad tomcrypt library
  static const int isc_tom_reg = 335545218;

  /// Unknown crypt algorithm @1 in USING clause
  static const int isc_tom_algorithm = 335545219;

  /// Should specify mode parameter for symmetric cipher
  static const int isc_tom_mode_miss = 335545220;

  /// Unknown symmetric crypt mode specified
  static const int isc_tom_mode_bad = 335545221;

  /// Mode parameter makes no sense for chosen cipher
  static const int isc_tom_no_mode = 335545222;

  /// Should specify initialization vector (IV) for chosen cipher and/or mode
  static const int isc_tom_iv_miss = 335545223;

  /// Initialization vector (IV) makes no sense for chosen cipher and/or mode
  static const int isc_tom_no_iv = 335545224;

  /// Invalid counter endianess @1
  static const int isc_tom_ctrtype_bad = 335545225;

  /// Counter endianess parameter is not used in mode @1
  static const int isc_tom_no_ctrtype = 335545226;

  /// Too big counter value @1, maximum @2 can be used
  static const int isc_tom_ctr_big = 335545227;

  /// Counter length/value parameter is not used with @1 @2
  static const int isc_tom_no_ctr = 335545228;

  /// Invalid initialization vector (IV) length @1, need @2
  static const int isc_tom_iv_length = 335545229;

  /// TomCrypt library error: @1
  static const int isc_tom_error = 335545230;

  /// Starting PRNG yarrow
  static const int isc_tom_yarrow_start = 335545231;

  /// Setting up PRNG yarrow
  static const int isc_tom_yarrow_setup = 335545232;

  /// Initializing @1 mode
  static const int isc_tom_init_mode = 335545233;

  /// Encrypting in @1 mode
  static const int isc_tom_crypt_mode = 335545234;

  /// Decrypting in @1 mode
  static const int isc_tom_decrypt_mode = 335545235;

  /// Initializing cipher @1
  static const int isc_tom_init_cip = 335545236;

  /// Encrypting using cipher @1
  static const int isc_tom_crypt_cip = 335545237;

  /// Decrypting using cipher @1
  static const int isc_tom_decrypt_cip = 335545238;

  /// Setting initialization vector (IV) for @1
  static const int isc_tom_setup_cip = 335545239;

  /// Invalid initialization vector (IV) length @1, need 8 or 12
  static const int isc_tom_setup_chacha = 335545240;

  /// Encoding @1
  static const int isc_tom_encode = 335545241;

  /// Decoding @1
  static const int isc_tom_decode = 335545242;

  /// Importing RSA key
  static const int isc_tom_rsa_import = 335545243;

  /// Invalid OAEP packet
  static const int isc_tom_oaep = 335545244;

  /// Unknown hash algorithm @1
  static const int isc_tom_hash_bad = 335545245;

  /// Making RSA key
  static const int isc_tom_rsa_make = 335545246;

  /// Exporting @1 RSA key
  static const int isc_tom_rsa_export = 335545247;

  /// RSA-signing data
  static const int isc_tom_rsa_sign = 335545248;

  /// Verifying RSA-signed data
  static const int isc_tom_rsa_verify = 335545249;

  /// Invalid key length @1, need 16 or 32
  static const int isc_tom_chacha_key = 335545250;

  /// invalid replicator handle
  static const int isc_bad_repl_handle = 335545251;

  /// Transaction's base snapshot number does not exist
  static const int isc_tra_snapshot_does_not_exist = 335545252;

  /// Input parameter '@1' is not used in SQL query text
  static const int isc_eds_input_prm_not_used = 335545253;

  /// Effective user is @1
  static const int isc_effective_user = 335545254;

  /// Invalid time zone bind mode @1
  static const int isc_invalid_time_zone_bind = 335545255;

  /// Invalid decfloat bind mode @1
  static const int isc_invalid_decfloat_bind = 335545256;

  /// Invalid hex text length @1, should be multiple of 2
  static const int isc_odd_hex_len = 335545257;

  /// Invalid hex digit @1 at position @2
  static const int isc_invalid_hex_digit = 335545258;

  /// Error processing isc_dpb_set_bind clumplet "@1"
  static const int isc_bind_err = 335545259;

  /// The following statement failed: @1
  static const int isc_bind_statement = 335545260;

  /// Can not convert @1 to @2
  static const int isc_bind_convert = 335545261;

  /// cannot update old BLOB
  static const int isc_cannot_update_old_blob = 335545262;

  /// cannot read from new BLOB
  static const int isc_cannot_read_new_blob = 335545263;

  /// No permission for CREATE @1 operation
  static const int isc_dyn_no_create_priv = 335545264;

  /// SUSPEND could not be used without RETURNS clause in PROCEDURE or EXECUTE BLOCK
  static const int isc_suspend_without_returns = 335545265;

  /// String truncated warning due to the following reason
  static const int isc_truncate_warn = 335545266;

  /// Monitoring data does not fit into the field
  static const int isc_truncate_monitor = 335545267;

  /// Engine data does not fit into return value of system function
  static const int isc_truncate_context = 335545268;

  /// Multiple source records cannot match the same target during MERGE
  static const int isc_merge_dup_update = 335545269;

  /// RDB$PAGES written by non-system transaction, DB appears to be damaged
  static const int isc_wrong_page = 335545270;

  /// Replication error
  static const int isc_repl_error = 335545271;

  /// Reset of user session failed. Connection is shut down.
  static const int isc_ses_reset_failed = 335545272;

  /// File size is less than expected
  static const int isc_block_size = 335545273;

  /// Invalid key length @1, need >@2
  static const int isc_tom_key_length = 335545274;

  /// Invalid information arguments
  static const int isc_inf_invalid_args = 335545275;

  /// Empty or NULL parameter @1 is not accepted
  static const int isc_sysf_invalid_null_empty = 335545276;
  static const int isc_gfix_db_name = 335740929;
  static const int isc_gfix_invalid_sw = 335740930;
  static const int isc_gfix_incmp_sw = 335740932;
  static const int isc_gfix_replay_req = 335740933;
  static const int isc_gfix_pgbuf_req = 335740934;
  static const int isc_gfix_val_req = 335740935;
  static const int isc_gfix_pval_req = 335740936;
  static const int isc_gfix_trn_req = 335740937;
  static const int isc_gfix_full_req = 335740940;
  static const int isc_gfix_usrname_req = 335740941;
  static const int isc_gfix_pass_req = 335740942;
  static const int isc_gfix_subs_name = 335740943;
  static const int isc_gfix_wal_req = 335740944;
  static const int isc_gfix_sec_req = 335740945;
  static const int isc_gfix_nval_req = 335740946;
  static const int isc_gfix_type_shut = 335740947;
  static const int isc_gfix_retry = 335740948;
  static const int isc_gfix_retry_db = 335740951;
  static const int isc_gfix_exceed_max = 335740991;
  static const int isc_gfix_corrupt_pool = 335740992;
  static const int isc_gfix_mem_exhausted = 335740993;
  static const int isc_gfix_bad_pool = 335740994;
  static const int isc_gfix_trn_not_valid = 335740995;
  static const int isc_gfix_unexp_eoi = 335741012;
  static const int isc_gfix_recon_fail = 335741018;
  static const int isc_gfix_trn_unknown = 335741036;
  static const int isc_gfix_mode_req = 335741038;
  static const int isc_gfix_pzval_req = 335741042;

  /// Cannot SELECT RDB$DB_KEY from a stored procedure.
  static const int isc_dsql_dbkey_from_non_table = 336003074;

  /// Precision 10 to 18 changed from DOUBLE PRECISION in SQL dialect 1 to 64-bit scaled integer in SQL dialect 3
  static const int isc_dsql_transitional_numeric = 336003075;

  /// Use of @1 expression that returns different results in dialect 1 and dialect 3
  static const int isc_dsql_dialect_warning_expr = 336003076;

  /// Database SQL dialect @1 does not support reference to @2 datatype
  static const int isc_sql_db_dialect_dtype_unsupport = 336003077;

  /// DB dialect @1 and client dialect @2 conflict with respect to numeric precision @3.
  static const int isc_sql_dialect_conflict_num = 336003079;

  /// WARNING: Numeric literal @1 is interpreted as a floating-point
  static const int isc_dsql_warning_number_ambiguous = 336003080;

  /// value in SQL dialect 1, but as an exact numeric value in SQL dialect 3.
  static const int isc_dsql_warning_number_ambiguous1 = 336003081;

  /// WARNING: NUMERIC and DECIMAL fields with precision 10 or greater are stored
  static const int isc_dsql_warn_precision_ambiguous = 336003082;

  /// as approximate floating-point values in SQL dialect 1, but as 64-bit
  static const int isc_dsql_warn_precision_ambiguous1 = 336003083;

  /// integers in SQL dialect 3.
  static const int isc_dsql_warn_precision_ambiguous2 = 336003084;

  /// Ambiguous field name between @1 and @2
  static const int isc_dsql_ambiguous_field_name = 336003085;

  /// External function should have return position between 1 and @1
  static const int isc_dsql_udf_return_pos_err = 336003086;

  /// Label @1 @2 in the current scope
  static const int isc_dsql_invalid_label = 336003087;

  /// Datatypes @1are not comparable in expression @2
  static const int isc_dsql_datatypes_not_comparable = 336003088;

  /// Empty cursor name is not allowed
  static const int isc_dsql_cursor_invalid = 336003089;

  /// Statement already has a cursor @1 assigned
  static const int isc_dsql_cursor_redefined = 336003090;

  /// Cursor @1 is not found in the current context
  static const int isc_dsql_cursor_not_found = 336003091;

  /// Cursor @1 already exists in the current context
  static const int isc_dsql_cursor_exists = 336003092;

  /// Relation @1 is ambiguous in cursor @2
  static const int isc_dsql_cursor_rel_ambiguous = 336003093;

  /// Relation @1 is not found in cursor @2
  static const int isc_dsql_cursor_rel_not_found = 336003094;

  /// Cursor is not open
  static const int isc_dsql_cursor_not_open = 336003095;

  /// Data type @1 is not supported for EXTERNAL TABLES. Relation '@2', field '@3'
  static const int isc_dsql_type_not_supp_ext_tab = 336003096;

  /// Feature not supported on ODS version older than @1.@2
  static const int isc_dsql_feature_not_supported_ods = 336003097;

  /// Primary key required on table @1
  static const int isc_primary_key_required = 336003098;

  /// UPDATE OR INSERT field list does not match primary key of table @1
  static const int isc_upd_ins_doesnt_match_pk = 336003099;

  /// UPDATE OR INSERT field list does not match MATCHING clause
  static const int isc_upd_ins_doesnt_match_matching = 336003100;

  /// UPDATE OR INSERT without MATCHING could not be used with views based on more than one table
  static const int isc_upd_ins_with_complex_view = 336003101;

  /// Incompatible trigger type
  static const int isc_dsql_incompatible_trigger_type = 336003102;

  /// Database trigger type can't be changed
  static const int isc_dsql_db_trigger_type_cant_change = 336003103;

  /// To be used with RDB$RECORD_VERSION, @1 must be a table or a view of single table
  static const int isc_dsql_record_version_table = 336003104;

  /// SQLDA version expected between @1 and @2, found @3
  static const int isc_dsql_invalid_sqlda_version = 336003105;

  /// at SQLVAR index @1
  static const int isc_dsql_sqlvar_index = 336003106;

  /// empty pointer to NULL indicator variable
  static const int isc_dsql_no_sqlind = 336003107;

  /// empty pointer to data
  static const int isc_dsql_no_sqldata = 336003108;

  /// No SQLDA for input values provided
  static const int isc_dsql_no_input_sqlda = 336003109;

  /// No SQLDA for output values provided
  static const int isc_dsql_no_output_sqlda = 336003110;

  /// Wrong number of parameters (expected @1, got @2)
  static const int isc_dsql_wrong_param_num = 336003111;

  /// Invalid DROP SQL SECURITY clause
  static const int isc_dsql_invalid_drop_ss_clause = 336003112;

  /// UPDATE OR INSERT value for field @1, part of the implicit or explicit MATCHING clause, cannot be DEFAULT
  static const int isc_upd_ins_cannot_default = 336003113;

  /// BLOB Filter @1 not found
  static const int isc_dyn_filter_not_found = 336068645;

  /// Function @1 not found
  static const int isc_dyn_func_not_found = 336068649;

  /// Index not found
  static const int isc_dyn_index_not_found = 336068656;

  /// View @1 not found
  static const int isc_dyn_view_not_found = 336068662;

  /// Domain not found
  static const int isc_dyn_domain_not_found = 336068697;

  /// Triggers created automatically cannot be modified
  static const int isc_dyn_cant_modify_auto_trig = 336068717;

  /// Table @1 already exists
  static const int isc_dyn_dup_table = 336068740;

  /// Procedure @1 not found
  static const int isc_dyn_proc_not_found = 336068748;

  /// Exception not found
  static const int isc_dyn_exception_not_found = 336068752;

  /// Parameter @1 in procedure @2 not found
  static const int isc_dyn_proc_param_not_found = 336068754;

  /// Trigger @1 not found
  static const int isc_dyn_trig_not_found = 336068755;

  /// Character set @1 not found
  static const int isc_dyn_charset_not_found = 336068759;

  /// Collation @1 not found
  static const int isc_dyn_collation_not_found = 336068760;

  /// Role @1 not found
  static const int isc_dyn_role_not_found = 336068763;

  /// Name longer than database column size
  static const int isc_dyn_name_longer = 336068767;

  /// column @1 does not exist in table/view @2
  static const int isc_dyn_column_does_not_exist = 336068784;

  /// SQL role @1 does not exist
  static const int isc_dyn_role_does_not_exist = 336068796;

  /// user @1 has no grant admin option on SQL role @2
  static const int isc_dyn_no_grant_admin_opt = 336068797;

  /// user @1 is not a member of SQL role @2
  static const int isc_dyn_user_not_role_member = 336068798;

  /// @1 is not the owner of SQL role @2
  static const int isc_dyn_delete_role_failed = 336068799;

  /// @1 is a SQL role and not a user
  static const int isc_dyn_grant_role_to_user = 336068800;

  /// user name @1 could not be used for SQL role
  static const int isc_dyn_inv_sql_role_name = 336068801;

  /// SQL role @1 already exists
  static const int isc_dyn_dup_sql_role = 336068802;

  /// keyword @1 can not be used as a SQL role name
  static const int isc_dyn_kywd_spec_for_role = 336068803;

  /// SQL roles are not supported in on older versions of the database. A backup and restore of the database is required.
  static const int isc_dyn_roles_not_supported = 336068804;

  /// Cannot rename domain @1 to @2. A domain with that name already exists.
  static const int isc_dyn_domain_name_exists = 336068812;

  /// Cannot rename column @1 to @2. A column with that name already exists in table @3.
  static const int isc_dyn_field_name_exists = 336068813;

  /// Column @1 from table @2 is referenced in @3
  static const int isc_dyn_dependency_exists = 336068814;

  /// Cannot change datatype for column @1. Changing datatype is not supported for BLOB or ARRAY columns.
  static const int isc_dyn_dtype_invalid = 336068815;

  /// New size specified for column @1 must be at least @2 characters.
  static const int isc_dyn_char_fld_too_small = 336068816;

  /// Cannot change datatype for @1. Conversion from base type @2 to @3 is not supported.
  static const int isc_dyn_invalid_dtype_conversion = 336068817;

  /// Cannot change datatype for column @1 from a character type to a non-character type.
  static const int isc_dyn_dtype_conv_invalid = 336068818;

  /// Zero length identifiers are not allowed
  static const int isc_dyn_zero_len_id = 336068820;

  /// Sequence @1 not found
  static const int isc_dyn_gen_not_found = 336068822;

  /// Maximum number of collations per character set exceeded
  static const int isc_max_coll_per_charset = 336068829;

  /// Invalid collation attributes
  static const int isc_invalid_coll_attr = 336068830;

  /// @1 cannot reference @2
  static const int isc_dyn_wrong_gtt_scope = 336068840;

  /// Collation @1 is used in table @2 (field name @3) and cannot be dropped
  static const int isc_dyn_coll_used_table = 336068843;

  /// Collation @1 is used in domain @2 and cannot be dropped
  static const int isc_dyn_coll_used_domain = 336068844;

  /// Cannot delete system collation
  static const int isc_dyn_cannot_del_syscoll = 336068845;

  /// Cannot delete default collation of CHARACTER SET @1
  static const int isc_dyn_cannot_del_def_coll = 336068846;

  /// Table @1 not found
  static const int isc_dyn_table_not_found = 336068849;

  /// Collation @1 is used in procedure @2 (parameter name @3) and cannot be dropped
  static const int isc_dyn_coll_used_procedure = 336068851;

  /// New scale specified for column @1 must be at most @2.
  static const int isc_dyn_scale_too_big = 336068852;

  /// New precision specified for column @1 must be at least @2.
  static const int isc_dyn_precision_too_small = 336068853;

  /// Warning: @1 on @2 is not granted to @3.
  static const int isc_dyn_miss_priv_warning = 336068855;

  /// Feature '@1' is not supported in ODS @2.@3
  static const int isc_dyn_ods_not_supp_feature = 336068856;

  /// Cannot add or remove COMPUTED from column @1
  static const int isc_dyn_cannot_addrem_computed = 336068857;

  /// Password should not be empty string
  static const int isc_dyn_no_empty_pw = 336068858;

  /// Index @1 already exists
  static const int isc_dyn_dup_index = 336068859;

  /// Package @1 not found
  static const int isc_dyn_package_not_found = 336068864;

  /// Schema @1 not found
  static const int isc_dyn_schema_not_found = 336068865;

  /// Cannot ALTER or DROP system procedure @1
  static const int isc_dyn_cannot_mod_sysproc = 336068866;

  /// Cannot ALTER or DROP system trigger @1
  static const int isc_dyn_cannot_mod_systrig = 336068867;

  /// Cannot ALTER or DROP system function @1
  static const int isc_dyn_cannot_mod_sysfunc = 336068868;

  /// Invalid DDL statement for procedure @1
  static const int isc_dyn_invalid_ddl_proc = 336068869;

  /// Invalid DDL statement for trigger @1
  static const int isc_dyn_invalid_ddl_trig = 336068870;

  /// Function @1 has not been defined on the package body @2
  static const int isc_dyn_funcnotdef_package = 336068871;

  /// Procedure @1 has not been defined on the package body @2
  static const int isc_dyn_procnotdef_package = 336068872;

  /// Function @1 has a signature mismatch on package body @2
  static const int isc_dyn_funcsignat_package = 336068873;

  /// Procedure @1 has a signature mismatch on package body @2
  static const int isc_dyn_procsignat_package = 336068874;

  /// Default values for parameters are not allowed in the definition of a previously declared packaged procedure @1.@2
  static const int isc_dyn_defvaldecl_package_proc = 336068875;

  /// Package body @1 already exists
  static const int isc_dyn_package_body_exists = 336068877;

  /// Invalid DDL statement for function @1
  static const int isc_dyn_invalid_ddl_func = 336068878;

  /// Cannot alter new style function @1 with ALTER EXTERNAL FUNCTION. Use ALTER FUNCTION instead.
  static const int isc_dyn_newfc_oldsyntax = 336068879;

  /// Parameter @1 in function @2 not found
  static const int isc_dyn_func_param_not_found = 336068886;

  /// Parameter @1 of routine @2 not found
  static const int isc_dyn_routine_param_not_found = 336068887;

  /// Parameter @1 of routine @2 is ambiguous (found in both procedures and functions). Use a specifier keyword.
  static const int isc_dyn_routine_param_ambiguous = 336068888;

  /// Collation @1 is used in function @2 (parameter name @3) and cannot be dropped
  static const int isc_dyn_coll_used_function = 336068889;

  /// Domain @1 is used in function @2 (parameter name @3) and cannot be dropped
  static const int isc_dyn_domain_used_function = 336068890;

  /// ALTER USER requires at least one clause to be specified
  static const int isc_dyn_alter_user_no_clause = 336068891;

  /// Duplicate @1 @2
  static const int isc_dyn_duplicate_package_item = 336068894;

  /// System @1 @2 cannot be modified
  static const int isc_dyn_cant_modify_sysobj = 336068895;

  /// INCREMENT BY 0 is an illegal option for sequence @1
  static const int isc_dyn_cant_use_zero_increment = 336068896;

  /// Can't use @1 in FOREIGN KEY constraint
  static const int isc_dyn_cant_use_in_foreignkey = 336068897;

  /// Default values for parameters are not allowed in the definition of a previously declared packaged function @1.@2
  static const int isc_dyn_defvaldecl_package_func = 336068898;

  /// role @1 can not be granted to role @2
  static const int isc_dyn_cyclic_role = 336068900;

  /// INCREMENT BY 0 is an illegal option for identity column @1 of table @2
  static const int isc_dyn_cant_use_zero_inc_ident = 336068904;

  /// no @1 privilege with grant option on DDL @2
  static const int isc_dyn_no_ddl_grant_opt_priv = 336068907;

  /// no @1 privilege with grant option on object @2
  static const int isc_dyn_no_grant_opt_priv = 336068908;

  /// Function @1 does not exist
  static const int isc_dyn_func_not_exist = 336068909;

  /// Procedure @1 does not exist
  static const int isc_dyn_proc_not_exist = 336068910;

  /// Package @1 does not exist
  static const int isc_dyn_pack_not_exist = 336068911;

  /// Trigger @1 does not exist
  static const int isc_dyn_trig_not_exist = 336068912;

  /// View @1 does not exist
  static const int isc_dyn_view_not_exist = 336068913;

  /// Table @1 does not exist
  static const int isc_dyn_rel_not_exist = 336068914;

  /// Exception @1 does not exist
  static const int isc_dyn_exc_not_exist = 336068915;

  /// Generator/Sequence @1 does not exist
  static const int isc_dyn_gen_not_exist = 336068916;

  /// Field @1 of table @2 does not exist
  static const int isc_dyn_fld_not_exist = 336068917;
  static const int isc_gbak_unknown_switch = 336330753;
  static const int isc_gbak_page_size_missing = 336330754;
  static const int isc_gbak_page_size_toobig = 336330755;
  static const int isc_gbak_redir_ouput_missing = 336330756;
  static const int isc_gbak_switches_conflict = 336330757;
  static const int isc_gbak_unknown_device = 336330758;
  static const int isc_gbak_no_protection = 336330759;
  static const int isc_gbak_page_size_not_allowed = 336330760;
  static const int isc_gbak_multi_source_dest = 336330761;
  static const int isc_gbak_filename_missing = 336330762;
  static const int isc_gbak_dup_inout_names = 336330763;
  static const int isc_gbak_inv_page_size = 336330764;
  static const int isc_gbak_db_specified = 336330765;
  static const int isc_gbak_db_exists = 336330766;
  static const int isc_gbak_unk_device = 336330767;
  static const int isc_gbak_blob_info_failed = 336330772;
  static const int isc_gbak_unk_blob_item = 336330773;
  static const int isc_gbak_get_seg_failed = 336330774;
  static const int isc_gbak_close_blob_failed = 336330775;
  static const int isc_gbak_open_blob_failed = 336330776;
  static const int isc_gbak_put_blr_gen_id_failed = 336330777;
  static const int isc_gbak_unk_type = 336330778;
  static const int isc_gbak_comp_req_failed = 336330779;
  static const int isc_gbak_start_req_failed = 336330780;
  static const int isc_gbak_rec_failed = 336330781;
  static const int isc_gbak_rel_req_failed = 336330782;
  static const int isc_gbak_db_info_failed = 336330783;
  static const int isc_gbak_no_db_desc = 336330784;
  static const int isc_gbak_db_create_failed = 336330785;
  static const int isc_gbak_decomp_len_error = 336330786;
  static const int isc_gbak_tbl_missing = 336330787;
  static const int isc_gbak_blob_col_missing = 336330788;
  static const int isc_gbak_create_blob_failed = 336330789;
  static const int isc_gbak_put_seg_failed = 336330790;
  static const int isc_gbak_rec_len_exp = 336330791;
  static const int isc_gbak_inv_rec_len = 336330792;
  static const int isc_gbak_exp_data_type = 336330793;
  static const int isc_gbak_gen_id_failed = 336330794;
  static const int isc_gbak_unk_rec_type = 336330795;
  static const int isc_gbak_inv_bkup_ver = 336330796;
  static const int isc_gbak_missing_bkup_desc = 336330797;
  static const int isc_gbak_string_trunc = 336330798;
  static const int isc_gbak_cant_rest_record = 336330799;
  static const int isc_gbak_send_failed = 336330800;
  static const int isc_gbak_no_tbl_name = 336330801;
  static const int isc_gbak_unexp_eof = 336330802;
  static const int isc_gbak_db_format_too_old = 336330803;
  static const int isc_gbak_inv_array_dim = 336330804;
  static const int isc_gbak_xdr_len_expected = 336330807;
  static const int isc_gbak_open_bkup_error = 336330817;
  static const int isc_gbak_open_error = 336330818;
  static const int isc_gbak_missing_block_fac = 336330934;
  static const int isc_gbak_inv_block_fac = 336330935;
  static const int isc_gbak_block_fac_specified = 336330936;
  static const int isc_gbak_missing_username = 336330940;
  static const int isc_gbak_missing_password = 336330941;
  static const int isc_gbak_missing_skipped_bytes = 336330952;
  static const int isc_gbak_inv_skipped_bytes = 336330953;
  static const int isc_gbak_err_restore_charset = 336330965;
  static const int isc_gbak_err_restore_collation = 336330967;
  static const int isc_gbak_read_error = 336330972;
  static const int isc_gbak_write_error = 336330973;
  static const int isc_gbak_db_in_use = 336330985;
  static const int isc_gbak_sysmemex = 336330990;
  static const int isc_gbak_restore_role_failed = 336331002;
  static const int isc_gbak_role_op_missing = 336331005;
  static const int isc_gbak_page_buffers_missing = 336331010;
  static const int isc_gbak_page_buffers_wrong_param = 336331011;
  static const int isc_gbak_page_buffers_restore = 336331012;
  static const int isc_gbak_inv_size = 336331014;
  static const int isc_gbak_file_outof_sequence = 336331015;
  static const int isc_gbak_join_file_missing = 336331016;
  static const int isc_gbak_stdin_not_supptd = 336331017;
  static const int isc_gbak_stdout_not_supptd = 336331018;
  static const int isc_gbak_bkup_corrupt = 336331019;
  static const int isc_gbak_unk_db_file_spec = 336331020;
  static const int isc_gbak_hdr_write_failed = 336331021;
  static const int isc_gbak_disk_space_ex = 336331022;
  static const int isc_gbak_size_lt_min = 336331023;
  static const int isc_gbak_svc_name_missing = 336331025;
  static const int isc_gbak_not_ownr = 336331026;
  static const int isc_gbak_mode_req = 336331031;
  static const int isc_gbak_just_data = 336331033;
  static const int isc_gbak_data_only = 336331034;
  static const int isc_gbak_missing_interval = 336331078;
  static const int isc_gbak_wrong_interval = 336331079;
  static const int isc_gbak_verify_verbint = 336331081;
  static const int isc_gbak_option_only_restore = 336331082;
  static const int isc_gbak_option_only_backup = 336331083;
  static const int isc_gbak_option_conflict = 336331084;
  static const int isc_gbak_param_conflict = 336331085;
  static const int isc_gbak_option_repeated = 336331086;
  static const int isc_gbak_max_dbkey_recursion = 336331091;
  static const int isc_gbak_max_dbkey_length = 336331092;
  static const int isc_gbak_invalid_metadata = 336331093;
  static const int isc_gbak_invalid_data = 336331094;
  static const int isc_gbak_inv_bkup_ver2 = 336331096;
  static const int isc_gbak_db_format_too_old2 = 336331100;

  /// ODS versions before ODS@1 are not supported
  static const int isc_dsql_too_old_ods = 336397205;

  /// Table @1 does not exist
  static const int isc_dsql_table_not_found = 336397206;

  /// View @1 does not exist
  static const int isc_dsql_view_not_found = 336397207;

  /// At line @1, column @2
  static const int isc_dsql_line_col_error = 336397208;

  /// At unknown line and column
  static const int isc_dsql_unknown_pos = 336397209;

  /// Column @1 cannot be repeated in @2 statement
  static const int isc_dsql_no_dup_name = 336397210;

  /// Too many values (more than @1) in member list to match against
  static const int isc_dsql_too_many_values = 336397211;

  /// Array and BLOB data types not allowed in computed field
  static const int isc_dsql_no_array_computed = 336397212;

  /// Implicit domain name @1 not allowed in user created domain
  static const int isc_dsql_implicit_domain_name = 336397213;

  /// scalar operator used on field @1 which is not an array
  static const int isc_dsql_only_can_subscript_array = 336397214;

  /// cannot sort on more than 255 items
  static const int isc_dsql_max_sort_items = 336397215;

  /// cannot group on more than 255 items
  static const int isc_dsql_max_group_items = 336397216;

  /// Cannot include the same field (@1.@2) twice in the ORDER BY clause with conflicting sorting options
  static const int isc_dsql_conflicting_sort_field = 336397217;

  /// column list from derived table @1 has more columns than the number of items in its SELECT statement
  static const int isc_dsql_derived_table_more_columns = 336397218;

  /// column list from derived table @1 has less columns than the number of items in its SELECT statement
  static const int isc_dsql_derived_table_less_columns = 336397219;

  /// no column name specified for column number @1 in derived table @2
  static const int isc_dsql_derived_field_unnamed = 336397220;

  /// column @1 was specified multiple times for derived table @2
  static const int isc_dsql_derived_field_dup_name = 336397221;

  /// Internal dsql error: alias type expected by pass1_expand_select_node
  static const int isc_dsql_derived_alias_select = 336397222;

  /// Internal dsql error: alias type expected by pass1_field
  static const int isc_dsql_derived_alias_field = 336397223;

  /// Internal dsql error: column position out of range in pass1_union_auto_cast
  static const int isc_dsql_auto_field_bad_pos = 336397224;

  /// Recursive CTE member (@1) can refer itself only in FROM clause
  static const int isc_dsql_cte_wrong_reference = 336397225;

  /// CTE '@1' has cyclic dependencies
  static const int isc_dsql_cte_cycle = 336397226;

  /// Recursive member of CTE can't be member of an outer join
  static const int isc_dsql_cte_outer_join = 336397227;

  /// Recursive member of CTE can't reference itself more than once
  static const int isc_dsql_cte_mult_references = 336397228;

  /// Recursive CTE (@1) must be an UNION
  static const int isc_dsql_cte_not_a_union = 336397229;

  /// CTE '@1' defined non-recursive member after recursive
  static const int isc_dsql_cte_nonrecurs_after_recurs = 336397230;

  /// Recursive member of CTE '@1' has @2 clause
  static const int isc_dsql_cte_wrong_clause = 336397231;

  /// Recursive members of CTE (@1) must be linked with another members via UNION ALL
  static const int isc_dsql_cte_union_all = 336397232;

  /// Non-recursive member is missing in CTE '@1'
  static const int isc_dsql_cte_miss_nonrecursive = 336397233;

  /// WITH clause can't be nested
  static const int isc_dsql_cte_nested_with = 336397234;

  /// column @1 appears more than once in USING clause
  static const int isc_dsql_col_more_than_once_using = 336397235;

  /// feature is not supported in dialect @1
  static const int isc_dsql_unsupp_feature_dialect = 336397236;

  /// CTE "@1" is not used in query
  static const int isc_dsql_cte_not_used = 336397237;

  /// column @1 appears more than once in ALTER VIEW
  static const int isc_dsql_col_more_than_once_view = 336397238;

  /// @1 is not supported inside IN AUTONOMOUS TRANSACTION block
  static const int isc_dsql_unsupported_in_auto_trans = 336397239;

  /// Unknown node type @1 in dsql/GEN_expr
  static const int isc_dsql_eval_unknode = 336397240;

  /// Argument for @1 in dialect 1 must be string or numeric
  static const int isc_dsql_agg_wrongarg = 336397241;

  /// Argument for @1 in dialect 3 must be numeric
  static const int isc_dsql_agg2_wrongarg = 336397242;

  /// Strings cannot be added to or subtracted from DATE or TIME types
  static const int isc_dsql_nodateortime_pm_string = 336397243;

  /// Invalid data type for subtraction involving DATE, TIME or TIMESTAMP types
  static const int isc_dsql_invalid_datetime_subtract = 336397244;

  /// Adding two DATE values or two TIME values is not allowed
  static const int isc_dsql_invalid_dateortime_add = 336397245;

  /// DATE value cannot be subtracted from the provided data type
  static const int isc_dsql_invalid_type_minus_date = 336397246;

  /// Strings cannot be added or subtracted in dialect 3
  static const int isc_dsql_nostring_addsub_dial3 = 336397247;

  /// Invalid data type for addition or subtraction in dialect 3
  static const int isc_dsql_invalid_type_addsub_dial3 = 336397248;

  /// Invalid data type for multiplication in dialect 1
  static const int isc_dsql_invalid_type_multip_dial1 = 336397249;

  /// Strings cannot be multiplied in dialect 3
  static const int isc_dsql_nostring_multip_dial3 = 336397250;

  /// Invalid data type for multiplication in dialect 3
  static const int isc_dsql_invalid_type_multip_dial3 = 336397251;

  /// Division in dialect 1 must be between numeric data types
  static const int isc_dsql_mustuse_numeric_div_dial1 = 336397252;

  /// Strings cannot be divided in dialect 3
  static const int isc_dsql_nostring_div_dial3 = 336397253;

  /// Invalid data type for division in dialect 3
  static const int isc_dsql_invalid_type_div_dial3 = 336397254;

  /// Strings cannot be negated (applied the minus operator) in dialect 3
  static const int isc_dsql_nostring_neg_dial3 = 336397255;

  /// Invalid data type for negation (minus operator)
  static const int isc_dsql_invalid_type_neg = 336397256;

  /// Cannot have more than 255 items in DISTINCT / UNION DISTINCT list
  static const int isc_dsql_max_distinct_items = 336397257;

  /// ALTER CHARACTER SET @1 failed
  static const int isc_dsql_alter_charset_failed = 336397258;

  /// COMMENT ON @1 failed
  static const int isc_dsql_comment_on_failed = 336397259;

  /// CREATE FUNCTION @1 failed
  static const int isc_dsql_create_func_failed = 336397260;

  /// ALTER FUNCTION @1 failed
  static const int isc_dsql_alter_func_failed = 336397261;

  /// CREATE OR ALTER FUNCTION @1 failed
  static const int isc_dsql_create_alter_func_failed = 336397262;

  /// DROP FUNCTION @1 failed
  static const int isc_dsql_drop_func_failed = 336397263;

  /// RECREATE FUNCTION @1 failed
  static const int isc_dsql_recreate_func_failed = 336397264;

  /// CREATE PROCEDURE @1 failed
  static const int isc_dsql_create_proc_failed = 336397265;

  /// ALTER PROCEDURE @1 failed
  static const int isc_dsql_alter_proc_failed = 336397266;

  /// CREATE OR ALTER PROCEDURE @1 failed
  static const int isc_dsql_create_alter_proc_failed = 336397267;

  /// DROP PROCEDURE @1 failed
  static const int isc_dsql_drop_proc_failed = 336397268;

  /// RECREATE PROCEDURE @1 failed
  static const int isc_dsql_recreate_proc_failed = 336397269;

  /// CREATE TRIGGER @1 failed
  static const int isc_dsql_create_trigger_failed = 336397270;

  /// ALTER TRIGGER @1 failed
  static const int isc_dsql_alter_trigger_failed = 336397271;

  /// CREATE OR ALTER TRIGGER @1 failed
  static const int isc_dsql_create_alter_trigger_failed = 336397272;

  /// DROP TRIGGER @1 failed
  static const int isc_dsql_drop_trigger_failed = 336397273;

  /// RECREATE TRIGGER @1 failed
  static const int isc_dsql_recreate_trigger_failed = 336397274;

  /// CREATE COLLATION @1 failed
  static const int isc_dsql_create_collation_failed = 336397275;

  /// DROP COLLATION @1 failed
  static const int isc_dsql_drop_collation_failed = 336397276;

  /// CREATE DOMAIN @1 failed
  static const int isc_dsql_create_domain_failed = 336397277;

  /// ALTER DOMAIN @1 failed
  static const int isc_dsql_alter_domain_failed = 336397278;

  /// DROP DOMAIN @1 failed
  static const int isc_dsql_drop_domain_failed = 336397279;

  /// CREATE EXCEPTION @1 failed
  static const int isc_dsql_create_except_failed = 336397280;

  /// ALTER EXCEPTION @1 failed
  static const int isc_dsql_alter_except_failed = 336397281;

  /// CREATE OR ALTER EXCEPTION @1 failed
  static const int isc_dsql_create_alter_except_failed = 336397282;

  /// RECREATE EXCEPTION @1 failed
  static const int isc_dsql_recreate_except_failed = 336397283;

  /// DROP EXCEPTION @1 failed
  static const int isc_dsql_drop_except_failed = 336397284;

  /// CREATE SEQUENCE @1 failed
  static const int isc_dsql_create_sequence_failed = 336397285;

  /// CREATE TABLE @1 failed
  static const int isc_dsql_create_table_failed = 336397286;

  /// ALTER TABLE @1 failed
  static const int isc_dsql_alter_table_failed = 336397287;

  /// DROP TABLE @1 failed
  static const int isc_dsql_drop_table_failed = 336397288;

  /// RECREATE TABLE @1 failed
  static const int isc_dsql_recreate_table_failed = 336397289;

  /// CREATE PACKAGE @1 failed
  static const int isc_dsql_create_pack_failed = 336397290;

  /// ALTER PACKAGE @1 failed
  static const int isc_dsql_alter_pack_failed = 336397291;

  /// CREATE OR ALTER PACKAGE @1 failed
  static const int isc_dsql_create_alter_pack_failed = 336397292;

  /// DROP PACKAGE @1 failed
  static const int isc_dsql_drop_pack_failed = 336397293;

  /// RECREATE PACKAGE @1 failed
  static const int isc_dsql_recreate_pack_failed = 336397294;

  /// CREATE PACKAGE BODY @1 failed
  static const int isc_dsql_create_pack_body_failed = 336397295;

  /// DROP PACKAGE BODY @1 failed
  static const int isc_dsql_drop_pack_body_failed = 336397296;

  /// RECREATE PACKAGE BODY @1 failed
  static const int isc_dsql_recreate_pack_body_failed = 336397297;

  /// CREATE VIEW @1 failed
  static const int isc_dsql_create_view_failed = 336397298;

  /// ALTER VIEW @1 failed
  static const int isc_dsql_alter_view_failed = 336397299;

  /// CREATE OR ALTER VIEW @1 failed
  static const int isc_dsql_create_alter_view_failed = 336397300;

  /// RECREATE VIEW @1 failed
  static const int isc_dsql_recreate_view_failed = 336397301;

  /// DROP VIEW @1 failed
  static const int isc_dsql_drop_view_failed = 336397302;

  /// DROP SEQUENCE @1 failed
  static const int isc_dsql_drop_sequence_failed = 336397303;

  /// RECREATE SEQUENCE @1 failed
  static const int isc_dsql_recreate_sequence_failed = 336397304;

  /// DROP INDEX @1 failed
  static const int isc_dsql_drop_index_failed = 336397305;

  /// DROP FILTER @1 failed
  static const int isc_dsql_drop_filter_failed = 336397306;

  /// DROP SHADOW @1 failed
  static const int isc_dsql_drop_shadow_failed = 336397307;

  /// DROP ROLE @1 failed
  static const int isc_dsql_drop_role_failed = 336397308;

  /// DROP USER @1 failed
  static const int isc_dsql_drop_user_failed = 336397309;

  /// CREATE ROLE @1 failed
  static const int isc_dsql_create_role_failed = 336397310;

  /// ALTER ROLE @1 failed
  static const int isc_dsql_alter_role_failed = 336397311;

  /// ALTER INDEX @1 failed
  static const int isc_dsql_alter_index_failed = 336397312;

  /// ALTER DATABASE failed
  static const int isc_dsql_alter_database_failed = 336397313;

  /// CREATE SHADOW @1 failed
  static const int isc_dsql_create_shadow_failed = 336397314;

  /// DECLARE FILTER @1 failed
  static const int isc_dsql_create_filter_failed = 336397315;

  /// CREATE INDEX @1 failed
  static const int isc_dsql_create_index_failed = 336397316;

  /// CREATE USER @1 failed
  static const int isc_dsql_create_user_failed = 336397317;

  /// ALTER USER @1 failed
  static const int isc_dsql_alter_user_failed = 336397318;

  /// GRANT failed
  static const int isc_dsql_grant_failed = 336397319;

  /// REVOKE failed
  static const int isc_dsql_revoke_failed = 336397320;

  /// Recursive member of CTE cannot use aggregate or window function
  static const int isc_dsql_cte_recursive_aggregate = 336397321;

  /// @2 MAPPING @1 failed
  static const int isc_dsql_mapping_failed = 336397322;

  /// ALTER SEQUENCE @1 failed
  static const int isc_dsql_alter_sequence_failed = 336397323;

  /// CREATE GENERATOR @1 failed
  static const int isc_dsql_create_generator_failed = 336397324;

  /// SET GENERATOR @1 failed
  static const int isc_dsql_set_generator_failed = 336397325;

  /// WITH LOCK can be used only with a single physical table
  static const int isc_dsql_wlock_simple = 336397326;

  /// FIRST/SKIP cannot be used with OFFSET/FETCH or ROWS
  static const int isc_dsql_firstskip_rows = 336397327;

  /// WITH LOCK cannot be used with aggregates
  static const int isc_dsql_wlock_aggregates = 336397328;

  /// WITH LOCK cannot be used with @1
  static const int isc_dsql_wlock_conflict = 336397329;

  /// Number of arguments (@1) exceeds the maximum (@2) number of EXCEPTION USING arguments
  static const int isc_dsql_max_exception_arguments = 336397330;

  /// String literal with @1 bytes exceeds the maximum length of @2 bytes
  static const int isc_dsql_string_byte_length = 336397331;

  /// String literal with @1 characters exceeds the maximum length of @2 characters for the @3 character set
  static const int isc_dsql_string_char_length = 336397332;

  /// Too many BEGIN??END nesting. Maximum level is @1
  static const int isc_dsql_max_nesting = 336397333;

  /// RECREATE USER @1 failed
  static const int isc_dsql_recreate_user_failed = 336397334;
  static const int isc_gsec_cant_open_db = 336723983;
  static const int isc_gsec_switches_error = 336723984;
  static const int isc_gsec_no_op_spec = 336723985;
  static const int isc_gsec_no_usr_name = 336723986;
  static const int isc_gsec_err_add = 336723987;
  static const int isc_gsec_err_modify = 336723988;
  static const int isc_gsec_err_find_mod = 336723989;
  static const int isc_gsec_err_rec_not_found = 336723990;
  static const int isc_gsec_err_delete = 336723991;
  static const int isc_gsec_err_find_del = 336723992;
  static const int isc_gsec_err_find_disp = 336723996;
  static const int isc_gsec_inv_param = 336723997;
  static const int isc_gsec_op_specified = 336723998;
  static const int isc_gsec_pw_specified = 336723999;
  static const int isc_gsec_uid_specified = 336724000;
  static const int isc_gsec_gid_specified = 336724001;
  static const int isc_gsec_proj_specified = 336724002;
  static const int isc_gsec_org_specified = 336724003;
  static const int isc_gsec_fname_specified = 336724004;
  static const int isc_gsec_mname_specified = 336724005;
  static const int isc_gsec_lname_specified = 336724006;
  static const int isc_gsec_inv_switch = 336724008;
  static const int isc_gsec_amb_switch = 336724009;
  static const int isc_gsec_no_op_specified = 336724010;
  static const int isc_gsec_params_not_allowed = 336724011;
  static const int isc_gsec_incompat_switch = 336724012;
  static const int isc_gsec_inv_username = 336724044;
  static const int isc_gsec_inv_pw_length = 336724045;
  static const int isc_gsec_db_specified = 336724046;
  static const int isc_gsec_db_admin_specified = 336724047;
  static const int isc_gsec_db_admin_pw_specified = 336724048;
  static const int isc_gsec_sql_role_specified = 336724049;
  static const int isc_gstat_unknown_switch = 336920577;
  static const int isc_gstat_retry = 336920578;
  static const int isc_gstat_wrong_ods = 336920579;
  static const int isc_gstat_unexpected_eof = 336920580;
  static const int isc_gstat_open_err = 336920605;
  static const int isc_gstat_read_err = 336920606;
  static const int isc_gstat_sysmemex = 336920607;
  static const int isc_fbsvcmgr_bad_am = 336986113;
  static const int isc_fbsvcmgr_bad_wm = 336986114;
  static const int isc_fbsvcmgr_bad_rs = 336986115;
  static const int isc_fbsvcmgr_info_err = 336986116;
  static const int isc_fbsvcmgr_query_err = 336986117;
  static const int isc_fbsvcmgr_switch_unknown = 336986118;
  static const int isc_fbsvcmgr_bad_sm = 336986159;
  static const int isc_fbsvcmgr_fp_open = 336986160;
  static const int isc_fbsvcmgr_fp_read = 336986161;
  static const int isc_fbsvcmgr_fp_empty = 336986162;
  static const int isc_fbsvcmgr_bad_arg = 336986164;
  static const int isc_fbsvcmgr_info_limbo = 336986170;
  static const int isc_fbsvcmgr_limbo_state = 336986171;
  static const int isc_fbsvcmgr_limbo_advise = 336986172;
  static const int isc_fbsvcmgr_bad_rm = 336986173;
  static const int isc_utl_trusted_switch = 337051649;
  static const int isc_nbackup_missing_param = 337117213;
  static const int isc_nbackup_allowed_switches = 337117214;
  static const int isc_nbackup_unknown_param = 337117215;
  static const int isc_nbackup_unknown_switch = 337117216;
  static const int isc_nbackup_nofetchpw_svc = 337117217;
  static const int isc_nbackup_pwfile_error = 337117218;
  static const int isc_nbackup_size_with_lock = 337117219;
  static const int isc_nbackup_no_switch = 337117220;
  static const int isc_nbackup_err_read = 337117223;
  static const int isc_nbackup_err_write = 337117224;
  static const int isc_nbackup_err_seek = 337117225;
  static const int isc_nbackup_err_opendb = 337117226;
  static const int isc_nbackup_err_fadvice = 337117227;
  static const int isc_nbackup_err_createdb = 337117228;
  static const int isc_nbackup_err_openbk = 337117229;
  static const int isc_nbackup_err_createbk = 337117230;
  static const int isc_nbackup_err_eofdb = 337117231;
  static const int isc_nbackup_fixup_wrongstate = 337117232;
  static const int isc_nbackup_err_db = 337117233;
  static const int isc_nbackup_userpw_toolong = 337117234;
  static const int isc_nbackup_lostrec_db = 337117235;
  static const int isc_nbackup_lostguid_db = 337117236;
  static const int isc_nbackup_err_eofhdrdb = 337117237;
  static const int isc_nbackup_db_notlock = 337117238;
  static const int isc_nbackup_lostguid_bk = 337117239;
  static const int isc_nbackup_page_changed = 337117240;
  static const int isc_nbackup_dbsize_inconsistent = 337117241;
  static const int isc_nbackup_failed_lzbk = 337117242;
  static const int isc_nbackup_err_eofhdrbk = 337117243;
  static const int isc_nbackup_invalid_incbk = 337117244;
  static const int isc_nbackup_unsupvers_incbk = 337117245;
  static const int isc_nbackup_invlevel_incbk = 337117246;
  static const int isc_nbackup_wrong_orderbk = 337117247;
  static const int isc_nbackup_err_eofbk = 337117248;
  static const int isc_nbackup_err_copy = 337117249;
  static const int isc_nbackup_err_eofhdr_restdb = 337117250;
  static const int isc_nbackup_lostguid_l0bk = 337117251;
  static const int isc_nbackup_switchd_parameter = 337117255;
  static const int isc_nbackup_user_stop = 337117257;
  static const int isc_nbackup_deco_parse = 337117259;
  static const int isc_nbackup_lostrec_guid_db = 337117261;
  static const int isc_nbackup_seq_misuse = 337117265;
  static const int isc_nbackup_wrong_param = 337117268;
  static const int isc_nbackup_clean_hist_misuse = 337117269;
  static const int isc_nbackup_clean_hist_missed = 337117270;
  static const int isc_nbackup_keep_hist_missed = 337117271;
  static const int isc_nbackup_second_keep_switch = 337117272;
  static const int isc_trace_conflict_acts = 337182750;
  static const int isc_trace_act_notfound = 337182751;
  static const int isc_trace_switch_once = 337182752;
  static const int isc_trace_param_val_miss = 337182753;
  static const int isc_trace_param_invalid = 337182754;
  static const int isc_trace_switch_unknown = 337182755;
  static const int isc_trace_switch_svc_only = 337182756;
  static const int isc_trace_switch_user_only = 337182757;
  static const int isc_trace_switch_param_miss = 337182758;
  static const int isc_trace_param_act_notcompat = 337182759;
  static const int isc_trace_mandatory_switch_miss = 337182760;

  /// The maximum error code used.
  static const int isc_err_max = 1453;
}
