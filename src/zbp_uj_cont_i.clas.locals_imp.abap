CLASS lhc_Contract DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Contract RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Contract RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Contract RESULT result.

    METHODS CancelEnrollment FOR MODIFY
      IMPORTING keys FOR ACTION Contract~CancelEnrollment RESULT result.
    METHODS suspend_enrollment FOR MODIFY
      IMPORTING keys FOR ACTION Contract~SuspendEnrollment RESULT result.
    METHODS reactivate_enrollment FOR MODIFY
      IMPORTING keys FOR ACTION Contract~ReactivateEnrollment RESULT result.

    METHODS validate_status FOR VALIDATE ON SAVE
      IMPORTING keys FOR Contract~ValidateStatus.
    METHODS validate_suspend_dates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Contract~ValidateSuspendDates.
    METHODS validate_cancel_date FOR VALIDATE ON SAVE
      IMPORTING keys FOR Contract~ValidateCancelDate.

    METHODS set_initial_status FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Contract~SetInitialStatus.
    METHODS set_cancelled_on FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Contract~SetCancelledOn.
    METHODS clear_suspend_dates FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Contract~ClearSuspendDates.

ENDCLASS.

CLASS lhc_Contract IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
        ENTITY Contract
          FIELDS ( status )
          WITH CORRESPONDING #( keys )
        RESULT DATA(contracts).
*      FAILED DATA(failed).

    result = VALUE #(
      FOR contract IN contracts (
        %tky = contract-%tky

        " Cancel button: visible only when Active or Suspended
        %action-CancelEnrollment     =
          COND #(
            WHEN contract-status = zcl_uj_cont_status=>gc_cancelled
            THEN if_abap_behv=>fc-o-disabled
            ELSE if_abap_behv=>fc-o-enabled )

        " Suspend button: visible only when Active
        %action-SuspendEnrollment    =
          COND #(
            WHEN contract-status = zcl_uj_cont_status=>gc_active
            THEN if_abap_behv=>fc-o-enabled
            ELSE if_abap_behv=>fc-o-disabled )

        " Reactivate button: visible only when Cancelled or Suspended
        %action-ReactivateEnrollment =
          COND #(
            WHEN contract-status = zcl_uj_cont_status=>gc_active
            THEN if_abap_behv=>fc-o-disabled
            ELSE if_abap_behv=>fc-o-enabled )
      )
    ).


  ENDMETHOD.

  METHOD CancelEnrollment.
    " Read current data
    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
    ENTITY Contract
    FIELDS ( status cancelledon )
    WITH CORRESPONDING #( keys )
    RESULT DATA(contracts)
    REPORTED reported.
*    FAILED failed.

    DATA updates TYPE TABLE FOR UPDATE zuj_cont_i\\Contract.

    LOOP AT contracts INTO DATA(contract).

      " Only Active or Suspended can be Cancelled
      IF contract-status = zcl_uj_cont_status=>gc_cancelled.
        APPEND VALUE #(
          %tky        = contract-%tky
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Enrollment is already Cancelled' )
                        ) TO reported-contract.
*        ) TO failed-contract.
        CONTINUE.
      ENDIF.

      " Update to Cancelled

      APPEND VALUE #(
        %tky         = contract-%tky
        status       = zcl_uj_cont_status=>gc_cancelled
        cancelledon  = cl_abap_context_info=>get_system_date( )
        suspend_start = '00000000'   " clear suspend dates
        suspend_end   = '00000000'
*        last_changed_at = cl_abap_context_info=>get_system_date
        %control = VALUE #(
          status        = if_abap_behv=>mk-on
          cancelledon   = if_abap_behv=>mk-on
          suspend_start = if_abap_behv=>mk-on
          suspend_end   = if_abap_behv=>mk-on
          last_changed_at = if_abap_behv=>mk-on
        )
      ) TO updates.

    ENDLOOP.

    " Modify
    MODIFY ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract UPDATE FROM updates
      FAILED DATA(mod_failed)
      REPORTED DATA(mod_reported).

    " Return updated records
    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated_contracts).

    result = VALUE #(
      FOR rec IN updated_contracts (
        %tky   = rec-%tky
        %param = rec
      )
    ).

  ENDMETHOD.

  METHOD suspend_enrollment.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts)
      REPORTED reported.
*      FAILED DATA(failed).

    DATA updates TYPE TABLE FOR UPDATE zuj_cont_i\\Contract.

    LOOP AT contracts INTO DATA(contract).

      " Get action parameters from key
      READ TABLE keys INTO DATA(key)  WITH KEY %tky = contract-%tky.

      " Only Active enrollments can be suspended
      IF contract-status <> zcl_uj_cont_status=>gc_active.
        APPEND VALUE #(
          %tky  = contract-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Only Active enrollments can be Suspended' )
                    ) TO reported-contract.
*        ) TO failed-contract.
        CONTINUE.
      ENDIF.

      " Validate parameter dates exist
      IF key-%param-suspend_start IS INITIAL OR
         key-%param-suspend_end IS INITIAL.
        APPEND VALUE #(
          %tky  = contract-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Suspend Start and End dates are required' )
                    ) TO reported-contract.
*        ) TO failed-contract.
        CONTINUE.
      ENDIF.

      " Suspend Start must be before Suspend End
      IF key-%param-suspend_start >= key-%param-suspend_end.
        APPEND VALUE #(
          %tky  = contract-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Suspend Start must be before Suspend End date' )
                    ) TO reported-contract.
*        ) TO failed-contract.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky          = contract-%tky
        status        = zcl_uj_cont_status=>gc_suspended
        suspend_start = key-%param-suspend_start
        suspend_end   = key-%param-suspend_end
*        last_changed_at = cl_abap_context_info=>get_system_datetime( )
        %control = VALUE #(
          status        = if_abap_behv=>mk-on
          suspend_start = if_abap_behv=>mk-on
          suspend_end   = if_abap_behv=>mk-on
          last_changed_at = if_abap_behv=>mk-on
        )
      ) TO updates.

    ENDLOOP.

    MODIFY ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract UPDATE FROM updates
      FAILED DATA(mod_failed)
      REPORTED DATA(mod_reported).

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated_contracts).

    result = VALUE #(
      FOR rec IN updated_contracts (
        %tky   = rec-%tky
        %param = rec
      )
    ).

  ENDMETHOD.

  METHOD reactivate_enrollment.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).
*      FAILED DATA(failed).

    DATA updates TYPE TABLE FOR UPDATE zuj_cont_i\\Contract.

    LOOP AT contracts INTO DATA(contract).

      " Already Active - cannot reactivate
      IF contract-status = zcl_uj_cont_status=>gc_active.
        APPEND VALUE #(
          %tky  = contract-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Enrollment is already Active' )
                    ) TO reported-contract.
*        ) TO failed-contract.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky          = contract-%tky
        status        = zcl_uj_cont_status=>gc_active
        cancelledon   = '00000000'   " clear cancelled date
        suspend_start = '00000000'   " clear suspend dates
        suspend_end   = '00000000'
*        last_changed_at = cl_abap_context_info=>get_system_datetime( )
        %control = VALUE #(
          status        = if_abap_behv=>mk-on
          cancelledon   = if_abap_behv=>mk-on
          suspend_start = if_abap_behv=>mk-on
          suspend_end   = if_abap_behv=>mk-on
          last_changed_at = if_abap_behv=>mk-on
        )
      ) TO updates.

    ENDLOOP.

    MODIFY ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract UPDATE FROM updates
      FAILED DATA(mod_failed)
      REPORTED DATA(mod_reported).

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated_contracts).

    result = VALUE #(
      FOR rec IN updated_contracts (
        %tky   = rec-%tky
        %param = rec
      )
    ).

  ENDMETHOD.

  METHOD validate_status.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    LOOP AT contracts INTO DATA(contract).

      IF contract-status <> zcl_uj_cont_status=>gc_active
       AND contract-status <> zcl_uj_cont_status=>gc_cancelled
       AND contract-status <> zcl_uj_cont_status=>gc_suspended.

        APPEND VALUE #(
          %tky        = contract-%tky
          %state_area = 'VALIDATE_STATUS'
          %msg    = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Status must be A (Active), C (Cancelled), or S (Suspended)'
                       )
          %element-status = if_abap_behv=>mk-on
        ) TO reported-contract.

        APPEND VALUE #( %tky = contract-%tky )
          TO failed-contract.

      ENDIF.

    ENDLOOP.
*    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
*      ENTITY Contract
*        FIELDS ( status )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(contracts).
*
*    LOOP AT contracts INTO DATA(contract).
*
*      IF contract-status NOT IN VALUE #(
**          VALUE abap.char(1) tab(
*        ( sign = 'I' option = 'EQ' low = zcl_uj_cont_status=>gc_active )
*        ( sign = 'I' option = 'EQ' low = zcl_uj_cont_status=>gc_cancelled )
*        ( sign = 'I' option = 'EQ' low = zcl_uj_cont_status=>gc_suspended )
*        ).
*
*        APPEND VALUE #(
*          %tky        = contract-%tky
*          %state_area = 'VALIDATE_STATUS'
*          %msg        = new_message_with_text(
*                          severity = if_abap_behv_message=>severity-error
*                          text     = 'Status must be A (Active), C (Cancelled), or S (Suspended)' )
*          %element-status = if_abap_behv=>mk-on
*        ) TO reported-contract.
*
*        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
*
*      ENDIF.

*    ENDLOOP.

  ENDMETHOD.

  METHOD validate_suspend_dates.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status suspend_start suspend_end )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    LOOP AT contracts INTO DATA(contract).

      IF contract-status = zcl_uj_cont_status=>gc_suspended.

        " Both dates must be filled
        IF contract-suspend_start IS INITIAL OR
           contract-suspend_end IS INITIAL.

          APPEND VALUE #(
            %tky        = contract-%tky
            %state_area = 'VALIDATE_SUSPEND'
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Suspend Start and End dates are mandatory for Suspended status' )
            %element-suspend_start = if_abap_behv=>mk-on
            %element-suspend_end   = if_abap_behv=>mk-on
          ) TO reported-contract.

          APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.

          " End date must be after Start date
        ELSEIF contract-suspend_end <= contract-suspend_start.

          APPEND VALUE #(
            %tky        = contract-%tky
            %state_area = 'VALIDATE_SUSPEND'
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Suspend End Date must be after Suspend Start Date' )
            %element-suspend_end = if_abap_behv=>mk-on
          ) TO reported-contract.

          APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.

        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validate_cancel_date.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status cancelledon )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    LOOP AT contracts INTO DATA(contract).

      IF contract-status = zcl_uj_cont_status=>gc_cancelled
         AND contract-cancelledon IS INITIAL.

        APPEND VALUE #(
          %tky        = contract-%tky
          %state_area = 'VALIDATE_CANCEL'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Cancelled On date is required when status is Cancelled' )
          %element-cancelledon = if_abap_behv=>mk-on
        ) TO reported-contract.

        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD set_initial_status.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status enrolledon )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    DATA updates TYPE TABLE FOR UPDATE zuj_cont_i\\Contract.

    LOOP AT contracts INTO DATA(contract).

      " Only set if status is blank (new record)
      IF contract-status IS INITIAL.
        APPEND VALUE #(
          %tky    = contract-%tky
          status  = zcl_uj_cont_status=>gc_active
          %control-status = if_abap_behv=>mk-on
        ) TO updates.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract UPDATE FROM updates
*      REPORTED REPORTED
      FAILED DATA(failed).

  ENDMETHOD.

  METHOD set_cancelled_on.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status cancelledon )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    DATA updates TYPE TABLE FOR UPDATE zuj_cont_i\\Contract.

    LOOP AT contracts INTO DATA(contract).

      IF contract-status = zcl_uj_cont_status=>gc_cancelled
         AND contract-cancelledon IS INITIAL.

        APPEND VALUE #(
          %tky         = contract-%tky
          cancelledon  = cl_abap_context_info=>get_system_date( )
          %control-cancelledon = if_abap_behv=>mk-on
        ) TO updates.

      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract UPDATE FROM updates
*      REPORTED DATA(reported)
      FAILED DATA(failed).

  ENDMETHOD.

  METHOD clear_suspend_dates.

    READ ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract
        FIELDS ( status suspend_start suspend_end )
        WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    DATA updates TYPE TABLE FOR UPDATE zuj_cont_i\\Contract.

    LOOP AT contracts INTO DATA(contract).

      IF contract-status <> zcl_uj_cont_status=>gc_suspended
         AND ( contract-suspend_start IS NOT INITIAL
            OR contract-suspend_end   IS NOT INITIAL ).

        APPEND VALUE #(
          %tky          = contract-%tky
          suspend_start = '00000000'
          suspend_end   = '00000000'
          %control = VALUE #(
            suspend_start = if_abap_behv=>mk-on
            suspend_end   = if_abap_behv=>mk-on
          )
        ) TO updates.

      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zuj_cont_i IN LOCAL MODE
      ENTITY Contract UPDATE FROM updates
*      REPORTED DATA(reported)
      FAILED DATA(failed).

  ENDMETHOD.





ENDCLASS.
