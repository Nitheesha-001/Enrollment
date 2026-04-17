@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Status Value Help View'
@ObjectModel.dataCategory: #VALUE_HELP
define view entity ZUJ_STATUS_VH
  as select from zuj_status
{
  key status      as Status,
      status_text as StatusText
}
