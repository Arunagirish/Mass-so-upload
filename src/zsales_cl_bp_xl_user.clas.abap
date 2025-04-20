CLASS zsales_cl_bp_xl_user DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zsales_i_xl_user.
  PUBLIC SECTION..

    TYPES : BEGIN OF gty_gr_xl,
              sales_order           TYPE string,
              sales_item            TYPE string,
              order_quantity        TYPE string,
              product               TYPE string,
              requestedquantity     TYPE string,
              plant                 TYPE string,
              sales_order_type      TYPE string,
              sales_organization    TYPE string,
              distribution_channel  TYPE string,
              organization_division TYPE string,
              sold_to_party         TYPE string,
              header_text           TYPE string,
              line_number           TYPE string, "Internal Use during Upload
              line_id               TYPE string, "Internal Use during Upload
            END OF gty_gr_xl.

            CLASS-DATA mapped_purchase_requisition TYPE RESPONSE FOR MAPPED i_salesordertp.
ENDCLASS.



CLASS ZSALES_CL_BP_XL_USER IMPLEMENTATION.
ENDCLASS.
