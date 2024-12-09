create or replace package PK_EXT_CUST_MEMO_SVC is

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
    RETURN NUMBER;

end PK_EXT_CUST_MEMO_SVC;
