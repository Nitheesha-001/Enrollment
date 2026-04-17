@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Entity for Shipping'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZUJ_SHIP_I
  as select from zuj_ship as S
  association [0..1] to zuj_addr as _Addr
    on $projection.addrnumber = _Addr.addrnumber
{
  key S.bpnumber,
  key S.modelnumber,
  key S.serialnumber,
      S.addrnumber,
      S.active,
      _Addr,           
      _Addr.street1,
      _Addr.street2,
      _Addr.city,
      _Addr.state,
      _Addr.country,
      _Addr.zipcode
}
