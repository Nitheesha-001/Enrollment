CLASS zcl_uj_cont_status DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  CONSTANTS:
      " Status Values
      gc_active    TYPE string  VALUE 'A',
      gc_cancelled TYPE string VALUE 'C',
      gc_suspended TYPE string VALUE 'S',

      " Status Texts
      gc_active_text    TYPE string VALUE 'Active',
      gc_cancelled_text TYPE string VALUE 'Cancelled',
      gc_suspended_text TYPE string VALUE 'Suspended'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_uj_cont_status IMPLEMENTATION.
ENDCLASS.
