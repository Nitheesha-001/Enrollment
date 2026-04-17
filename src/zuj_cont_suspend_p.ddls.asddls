@EndUserText.label: 'Suspend Enrollments'
define abstract entity ZUJ_CONT_SUSPEND_P
{
  @EndUserText.label: 'Suspend Start Date'
  suspend_start : abap.dats;

  @EndUserText.label: 'Suspend End Date'
  suspend_end   : abap.dats;
    
}
