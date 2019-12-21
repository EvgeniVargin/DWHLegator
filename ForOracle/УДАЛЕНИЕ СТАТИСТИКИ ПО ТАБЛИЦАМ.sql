BEGIN
  FOR idx IN (
    SELECT owner,table_name
      FROM all_tables
      WHERE owner = 'DM_SKB' AND table_name LIKE 'TB%VALUES'
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'BEGIN dbms_stats.delete_table_stats('''||idx.owner||''','''||idx.table_name||'''); END;';
      dbms_output.put_line('SUCCESSFULLY :: '||idx.owner||'.'||idx.table_name||' - stats dropped');
    EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line('ERROR :: '||idx.owner||'.'||idx.table_name||CHR(10)||SQLERRM);
    END;
  END LOOP;
END;



--SELECT COUNT(1) FROM dm_skb.tb_curid_values PARTITION(DPS_BALANCE)
