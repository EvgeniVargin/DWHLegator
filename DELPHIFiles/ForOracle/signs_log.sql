WITH
  logs AS (
    SELECT to_number(id||2) AS id,dat,unit,message
      FROM dm_skb.tb_signs_log WHERE dat >= TRUNC(SYSDATE - 5,'DD')
    UNION ALL
    SELECT to_number(id||1) AS id,dat,unit,message
      FROM dwh.t_log WHERE dat >= TRUNC(SYSDATE - 5,'DD')
        --AND message LIKE '%ref_contract_new%'
    ORDER BY dat DESC
  )
  SELECT id,dat,unit,message FROM logs
    WHERE dat >= TRUNC(SYSDATE - 5,'DD') --AND message LIKE '%ERROR%'
      --AND LOWER(unit) LIKE '%load%'
      --AND unit = 'DWH.loadmass_408339'
  ORDER BY dat desc,ID DESC

--DELETE FROM dm_skb.tb_signs_log WHERE dat < to_date('01.02.2018','DD.MM.YYYY')

SELECT * FROM dm_skb.tb_signs_pool ORDER BY ID DESC FOR UPDATE
SELECT * FROM dm_skb.tb_signs_job ORDER BY start_time DESC FOR UPDATE
SELECT * FROM dm_skb.tb_rep_aggr_chunks ORDER BY ID
SELECT * FROM dm_skb.tb_calc_pool ORDER BY ID FOR UPDATE
SELECT * FROM dm_skb.tb_signs_pictures ORDER BY ID FOR UPDATE
SELECT * FROM dm_skb.tb_signs_group ORDER BY group_id
SELECT * FROM dm_skb.tb_entity FOR UPDATE
SELECT * FROM dm_skb.tb_signs_2_group WHERE sign_name = 'CTR_CLOSE_FACT_DATE'--group_id = 53 AND sign_id = 519
SELECT * FROM dm_skb.tb_signs_anlt_spec ORDER BY ID DESC FOR UPDATE
SELECT * FROM dm_skb.tb_sign_2_anlt FOR UPDATE
SELECT * FROM dm_skb.tb_anlt_2_group FOR UPDATE
SELECT * FROM dm_skb.tb_signs_anlt FOR UPDATE
SELECT * FROM dm_skb.tb_version_registry FOR UPDATE
SELECT * FROM dm_skb.tb_tables_registry
SELECT * FROM dm_skb.tb_user_registry

SELECT * FROM dm_skb.tb_signs_calc_stat
  WHERE anlt_code IS NULL AND action = 'CALC'
ORDER BY ID DESC
--DELETE FROM dm_skb.tb_signs_calc_stat WHERE dt < to_date('10.01.2018','DD.MM.YYYY')

SELECT * FROM dm_skb.tb_sign_2_sign WHERE prev_sign_name = 'PR_TOP_UP'

SELECT * FROM dm_Skb.tb_calc_2_calc WHERE unit LIKE '%pkg_etl.tb_fpd_spd_tpd_fact' FOR UPDATE

--UPDATE dm_skb.tb_entity SET parent_id = 42 WHERE parent_id = -1
