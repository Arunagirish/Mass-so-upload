CLASS lhc_xlhead DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR xlhead RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE xlhead.

    METHODS uploadexceldata FOR MODIFY
      IMPORTING keys FOR ACTION xlhead~uploadexceldata RESULT result.

    METHODS fillfilestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR xlhead~fillfilestatus.

    METHODS fillselectedstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR xlhead~fillselectedstatus.

ENDCLASS.

CLASS lhc_xlhead IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Implement the logic for instance authorizations here
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_entities>).
      APPEND CORRESPONDING #( <lfs_entities> ) TO mapped-xlhead
          ASSIGNING FIELD-SYMBOL(<lfs_xlhead>).
      <lfs_xlhead>-enduser = lv_user.
      IF <lfs_xlhead>-fileid IS INITIAL.
        TRY.
            <lfs_xlhead>-fileid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
            " Do nothing, proceed to other entry
        ENDTRY.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD uploadexceldata.
    DATA: lt_rows         TYPE STANDARD TABLE OF string,
          lv_content      TYPE string,
          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
          lo_struct_descr TYPE REF TO cl_abap_structdescr,
          lt_excel        TYPE STANDARD TABLE OF zsales_cl_bp_xl_user=>gty_gr_xl,
          lt_data         TYPE TABLE FOR CREATE zsales_i_xl_user\_xldata,
          lv_index        TYPE sy-index.

    FIELD-SYMBOLS: <lfs_col_header> TYPE string.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    READ ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_file_entity).

    DATA(lv_attachment) = lt_file_entity[ 1 ]-attachment.
    CHECK lv_attachment IS NOT INITIAL.

    " Move Excel Data to Internal Table
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
        iv_file_content = lv_attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
    DATA(lo_execute) = lo_worksheet->select(
        lo_selection_pattern )->row_stream( )->operation->write_to(
            REF #( lt_excel ) ).
    lo_execute->set_value_transformation(
        xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).

    " Get number of columns in upload file for validation
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        " Implement error handling
    ENDTRY.

    " Validate Header record
    DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
    IF ls_excel IS NOT INITIAL.
      DO lv_no_of_cols TIMES.
        lv_index = sy-index.
        ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
        CHECK <lfs_col_header> IS ASSIGNED.
        DATA(lv_value) = to_upper( <lfs_col_header> ).
        DATA(lv_has_error) = abap_false.
        CASE lv_index.
          WHEN 1.
            lv_has_error = COND #( WHEN lv_value <> 'SALES ORDER' THEN abap_true ELSE lv_has_error ).
          WHEN 2.
            lv_has_error = COND #( WHEN lv_value <> 'SALES ITEM' THEN abap_true ELSE lv_has_error ).
          WHEN 3.
            lv_has_error = COND #( WHEN lv_value <> 'ORDER QUANTITY' THEN abap_true ELSE lv_has_error ).
          WHEN 4.
            lv_has_error = COND #( WHEN lv_value <> 'PRODUCT' THEN abap_true ELSE lv_has_error ).
          WHEN 5.
            lv_has_error = COND #( WHEN lv_value <> 'REQUESTED QUANTITY' THEN abap_true ELSE lv_has_error ).
          WHEN 6.
            lv_has_error = COND #( WHEN lv_value <> 'PLANT' THEN abap_true ELSE lv_has_error ).
          WHEN 7.
            lv_has_error = COND #( WHEN lv_value <> 'SALES ORDER TYPE'  THEN abap_true ELSE lv_has_error ).
          WHEN 8.
            lv_has_error = COND #( WHEN lv_value <> 'SALES ORGANIZATION'  THEN abap_true ELSE lv_has_error ).
          WHEN 9.
            lv_has_error = COND #( WHEN lv_value <> 'DISTRIBUTION CHANNEL'  THEN abap_true ELSE lv_has_error ).
          WHEN 10.
            lv_has_error = COND #( WHEN lv_value <> 'ORGANIZATION DIVISION'  THEN abap_true ELSE lv_has_error ).
          WHEN 11.
            lv_has_error = COND #( WHEN lv_value <> 'SOLD TO PARTY'  THEN abap_true ELSE lv_has_error ).
          WHEN 12.
            lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
        ENDCASE.
        IF lv_has_error = abap_true.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky ) TO failed-xlhead.
          APPEND VALUE #(
            %tky = lt_file_entity[ 1 ]-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Wrong File Format!!' )
          ) TO reported-xlhead.
          UNASSIGN <lfs_col_header>.
          EXIT.
        ENDIF.
        UNASSIGN <lfs_col_header>.
      ENDDO.
    ENDIF.
    CHECK lv_has_error = abap_false.

    DELETE lt_excel INDEX 1.
*    DELETE lt_excel WHERE po_number IS INITIAL.

    " Fill Line ID / Line Number
    TRY.
        DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.
    LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<lfs_excel>).
      <lfs_excel>-line_id     = lv_line_id.
      <lfs_excel>-line_number = sy-tabix.
    ENDLOOP.

    " Prepare Data for Child Entity (XLData)
    lt_data = VALUE #(
        (   %cid_ref  = keys[ 1 ]-%cid_ref
            %is_draft = keys[ 1 ]-%is_draft
            enduser   = keys[ 1 ]-enduser
            fileid    = keys[ 1 ]-fileid
            %target   = VALUE #(
                FOR lwa_excel IN lt_excel (
                    "%cid        = |{ lwa_excel-po_number }_{ lwa_excel-po_item }|
                    %cid         = keys[ 1 ]-%cid_ref
                    %is_draft   = keys[ 1 ]-%is_draft
                    %data = VALUE #(
                        enduser                 = keys[ 1 ]-enduser
                        fileid                  = keys[ 1 ]-fileid
                        lineid                  = lwa_excel-line_id
                        linenumber              = lwa_excel-line_number
                        salesorder              = lwa_excel-sales_order
                        salesitem               = lwa_excel-sales_item
                        orderquantity           = lwa_excel-order_quantity
                        product                 = lwa_excel-product
                        requestedquantity       = lwa_excel-requestedquantity
                        plant                   = lwa_excel-plant
                        salesordertype          = lwa_excel-sales_order_type
                        salesorganization       = lwa_excel-sales_organization
                        distributionchannel     = lwa_excel-distribution_channel
                        organizationdivision    = lwa_excel-organization_division
                        soldtoparty             = lwa_excel-sold_to_party
                        headertext              = lwa_excel-header_text
                    )
                    %control = VALUE #(
                        enduser               = if_abap_behv=>mk-on
                        fileid                = if_abap_behv=>mk-on
                        lineid                = if_abap_behv=>mk-on
                        linenumber            = if_abap_behv=>mk-on
                        salesorder            = if_abap_behv=>mk-on
                         salesitem            = if_abap_behv=>mk-on
                         orderquantity        = if_abap_behv=>mk-on
                         product              = if_abap_behv=>mk-on
                         requestedquantity    = if_abap_behv=>mk-on
                         plant                = if_abap_behv=>mk-on
                         salesordertype       = if_abap_behv=>mk-on
                         salesorganization    = if_abap_behv=>mk-on
                         distributionchannel  = if_abap_behv=>mk-on
                         organizationdivision = if_abap_behv=>mk-on
                         soldtoparty          = if_abap_behv=>mk-on
                         headertext           = if_abap_behv=>mk-on

                    )
                )
            )
        )
    ).

    " Delete Existing entry for user if any
    READ ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead BY \_xldata
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_xldata).
    IF lt_existing_xldata IS NOT INITIAL.
      MODIFY ENTITIES OF zsales_i_xl_user IN LOCAL MODE
        ENTITY xldata DELETE FROM VALUE #(
          FOR lwa_data IN lt_existing_xldata (
            %key        = lwa_data-%key
            %is_draft   = lwa_data-%is_draft
          )
        )
        MAPPED DATA(lt_del_mapped)
        REPORTED DATA(lt_del_reported)
        FAILED DATA(lt_del_failed).
    ENDIF.

    " Add New Entry for XLData (association)
    MODIFY ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead CREATE BY \_xldata
      AUTO FILL CID WITH lt_data.

    " Modify Status
    MODIFY ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead
      UPDATE FROM VALUE #(  (
          %tky        = lt_file_entity[ 1 ]-%tky
          filestatus  = 'File Uploaded'
          %control-filestatus = if_abap_behv=>mk-on ) )
      MAPPED DATA(lt_upd_mapped)
      FAILED DATA(lt_upd_failed)
      REPORTED DATA(lt_upd_reported).

    " Read Updated Entry
    READ ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_xlhead).

    " Send Status back to front end
    result = VALUE #(
      FOR lwa_upd_head IN lt_updated_xlhead (
        %tky    = lwa_upd_head-%tky
        %param  = lwa_upd_head
      )
    ).
  ENDMETHOD.

  METHOD fillfilestatus.
    " Read the data to be modified
    READ ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead FIELDS ( enduser filestatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_user).

    " Update File Status
    LOOP AT lt_user INTO DATA(ls_user).
      MODIFY ENTITIES OF zsales_i_xl_user IN LOCAL MODE
        ENTITY xlhead
        UPDATE FIELDS ( filestatus )
        WITH VALUE #( (
            %tky                  = ls_user-%tky
            %data-filestatus      = 'File Not Selected'
            %control-filestatus   = if_abap_behv=>mk-on
          ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD fillselectedstatus.
    " Delete XLDATA Existing (if any)
    READ ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead BY \_xldata
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_xldata).

    IF lt_existing_xldata IS NOT INITIAL.
      MODIFY ENTITIES OF zsales_i_xl_user IN LOCAL MODE
        ENTITY xldata DELETE FROM VALUE #(
          FOR lwa_data IN lt_existing_xldata (
            %key        = lwa_data-%key
            %is_draft   = lwa_data-%is_draft ) ).
    ENDIF.

    " Read XL_Head Entities and change file status
    READ ENTITIES OF zsales_i_xl_user IN LOCAL MODE
      ENTITY xlhead ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_xlhead).

    " Update File Status
    LOOP AT lt_xlhead INTO DATA(ls_xlhead).
      MODIFY ENTITIES OF zsales_i_xl_user IN LOCAL MODE
        ENTITY xlhead
        UPDATE FIELDS ( filestatus )
        WITH VALUE #( (
            %tky                  = ls_xlhead-%tky
            %data-filestatus      = COND #(
                                      WHEN ls_xlhead-attachment IS INITIAL
                                      THEN 'File Not Selected'
                                      ELSE 'File Selected' )
            %control-filestatus   = if_abap_behv=>mk-on
          ) ).
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
