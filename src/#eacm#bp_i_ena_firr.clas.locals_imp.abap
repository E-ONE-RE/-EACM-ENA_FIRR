CLASS lhc_EnaFirr DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR EnaFirr RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR EnaFirr RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE EnaFirr.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE EnaFirr.

    METHODS read FOR READ
      IMPORTING keys FOR READ EnaFirr RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK EnaFirr.

    METHODS calculateandcreatepdfs FOR MODIFY
      IMPORTING keys FOR ACTION EnaFirr~CalculateAndCreatePdfs RESULT result.
ENDCLASS.

CLASS lhc_EnaFirr IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      DELETE /eacm/bp_i_ena_firr=>gt_ena_firr
        WHERE bukrs  = <entity>-CompanyCode
          AND gjahr  = <entity>-FiscalYear
          AND zcdage = <entity>-AgentCode
          AND lifnr  = <entity>-Supplier.

      APPEND VALUE #(
        client                      = sy-mandt
        bukrs                       = <entity>-CompanyCode
        gjahr                       = <entity>-FiscalYear
        zcdage                      = <entity>-AgentCode
        lifnr                       = <entity>-Supplier
        bukrs_name                  = <entity>-CompanyName
        bukrs_country               = <entity>-CompanyCountry
        bukrs_city                  = <entity>-CompanyCity
        bukrs_post_code             = <entity>-CompanyPostCode
        bukrs_street                = <entity>-CompanyStreet
        bukrs_house_num             = <entity>-CompanyHouseNumber
        bukrs_region                = <entity>-CompanyRegion
        bukrs_piva                  = <entity>-CompanyVatNumber
        currency                    = <entity>-TransactionCurrency
        age_name                    = <entity>-AgentName
        age_country                 = <entity>-AgentCountry
        age_city                    = <entity>-AgentCity
        age_post_code               = <entity>-AgentPostCode
        age_street                  = <entity>-AgentStreet
        age_house_num               = <entity>-AgentHouseNumber
        age_region                  = <entity>-AgentRegion
        age_piva                    = <entity>-AgentVatNumber
        paymenttype                 = <entity>-PaymentType
        enasarcoscope               = <entity>-EnasarcoScope
        firrmaturedcommission       = <entity>-FirrMaturedCommission
        firrcontribution            = <entity>-FirrContribution
        hasfirrcontribution         = <entity>-HasFirrContribution
        firrrate                    = <entity>-FirrRate
        enasarcoagentcontribution   = <entity>-EnasarcoAgentContribution
        enasarcopaidamount          = <entity>-EnasarcoPaidAmount
        cessationdate               = <entity>-CessationDate
        iscessationinyear           = <entity>-IsCessationInYear
        servicedescription          = <entity>-ServiceDescription
        filename                    = <entity>-FileName
        mime_type                   = <entity>-MimeType
        attachment                  = <entity>-Attachment ) TO /eacm/bp_i_ena_firr=>gt_ena_firr.

      APPEND VALUE #(
        %cid        = <entity>-%cid
        CompanyCode = <entity>-CompanyCode
        FiscalYear  = <entity>-FiscalYear
        AgentCode   = <entity>-AgentCode
        Supplier    = <entity>-Supplier ) TO mapped-enafirr.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DELETE /eacm/bp_i_ena_firr=>gt_ena_firr
        WHERE bukrs  = <key>-CompanyCode
          AND gjahr  = <key>-FiscalYear
          AND zcdage = <key>-AgentCode
          AND lifnr  = <key>-Supplier.

      IF sy-subrc = 0.
        APPEND VALUE #(
          CompanyCode = <key>-CompanyCode
          FiscalYear  = <key>-FiscalYear
          AgentCode   = <key>-AgentCode
          Supplier    = <key>-Supplier
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = |Record ENA/FIRR rimosso dal buffer.| ) ) TO reported-enafirr.
        CONTINUE.
      ENDIF.

      SELECT SINGLE @abap_true
        FROM /eacm/ena_firr
        WHERE bukrs  = @<key>-CompanyCode
          AND gjahr  = @<key>-FiscalYear
          AND zcdage = @<key>-AgentCode
          AND lifnr  = @<key>-Supplier
        INTO @DATA(lv_exists).

      IF lv_exists IS INITIAL.
        APPEND VALUE #(
          CompanyCode = <key>-CompanyCode
          FiscalYear  = <key>-FiscalYear
          AgentCode   = <key>-AgentCode
          Supplier    = <key>-Supplier
          %fail-cause = if_abap_behv=>cause-not_found ) TO failed-enafirr.

        APPEND VALUE #(
          CompanyCode = <key>-CompanyCode
          FiscalYear  = <key>-FiscalYear
          AgentCode   = <key>-AgentCode
          Supplier    = <key>-Supplier
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Record ENA/FIRR non trovato.| ) ) TO reported-enafirr.
        CONTINUE.
      ENDIF.

      INSERT VALUE #(
        bukrs  = <key>-CompanyCode
        gjahr  = <key>-FiscalYear
        zcdage = <key>-AgentCode
        lifnr  = <key>-Supplier ) INTO TABLE /eacm/bp_i_ena_firr=>gt_delete.

      APPEND VALUE #(
        CompanyCode = <key>-CompanyCode
        FiscalYear  = <key>-FiscalYear
        AgentCode   = <key>-AgentCode
        Supplier    = <key>-Supplier
        %msg        = new_message_with_text(
                        severity = if_abap_behv_message=>severity-success
                        text     = |Record ENA/FIRR marcato per cancellazione.| ) ) TO reported-enafirr.

      CLEAR lv_exists.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      READ TABLE /eacm/bp_i_ena_firr=>gt_ena_firr ASSIGNING FIELD-SYMBOL(<entity>)
        WITH KEY bukrs  = <key>-CompanyCode
                 gjahr  = <key>-FiscalYear
                 zcdage = <key>-AgentCode
                 lifnr  = <key>-Supplier.

      IF sy-subrc = 0.
        APPEND VALUE #(
          CompanyCode                 = <entity>-bukrs
          FiscalYear                  = <entity>-gjahr
          AgentCode                   = <entity>-zcdage
          Supplier                    = <entity>-lifnr
          CompanyName                 = <entity>-bukrs_name
          CompanyCountry              = <entity>-bukrs_country
          CompanyCity                 = <entity>-bukrs_city
          CompanyPostCode             = <entity>-bukrs_post_code
          CompanyStreet               = <entity>-bukrs_street
          CompanyHouseNumber          = <entity>-bukrs_house_num
          CompanyRegion               = <entity>-bukrs_region
          CompanyVatNumber            = <entity>-bukrs_piva
          TransactionCurrency         = <entity>-currency
          AgentName                   = <entity>-age_name
          AgentCountry                = <entity>-age_country
          AgentCity                   = <entity>-age_city
          AgentPostCode               = <entity>-age_post_code
          AgentStreet                 = <entity>-age_street
          AgentHouseNumber            = <entity>-age_house_num
          AgentRegion                 = <entity>-age_region
          AgentVatNumber              = <entity>-age_piva
          PaymentType                 = <entity>-paymenttype
          EnasarcoScope               = <entity>-enasarcoscope
          FirrMaturedCommission       = <entity>-firrmaturedcommission
          FirrContribution            = <entity>-firrcontribution
          HasFirrContribution         = <entity>-hasfirrcontribution
          FirrRate                    = <entity>-firrrate
          EnasarcoAgentContribution   = <entity>-enasarcoagentcontribution
          EnasarcoPaidAmount          = <entity>-enasarcopaidamount
          CessationDate               = <entity>-cessationdate
          IsCessationInYear           = <entity>-iscessationinyear
          ServiceDescription          = <entity>-servicedescription
          FileName                    = <entity>-filename
          MimeType                    = <entity>-mime_type
          Attachment                  = <entity>-attachment ) TO result.
        CONTINUE.
      ENDIF.

      DATA ls_db_run TYPE STRUCTURE FOR READ RESULT /EACM/I_ENA_FIRR.

      SELECT SINGLE FROM /EACM/I_ENA_FIRR
        FIELDS *
        WHERE CompanyCode = @<key>-CompanyCode
          AND FiscalYear  = @<key>-FiscalYear
          AND AgentCode   = @<key>-AgentCode
          AND Supplier    = @<key>-Supplier
        INTO CORRESPONDING FIELDS OF @ls_db_run.

      IF sy-subrc = 0.
        APPEND ls_db_run TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD calculateandcreatepdfs.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      IF <ls_key>-%param-CompanyCode IS INITIAL
         OR <ls_key>-%param-FiscalYear IS INITIAL.
        APPEND VALUE #(
          %cid        = <ls_key>-%cid
          %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-enafirr.

        APPEND VALUE #(
          %cid                   = <ls_key>-%cid
          %msg                   = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-error
                                     text     = 'Inserire societa ed esercizio per il calcolo ENA/FIRR.' )
          %op-%action-CalculateAndCreatePdfs = if_abap_behv=>mk-on
          %element-CompanyCode   = if_abap_behv=>mk-on
          %element-FiscalYear    = if_abap_behv=>mk-on ) TO reported-enafirr.
        RETURN.
      ENDIF.

      SELECT COUNT( * )
        FROM /eacm/ena_firr
        WHERE bukrs = @<ls_key>-%param-CompanyCode
          AND gjahr = @<ls_key>-%param-FiscalYear
          AND ( @<ls_key>-%param-Zcdaz IS INITIAL OR zcdage = @<ls_key>-%param-Zcdaz )
          AND ( @<ls_key>-%param-Ztpag IS INITIAL OR paymenttype = @<ls_key>-%param-Ztpag )
          AND ( @<ls_key>-%param-Lifnr IS INITIAL OR lifnr = @<ls_key>-%param-Lifnr )
        INTO @DATA(lv_existing_records).

      IF lv_existing_records > 0.
        INSERT VALUE #(
          bukrs  = <ls_key>-%param-CompanyCode
          gjahr  = <ls_key>-%param-FiscalYear
          zcdage = <ls_key>-%param-Zcdaz
          ztpag  = <ls_key>-%param-Ztpag
          lifnr  = <ls_key>-%param-Lifnr ) INTO TABLE /eacm/bp_i_ena_firr=>gt_delete.

        APPEND VALUE #(
          %cid = <ls_key>-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-warning
                   text     = |Esistono gia { lv_existing_records } righe per la selezione: saranno cancellate prima del ricalcolo.| ) ) TO reported-enafirr.
      ENDIF.

      DATA(lt_ena_firr) = /eacm/cl_ena_firr_query=>calculate_pdfs(
        iv_bukrs = <ls_key>-%param-CompanyCode
        iv_gjahr = <ls_key>-%param-FiscalYear
        iv_zcdaz = <ls_key>-%param-Zcdaz
        iv_ztpag = <ls_key>-%param-Ztpag
        iv_lifnr = <ls_key>-%param-Lifnr ).

      IF lt_ena_firr IS INITIAL.
        APPEND VALUE #(
          %cid = <ls_key>-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-warning
                   text     = |Nessun dato ENA/FIRR generato per la selezione.| ) ) TO reported-enafirr.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF /EACM/I_ENA_FIRR IN LOCAL MODE
        ENTITY EnaFirr
        CREATE
        FIELDS (
          CompanyCode
          FiscalYear
          AgentCode
          Supplier
          CompanyName
          CompanyCountry
          CompanyCity
          CompanyPostCode
          CompanyStreet
          CompanyHouseNumber
          CompanyRegion
          CompanyVatNumber
          TransactionCurrency
          AgentName
          AgentCountry
          AgentCity
          AgentPostCode
          AgentStreet
          AgentHouseNumber
          AgentRegion
          AgentVatNumber
          PaymentType
          EnasarcoScope
          FirrMaturedCommission
          FirrContribution
          HasFirrContribution
          FirrRate
          EnasarcoAgentContribution
          EnasarcoPaidAmount
          CessationDate
          IsCessationInYear
          ServiceDescription
          FileName
          MimeType
          Attachment )
        WITH VALUE #(
          FOR ls_ena_firr IN lt_ena_firr INDEX INTO lv_idx
          (
            %cid                        = |ENA_FIRR_{ ls_ena_firr-bukrs }_{ ls_ena_firr-gjahr }_{ lv_idx }|
            CompanyCode                 = ls_ena_firr-bukrs
            FiscalYear                  = ls_ena_firr-gjahr
            AgentCode                   = ls_ena_firr-zcdage
            Supplier                    = ls_ena_firr-lifnr
            CompanyName                 = ls_ena_firr-bukrs_name
            CompanyCountry              = ls_ena_firr-bukrs_country
            CompanyCity                 = ls_ena_firr-bukrs_city
            CompanyPostCode             = ls_ena_firr-bukrs_post_code
            CompanyStreet               = ls_ena_firr-bukrs_street
            CompanyHouseNumber          = ls_ena_firr-bukrs_house_num
            CompanyRegion               = ls_ena_firr-bukrs_region
            CompanyVatNumber            = ls_ena_firr-bukrs_piva
            TransactionCurrency         = ls_ena_firr-currency
            AgentName                   = ls_ena_firr-age_name
            AgentCountry                = ls_ena_firr-age_country
            AgentCity                   = ls_ena_firr-age_city
            AgentPostCode               = ls_ena_firr-age_post_code
            AgentStreet                 = ls_ena_firr-age_street
            AgentHouseNumber            = ls_ena_firr-age_house_num
            AgentRegion                 = ls_ena_firr-age_region
            AgentVatNumber              = ls_ena_firr-age_piva
            PaymentType                 = ls_ena_firr-paymenttype
            EnasarcoScope               = ls_ena_firr-enasarcoscope
            FirrMaturedCommission       = ls_ena_firr-firrmaturedcommission
            FirrContribution            = ls_ena_firr-firrcontribution
            HasFirrContribution         = ls_ena_firr-hasfirrcontribution
            FirrRate                    = ls_ena_firr-firrrate
            EnasarcoAgentContribution   = ls_ena_firr-enasarcoagentcontribution
            EnasarcoPaidAmount          = ls_ena_firr-enasarcopaidamount
            CessationDate               = ls_ena_firr-cessationdate
            IsCessationInYear           = ls_ena_firr-iscessationinyear
            ServiceDescription          = ls_ena_firr-servicedescription
            FileName                    = ls_ena_firr-filename
            MimeType                    = ls_ena_firr-mime_type
            Attachment                  = ls_ena_firr-attachment
          ) )
        MAPPED DATA(mapped_create)
        FAILED DATA(failed_create)
        REPORTED DATA(reported_create).

      reported-enafirr = VALUE #(
        BASE reported-enafirr
        ( LINES OF reported_create-enafirr ) ).

      IF failed_create-enafirr IS INITIAL.
        READ ENTITIES OF /EACM/I_ENA_FIRR IN LOCAL MODE
          ENTITY EnaFirr
          ALL FIELDS
          WITH CORRESPONDING #( mapped_create-enafirr )
          RESULT DATA(lt_created).

        result = VALUE #(
          BASE result
          FOR ls_created IN lt_created
          (
            %param = ls_created
          ) ).

        APPEND VALUE #(
          %cid = <ls_key>-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = |Calcolo ENA/FIRR completato: { lines( lt_ena_firr ) } righe PDF generate.| ) ) TO reported-enafirr.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_ena_firr DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_ena_firr IMPLEMENTATION.
  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    LOOP AT /eacm/bp_i_ena_firr=>gt_delete ASSIGNING FIELD-SYMBOL(<delete>).
      DELETE FROM /eacm/ena_firr
        WHERE bukrs = @<delete>-bukrs
          AND gjahr = @<delete>-gjahr
          AND ( @<delete>-zcdage IS INITIAL OR zcdage = @<delete>-zcdage )
          AND ( @<delete>-ztpag IS INITIAL OR paymenttype = @<delete>-ztpag )
          AND ( @<delete>-lifnr IS INITIAL OR lifnr = @<delete>-lifnr ).
    ENDLOOP.

    IF /eacm/bp_i_ena_firr=>gt_ena_firr IS NOT INITIAL.
      DATA(lt_ena_firr) = /eacm/bp_i_ena_firr=>gt_ena_firr.
      MODIFY /eacm/ena_firr FROM TABLE @lt_ena_firr.
    ENDIF.

    CLEAR:
      /eacm/bp_i_ena_firr=>gt_ena_firr,
      /eacm/bp_i_ena_firr=>gt_delete.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.
ENDCLASS.

