WITH
  sgn AS (
    SELECT sign_name,sec FROM (
    SELECT sign_name,ROUND(AVG(sec)) AS sec
      FROM dm_skb.tb_signs_calc_stat
      WHERE ACTION = 'CALC'
        AND dt BETWEEN TRUNC(SYSDATE,'DD') - 7 AND SYSDATE
        AND anlt_code IS NULL
    GROUP BY sign_name
    ORDER BY 2 DESC
    ) WHERE ROWNUM <= 30
  ),
  h AS (
    SELECT to_number(table_id) AS table_id,MAX(dt) AS dt,MAX(os_user) KEEP (dense_rank LAST ORDER BY dt) AS os_user 
      FROM DM_SKB.Tb_Signs_History PARTITION (DM_SKB#TB_SIGNS_POOL) WHERE os_user != 'oracle'
    GROUP BY table_id
  )
SELECT p.sign_name,p.sign_descr,h.dt,h.os_user,ROUND(sgn.sec/60,1) AS sec
  FROM dm_skb.tb_signs_pool p
       INNER JOIN sgn
         ON sgn.sign_name = p.sign_name 
       LEFT JOIN h
         ON to_number(h.table_id) = p.id
ORDER BY 5 DESC

