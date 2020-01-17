BEGIN
  FOR idx IN (
  SELECT 'BEGIN'||CHR(10)||'  sys.dbms_scheduler.stop_job(job_name => ''' || owner || '.' || job_name || ''', force => true);'||CHR(10)||'END;' AS a
        ,owner || '.' || job_name AS job_name
    FROM sys.dba_scheduler_running_jobs
    WHERE owner = 'DM_SKB'
      AND job_name like 'TASK%'
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE idx.a;
      dbms_output.put_line('SUCCESSFULLY :: '||idx.job_name||' killed');   
    EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line(SQLERRM);
    END;  
  END LOOP;
END;
