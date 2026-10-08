class RenameSearchTablePartitions < ActiveRecord::Migration[8.0]

  MODELS_FOR_SEARCH_DOCUMENT_PARTITIONS = [
    CensorRule,
    Citation,
    Comment,
    User::EmailHistory,
    FoiAttachment,
    IncomingMessage,
    InfoRequest,
    InfoRequestEvent,
    OutgoingMessage,
    MailServerLog,
    Note,
    PublicBody,
    PublicBodyChangeRequest,
    User
  ].freeze

  INDICES_OLD_NAMES = %w[
    search_documents_censorrule_admin_content_tsv_idx
    search_documents_censorrule_content_tsv_idx
    search_documents_censorrule_pkey
    search_documents_censorrule_searchable_type_searchable_id_idx
    search_documents_censorrule_searchable_type_searchable_id_s_idx
    search_documents_citation_admin_content_tsv_idx
    search_documents_citation_content_tsv_idx
    search_documents_citation_pkey
    search_documents_citation_searchable_type_searchable_id_idx
    search_documents_citation_searchable_type_searchable_id_sec_idx
    search_documents_comment_admin_content_tsv_idx
    search_documents_comment_content_tsv_idx
    search_documents_comment_pkey
    search_documents_comment_searchable_type_searchable_id_idx
    search_documents_comment_searchable_type_searchable_id_sect_idx
    search_documents_foiattachmen_searchable_type_searchable_i_idx1
    search_documents_foiattachmen_searchable_type_searchable_id_idx
    search_documents_foiattachment_admin_content_tsv_idx
    search_documents_foiattachment_content_tsv_idx
    search_documents_foiattachment_pkey
    search_documents_incomingmess_searchable_type_searchable_i_idx1
    search_documents_incomingmess_searchable_type_searchable_id_idx
    search_documents_incomingmessage_admin_content_tsv_idx
    search_documents_incomingmessage_content_tsv_idx
    search_documents_incomingmessage_pkey
    search_documents_inforequest_admin_content_tsv_idx
    search_documents_inforequest_content_tsv_idx
    search_documents_inforequest_pkey
    search_documents_inforequest_searchable_type_searchable_id__idx
    search_documents_inforequest_searchable_type_searchable_id_idx
    search_documents_inforequeste_searchable_type_searchable_i_idx1
    search_documents_inforequeste_searchable_type_searchable_id_idx
    search_documents_inforequestevent_admin_content_tsv_idx
    search_documents_inforequestevent_content_tsv_idx
    search_documents_inforequestevent_pkey
    search_documents_mailserverlo_searchable_type_searchable_i_idx1
    search_documents_mailserverlo_searchable_type_searchable_id_idx
    search_documents_mailserverlog_admin_content_tsv_idx
    search_documents_mailserverlog_content_tsv_idx
    search_documents_mailserverlog_pkey
    search_documents_note_admin_content_tsv_idx
    search_documents_note_content_tsv_idx
    search_documents_note_pkey
    search_documents_note_searchable_type_searchable_id_idx
    search_documents_note_searchable_type_searchable_id_section_idx
    search_documents_outgoingmess_searchable_type_searchable_i_idx1
    search_documents_outgoingmess_searchable_type_searchable_id_idx
    search_documents_outgoingmessage_admin_content_tsv_idx
    search_documents_outgoingmessage_content_tsv_idx
    search_documents_outgoingmessage_pkey
    search_documents_publicbody_admin_content_tsv_idx
    search_documents_publicbody_content_tsv_idx
    search_documents_publicbody_pkey
    search_documents_publicbody_searchable_type_searchable_id_idx
    search_documents_publicbody_searchable_type_searchable_id_s_idx
    search_documents_publicbodych_searchable_type_searchable_i_idx1
    search_documents_publicbodych_searchable_type_searchable_id_idx
    search_documents_publicbodychangerequest_admin_content_tsv_idx
    search_documents_publicbodychangerequest_content_tsv_idx
    search_documents_publicbodychangerequest_pkey
    search_documents_user_admin_content_tsv_idx
    search_documents_user_content_tsv_idx
    search_documents_user_emailhi_searchable_type_searchable_i_idx1
    search_documents_user_emailhi_searchable_type_searchable_id_idx
    search_documents_user_emailhistory_admin_content_tsv_idx
    search_documents_user_emailhistory_content_tsv_idx
    search_documents_user_emailhistory_pkey
    search_documents_user_pkey
    search_documents_user_searchable_type_searchable_id_idx
    search_documents_user_searchable_type_searchable_id_section_idx
  ].freeze

  INDICES_NEW_NAMES = %w[
    search_documents_censor_rules_admin_content_tsv_idx
    search_documents_censor_rules_content_tsv_idx
    search_documents_censor_rules_pkey
    search_documents_censor_rules_searchable_type_searchable_id_idx
    search_documents_censor_rules_searchable_type_searchab_id_s_idx
    search_documents_citations_admin_content_tsv_idx
    search_documents_citations_content_tsv_idx
    search_documents_citations_pkey
    search_documents_citations_searchable_type_searchable_id_idx
    search_documents_citations_searchable_type_searchable_id_se_idx
    search_documents_comments_admin_content_tsv_idx
    search_documents_comments_content_tsv_idx
    search_documents_comments_pkey
    search_documents_comments_searchable_type_searchable_id_idx
    search_documents_comments_searchable_type_searchable_id_sec_idx
    search_documents_foi_attachme_searchable_type_searchable_i_idx1
    search_documents_foi_attachme_searchable_type_searchable_id_idx
    search_documents_foi_attachments_admin_content_tsv_idx
    search_documents_foi_attachments_content_tsv_idx
    search_documents_foi_attachments_pkey
    search_documents_incoming_mes_searchable_type_searchable_i_idx1
    search_documents_incoming_mes_searchable_type_searchable_id_idx
    search_documents_incoming_messages_admin_content_tsv_idx
    search_documents_incoming_messages_content_tsv_idx
    search_documents_incoming_messages_pkey
    search_documents_info_requests_admin_content_tsv_idx
    search_documents_info_requests_content_tsv_idx
    search_documents_info_requests_pkey
    search_documents_info_requests_searchable_type_searchable_i_idx
    search_documents_info_requests_searchable_type_searchabl_id_idx
    search_documents_info_request_ev_searchable_type_searcha_i_idx1
    search_documents_info_request_ev_searchable_type_searcha_id_idx
    search_documents_info_request_events_admin_content_tsv_idx
    search_documents_info_request_events_content_tsv_idx
    search_documents_info_request_events_pkey
    search_documents_mail_server_l_searchable_type_searchabl_i_idx1
    search_documents_mail_server_l_searchable_type_searchabl_id_idx
    search_documents_mail_server_logs_admin_content_tsv_idx
    search_documents_mail_server_logs_content_tsv_idx
    search_documents_mail_server_logs_pkey
    search_documents_notes_admin_content_tsv_idx
    search_documents_notes_content_tsv_idx
    search_documents_notes_pkey
    search_documents_notes_searchable_type_searchable_id_idx
    search_documents_notes_searchable_type_searchable_id_sectio_idx
    search_documents_outgoing_mess_searchable_type_searchabl_i_idx1
    search_documents_outgoing_mess_searchable_type_searchabl_id_idx
    search_documents_outgoing_messages_admin_content_tsv_idx
    search_documents_outgoing_messages_content_tsv_idx
    search_documents_outgoing_messages_pkey
    search_documents_public_bodies_admin_content_tsv_idx
    search_documents_public_bodies_content_tsv_idx
    search_documents_public_bodies_pkey
    search_documents_public_bodies_searchable_type_searchable_i_idx
    search_documents_public_bodies_searchable_type_searchab_i_s_idx
    search_documents_public_body_ch_searchable_type_searchab_i_idx1
    search_documents_public_body_ch_searchable_type_searchab_id_idx
    search_documents_public_body_change_reque_admin_content_tsv_idx
    search_documents_public_body_change_requests_content_tsv_idx
    search_documents_public_body_change_requests_pkey
    search_documents_users_admin_content_tsv_idx
    search_documents_users_content_tsv_idx
    search_documents_user_email_hi_searchable_type_searchabl_i_idx1
    search_documents_user_email_hi_searchable_type_searchabl_id_idx
    search_documents_user_email_histories_admin_content_tsv_idx
    search_documents_user_email_histories_content_tsv_idx
    search_documents_user_email_histories_pkey
    search_documents_users_pkey
    search_documents_users_searchable_type_searchable_id_idx
    search_documents_users_searchable_type_searchable_id_sectio_idx
  ].freeze

  INDICES_TO_DROP = %[
  ].freeze

  def change
    MODELS_FOR_SEARCH_DOCUMENT_PARTITIONS.each do |model|
      rename_table(
        old_partition_table_name(model),
        new_partition_table_name(model)
      )
    end

    # not using the rails remove_index function because it
    # requires passing the table name for each, which is annoying
    reversible do |direction|
      direction.up do
        INDICES_OLD_NAMES.each_with_index do |idx, i|
          execute("ALTER INDEX #{idx} RENAME TO #{INDICES_NEW_NAMES[i]}")
        end
      end
      direction.down do
        INDICES_NEW_NAMES.each_with_index do |idx, i|
          execute("ALTER INDEX #{idx} RENAME TO #{INDICES_OLD_NAMES[i]}")
        end
      end
    end
  end

  private

  def old_partition_table_name(model)
    "search_documents_#{model.name.downcase.gsub('::', '_')}"
  end

  def new_partition_table_name(model)
    "search_documents_#{model.table_name}"
  end
end
