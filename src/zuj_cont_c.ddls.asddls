@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption Entity for Contract'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZUJ_CONT_C
  provider contract transactional_query
  as projection on ZUJ_CONT_I
{
      @Search.defaultSearchElement: true
  key bpnumber,

      @EndUserText.label: 'Model Number'
  key modelnumber,

      @EndUserText.label: 'Serial Number'
  key serialnumber,

      country,

      @EndUserText.label: 'Enrolled On'
      @Consumption.filter.selectionType: #RANGE
      enrolledon,

      @EndUserText.label: 'Cancelled On'
      cancelledon,

      @EndUserText.label: 'Status'
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZUJ_STATUS_VH', element: 'Status' }
      }]
      status,

      status_text,

      @EndUserText.label: 'Suspend Start Date'
      suspend_start,

      @EndUserText.label: 'Suspend End Date'
      suspend_end,

      last_changed_at,
      local_last_changed_at,

      @Search.defaultSearchElement: true
      @EndUserText.label: 'First Name'
      firstname,

      @Search.defaultSearchElement: true
      @EndUserText.label: 'Last Name'
      lastname,

      @EndUserText.label: 'Email Address'
      email,

      @EndUserText.label: 'Street1'
      street1,

      @EndUserText.label: 'Street2'
      street2,

      @EndUserText.label: 'City'
      city,

      @EndUserText.label: 'State'
      state,

      @EndUserText.label: 'Country'
      address_country,

      @EndUserText.label: 'Zipcode'
      zipcode
}
