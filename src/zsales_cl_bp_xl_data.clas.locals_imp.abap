CLASS lsc_zsales_i_xl_user DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zsales_i_xl_user IMPLEMENTATION.

  METHOD save_modified.

    DATA(lt_so) = zsales_cl_bp_xl_data=>mapped_sales_order.
    IF lt_so IS NOT INITIAL.
      DATA: ls_so_temp_key      TYPE STRUCTURE FOR KEY OF i_salesordertp,
            ls_so_item_temp_key TYPE STRUCTURE FOR KEY OF i_salesorderitemtp.
      LOOP AT lt_so INTO DATA(wa_so).
      data(lv_tabix) = sy-tabix.
        CONVERT KEY OF i_salesordertp FROM ls_so_temp_key TO DATA(ls_so_final_key).
        MOVE-CORRESPONDING wa_so TO ls_so_item_temp_key.
        ls_so_item_temp_key-SalesOrderItem = create-xldata[ lV_tabix ]-salesitem.
        CONVERT KEY OF i_salesorderitemtp FROM ls_so_item_temp_key TO DATA(ls_so_item_final_key).

        APPEND VALUE #(  %msg = new_message_with_text(
                         severity = if_abap_behv_message=>severity-success
                         text =  |Sales Order { ls_so_final_key-salesorder } created successfully|
                         ) ) TO reported-xldata.

      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_xldata DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR xldata RESULT result.

    METHODS processdata FOR MODIFY
      IMPORTING keys FOR ACTION xldata~processdata RESULT result.
    METHODS save_so FOR DETERMINE ON SAVE
      IMPORTING keys FOR xldata~save_so.

ENDCLASS.

CLASS lhc_xldata IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD processdata.
  ENDMETHOD.

  METHOD save_so.

    READ ENTITIES OF zsales_i_xl_user
    ENTITY xldata FIELDS ( salesordertype salesorganization distributionchannel soldtoparty product requestedquantity plant  )
    WITH CORRESPONDING #( keys )
      RESULT DATA(lt_lfa1)
     FAILED DATA(failed).

    LOOP AT lt_lfa1 INTO DATA(ls_lfa1).
    data(lv_tabix) = sy-tabix.
    data:lv_cid  type string , lv_cid1 type string,lv_cid_ref type string.
      lv_cid = |H00{ lv_tabix }|.
     lv_cid1 = |I00{ lv_tabix }|.
      lv_cid_ref = |H00{ lv_tabix }|.
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
    ENTITY salesorder
    CREATE
       FIELDS ( salesordertype
        salesorganization
        distributionchannel
        organizationdivision
        soldtoparty )
    WITH VALUE #( ( %cid = lv_cid
    %data = VALUE #( salesordertype = ls_lfa1-salesordertype
    salesorganization = ls_lfa1-salesorganization
    distributionchannel = ls_lfa1-distributionchannel
    organizationdivision = ls_lfa1-organizationdivision
    soldtoparty = ls_lfa1-soldtoparty ) ) )
   CREATE BY \_item
    FIELDS ( product
    requestedquantity plant )
    WITH VALUE #( ( %cid_ref = lv_cid_ref
    salesorder = space
    %target = VALUE #( ( %cid = lv_cid1
    product = ls_lfa1-product
    requestedquantity = ls_lfa1-requestedquantity
    plant = ls_lfa1-plant ) ) ) )
    MAPPED DATA(ls_mapped)
    FAILED DATA(ls_failed)
    REPORTED DATA(ls_reported).

      DATA: mapped_sales_order1 TYPE TABLE FOR MAPPED EARLY i_salesordertp.
      MOVE-CORRESPONDING ls_mapped-salesorder TO mapped_sales_order1.
      MOVE-CORRESPONDING ls_mapped-salesorderitem TO mapped_sales_order1.

      APPEND mapped_sales_order1[ lv_tabix ] TO zsales_cl_bp_xl_data=>mapped_sales_order.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
