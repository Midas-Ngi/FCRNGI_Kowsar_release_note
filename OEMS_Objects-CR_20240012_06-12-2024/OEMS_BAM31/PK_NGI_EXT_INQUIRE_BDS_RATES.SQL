CREATE OR REPLACE PACKAGE PK_NGI_EXT_INQUIRE_BDS_RATES IS

  FUNCTION AP_NGI_EXT_INQUIRE_BDS_RATES(CURSNAME            OUT CV_TYPES.GENTYPE,
                                          var_cust_type       varchar2,
                                          VAR_PI_CHANNEL_ID   IN VARCHAR2,
                                          VAR_PI_USER_ID      IN VARCHAR2,
                                          VAR_PI_SUPER_USERID IN VARCHAR2,
                                          VAR_PI_SRV_ID       IN VARCHAR2,
                                          VAR_PI_SVC_CODE     IN VARCHAR2,
                                          VAR_PI_TRACE_ID     IN VARCHAR2,
                                          VAR_PI_TXN_DATE     IN VARCHAR2,
                                          VAR_PIO_ERR_CODE    OUT VARCHAR2,
                                          VAR_PIO_ERR_MSG     OUT VARCHAR2)
    RETURN NUMBER;

END PK_NGI_EXT_INQUIRE_BDS_RATES;
/

CREATE OR REPLACE PACKAGE BODY PK_NGI_EXT_INQUIRE_BDS_RATES IS

  FUNCTION "AP_NGI_EXT_INQUIRE_BDS_RATES"(CURSNAME            OUT CV_TYPES.GENTYPE,
                                          VAR_CUST_TYPE       VARCHAR2,
                                          VAR_PI_CHANNEL_ID   IN VARCHAR2,
                                          VAR_PI_USER_ID      IN VARCHAR2,
                                          VAR_PI_SUPER_USERID IN VARCHAR2,
                                          VAR_PI_SRV_ID       IN VARCHAR2,
                                          VAR_PI_SVC_CODE     IN VARCHAR2,
                                          VAR_PI_TRACE_ID     IN VARCHAR2,
                                          VAR_PI_TXN_DATE     IN VARCHAR2,
                                          VAR_PIO_ERR_CODE    OUT VARCHAR2,
                                          VAR_PIO_ERR_MSG     OUT VARCHAR2)
    RETURN NUMBER AS
    VAR_RET_VAL        NUMBER;
    var_l_session_id   NUMBER;
    VAR_L_RETURN_VALUE NUMBER := 0;
    FUNCTION AP_NGI_EXT_INQUIRE_BDS_RATES RETURN NUMBER AS
      var_l_cod_ccy       NUMBER(5);
      VAR_L_BASE_CURRENCY NUMBER(5);
      VAR_L_SLAB_1        inquire_bds_rates.Slab_1%TYPE;
      VAR_L_SLAB_2        inquire_bds_rates.Slab_2%TYPE;
      VAR_L_SLAB_3        inquire_bds_rates.Slab_3%TYPE;
      VAR_L_SLAB_4        inquire_bds_rates.Slab_4%TYPE;
      VAR_L_SLAB_5        inquire_bds_rates.Slab_5%TYPE;
      VAR_L_SLAB_6        inquire_bds_rates.Slab_6%TYPE;
      VAR_L_SLAB_7        inquire_bds_rates.Slab_7%TYPE;
      VAR_L_SLAB_8        inquire_bds_rates.Slab_8%TYPE;
      VAR_L_SLAB_9        inquire_bds_rates.Slab_9%TYPE;
      VAR_L_SLAB_10       inquire_bds_rates.Slab_10%TYPE;
      i                   integer;
      CURSOR CUR_INQ_BDS_RATE(VAR_L_BASE_CURRENCY1 NUMBER) IS
        SELECT COD_CCY, BASE_CURRENCY, TT_BID_RATE, TT_ASK_RATE
          FROM INQUIRE_BDS_RATES
         WHERE SESSION_ID = var_l_session_id
           AND BASE_CURRENCY = VAR_L_BASE_CURRENCY1
         ORDER BY BASE_CURRENCY;
      CURSOR CUR_SPREAD(VAR_L_COD_CCY NUMBER, VAR_L_BASE_CURRENCY NUMBER) IS
        SELECT B.TT_BID_RATE_SPRD,
               B.TT_ASK_RATE_SPRD,
               B.FX_CUST_CAT,
               B.MIN_AMT --,A.TT_BID_RATE-B.TT_BID_RATE_SPRD
          FROM ba_ccy_bds_lcy_rates A, ba_ccy_bds_rate_sprds B
         WHERE A.COD_CCY = VAR_L_COD_CCY
           AND b.cod_ccy = A.COD_CCY
           AND B.BASE_CURRENCY = '360'
           AND B.FX_CUST_CAT = var_cust_type
         ORDER BY B.FX_CUST_CAT, B.MIN_AMT;
      CURSOR CUR_USD_SPREAD(VAR_L_COD_CCY NUMBER, VAR_L_BASE_CURRENCY NUMBER) IS
        SELECT B.TT_BID_RATE_SPRD,
               B.TT_ASK_RATE_SPRD,
               B.FX_CUST_CAT,
               B.MIN_AMT --,A.TT_BID_RATE-B.TT_BID_RATE_SPRD
          FROM ba_ccy_usd_rate_bds A, ba_ccy_bds_rate_sprds B
         WHERE A.COD_CCY = VAR_L_COD_CCY
           AND b.cod_ccy = A.COD_CCY
           AND B.BASE_CURRENCY = '840'
           AND B.FX_CUST_CAT = var_cust_type
         ORDER BY B.FX_CUST_CAT, B.MIN_AMT;
    BEGIN
      var_l_session_id := USERENV('SESSIONID');
      BEGIN
        DELETE FROM inquire_bds_rates WHERE session_id = var_l_session_id;
      END;
      BEGIN
        INSERT INTO inquire_bds_rates -- Insert Into the Temporray Table
          (BASE_CURRENCY,
           COD_CCY,
           NAM_CCY_SHORT,
           TT_BID_RATE,
           TT_ASK_RATE,
           CAL_BID_RATE,
           CAL_ASK_RATE,
           session_id)
          SELECT '360',
                 a.cod_ccy,
                 a.nam_ccy_short,
                 a.tt_bid_rate,
                 a.tt_ask_rate,
                 a.tt_bid_rate,
                 a.tt_ask_rate,
                 var_l_session_id
            FROM ba_ccy_bds_lcy_rates a
           order by cod_ccy;
      EXCEPTION
        WHEN OTHERS THEN
          ora_raiserror(SQLCODE,
                        'INSERTION FAILED FROM ba_ccy_bds_lcy_rates.',
                        94);
      END;
      FOR L_VAR_TYP_CURRENCY IN CUR_INQ_BDS_RATE(360) LOOP
        i := 1;
        FOR X IN CUR_SPREAD(L_VAR_TYP_CURRENCY.COD_CCY,
                            L_VAR_TYP_CURRENCY.BASE_CURRENCY) LOOP
          if (i = 1) THEN
            i            := i + 1;
            VAR_L_SLAB_1 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_6 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_ASK_RATE_SPRD;
          elsif (i = 2) THEN
            i            := i + 1;
            VAR_L_SLAB_2 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_7 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_BID_RATE_SPRD;
          elsif (i = 3) THEN
            i            := i + 1;
            VAR_L_SLAB_3 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_8 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_ASK_RATE_SPRD;
          elsif (i = 4) THEN
            i            := i + 1;
            VAR_L_SLAB_4 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_9 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_ASK_RATE_SPRD;
          elsif (i = 5) THEN
            i             := i + 1;
            VAR_L_SLAB_5  := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                             X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_10 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                             X.TT_ASK_RATE_SPRD;
          end if;
        END LOOP;
        UPDATE inquire_bds_rates
           SET SLAB_1  = NVL(VAR_L_SLAB_1, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_2  = NVL(VAR_L_SLAB_2, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_3  = NVL(VAR_L_SLAB_3, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_4  = NVL(VAR_L_SLAB_4, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_5  = NVL(VAR_L_SLAB_5, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_6  = NVL(VAR_L_SLAB_6, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_7  = NVL(VAR_L_SLAB_7, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_8  = NVL(VAR_L_SLAB_8, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_9  = NVL(VAR_L_SLAB_9, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_10 = NVL(VAR_L_SLAB_10, L_VAR_TYP_CURRENCY.TT_ASK_RATE)
         WHERE COD_CCY = L_VAR_TYP_CURRENCY.COD_CCY
           AND BASE_CURRENCY = L_VAR_TYP_CURRENCY.BASE_CURRENCY
           AND SESSION_ID = var_l_session_id;
        VAR_L_SLAB_1                   := NULL;
        VAR_L_SLAB_2                   := NULL;
        VAR_L_SLAB_3                   := NULL;
        VAR_L_SLAB_4                   := NULL;
        VAR_L_SLAB_5                   := NULL;
        VAR_L_SLAB_6                   := NULL;
        VAR_L_SLAB_7                   := NULL;
        VAR_L_SLAB_8                   := NULL;
        VAR_L_SLAB_9                   := NULL;
        VAR_L_SLAB_10                  := NULL;
        L_VAR_TYP_CURRENCY.TT_ASK_RATE := 0;
        L_VAR_TYP_CURRENCY.TT_BID_RATE := 0;
      END LOOP;
      BEGIN
        INSERT INTO inquire_bds_rates -- Insert Into the Temporray Table
          (BASE_CURRENCY,
           COD_CCY,
           NAM_CCY_SHORT,
           TT_BID_RATE,
           TT_ASK_RATE,
           CAL_BID_RATE,
           CAL_ASK_RATE,
           session_id)
          SELECT '840',
                 a.cod_ccy,
                 b.nam_ccy_short,
                 a.tt_bid_rate,
                 a.tt_ask_rate,
                 a.tt_bid_rate,
                 a.tt_ask_rate,
                 var_l_session_id
            FROM ba_ccy_usd_rate_bds a, ba_ccy_code b
           where a.cod_ccy = b.cod_ccy
             and b.flg_mnt_status = 'A'
             and a.cod_ccy <> '360'
           order by cod_ccy;
      EXCEPTION
        WHEN OTHERS THEN
          ora_raiserror(SQLCODE,
                        'INSERTION FAILED FROM ba_ccy_bds_lcy_rates.',
                        186);
      END;
      --  OPEN CUR_INQ_BDS_RATE;
      -- LOOP
      -- FETCH CUR_INQ_BDS_RATE INTO L_VAR_TYP_CURRENCY;
      -- OPEN  CUR_SPREAD(L_VAR_TYP_CURRENCY.COD_CCY, L_VAR_TYP_CURRENCY.BASE_CURRENCY );
      FOR L_VAR_TYP_CURRENCY IN CUR_INQ_BDS_RATE(840) LOOP
        i := 1;
        FOR X IN CUR_USD_SPREAD(L_VAR_TYP_CURRENCY.COD_CCY,
                                L_VAR_TYP_CURRENCY.BASE_CURRENCY) LOOP
          if (i = 1) THEN
            i            := i + 1;
            VAR_L_SLAB_1 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_6 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_ASK_RATE_SPRD;
          elsif (i = 2) THEN
            i            := i + 1;
            VAR_L_SLAB_2 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_7 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_BID_RATE_SPRD;
          elsif (i = 3) THEN
            i            := i + 1;
            VAR_L_SLAB_3 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_8 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_ASK_RATE_SPRD;
          elsif (i = 4) THEN
            i            := i + 1;
            VAR_L_SLAB_4 := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                            X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_9 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                            X.TT_ASK_RATE_SPRD;
          elsif (i = 5) THEN
            i             := i + 1;
            VAR_L_SLAB_5  := L_VAR_TYP_CURRENCY.TT_BID_RATE -
                             X.TT_BID_RATE_SPRD;
            VAR_L_SLAB_10 := L_VAR_TYP_CURRENCY.TT_ASK_RATE +
                             X.TT_ASK_RATE_SPRD;
          end if;
        END LOOP;
        UPDATE inquire_bds_rates
           SET SLAB_1  = NVL(VAR_L_SLAB_1, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_2  = NVL(VAR_L_SLAB_2, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_3  = NVL(VAR_L_SLAB_3, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_4  = NVL(VAR_L_SLAB_4, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_5  = NVL(VAR_L_SLAB_5, L_VAR_TYP_CURRENCY.TT_BID_RATE),
               SLAB_6  = NVL(VAR_L_SLAB_6, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_7  = NVL(VAR_L_SLAB_7, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_8  = NVL(VAR_L_SLAB_8, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_9  = NVL(VAR_L_SLAB_9, L_VAR_TYP_CURRENCY.TT_ASK_RATE),
               SLAB_10 = NVL(VAR_L_SLAB_10, L_VAR_TYP_CURRENCY.TT_ASK_RATE)
         WHERE COD_CCY = L_VAR_TYP_CURRENCY.COD_CCY
           AND BASE_CURRENCY = L_VAR_TYP_CURRENCY.BASE_CURRENCY
           AND SESSION_ID = var_l_session_id;
        VAR_L_SLAB_1                   := NULL;
        VAR_L_SLAB_2                   := NULL;
        VAR_L_SLAB_3                   := NULL;
        VAR_L_SLAB_4                   := NULL;
        VAR_L_SLAB_5                   := NULL;
        VAR_L_SLAB_6                   := NULL;
        VAR_L_SLAB_7                   := NULL;
        VAR_L_SLAB_8                   := NULL;
        VAR_L_SLAB_9                   := NULL;
        VAR_L_SLAB_10                  := NULL;
        L_VAR_TYP_CURRENCY.TT_ASK_RATE := 0;
        L_VAR_TYP_CURRENCY.TT_BID_RATE := 0;
      END LOOP;
      return 0;
    EXCEPTION
      WHEN OTHERS THEN
        ora_raiserror(SQLCODE,
                      'EXECUTION OF ap_inquire_bds_rates FAILED',
                      261);
        RETURN - 1;
    END;
  BEGIN
  
    --CHECKING DUPLICATE USER REFERENCE--
    BEGIN
      VAR_L_RETURN_VALUE := AP_VAL_DUP_SVC_REQ(VAR_PI_TRACE_ID,
                                               VAR_PI_CHANNEL_ID,
                                               VAR_PI_SVC_CODE,
                                               VAR_PI_SRV_ID,
                                               VAR_PI_TXN_DATE,
                                               VAR_PIO_ERR_CODE,
                                               VAR_PIO_ERR_MSG);
    
    EXCEPTION
      WHEN OTHERS THEN
        VAR_PIO_ERR_CODE := '1210';
        VAR_PIO_ERR_MSG  := 'DATABASE ERROR: AP_VAL_DUP_SVC_REQ';
        RETURN VAR_L_RETURN_VALUE;
    END;
  
    IF VAR_L_RETURN_VALUE <> 0 THEN
      RETURN VAR_L_RETURN_VALUE;
    END IF;
  
    VAR_RET_VAL := AP_NGI_EXT_INQUIRE_BDS_RATES;
    OPEN CURSNAME FOR
      SELECT NAM_CCY_SHORT,
             DECODE(BASE_CURRENCY, 360, 'IDR', 'USD') AS BASE_CURRENCY,
             TT_BID_RATE,
             TT_ASK_RATE,
             SLAB_1,
             SLAB_2,
             SLAB_3,
             SLAB_4,
             SLAB_5,
             SLAB_6,
             SLAB_7,
             SLAB_8,
             SLAB_9,
             SLAB_10
        FROM inquire_bds_rates
       WHERE session_id = var_l_session_id
         and base_currency = 360
      UNION ALL
      SELECT NAM_CCY_SHORT,
             DECODE(BASE_CURRENCY, 360, 'IDR', 'USD') AS BASE_CURRENCY,
             TT_BID_RATE,
             TT_ASK_RATE,
             SLAB_1,
             SLAB_2,
             SLAB_3,
             SLAB_4,
             SLAB_5,
             SLAB_6,
             SLAB_7,
             SLAB_8,
             SLAB_9,
             SLAB_10
        FROM inquire_bds_rates
       WHERE session_id = var_l_session_id
         and base_currency = 840
         and nam_ccy_short in ('AUD', 'GBP', 'EUR', 'NZD')
      UNION ALL
      SELECT b.NAM_CCY_SHORT,
             a.nam_ccy_short AS BASE_CURRENCY,
             a.TT_BID_RATE,
             a.TT_ASK_RATE,
             a.SLAB_1,
             a.SLAB_2,
             a.SLAB_3,
             a.SLAB_4,
             a.SLAB_5,
             a.SLAB_6,
             a.SLAB_7,
             a.SLAB_8,
             a.SLAB_9,
             a.SLAB_10
        FROM inquire_bds_rates a, ba_ccy_code b
       WHERE session_id = var_l_session_id
         and a.base_currency = b.cod_ccy
         and a.base_currency = 840
         and a.nam_ccy_short not in ('AUD', 'GBP', 'EUR', 'NZD');
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      ora_raiserror(SQLCODE,
                    'EXECUTION OF ap_inquire_bds_rates FAILED',
                    326);
      RETURN - 1;
  END;

END PK_NGI_EXT_INQUIRE_BDS_RATES;

/