@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Excel Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSALES_C_XL_DATA
  as projection on ZSALES_I_XL_DATA
{
  key EndUser,
  key FileId,
  key LineId,
  key LineNumber,
      salesorder,
      salesitem,
      orderquantity,
      plant,
      product,
      requestedquantity,
      salesordertype,
      salesorganization,
      distributionchannel,
      organizationdivision,
      soldtoparty,
      HeaderText,
      /* Associations */
      _XLUser : redirected to parent ZSALES_C_XL_USER
}
