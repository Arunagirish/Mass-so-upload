@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'excel data definition'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZSALES_I_XL_DATA
  as select from zsales_exceldata
  association to parent ZSALES_I_XL_USER as _XLUser on  $projection.EndUser = _XLUser.EndUser
                                                    and $projection.FileId  = _XLUser.FileId

{
  key end_user              as EndUser,
  key file_id               as FileId,
  key line_id               as LineId,
  key line_no               as LineNumber,
      salesorder            as salesorder,
      salesitem             as salesitem,
      orderquantity         as orderquantity,
      product               as product,
      requestedquantity     as requestedquantity,
      plant                 as plant,
      sales_order_type      as salesordertype,
      sales_organization    as salesorganization,
      distribution_channel  as distributionchannel,
      organization_division as organizationdivision,
      sold_to_party         as soldtoparty,
      header_text           as HeaderText,
      _XLUser
}
