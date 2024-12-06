create or replace package body PK_EXT_CUST_MEMO_SVC is

  FUNCTION AP_EXT_CUST_MEMO_SVC(var_pi_svc_code       IN VARCHAR2,
                                var_pi_trace_id       IN VARCHAR2,
                                var_pi_channel_direct IN VARCHAR2,
                                var_pi_txn_dat        IN NUMBER,
                                var_pi_channel_id     IN VARCHAR2,
                                var_pi_user_id        IN VARCHAR2,
                                var_pi_svc_rq_id      IN VARCHAR2,
                                
                                var_pi_cust_id          IN VARCHAR2,
                                var_pi_memo_severity    IN CHAR,
                                var_pi_memo_reason      IN VARCHAR2,
                                var_pi_memo_start_date  IN VARCHAR2,
                                var_pi_memo_end_date    IN VARCHAR2,
                                var_pi_memo_text        IN VARCHAR2,
                                var_pi_memo_number      IN VARCHAR2,
                                var_pi_flgops           IN CHAR,
                                var_po_memo_number      OUT VARCHAR2,
                                var_po_response_code    OUT VARCHAR2,
                                var_po_response_message OUT VARCHAR2)
    RETURN NUMBER AS
    var_l_return_val      NUMBER;
    dormant_cust_count    NUMBER;
    cod_reason_count      NUMBER;
    var_l_ctr_instr_no    NUMBER;
    var_l_memo_count      NUMBER;
	var_pi_start_date     DATE;
    var_pi_memo_start_dat DATE;
    var_pi_memo_end_dat   DATE;
  
  BEGIN
    --Checking Duplicate User Reference--
    BEGIN
      var_l_return_val := AP_VAL_DUP_SVC_REQ(var_pi_trace_id,
                                             var_pi_channel_id,
                                             var_pi_svc_code,
                                             var_pi_svc_rq_id,
                                             var_pi_txn_dat,
                                             var_po_response_code,
                                             var_po_response_message);
    
      IF var_l_return_val <> 0 THEN
        RETURN var_l_return_val;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN VAR_L_RETURN_VAL;
    END; 
	-- Fetch system date from ba_bank_mast
	select Dat_process into var_pi_start_date from ba_bank_mast;
	
      -- Field validation for add and update
     IF lower(var_pi_flgops) IN('a','m') THEN
      BEGIN
        IF var_pi_memo_severity IS NULL THEN
        
          BEGIN
          
            var_po_response_code    := 10171;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          END;
        
        END IF;
        IF TRIM(var_pi_memo_reason)IS NULL THEN
          BEGIN
          
            var_po_response_code    := 10198;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          END;
        END IF;
        
        IF TRIM(var_pi_memo_start_date) IS NULL THEN
          var_pi_memo_start_dat := var_pi_start_date; 
        ELSE
          var_pi_memo_start_dat := TO_DATE(var_pi_memo_start_date, 'dd/MM/yyyy');
        END IF;
      
        IF TRIM(var_pi_memo_end_date) IS NULL THEN
          BEGIN
          
            var_po_response_code    := 10200;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          END;
        END IF;
      
        IF TRIM(var_pi_memo_text) IS NULL THEN
          BEGIN
          
            var_po_response_code    := 10201;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          END;
        END IF;
      
      END;
          
    END IF;
	
	 -- Additional checks for update
      IF lower(var_pi_flgops) = 'm' THEN
        IF TRIM(var_pi_memo_number) IS NULL THEN
          BEGIN
            var_po_response_code    := 10172;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          END;
        END IF;
      END IF;
	
	    --Reason Code checking 
    IF var_pi_memo_reason IS NOT NULL THEN
      BEGIN
        BEGIN
          select count(1)
            INTO cod_reason_count
            from ba_reason_codes
           where cod_task = 'CIM13'
             and cod_reason = TO_NUMBER(var_pi_memo_reason);
        
        EXCEPTION
          WHEN OTHERS THEN
            var_po_response_code    := 10175;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          
        END;
      
        IF cod_reason_count = 0 THEN
          BEGIN
            var_po_response_code    := 10176;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
            RETURN 1;
          END;
        END IF;
      END;
    END IF;
    --startDate , endDate validation check 
    IF TRIM(var_pi_memo_end_date) IS NOT NULL AND
       TRIM(var_pi_memo_start_date) IS NOT NULL THEN
      BEGIN
        IF TO_DATE(var_pi_memo_start_date, 'dd/MM/yyyy') >=
           TO_DATE(var_pi_memo_end_date, 'dd/MM/yyyy') THEN
          BEGIN
            var_po_response_code    := 10202;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
          END;
        END IF;
      END;
    END IF;
     IF TRIM(var_pi_memo_start_date) IS NOT NULL THEN
      BEGIN
        IF TO_DATE(var_pi_memo_start_date, 'dd/MM/yyyy') <
           var_pi_start_date THEN
          var_po_response_code    := 10215;
          var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          RETURN 1;
        
        END IF;
      END;
    END IF;
   
    --dormant checking 
    BEGIN
      SELECT COUNT(1)
        INTO dormant_cust_count
        FROM Vwe_Ci_Custmast
       WHERE flg_cust_typ = 'I'
         AND cod_cust_status = '7'
         and cod_cust_id = TO_NUMBER(var_pi_cust_id)
         and flg_mnt_status = 'A';
    EXCEPTION
      WHEN OTHERS THEN
        var_po_response_code    := 10173;
        var_po_response_message := ap_ext_get_ngi_error(var_po_response_code) ||
                                   ' for cust Id: ' || var_pi_cust_id;
        RETURN 1;
    END;
    IF dormant_cust_count > 0 THEN
      BEGIN
        var_po_response_code    := 10174;
        var_po_response_message := ap_ext_get_ngi_error(var_po_response_code) ||
                                   ' cust Id' || var_pi_cust_id;
      
        RETURN 1;
      END;
    END IF;

  
    --for add operaion
    IF lower(var_pi_flgops) = 'a' THEN
      BEGIN
        BEGIN
          SELECT nvl(max(ctr_instr_no), 0)
            INTO var_l_ctr_instr_no
            FROM ci_custmemo
           WHERE cod_cust_id = TO_NUMBER(var_pi_cust_id)
             AND flg_mnt_status = 'A';
        EXCEPTION
          WHEN OTHERS THEN
            var_po_response_code    := 10177;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
          
            RETURN 1;
        END;
        BEGIN
          var_l_return_val := AP_FFI_CI_CUSTMEMO_REPL(TO_NUMBER(var_pi_cust_id),
                                                      'a',
                                                      var_l_ctr_instr_no,
                                                      var_po_response_message);
          IF var_l_return_val <> 0 THEN
            RETURN var_l_return_val;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            var_po_response_code    := 10178;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
            RETURN 1;
        END;
        --insert into ci_custmemo
        BEGIN
          INSERT INTO ci_custmemo
            (cod_cust_id,
             dat_cust_memo,
             txt_cust_memo,
             flg_severity,
             flg_mnt_status,
             cod_mnt_action,
             cod_last_mnt_makerid,
             cod_last_mnt_chkrid,
             dat_last_mnt,
             ctr_updat_srlno,
             cod_reason,
             dat_memo_start,
             dat_memo_end,
             ctr_instr_no)
          VALUES
            (TO_NUMBER(var_pi_cust_id),
             SYSDATE,
             var_pi_memo_text,
             var_pi_memo_severity,
             'A',
             var_pi_flgops,
             var_pi_user_id,
             var_pi_user_id,
             SYSDATE,
             1,
             TO_NUMBER(var_pi_memo_reason),
             var_pi_memo_start_dat,
             TO_CHAR(TO_DATE(var_pi_memo_end_date, 'dd/MM/yyyy')),
             var_l_ctr_instr_no + 1);
        EXCEPTION
          WHEN OTHERS THEN
            var_po_response_code    := 10179;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
            RETURN 1;
        END;
      var_po_memo_number := var_l_ctr_instr_no + 1;
      END;
      --for update operation
    ELSE
      BEGIN
        BEGIN
          SELECT COUNT(1)
            INTO var_l_memo_count
            FROM CI_CUSTMEMO
           WHERE cod_cust_id = TO_NUMBER(var_pi_cust_id)
             AND ctr_instr_no = TO_NUMBER(var_pi_memo_number)
             AND flg_mnt_status = 'A';
        EXCEPTION
          WHEN OTHERS THEN
            var_po_response_code    := 10177;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
            RETURN 1;
          
        END;
        IF var_l_memo_count = 0 THEN
          BEGIN
            var_po_response_code    := 10180;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
            RETURN 1;
          END;
        END IF;
        
        
      
        IF var_pi_memo_end_date IS NOT NULL THEN
          BEGIN
            var_pi_memo_end_dat := TO_CHAR(TO_DATE(var_pi_memo_end_date,
                                                   'dd/MM/yyyy'));
          END;
        END IF;
        BEGIN
          UPDATE CI_CUSTMEMO
             SET txt_cust_memo        = NVL(var_pi_memo_text, txt_cust_memo),
                 dat_cust_memo        = SYSDATE,
                 flg_severity         = NVL(var_pi_memo_severity,
                                            flg_severity),
                 cod_mnt_action       = var_pi_flgops,
                 cod_last_mnt_makerid = var_pi_user_id,
                 cod_last_mnt_chkrid  = var_pi_user_id,
                 dat_last_mnt         = SYSDATE,
                 cod_reason           = NVL(TO_NUMBER(var_pi_memo_reason),
                                            cod_reason),
                 dat_memo_start       = NVL(var_pi_memo_start_dat,
                                            dat_memo_start),
                 dat_memo_end         = NVL(var_pi_memo_end_dat,
                                            dat_memo_end)
           WHERE cod_cust_id = TO_NUMBER(var_pi_cust_id)
             AND ctr_instr_no = TO_NUMBER(var_pi_memo_number)
             and flg_mnt_status = 'A';
        EXCEPTION
          WHEN OTHERS THEN
            var_po_response_code    := 10181;
            var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
            RETURN 1;
          
        END;
        var_po_memo_number := TO_NUMBER(var_pi_memo_number);
      END;
    END IF;
  
    return 0;
  EXCEPTION
    WHEN OTHERS THEN
      var_po_response_code    := 10181;
      var_po_response_message := ap_ext_get_ngi_error(var_po_response_code);
      RETURN 1;
  END;
END PK_EXT_CUST_MEMO_SVC;
