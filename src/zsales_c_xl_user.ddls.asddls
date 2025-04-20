@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'User Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define root view entity ZSALES_C_XL_USER
  provider contract transactional_query
  as projection on ZSALES_I_XL_USER
{
  key EndUser,
  key FileId,
      FileStatus,
      @Semantics.largeObject:
            { mimeType: 'Mimetype',
            fileName: 'Filename',
            contentDispositionPreference: #INLINE }
      Attachment,
      Mimetype,
      Filename,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */

      _XLData : redirected to composition child ZSALES_C_XL_DATA
}
