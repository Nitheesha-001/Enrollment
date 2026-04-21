@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Entity for Contract'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.dataCategory: #VALUE_HELP
@Metadata.allowExtensions: true
define root view entity ZUJ_CONT_I
  as select from zuj_cont as E

  association [1..1] to zuj_bp        as _BP       on  $projection.bpnumber = _BP.bpnumber
  association [0..1] to ZUJ_SHIP_I    as _Ship     on  $projection.bpnumber     = _Ship.bpnumber
                                                   and $projection.modelnumber  = _Ship.modelnumber
                                                   and $projection.serialnumber = _Ship.serialnumber
  association [0..1] to ZUJ_STATUS_VH as _StatusVH on  $projection.status = _StatusVH.Status
{
  key E.bpnumber,
  key E.modelnumber,
  key E.serialnumber,
      E.country,

      @EndUserText.label: 'Enrolled On'
      E.enrolledon,

      @EndUserText.label: 'Cancelled On'
      E.cancelledon,

      @EndUserText.label: 'Status'
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZUJ_STATUS_VH', element: 'Status' }
      }]
      @ObjectModel.text.element: ['status_text']
      //      case E.status
      //      when 'A' then 3
      //      when 'C' then 1
      //      when 'S' then 2
      //      else          0
      //      end                  as statusCriticality,
      E.status,

      _StatusVH.StatusText as status_text,

      @EndUserText.label: 'Suspend Start Date'
      E.suspend_start,

      @EndUserText.label: 'Suspend End Date'
      E.suspend_end,

      E.last_changed_at,
      E.local_last_changed_at,

      _BP.firstname,
      _BP.lastname,
      _BP.email,

      _Ship._Addr.street1,
      _Ship._Addr.street2,
      _Ship._Addr.city,
      _Ship._Addr.state,
      _Ship._Addr.country  as address_country,
      _Ship._Addr.zipcode,


      _BP,
      _Ship,
      _StatusVH
}
