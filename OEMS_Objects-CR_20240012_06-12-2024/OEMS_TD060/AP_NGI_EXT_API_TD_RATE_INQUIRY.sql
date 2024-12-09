create or replace procedure AP_NGI_EXT_API_TD_RATE_INQUIRY(o_txn_log_cursor OUT sys_refcursor) AS
begin
  OPEN o_txn_log_cursor FOR
     with t1(indx,
    cod_prod,
    prod_name,
    currency,
    term,
    from_amount,
    rat_var_slab,
    int_rate,
    td_rate) as
     (select rownum, tbl.*
        from (select a.cod_prod,
                     (select nam_product
                        from fcr24.td_prod_mast c
                       where c.cod_prod = a.cod_prod
                         and flg_mnt_status = 'A') as prod_name,
                     (select decode(cod_ccy, '360', '000', cod_ccy)
                        from fcr24.td_prod_mast
                       where cod_prod = a.cod_prod
                         and flg_mnt_status = 'A') as currency,
                     decode(a.ctr_from_term_slab,
                            65536,
                            '1',
                            131095,
                            '3',
                            327703,
                            '6',
                            '524311',
                            '9',
                            '720919',
                            '12') as term,
                     b.ctr_from_amt_slab as from_amount,
                     b.rat_var_slab,
                     (select rat_indx
                        from fcr24.ba_int_indx_rate
                       where cod_int_indx = b.cod_int_index_slab
                         and flg_mnt_status = 'A'
                         and dat_eff_int_indx in
                             (select max(dat_eff_int_indx)
                                from fcr24.ba_int_indx_rate
                               where cod_int_indx = b.cod_int_index_slab
                                 and flg_mnt_status = 'A')) as int_rate,
                     b.rat_var_slab +
                     (select rat_indx
                        from fcr24.ba_int_indx_rate
                       where cod_int_indx = b.cod_int_index_slab
                         and flg_mnt_status = 'A'
                         and dat_eff_int_indx in
                             (select max(dat_eff_int_indx)
                                from fcr24.ba_int_indx_rate
                               where cod_int_indx = b.cod_int_index_slab
                                 and flg_mnt_status = 'A')) as td_rate
                from (select cod_prod,
                             ctr_from_term_slab,
                             max(dat_effective) as max_dat_effective
                        from fcr24.td_prod_rates a
                       where 1 = 1
                         and flg_mnt_status = 'A'
                         and ctr_from_term_slab <> 1
                         and cod_prod in
                             (
                             --DCC
                             65,66,67,68,69,70,72,73,114,115,121,124,125,159,188,216,219,220,258,
                             --EXISTING
                             110, 214, 215, 245, 255, 265, 284, 286,109
                             )
                       group by cod_prod, ctr_from_term_slab
                       order by cod_prod, ctr_from_term_slab) a,
                     fcr24.td_prod_rates b
               where 1 = 1
                 and a.ctr_from_term_slab in
                     (65536, 131095, 327703, 524311, 720919)
                 and a.cod_prod = b.cod_prod
                 and a.ctr_from_term_slab = b.ctr_from_term_slab
                 and a.max_dat_effective = b.dat_effective
               order by a.cod_prod,
                        currency,
                        a.ctr_from_term_slab,
                        b.ctr_from_amt_slab) tbl)
    select a.cod_prod,prod_name,int_rate,rat_var_slab,
           lpad(a.currency, 3, '0') as currency,
           a.term,
           a.FROM_AMOUNT as from_amount,
           decode((select b.FROM_AMOUNT
                    from t1 b
                   where b.indx = a.indx + 1
                     and b.term = a.term
                     and a.cod_prod = b.cod_prod
                     and a.currency = b.currency),
                  null,
                  --999999999999,
                  1000000000000,
                  (select b.FROM_AMOUNT
                     from t1 b
                    where b.indx = a.indx + 1
                      and b.term = a.term
                      and a.cod_prod = b.cod_prod
                      and a.currency = b.currency)) - 1 as to_amount,
           a.td_rate
      from t1 a;
end;