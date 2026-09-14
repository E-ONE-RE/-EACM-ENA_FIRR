CLASS /eacm/cl_ena_firr_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES tt_ena_firr TYPE STANDARD TABLE OF /eacm/ena_firr WITH EMPTY KEY.

    CLASS-METHODS calculate_and_store_pdfs
      IMPORTING iv_bukrs          TYPE bukrs
                iv_gjahr          TYPE gjahr
                iv_zcdaz          TYPE /eacm/zpren-zcdaz OPTIONAL
                iv_ztpag          TYPE /eacm/zpraa-ztpag OPTIONAL
                iv_lifnr          TYPE lifnr OPTIONAL
      RETURNING VALUE(rv_records) TYPE i.

    CLASS-METHODS calculate_pdfs
      IMPORTING iv_bukrs             TYPE bukrs
                iv_gjahr             TYPE gjahr
                iv_zcdaz             TYPE /eacm/zpren-zcdaz OPTIONAL
                iv_ztpag             TYPE /eacm/zpraa-ztpag OPTIONAL
                iv_lifnr             TYPE lifnr OPTIONAL
      RETURNING VALUE(rt_ena_firr)   TYPE tt_ena_firr.

  PRIVATE SECTION.
    TYPES:
      tt_agent_range   TYPE RANGE OF /eacm/zpren-zcdaz,
      tt_supplier_range TYPE RANGE OF /eacm/zpren-lifnr,
      tt_payment_range TYPE RANGE OF /eacm/zpraa-ztpag.

    TYPES:
  BEGIN OF ty_result,
    companycode                 TYPE bukrs,
    fiscalyear                  TYPE gjahr,
    agentcode                   TYPE c LENGTH 20,
    supplier                    TYPE lifnr,

    companyname                 TYPE c LENGTH 60,
    companycountry              TYPE land1,
    companycity                 TYPE /eacm/city,
    companypostcode             TYPE /eacm/post_code,
    companystreet               TYPE /eacm/street,
    companyhousenumber          TYPE /eacm/house_num,
    companyregion               TYPE regio,
    companyvatnumber            TYPE c LENGTH 20,

    transactioncurrency         TYPE waers,

    agentname                   TYPE c LENGTH 80,
    agentcountry                TYPE land1,
    agentcity                   TYPE /eacm/city,
    agentpostcode               TYPE /eacm/post_code,
    agentstreet                 TYPE /eacm/street,
    agenthousenumber            TYPE /eacm/house_num,
    agentregion                 TYPE regio,
    agentvatnumber              TYPE c LENGTH 20,

    paymenttype                 TYPE c LENGTH 10,
    enasarcoscope               TYPE c LENGTH 1,

    firrmaturedcommission       TYPE decfloat34,
    firrcontribution            TYPE decfloat34,
    hasfirrcontribution         TYPE c LENGTH 1,
    firrrate                    TYPE decfloat34,

    enasarcoagentcontribution   TYPE decfloat34,
    enasarcopaidamount          TYPE decfloat34,

    cessationdate               TYPE d,
    iscessationinyear           TYPE c LENGTH 1,
    servicedescription          TYPE c LENGTH 8,

    filename                    TYPE c LENGTH 100,
    mimetype                    TYPE c LENGTH 50,
    attachment                  TYPE xstring,
  END OF ty_result,

  tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    TYPES tt_component_names TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_work,
        companycode               TYPE bukrs,
        fiscalyear                TYPE gjahr,
        agentcode                 TYPE c LENGTH 20,
        supplier                  TYPE lifnr,
        transactioncurrency       TYPE waers,
        firrmaturedcommission     TYPE /eacm/zpmat,
        firrcontribution          TYPE /eacm/zpmat,
        firrrate                  TYPE /eacm/ztprc,
        enasarcoagentcontribution TYPE /eacm/zpmat,
        enasarcopaidamount        TYPE /eacm/zpmat,
      END OF ty_work,
      tt_work TYPE STANDARD TABLE OF ty_work WITH EMPTY KEY.

    CLASS-METHODS get_parameters
      IMPORTING io_request TYPE REF TO if_rap_query_request
      EXPORTING ev_bukrs   TYPE bukrs
                ev_gjahr   TYPE gjahr.

    CLASS-METHODS get_filter_ranges
      IMPORTING io_request        TYPE REF TO if_rap_query_request
      EXPORTING et_agent_range    TYPE tt_agent_range
                et_supplier_range TYPE tt_supplier_range
                et_payment_range  TYPE tt_payment_range.

    CLASS-METHODS build_data
      IMPORTING iv_bukrs          TYPE bukrs
                iv_gjahr          TYPE gjahr
                it_agent_range    TYPE tt_agent_range
                it_supplier_range TYPE tt_supplier_range
                it_payment_range  TYPE tt_payment_range
      RETURNING VALUE(rt_result)  TYPE tt_result.

    CLASS-METHODS add_firr_row
      IMPORTING is_row        TYPE ty_work
      CHANGING  ct_work       TYPE tt_work.

    CLASS-METHODS add_accrual_row
      IMPORTING is_row        TYPE ty_work
      CHANGING  ct_work       TYPE tt_work.

    CLASS-METHODS adjust_firr_for_quarterly
      CHANGING cs_firr TYPE /eacm/zprfirr.

    CLASS-METHODS apply_paging
      IMPORTING io_request       TYPE REF TO if_rap_query_request
                it_result        TYPE tt_result
      RETURNING VALUE(rt_result) TYPE tt_result.

    CLASS-METHODS is_attachment_requested
      IMPORTING io_request          TYPE REF TO if_rap_query_request
      RETURNING VALUE(rv_requested) TYPE abap_bool.

    CLASS-METHODS fill_pdf_attachment
      CHANGING ct_result TYPE tt_result.

    CLASS-METHODS persist_result
      IMPORTING it_result TYPE tt_result.

    CLASS-METHODS result_to_table
      IMPORTING it_result          TYPE tt_result
      RETURNING VALUE(rt_ena_firr) TYPE tt_ena_firr.

    CLASS-METHODS build_file_name
      IMPORTING is_result           TYPE ty_result
      RETURNING VALUE(rv_file_name) TYPE string.

    CLASS-METHODS build_form_xml
      IMPORTING is_result     TYPE ty_result
      RETURNING VALUE(rv_xml) TYPE xstring.

    CLASS-METHODS add_xml_element
      IMPORTING iv_name  TYPE string
                iv_value TYPE string
      CHANGING  cv_xml   TYPE string.

    CLASS-METHODS get_first_component_value
      IMPORTING is_data             TYPE any
                it_component_names  TYPE tt_component_names
      RETURNING VALUE(rv_value)     TYPE string.

    CLASS-METHODS render_pdf_for_row
      IMPORTING is_result     TYPE ty_result
      RETURNING VALUE(rv_pdf) TYPE xstring.

ENDCLASS.



CLASS /EACM/CL_ENA_FIRR_QUERY IMPLEMENTATION.


  METHOD persist_result.
    DATA(lt_ena_firr) = result_to_table( it_result ).

    CHECK lt_ena_firr IS NOT INITIAL.

    MODIFY /eacm/ena_firr FROM TABLE @lt_ena_firr.
  ENDMETHOD.


METHOD result_to_table.

  LOOP AT it_result ASSIGNING FIELD-SYMBOL(<ls_result>).

    APPEND VALUE #(
      client                      = sy-mandt
      bukrs                       = <ls_result>-companycode
      gjahr                       = <ls_result>-fiscalyear
      zcdage                      = <ls_result>-agentcode
      lifnr                       = <ls_result>-supplier

      bukrs_name                  = <ls_result>-companyname
      bukrs_country               = <ls_result>-companycountry
      bukrs_city                  = <ls_result>-companycity
      bukrs_post_code             = <ls_result>-companypostcode
      bukrs_street                = <ls_result>-companystreet
      bukrs_house_num             = <ls_result>-companyhousenumber
      bukrs_region                = <ls_result>-companyregion
      bukrs_piva                  = <ls_result>-companyvatnumber

      currency                    = <ls_result>-transactioncurrency

      age_name                    = <ls_result>-agentname
      age_country                 = <ls_result>-agentcountry
      age_city                    = <ls_result>-agentcity
      age_post_code               = <ls_result>-agentpostcode
      age_street                  = <ls_result>-agentstreet
      age_house_num               = <ls_result>-agenthousenumber
      age_region                  = <ls_result>-agentregion
      age_piva                    = <ls_result>-agentvatnumber

      paymenttype                 = <ls_result>-paymenttype
      enasarcoscope               = <ls_result>-enasarcoscope

      firrmaturedcommission       = <ls_result>-firrmaturedcommission
      firrcontribution            = <ls_result>-firrcontribution
      hasfirrcontribution         = <ls_result>-hasfirrcontribution
      firrrate                    = <ls_result>-firrrate
      enasarcoagentcontribution   = <ls_result>-enasarcoagentcontribution
      enasarcopaidamount          = <ls_result>-enasarcopaidamount

      cessationdate               = <ls_result>-cessationdate
      iscessationinyear           = <ls_result>-iscessationinyear
      servicedescription          = <ls_result>-servicedescription

      filename                    = <ls_result>-filename
      mime_type                   = <ls_result>-mimetype
      attachment                  = <ls_result>-attachment

    ) TO rt_ena_firr.

  ENDLOOP.

ENDMETHOD.


  METHOD if_rap_query_provider~select.
    DATA lv_bukrs TYPE bukrs.
    DATA lv_gjahr TYPE gjahr.
    DATA lt_agent_range TYPE tt_agent_range.
    DATA lt_supplier_range TYPE tt_supplier_range.
    DATA lt_payment_range TYPE tt_payment_range.

    get_parameters(
      EXPORTING io_request = io_request
      IMPORTING ev_bukrs   = lv_bukrs
                ev_gjahr   = lv_gjahr ).

    get_filter_ranges(
      EXPORTING io_request        = io_request
      IMPORTING et_agent_range    = lt_agent_range
                et_supplier_range = lt_supplier_range
                et_payment_range  = lt_payment_range ).

    DATA(lt_result) = build_data(
      iv_bukrs          = lv_bukrs
      iv_gjahr          = lv_gjahr
      it_agent_range    = lt_agent_range
      it_supplier_range = lt_supplier_range
      it_payment_range  = lt_payment_range ).

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      DATA(lt_page_result) = apply_paging(
        io_request = io_request
        it_result  = lt_result ).

      IF is_attachment_requested( io_request ).
        fill_pdf_attachment( CHANGING ct_result = lt_page_result ).
      ENDIF.

      io_response->set_data( lt_page_result ).
    ENDIF.
  ENDMETHOD.


  METHOD get_parameters.
    DATA(lt_parameters) = io_request->get_parameters( ).

    LOOP AT lt_parameters ASSIGNING FIELD-SYMBOL(<ls_parameter>).
      DATA(lv_parameter_name) = <ls_parameter>-parameter_name.
      TRANSLATE lv_parameter_name TO UPPER CASE.

      CASE lv_parameter_name.
        WHEN 'P_BUKRS'.
          ev_bukrs = <ls_parameter>-value.
        WHEN 'P_GJAHR'.
          ev_gjahr = <ls_parameter>-value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_filter_ranges.
    TRY.
        DATA(lt_filter_ranges) = io_request->get_filter( )->get_as_ranges( ).

        LOOP AT lt_filter_ranges ASSIGNING FIELD-SYMBOL(<ls_filter_range>).
          DATA(lv_name) = <ls_filter_range>-name.
          TRANSLATE lv_name TO UPPER CASE.

          CASE lv_name.
            WHEN 'AGENTCODE'.
              LOOP AT <ls_filter_range>-range ASSIGNING FIELD-SYMBOL(<ls_agent_range>).
                APPEND VALUE #( sign   = <ls_agent_range>-sign
                                option = <ls_agent_range>-option
                                low    = CONV #( <ls_agent_range>-low )
                                high   = CONV #( <ls_agent_range>-high ) ) TO et_agent_range.
              ENDLOOP.

            WHEN 'SUPPLIER'.
              LOOP AT <ls_filter_range>-range ASSIGNING FIELD-SYMBOL(<ls_supplier_range>).
                APPEND VALUE #( sign   = <ls_supplier_range>-sign
                                option = <ls_supplier_range>-option
                                low    = CONV #( <ls_supplier_range>-low )
                                high   = CONV #( <ls_supplier_range>-high ) ) TO et_supplier_range.
              ENDLOOP.

            WHEN 'PAYMENTTYPE'.
              LOOP AT <ls_filter_range>-range ASSIGNING FIELD-SYMBOL(<ls_payment_range>).
                APPEND VALUE #( sign   = <ls_payment_range>-sign
                                option = <ls_payment_range>-option
                                low    = CONV #( <ls_payment_range>-low )
                                high   = CONV #( <ls_payment_range>-high ) ) TO et_payment_range.
              ENDLOOP.
          ENDCASE.
        ENDLOOP.

      CATCH cx_rap_query_filter_no_range.
        CLEAR: et_agent_range, et_supplier_range, et_payment_range.
    ENDTRY.
  ENDMETHOD.


  METHOD build_data.
    DATA lt_work TYPE tt_work.
    DATA lt_agent_types TYPE STANDARD TABLE OF /eacm/zpr03.

    SELECT SINGLE *
      FROM /eacm/t001
      WHERE bukrs = @iv_bukrs
      INTO @DATA(ls_company).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT *
      FROM /eacm/zpraa
      WHERE zstre <> 'A'
        AND zstre <> 'S'
      INTO TABLE @DATA(lt_agents).

    IF lt_agents IS NOT INITIAL.
      SELECT *
        FROM /eacm/zpr03
        FOR ALL ENTRIES IN @lt_agents
        WHERE ztsoc = @lt_agents-ztsoc
        INTO TABLE @lt_agent_types.
    ENDIF.

    SELECT *
      FROM /eacm/zprfirr
      WHERE bukrs = @iv_bukrs
        AND gjahr = @iv_gjahr
      INTO TABLE @DATA(lt_firr).

    LOOP AT lt_firr ASSIGNING FIELD-SYMBOL(<ls_firr>).
      IF it_agent_range IS NOT INITIAL AND <ls_firr>-zcdaz NOT IN it_agent_range.
        CONTINUE.
      ENDIF.

      IF it_supplier_range IS NOT INITIAL AND <ls_firr>-lifnr NOT IN it_supplier_range.
        CONTINUE.
      ENDIF.

      adjust_firr_for_quarterly( CHANGING cs_firr = <ls_firr> ).

      DATA(lv_firr_currency) = CONV waers( <ls_firr>-waerk ).

      add_firr_row(
        EXPORTING
          is_row = VALUE ty_work(
            companycode               = <ls_firr>-bukrs
            fiscalyear                = <ls_firr>-gjahr
            agentcode                 = <ls_firr>-zcdaz
            supplier                  = <ls_firr>-lifnr
            transactioncurrency       = lv_firr_currency
            firrmaturedcommission     =  <ls_firr>-zfpmat
            firrcontribution          =  <ls_firr>-zfbuto
            firrrate                  =  <ls_firr>-ztprc )
        CHANGING
          ct_work = lt_work ).
    ENDLOOP.

    SELECT *
      FROM /eacm/zpren
      WHERE bukrs = @iv_bukrs
        AND gjahr = @iv_gjahr
      INTO TABLE @DATA(lt_enasarco).

    LOOP AT lt_enasarco ASSIGNING FIELD-SYMBOL(<ls_enasarco>).
      IF it_supplier_range IS NOT INITIAL AND <ls_enasarco>-lifnr NOT IN it_supplier_range.
        CONTINUE.
      ENDIF.

      DATA(lv_enasarco) =
        CONV decfloat34( <ls_enasarco>-zecag1 ) +
        CONV decfloat34( <ls_enasarco>-zecag2 ) +
        CONV decfloat34( <ls_enasarco>-zecag3 ) +
        CONV decfloat34( <ls_enasarco>-zecag4 ).

      DATA(lv_paid) =
        CONV decfloat34( <ls_enasarco>-zeccd1 ) +
        CONV decfloat34( <ls_enasarco>-zeccd2 ) +
        CONV decfloat34( <ls_enasarco>-zeccd3 ) +
        CONV decfloat34( <ls_enasarco>-zeccd4 ).

      DATA(lv_found) = abap_false.

      LOOP AT lt_work ASSIGNING FIELD-SYMBOL(<ls_work_match>)
        WHERE companycode = <ls_enasarco>-bukrs
          AND fiscalyear  = <ls_enasarco>-gjahr
          AND supplier    = <ls_enasarco>-lifnr.

        <ls_work_match>-enasarcoagentcontribution = lv_enasarco.
        <ls_work_match>-enasarcopaidamount = lv_paid.
        lv_found = abap_true.
      ENDLOOP.

      IF lv_found = abap_false.
        DATA(lv_agentcode) = CONV /eacm/zpren-zcdaz( <ls_enasarco>-zcdaz ).
        DATA(lv_ena_currency) = CONV waers( <ls_enasarco>-zwaer ).

        READ TABLE lt_agents INTO DATA(ls_agent_by_supplier)
          WITH KEY lifnr = <ls_enasarco>-lifnr.
        IF sy-subrc = 0.
          lv_agentcode = ls_agent_by_supplier-zcdaz.
        ENDIF.

        IF lv_agentcode IS INITIAL.
          READ TABLE lt_agents INTO DATA(ls_agent_by_previous)
            WITH KEY zcodpre = <ls_enasarco>-lifnr.
          IF sy-subrc = 0.
            lv_agentcode = ls_agent_by_previous-zcdaz.
          ENDIF.
        ENDIF.

        APPEND VALUE ty_work(
          companycode               = <ls_enasarco>-bukrs
          fiscalyear                = <ls_enasarco>-gjahr
          agentcode                 = lv_agentcode
          supplier                  = <ls_enasarco>-lifnr
          transactioncurrency       = lv_ena_currency
          enasarcoagentcontribution = lv_enasarco
          enasarcopaidamount        = lv_paid ) TO lt_work.
      ENDIF.
    ENDLOOP.

    DELETE lt_work WHERE firrcontribution = 0
                     AND enasarcoagentcontribution = 0.

    DATA(lt_before_accrual) = lt_work.
    CLEAR lt_work.

    LOOP AT lt_before_accrual INTO DATA(ls_before_accrual).
      DATA(ls_accrual) = ls_before_accrual.
      CLEAR: ls_accrual-supplier,
             ls_accrual-firrrate.

      add_accrual_row(
        EXPORTING is_row  = ls_accrual
        CHANGING  ct_work = lt_work ).
    ENDLOOP.

    LOOP AT lt_work ASSIGNING FIELD-SYMBOL(<ls_after_accrual>).
      READ TABLE lt_before_accrual INTO ls_before_accrual
        WITH KEY agentcode = <ls_after_accrual>-agentcode.
      IF sy-subrc = 0.
        <ls_after_accrual>-supplier = ls_before_accrual-supplier.
      ENDIF.
    ENDLOOP.

    SORT lt_work BY supplier agentcode.

DATA ls_work   TYPE ty_work.
DATA ls_result TYPE ty_result.

LOOP AT lt_work INTO ls_work.

  CLEAR ls_result.

  ls_result-companycode               = ls_work-companycode.
  ls_result-fiscalyear                = ls_work-fiscalyear.
  ls_result-agentcode                 = ls_work-agentcode.
  ls_result-supplier                  = ls_work-supplier.
  ls_result-companyname               = ls_company-butxt.
  ls_result-companycountry            = ls_company-land1.
  ls_result-companycity               = get_first_component_value(
    is_data            = ls_company
    it_component_names = VALUE #(
      ( `CITY` ) ( `CITY1` ) ( `CITY_NAME` ) ( `ORT01` ) ) ).
  ls_result-companypostcode           = get_first_component_value(
    is_data            = ls_company
    it_component_names = VALUE #(
      ( `POST_CODE` ) ( `POST_CODE1` ) ( `POSTAL_CODE` ) ( `PSTLZ` ) ) ).
  ls_result-companystreet             = get_first_component_value(
    is_data            = ls_company
    it_component_names = VALUE #(
      ( `STREET` ) ( `STREET_NAME` ) ( `STRAS` ) ) ).
  ls_result-companyhousenumber        = get_first_component_value(
    is_data            = ls_company
    it_component_names = VALUE #(
      ( `HOUSE_NUM` ) ( `HOUSE_NUM1` ) ( `HOUSE_NUMBER` ) ) ).
  ls_result-companyregion             = get_first_component_value(
    is_data            = ls_company
    it_component_names = VALUE #(
      ( `REGION` ) ( `REGIO` ) ) ).
  ls_result-companyvatnumber          = get_first_component_value(
    is_data            = ls_company
    it_component_names = VALUE #(
      ( `VAT_NUMBER` ) ( `STCEG` ) ( `STCD1` ) ( `TAXNUMBER` ) ( `TAX_NUM` ) ) ).
  ls_result-transactioncurrency       = ls_work-transactioncurrency.
  ls_result-firrmaturedcommission     = ls_work-firrmaturedcommission.
  ls_result-firrcontribution          = ls_work-firrcontribution.
  ls_result-firrrate                  = ls_work-firrrate.
  ls_result-enasarcoagentcontribution = ls_work-enasarcoagentcontribution.
  ls_result-enasarcopaidamount        = ls_work-enasarcopaidamount.

      SELECT SINGLE *
        FROM /eacm/bp_cache
        WHERE business_partner = @ls_work-supplier
        INTO @DATA(ls_vendor).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      READ TABLE lt_agents INTO DATA(ls_agent)
        WITH KEY zcdaz = ls_work-agentcode.

      IF sy-subrc = 0.
        ls_result-agentname = ls_agent-name1.
        ls_result-paymenttype = ls_agent-ztpag.

        READ TABLE lt_agent_types INTO DATA(ls_agent_type)
          WITH KEY ztsoc = ls_agent-ztsoc.
        IF sy-subrc = 0.
          ls_result-enasarcoscope = ls_agent_type-zscap.
        ENDIF.
      ELSE.
        ls_result-agentname = ls_vendor-first_name.
      ENDIF.

      IF ls_result-agentname IS INITIAL.
        ls_result-agentname = get_first_component_value(
          is_data            = ls_vendor
          it_component_names = VALUE #(
            ( `NAME1` ) ( `FULL_NAME` ) ( `BUSINESS_PARTNER_NAME` ) ( `ORGANIZATION_NAME` ) ) ).
      ENDIF.

      ls_result-agentcountry     = ls_vendor-land1.
      ls_result-agentcity        = get_first_component_value(
        is_data            = ls_vendor
        it_component_names = VALUE #(
          ( `CITY` ) ( `CITY1` ) ( `CITY_NAME` ) ( `ORT01` ) ) ).
      ls_result-agentpostcode    = get_first_component_value(
        is_data            = ls_vendor
        it_component_names = VALUE #(
          ( `POST_CODE` ) ( `POST_CODE1` ) ( `POSTAL_CODE` ) ( `PSTLZ` ) ) ).
      ls_result-agentstreet      = get_first_component_value(
        is_data            = ls_vendor
        it_component_names = VALUE #(
          ( `STREET` ) ( `STREET_NAME` ) ( `STRAS` ) ) ).
      ls_result-agenthousenumber = get_first_component_value(
        is_data            = ls_vendor
        it_component_names = VALUE #(
          ( `HOUSE_NUM` ) ( `HOUSE_NUM1` ) ( `HOUSE_NUMBER` ) ) ).
      ls_result-agentregion      = get_first_component_value(
        is_data            = ls_vendor
        it_component_names = VALUE #(
          ( `REGION` ) ( `REGIO` ) ) ).
      ls_result-agentvatnumber   = get_first_component_value(
        is_data            = ls_vendor
        it_component_names = VALUE #(
          ( `STCD1` ) ( `VAT_NUMBER` ) ( `TAXNUMBER` ) ( `TAX_NUM` ) ) ).

      SELECT SINGLE zdtfr
        FROM /eacm/zpr35
        WHERE bukrs = @ls_work-companycode
          AND zcdaz = @ls_work-agentcode
        INTO @ls_result-cessationdate.

      IF ls_result-cessationdate IS NOT INITIAL
         AND ls_result-cessationdate+0(4) <= iv_gjahr.
        CLEAR ls_result-firrcontribution.
        ls_result-iscessationinyear = 'X'.
      ELSE.
        ls_result-iscessationinyear = ' '.
      ENDIF.

      IF ls_result-firrcontribution IS INITIAL.
        ls_result-hasfirrcontribution = ' '.
      ELSE.
        ls_result-hasfirrcontribution = 'X'.
      ENDIF.

      IF ls_result-enasarcoscope = 'X'.
        ls_result-servicedescription = 'SERVICE'.
      ELSE.
        ls_result-servicedescription = 'SECURITY'.
      ENDIF.

      ls_result-filename = build_file_name( ls_result ).
      ls_result-mimetype = 'application/pdf'.

      IF ls_result-firrcontribution = 0
         AND ls_result-enasarcoagentcontribution = 0.
        CONTINUE.
      ENDIF.

      IF it_agent_range IS NOT INITIAL AND ls_result-agentcode NOT IN it_agent_range.
        CONTINUE.
      ENDIF.

      IF it_payment_range IS NOT INITIAL AND ls_result-paymenttype NOT IN it_payment_range.
        CONTINUE.
      ENDIF.

      APPEND ls_result TO rt_result.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_firr_row.
    READ TABLE ct_work ASSIGNING FIELD-SYMBOL(<ls_work>)
      WITH KEY companycode         = is_row-companycode
               fiscalyear          = is_row-fiscalyear
               agentcode           = is_row-agentcode
               supplier            = is_row-supplier
               transactioncurrency = is_row-transactioncurrency.

    IF sy-subrc = 0.
      <ls_work>-firrmaturedcommission += is_row-firrmaturedcommission.
      <ls_work>-firrcontribution += is_row-firrcontribution.

      IF <ls_work>-firrrate IS INITIAL.
        <ls_work>-firrrate = is_row-firrrate.
      ENDIF.
    ELSE.
      APPEND is_row TO ct_work.
    ENDIF.
  ENDMETHOD.


  METHOD add_accrual_row.
    READ TABLE ct_work ASSIGNING FIELD-SYMBOL(<ls_work>)
      WITH KEY companycode         = is_row-companycode
               fiscalyear          = is_row-fiscalyear
               agentcode           = is_row-agentcode
               transactioncurrency = is_row-transactioncurrency.

    IF sy-subrc = 0.
      <ls_work>-firrmaturedcommission += is_row-firrmaturedcommission.
      <ls_work>-firrcontribution += is_row-firrcontribution.
      <ls_work>-enasarcoagentcontribution += is_row-enasarcoagentcontribution.
      <ls_work>-enasarcopaidamount += is_row-enasarcopaidamount.
    ELSE.
      APPEND is_row TO ct_work.
    ENDIF.
  ENDMETHOD.


  METHOD adjust_firr_for_quarterly.
    DATA lv_trim TYPE i.
    DATA lv_last_trim TYPE i.

    FIELD-SYMBOLS <lv_rate> TYPE any.
    FIELD-SYMBOLS <lv_matured> TYPE any.
    FIELD-SYMBOLS <lv_contribution> TYPE any.

    CHECK cs_firr-ztprc <> 'S'.

    DO 4 TIMES.
      lv_trim = sy-index.
      ASSIGN COMPONENT |ZTPRC_{ lv_trim }| OF STRUCTURE cs_firr TO <lv_rate>.
      IF sy-subrc = 0 AND <lv_rate> = 'S'.
        cs_firr-ztprc = <lv_rate>.
        lv_last_trim = lv_trim.
      ENDIF.
    ENDDO.

    CHECK cs_firr-ztprc = 'S'.

    CLEAR: cs_firr-zfpmat,
           cs_firr-zfbuto.

    DO lv_last_trim TIMES.
      lv_trim = sy-index.

      ASSIGN COMPONENT |ZFPMAT_{ lv_trim }| OF STRUCTURE cs_firr TO <lv_matured>.
      IF sy-subrc = 0.
        cs_firr-zfpmat = cs_firr-zfpmat + CONV /eacm/zprfirr-zfpmat( <lv_matured> ).
      ENDIF.

      ASSIGN COMPONENT |ZFBUTO_{ lv_trim }| OF STRUCTURE cs_firr TO <lv_contribution>.
      IF sy-subrc = 0.
        cs_firr-zfbuto = cs_firr-zfbuto + CONV /eacm/zprfirr-zfbuto( <lv_contribution> ).
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD apply_paging.
    DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).
    DATA(lv_offset) = io_request->get_paging( )->get_offset( ).

    IF lv_page_size < 0.
      lv_page_size = lines( it_result ).
    ENDIF.

    DATA(lv_from) = CONV i( lv_offset ) + 1.
    DATA(lv_to) = CONV i( lv_offset + lv_page_size ).

    LOOP AT it_result INTO DATA(ls_result) FROM lv_from TO lv_to.
      APPEND ls_result TO rt_result.
    ENDLOOP.
  ENDMETHOD.


  METHOD is_attachment_requested.
    DATA(lt_requested_elements) = io_request->get_requested_elements( ).

    LOOP AT lt_requested_elements INTO DATA(lv_requested_element).
      TRANSLATE lv_requested_element TO UPPER CASE.
      IF lv_requested_element = 'ATTACHMENT'.
        rv_requested = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD fill_pdf_attachment.
    LOOP AT ct_result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-attachment = render_pdf_for_row( <ls_result> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD get_first_component_value.
    FIELD-SYMBOLS <ls_data> TYPE any.
    FIELD-SYMBOLS <lv_value> TYPE any.

    ASSIGN is_data TO <ls_data>.
    CHECK <ls_data> IS ASSIGNED.

    LOOP AT it_component_names INTO DATA(lv_component_name).
      ASSIGN COMPONENT lv_component_name OF STRUCTURE <ls_data> TO <lv_value>.
      IF sy-subrc = 0
         AND <lv_value> IS ASSIGNED
         AND <lv_value> IS NOT INITIAL.
        rv_value = |{ <lv_value> }|.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_xml_element.
    cv_xml &&= |<{ iv_name }>{ escape( val = iv_value format = cl_abap_format=>e_xml_text ) }</{ iv_name }>|.
  ENDMETHOD.


  METHOD build_file_name.
    rv_file_name = |certificazione_{ is_result-companycode }_{ is_result-fiscalyear }_{ is_result-agentcode }_{ is_result-supplier }.pdf|.
*    REPLACE ALL OCCURRENCES OF space IN rv_file_name WITH `_`.
  ENDMETHOD.


METHOD calculate_pdfs.

  DATA lr_zcdaz TYPE tt_agent_range.
  DATA lr_ztpag TYPE tt_payment_range.
  DATA lr_lifnr TYPE tt_supplier_range.

  IF iv_zcdaz IS NOT INITIAL.
    lr_zcdaz = VALUE #(
      (
        sign   = 'I'
        option = 'EQ'
        low    = iv_zcdaz
      )
    ).
  ENDIF.

  IF iv_ztpag IS NOT INITIAL.
    lr_ztpag = VALUE #(
      (
        sign   = 'I'
        option = 'EQ'
        low    = iv_ztpag
      )
    ).
  ENDIF.

  IF iv_lifnr IS NOT INITIAL.
    lr_lifnr = VALUE #(
      (
        sign   = 'I'
        option = 'EQ'
        low    = iv_lifnr
      )
    ).
  ENDIF.

  DATA(lt_result) = build_data(
    iv_bukrs          = iv_bukrs
    iv_gjahr          = iv_gjahr
    it_agent_range    = lr_zcdaz
    it_supplier_range = lr_lifnr
    it_payment_range  = lr_ztpag
  ).

  CHECK lt_result IS NOT INITIAL.

  fill_pdf_attachment(
    CHANGING
      ct_result = lt_result
  ).

  rt_ena_firr = result_to_table(
    lt_result
  ).

ENDMETHOD.


METHOD build_form_xml.

  DATA(lv_xml) =
    |<?xml version="1.0" encoding="utf-8"?>|
    && |<Form version="2">|
    && |<xEACMxC_ENA_FIRR>|.

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyCode'
      iv_value = CONV string( is_result-companycode )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'FiscalYear'
      iv_value = CONV string( is_result-fiscalyear )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentCode'
      iv_value = CONV string( is_result-agentcode )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'Supplier'
      iv_value = CONV string( is_result-supplier )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyName'
      iv_value = CONV string( is_result-companyname )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyCountry'
      iv_value = CONV string( is_result-companycountry )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyCity'
      iv_value = CONV string( is_result-companycity )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyPostCode'
      iv_value = CONV string( is_result-companypostcode )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyStreet'
      iv_value = CONV string( is_result-companystreet )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyHouseNumber'
      iv_value = CONV string( is_result-companyhousenumber )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyRegion'
      iv_value = CONV string( is_result-companyregion )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CompanyVatNumber'
      iv_value = CONV string( is_result-companyvatnumber )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'TransactionCurrency'
      iv_value = CONV string( is_result-transactioncurrency )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentName'
      iv_value = CONV string( is_result-agentname )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentCountry'
      iv_value = CONV string( is_result-agentcountry )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentCity'
      iv_value = CONV string( is_result-agentcity )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentPostCode'
      iv_value = CONV string( is_result-agentpostcode )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentStreet'
      iv_value = CONV string( is_result-agentstreet )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentHouseNumber'
      iv_value = CONV string( is_result-agenthousenumber )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentRegion'
      iv_value = CONV string( is_result-agentregion )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'AgentVatNumber'
      iv_value = CONV string( is_result-agentvatnumber )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'PaymentType'
      iv_value = CONV string( is_result-paymenttype )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'EnasarcoScope'
      iv_value = CONV string( is_result-enasarcoscope )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'FirrMaturedCommission'
      iv_value = CONV string( is_result-firrmaturedcommission )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'FirrContribution'
      iv_value = CONV string( is_result-firrcontribution )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'HasFirrContribution'
      iv_value = CONV string( is_result-hasfirrcontribution )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'FirrRate'
      iv_value = CONV string( is_result-firrrate )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'EnasarcoAgentContribution'
      iv_value = CONV string( is_result-enasarcoagentcontribution )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'EnasarcoPaidAmount'
      iv_value = CONV string( is_result-enasarcopaidamount )
    CHANGING
      cv_xml   = lv_xml ).

  DATA(lv_cessation_date) = CONV string( is_result-cessationdate ).

  add_xml_element(
    EXPORTING
      iv_name  = 'CessationDate'
      iv_value = lv_cessation_date
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'IsCessationInYear'
      iv_value = CONV string( is_result-iscessationinyear )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'ServiceDescription'
      iv_value = CONV string( is_result-servicedescription )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'FileName'
      iv_value = CONV string( is_result-filename )
    CHANGING
      cv_xml   = lv_xml ).

  add_xml_element(
    EXPORTING
      iv_name  = 'MimeType'
      iv_value = CONV string( is_result-mimetype )
    CHANGING
      cv_xml   = lv_xml ).

  lv_xml &&=
      |</xEACMxC_ENA_FIRR>|
    && |</Form>|.

  rv_xml =
    cl_abap_conv_codepage=>create_out( )->convert(
      source = lv_xml ).

ENDMETHOD.


 METHOD render_pdf_for_row.

  CONSTANTS lc_form_name TYPE fpname
    VALUE '/EACM/ENA_FIRR_PDF'.

  CONSTANTS lc_locale TYPE string
    VALUE 'it_IT'.

  TRY.

      DATA(lo_form_reader) =
        cl_fp_form_reader=>create_form_reader(
          lc_form_name ).

      DATA(lv_xml_data) =
        build_form_xml(
          is_result ).

      DATA(lv_xml_string) =
        cl_abap_conv_codepage=>create_in( )->convert(
          lv_xml_data ).

      cl_fp_ads_util=>render_pdf(
        EXPORTING
          iv_xml_data   = lv_xml_data
          iv_xdp_layout = lo_form_reader->get_layout( )
          iv_locale     = lc_locale
          is_options    = VALUE #(
            trace_level = 4
            embed_fonts = lo_form_reader->get_font_embed( )
          )
        IMPORTING
          ev_pdf          = rv_pdf
          ev_trace_string = DATA(lv_ads_trace) ).

    CATCH cx_root INTO DATA(lx_error).

      DATA(lv_error_text) = lx_error->get_text( ).

      " Per il debug, metti il breakpoint dall'editor sulla chiamata
      " cl_fp_ads_util=>render_pdf sopra.
      CLEAR rv_pdf.

  ENDTRY.

ENDMETHOD.


  METHOD calculate_and_store_pdfs.
    DELETE FROM /eacm/ena_firr
      WHERE bukrs = @iv_bukrs
        AND gjahr = @iv_gjahr
        AND ( @iv_zcdaz IS INITIAL OR zcdage = @iv_zcdaz )
        AND ( @iv_ztpag IS INITIAL OR paymenttype = @iv_ztpag )
        AND ( @iv_lifnr IS INITIAL OR lifnr = @iv_lifnr ).

    DATA(lt_ena_firr) = calculate_pdfs(
      iv_bukrs = iv_bukrs
      iv_gjahr = iv_gjahr
      iv_zcdaz = iv_zcdaz
      iv_ztpag = iv_ztpag
      iv_lifnr = iv_lifnr ).

    CHECK lt_ena_firr IS NOT INITIAL.

    MODIFY /eacm/ena_firr FROM TABLE @lt_ena_firr.

    rv_records = lines( lt_ena_firr ).
  ENDMETHOD.
ENDCLASS.

