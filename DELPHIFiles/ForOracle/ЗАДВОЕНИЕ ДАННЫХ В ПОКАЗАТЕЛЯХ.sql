WITH
  s AS (
    SELECT DISTINCT sg.sign_name,e.fct_table_name
      FROM tb_signs_2_group sg
           INNER JOIN tb_signs_pool p ON p.sign_name = sg.sign_name AND p.hist_flg = 0
           INNER JOIN tb_entity e ON e.id = p.entity_id AND fct_table_name = 'ptb_ent_signs'
      WHERE sg.group_id = 9
  )
  --SELECT DISTINCT sign_name FROM (
  SELECT sign_name,obj_gid,source_system_id,COUNT(1)
    FROM dm_skb.ptb_ent_signs
    WHERE as_of_Date = to_Date('08.04.2019','DD.MM.RRRR') 
      AND sign_name IN (SELECT sign_name FROM s)
  GROUP BY sign_name,obj_gid,source_system_id HAVING COUNT(1) > 1
  ORDER BY 4 DESC
  --)

SELECT * FROM dwh.fct_account_entry WHERE as_of_date = to_date('08.04.2019','DD.MM.RRRR') AND SID = 36607939982
--764340294 cred
--764532814 deb
SELECT * FROM dwh.ref_account WHERE account_gid = 72372325 AND source_system_id = 2 AND to_date('08.04.2019','DD.MM.RRRR') BETWEEN effective_start AND effective_end
SELECT * FROM dwh.ref_account_new WHERE account_gid = 72372325 AND source_system_id = 2 AND to_date('08.04.2019','DD.MM.RRRR') BETWEEN effective_start AND effective_end
