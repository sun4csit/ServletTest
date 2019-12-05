--------------------------------------------------------
--  DDL for Procedure DATA_E_PAYMENT_TRUEUP_TOGGLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AGENCYCOMP_ACE"."DATA_E_PAYMENT_TRUEUP_TOGGLE" 
-- Copyright(c) 2008 The Procter and Gamble Company
-- One Procter and Gamble Place, Cincinnati, Ohio 45202, U.S.A.
-- All rights reserved.
-- This software is the confidential and proprietary information of The Procter and Gamble Company.
--=============================================================================================================
---  Version 00.00.0000:001 -  9/24/08 21:00 - TW - PHASE II - Created intial stored procedure
(
   p_user_id            IN       VARCHAR2,
   p_message_language   IN       CHAR,
   p_data_check_id      IN       NUMBER,
   p_trueup_type        IN       VARCHAR2,
   p_data_grid_in_obj   IN       DATA_GRID_IN_OBJ,
   p_task_id            OUT      NUMBER,
   p_struts_action_name OUT      ACE_TASK_TYPE_C.STRUTS_ACTION_NAME%TYPE,
   p_message_id         OUT      NUMBER,
   p_message_str        OUT      VARCHAR2
) IS
--- *******************************************************************
--  DECLARE COMMON LOCAL VARIABLE AND INITIALIZE BLOCK (Required)
--- *******************************************************************
   v_procedure_name             ACTIVITY_TRACKER.PROCEDURE_NAME%TYPE := 'DATA_E_PAYMENT_TRUEUP_TOGGLE';
   v_procedure_begin_seconds    NUMBER := DBMS_UTILITY.get_time;
   v_snapshot_id                SNAPSHOT_USER.SNAPSHOT_ID%TYPE := 0;
   v_debug_note                 ACTIVITY_TRACKER.DEBUG_NOTE%TYPE;
   v_system_date                SNAPSHOT_USER.OVERRIDE_SYSTEM_DATE%TYPE := SYSDATE;

--- *******************************************************************
--  DECLARE LOCAL VARIABLE AND INITIALIZE BLOCK (Optional)
--- *******************************************************************
   v_record_count           NUMBER;
   --v_data_check_type        DATA_CHECK.DATA_CHECK_TYPE%TYPE;

   --- Dynamic Grid variables - we need to run to get filtered SQL
   v_dynamic_sql_view       VARCHAR2(30);
   v_data_grid_in_obj       DATA_GRID_IN_OBJ;
   v_data_grid_out_obj      data_grid_out_obj;
   v_meta_datagrid_cur      TYPES.ref_cursor;
   v_datagrid_cur           TYPES.ref_cursor;
   v_data_grid_id           NUMBER;
   v_data_grid_id_tbl       data_grid_id_tbl := data_grid_id_tbl ();
BEGIN

--- *******************************************************************
--  Description:
--
--- ******************************************************************


--******************************************************************************
-- DATA/PARAMETER VALIDATION BLOCK
--******************************************************************************
    --==============================================================================
    -- Security Check on p_user_id
    -- Get snapshot
    -- Get system date which might be overriden
    --==============================================================================
   PROCEDURE_START (p_user_id               => p_user_id,
                    p_message_language      => p_message_language,
                    p_snapshot_id           => v_snapshot_id,
                    p_system_date           => v_system_date,
                    p_message_id            => p_message_id,
                    p_message_str           => p_message_str
                   );

   IF p_message_id < 0
   THEN
      GOTO exit_proc;
   END IF;

    ---===============================================================================
    -- Check if the p_data_check_id parameter contains a empty string or is null
    -- Check if the p_data_check_id is already defined
    ---===============================================================================
   p_message_id := VALIDATE_DATA_CHECK_ID (
                             p_data_check_id => p_data_check_id,
                             p_snapshot_id   => v_snapshot_id,
                             p_checklist    => 'NOT_NULL, IN_TABLE',
                             p_status_in    => NULL);

   IF p_message_id < 0 THEN
      GOTO exit_proc;
   END IF;

    ---===============================================================================
    --- Validate p_data_grid_in_obj
        --- IF p_data_grid_in_obj.IS_CHECK_ALL = 'N' THEN
        ---     We could have SELECTED_IDS
    ---===============================================================================

-- #############################################################################
-- MAIN BODY
-- #############################################################################

    --==============================================================================
    ---  Get Type and SQL information
    --==============================================================================
    -- SELECT DC.DATA_CHECK_TYPE, DYNAMIC_SQL_VIEW
    -- INTO   v_data_check_type,  v_dynamic_sql_view
    -- FROM   DATA_CHECK DC JOIN DATA_CHECK_TYPE_C DCTC ON DC.DATA_CHECK_TYPE = DCTC.DATA_CHECK_TYPE
    -- WHERE  dc.data_check_id = p_data_check_id
    -- AND    dc.SNAPSHOT_ID   = v_snapshot_id;
	
	SELECT DYNAMIC_SQL_VIEW
    INTO   v_dynamic_sql_view
    FROM   DATA_CHECK DC JOIN DATA_CHECK_TYPE_C DCTC ON DC.DATA_CHECK_TYPE = DCTC.DATA_CHECK_TYPE
    WHERE  dc.data_check_id = p_data_check_id
    AND    dc.SNAPSHOT_ID   = v_snapshot_id;

	v_debug_note:='p_trueup_type=;' || p_trueup_type || 'p_data_check_id;'||p_data_check_id ||'v_snapshot_id'||v_snapshot_id||'v_dynamic_sql_view'||v_dynamic_sql_view;
    --v_debug_note:='p_trueup_type=;' || p_trueup_type || 'p_data_check_id;'||p_data_check_id;

    --======================================================================================
    --- Need to get Dynamic Cursor based on passed in Filter values
        --- Override any paging sorting, we dont care what that is
        --- Data Check Dynamic Views should have set context for data_check_id, snapshot_id
    --=====================================================================================

    -- We will be running the dynamic cursor with the filtered values.  Make sure context is set
    setcontext.set_ctx ('p_data_check_id', TO_CHAR (p_data_check_id));
    setcontext.set_ctx ('v_snapshot_id', TO_CHAR (v_snapshot_id));

    DYNAMIC_CUR_DATA_GRID_ID_LOAD (
                    p_user_id               => p_user_id,
                    p_message_language      => p_message_language,
                    p_viewSource            => v_dynamic_sql_view,
                    p_data_grid_in_obj      => p_data_grid_in_obj,
                    p_save_id_tmp_table     => 'N',
                    p_data_grid_id_tbl      => v_data_grid_id_tbl,
                    p_message_id            => p_message_id,
                    p_message_str           => p_message_str
                   );


    IF p_message_id < 0
    THEN
        GOTO exit_proc;
    END IF;

    --==============================================================================
    ---  Run update statement to toggle data
    --==============================================================================
    CASE
    	WHEN p_trueup_type = 'month_ibot' THEN

            UPDATE DATA_E_PAYMENT_SUPP_TRUEUP tbl
            SET   IS_RUN_TRUEUP = DECODE (IS_RUN_TRUEUP, 'Y', 'N', 'Y')
            WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
            AND   tbl.snapshot_id = v_snapshot_id;
            
            UPDATE DATA_E_PAYMENT_SUPP_TRUEUP tbl
            SET   tbl.IS_RUN_TRUEUP_IBOT = DECODE (IS_RUN_TRUEUP_IBOT, 'Y', 'N', 'Y')
            WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
            AND   tbl.snapshot_id = v_snapshot_id;

            SELECT COUNT (1)
            INTO   v_record_count
            FROM   DATA_E_PAYMENT_SUPP_TRUEUP
            WHERE  DATA_CHECK_ID = p_data_check_id
            AND    SNAPSHOT_ID = v_snapshot_id
            AND    IS_RUN_TRUEUP ='Y';
            
             SELECT COUNT (1)
            INTO   v_record_count
            FROM   DATA_E_PAYMENT_SUPP_TRUEUP
            WHERE  DATA_CHECK_ID = p_data_check_id
            AND    SNAPSHOT_ID = v_snapshot_id
            AND    IS_RUN_TRUEUP_IBOT ='Y';
			
		WHEN p_trueup_type = 'month' THEN

            UPDATE DATA_E_PAYMENT_SUPP_TRUEUP tbl
            SET   IS_RUN_TRUEUP = DECODE (IS_RUN_TRUEUP, 'Y', 'N', 'Y')
            WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
            AND   tbl.snapshot_id = v_snapshot_id;
            
            SELECT COUNT (1)
            INTO   v_record_count
            FROM   DATA_E_PAYMENT_SUPP_TRUEUP
            WHERE  DATA_CHECK_ID = p_data_check_id
            AND    SNAPSHOT_ID = v_snapshot_id
            AND    IS_RUN_TRUEUP ='Y';
            
          			
		WHEN p_trueup_type = 'ibot' THEN
           
            UPDATE DATA_E_PAYMENT_SUPP_TRUEUP tbl
            SET   tbl.IS_RUN_TRUEUP_IBOT = DECODE (IS_RUN_TRUEUP_IBOT, 'Y', 'N', 'Y')
            WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
            AND   tbl.snapshot_id = v_snapshot_id;
            
            SELECT COUNT (1)
            INTO   v_record_count
            FROM   DATA_E_PAYMENT_SUPP_TRUEUP
            WHERE  DATA_CHECK_ID = p_data_check_id
            AND    SNAPSHOT_ID = v_snapshot_id
            AND    IS_RUN_TRUEUP_IBOT ='Y';


        WHEN p_trueup_type = 'SUPP_TRUEUP' THEN

            UPDATE DATA_E_SUPP_TRUEUP tbl
            SET   REVIEWED_BY_TNUMBER = DECODE (REVIEWED_BY_TNUMBER, NULL, p_user_id, NULL),
                  REVIEWED_BY_DATE    = DECODE (REVIEWED_BY_TNUMBER, NULL, v_system_date, NULL),
                  TRUEUP_DATE         = DECODE (REVIEWED_BY_TNUMBER, NULL, v_system_date, NULL),
                  TRUEUP_TNUMBER      = DECODE (REVIEWED_BY_TNUMBER, NULL, p_user_id, NULL)
            WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
            AND   tbl.snapshot_id = v_snapshot_id;

            --+-----------------------------------------------------------------------
            --- ACE-1967 - Supplemental true-up
            --+-----------------------------------------------------------------------
            UPDATE PAY_PLAN_SUPP s
            SET (TRUEUP_DATE, TRUEUP_TNUMBER) = (
                 SELECT TRUEUP_DATE, TRUEUP_TNUMBER
                 FROM   DATA_E_SUPP_TRUEUP tbl
                 WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
                 AND   tbl.snapshot_id = v_snapshot_id
                 AND   s.pay_plan_id = tbl.pay_plan_id
                 AND   s.snapshot_id = v_snapshot_id
            )
            WHERE EXISTS (
                 SELECT TRUEUP_DATE, TRUEUP_TNUMBER
                 FROM   DATA_E_SUPP_TRUEUP tbl
                 WHERE tbl.data_err_id IN (SELECT TO_NUMBER(data_grid_id) FROM table (cast (v_data_grid_id_tbl as data_grid_id_tbl)))
                 AND   tbl.snapshot_id = v_snapshot_id
                 AND   s.pay_plan_id = tbl.pay_plan_id
                 AND   s.snapshot_id = v_snapshot_id
            );


            SELECT COUNT (1)
            INTO   v_record_count
            FROM   DATA_E_SUPP_TRUEUP
            WHERE  DATA_CHECK_ID = p_data_check_id
            AND    SNAPSHOT_ID = v_snapshot_id
            AND    REVIEWED_BY_TNUMBER IS NULL;

       
        ELSE
            v_debug_note:='p_trueup_type=' || p_trueup_type;
            p_message_id:=-3009;
            GOTO exit_proc;
    END CASE;


    --==============================================================================
    ---- Update the ITEMS_TO_REVIEW within the DATA_CHECK table.
    ----    - Auto complete or uncomplete ACE_TASK based on record count
    --==============================================================================

    DATA_CHECK_UPD_ITEMS_TO_REVIEW (p_user_id                => p_user_id,
                                    p_message_language       => p_message_language,
                                    p_data_check_id          => p_data_check_id,
                                    p_snapshot_id            => v_snapshot_id,
                                    p_record_count           => v_record_count,
                                    p_caller_proc            => v_procedure_name,
                                    p_message_str            => p_message_str,
                                    p_message_id             => p_message_id
                                   );

    IF p_message_id < 0
    THEN
        GOTO exit_proc;
    END IF;

    --==============================================================================
    --- Return task_id and structs action name
    --==============================================================================
    SELECT DC.TASK_ID, JTC.TARGET_ACTION
    INTO   p_task_id, p_struts_action_name
    FROM   DATA_CHECK DC JOIN DATA_CHECK_TYPE_C DCTC ON DC.DATA_CHECK_TYPE = DCTC.DATA_CHECK_TYPE
                         JOIN JOB_TYPE_C JTC ON DCTC.JOB_TYPE_ID = JTC.JOB_TYPE_ID
    WHERE  DATA_CHECK_ID = p_data_check_id
    AND    SNAPSHOT_ID   = v_snapshot_id;


--- #############################################################################
--  MAIN PROGRAM BODY - END
-- #############################################################################
   p_message_id := 0;

   <<exit_proc>>
   ACE_ACTIVITY_TRACKER_SAVE
                      (p_user_id                      => p_user_id,
                       p_message_language             => p_message_language,
                       p_procedure_name               => v_procedure_name,
                       p_procedure_begin_seconds      => v_procedure_begin_seconds,
                       p_snapshot_id                  => v_snapshot_id,
                       p_debug_note                   => v_debug_note,
                       p_caller_procedure_name        => NULL,
                       p_associated_sql               => NULL,
                       p_associated_syscontext        => NULL,
                       p_tracker_id                   => NULL,
                       p_tracker_only_flag            => NULL,
                       p_message_id                   => p_message_id,
                       p_message_str                  => p_message_str
                      );

   IF p_message_id >= 0
   THEN
      COMMIT;
   ELSE
      ROLLBACK;
   END IF;

--- *******************************************************************
--  EXCEPTION ERROR PROCESSING BLOCK
--- *******************************************************************

/* --(*)(*)--

EXCEPTION
   WHEN OTHERS THEN
      v_debug_note := v_debug_note || 'SQLCODE=' || SQLCODE || ' ;SQLERRM=' || SQLERRM;
      p_message_id:= -1;
      ACE_ACTIVITY_TRACKER_SAVE
                     (p_user_id                      => p_user_id,
                      p_message_language             => p_message_language,
                      p_procedure_name               => v_procedure_name,
                      p_procedure_begin_seconds      => v_procedure_begin_seconds,
                      p_snapshot_id                  => v_snapshot_id,
                      p_debug_note                   => v_debug_note,
                      p_caller_procedure_name        => NULL,
                      p_associated_sql               => NULL,
                      p_associated_syscontext        => NULL,
                      p_tracker_id                   => NULL,
                      p_tracker_only_flag            => 'Y',
                      p_message_id                   => p_message_id,
                      p_message_str                  => p_message_str
                     );

--(*)(*)-- */

END;

/
