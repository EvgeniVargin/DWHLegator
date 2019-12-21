SELECT * FROM dm_skb.t_log
WHERE --dat >= TRUNC(SYSDATE - 3,'DD') --AND LOWER(message) LIKE '%error%' AND osuser = 'oracle'
    dat >= to_date('16.12.2018 1:23:15','DD.MM.YYYY HH24:MI:SS')
  --AND lower(unit) LIKE '%contract%'
  --AND lower(unit) LIKE '%dm_clant.pkg_etl.tb_cl_contracts_all%' 
  --AND message LIKE 'close%'
ORDER BY ID DESC

SELECT task_owner,task_name,status
      ,COUNT(1)
      ,MIN(start_ts) as start_dt
      ,SUBSTR(MAX(end_ts),1,17) AS a
      ,(to_date(SUBSTR(NVL(MAX(end_ts),SYSDATE),1,17),'DD.MM.YY HH24:MI:SS') - to_date(SUBSTR(MIN(start_ts),1,17),'DD.MM.YY HH24:MI:SS'))*24*60 
  FROM Dba_Parallel_Execute_Chunks /*WHERE task_owner = 'DM_CLANT'*/ GROUP BY task_owner,task_name,status ORDER BY task_name,status

--SELECT * FROM Dba_Parallel_Execute_Chunks WHERE task_owner = 'DM_SKB' order by status
--SELECT * FROM Dba_parallel_execute_tasks WHERE task_owner = 'DM_SKB'

/*DECLARE
  vRes VARCHAR2(32700);
BEGIN
  FOR idx IN (
    SELECT task_name FROM Dba_parallel_execute_tasks WHERE task_owner = 'DM_SKB' AND status IN ('FINISHED','CRASHED')
  ) LOOP
    dm_skb.my_execute('BEGIN dbms_parallel_execute.drop_task('''||idx.task_name||'''); END;',vRes);
    dbms_output.put_line(vRes);
    dm_skb.my_execute('DROP TABLE TMP_'||idx.task_name,vRes);
    dbms_output.put_line(vRes);
  END LOOP;
END;*/

/*DECLARE
  vRes VARCHAR2(32700);
BEGIN
  dm_skb.my_execute('BEGIN dbms_parallel_execute.drop_task(''TASK$_2139838''); END;',vRes);
  dbms_output.put_line(vRes);
  dm_skb.my_execute('DROP TABLE TMP_TASK$_2139838',vRes);
  dbms_output.put_line(vRes);
END;*/

/*DECLARE
  vRes VARCHAR2(32700);
BEGIN
  dm_clant.my_execute('BEGIN dbms_parallel_execute.drop_task(''TASK$_2736259''); END;',vRes);
  dbms_output.put_line(vRes);
  dm_clant.my_execute('DROP TABLE TMP_TASK$_2736259',vRes);
  dbms_output.put_line(vRes);
END;*/

/*DECLARE
BEGIN
  dwh.execute_immediate('BEGIN dbms_parallel_execute.drop_task(''TASK$_2181039''); END;');
  dwh.execute_immediate('DROP TABLE TMP_TASK$_2181039');
END;*/

/*BEGIN 
  dbms_stats.gather_table_stats('DM_SKB','TB_CTR_SIGNS','OKVED');
  dbms_stats.gather_table_stats('DM_SKB','TB_CTR_SIGNS','BUSINESS');
END;*/
