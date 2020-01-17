WITH
  ses AS (
select s.osuser, s.username, SID
      ,sum(u.blocks*vp.value/1024/1024) TEMP_SIZE_MB
      ,t_size.free
      ,program
      ,t_size.total
      ,sum(u.blocks)
      ,s.EVENT
      ,s.P2
      --,x.SORTS
        from   v$session s, V$TEMPSEG_USAGE u, sys.v_$parameter vp--, v$sqlarea x
, (
select sum(s.TOTAL_BLOCKS*t.BLOCK_SIZE)/1024/1024 total, sum(s.free_blocks*t.BLOCK_SIZE)/1024/1024 free
from v$sort_segment s, dba_tablespaces t
where t.tablespace_name = s.tablespace_name
) t_size
        where  s.saddr = u.session_addr and  vp.name = 'db_block_size' --and x.SQL_ID(+) = u.SQL_ID 
having sum(u.blocks*vp.value/1024/1024) > 10 
group by 
s.osuser, s.username, sid, program
,t_size.total, t_size.free
, s.EVENT,s.p2--, x.SORTS
)
SELECT s.OSUSER
        ,s.sid
        ,sl.MESSAGE
        ,ses.event
        --,REGEXP_SUBSTR(SUBSTR(sl.MESSAGE,INSTR(sl.MESSAGE,' : ',1)+3),'*[0-9]{1,}') as a 
        --,REGEXP_SUBSTR(SUBSTR(sl.MESSAGE,INSTR(sl.MESSAGE,' of ',1)+4),'*[0-9]{1,}') as b
        ,ses.TEMP_SIZE_MB
        ,ses.free
        ,s.STATUS
        ,s.STATE 
  FROM v$session s
       LEFT JOIN ses 
         ON ses.sid = s.sid AND ses.osuser = s.osuser
       LEFT JOIN v$session_longops sl
         ON s.SID = sl.SID
            AND sl.SERIAL# = s.SERIAL#
            AND REGEXP_SUBSTR(SUBSTR(sl.MESSAGE,INSTR(sl.MESSAGE,' : ',1)+3),'*[0-9]{3,}') != 
                REGEXP_SUBSTR(SUBSTR(sl.MESSAGE,INSTR(sl.MESSAGE,' of ',1)+4),'*[0-9]{3,}')
            AND NOT(sl.MESSAGE LIKE 'RMAN%')
            AND NOT(sl.MESSAGE LIKE '%SYS.SYS$_TEMP$_%' escape '$')
            
  WHERE (ses.sid IS NOT NULL OR sl.sid IS NOT NULL)
        --s.STATUS = 'ACTIVE'
    --AND s.sid IN (822)
    --AND s.STATUS = 'ACTIVE'
    --AND s.Osuser = 'VarginEV'
ORDER BY  1
--ORDER BY temp_size_mb DESC NULLS LAST


--SELECT SID,message FROM v$session_longops WHERE time_remaining>0
