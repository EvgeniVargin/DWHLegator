/*«начени€ переменных выполн€емых запросов */
SELECT *
  FROM V$SQL_BIND_CAPTURE
  WHERE sql_id IN (
SELECT s.SQL_ID
  FROM v$session s
  WHERE s.SID = 902
  ) AND was_captured = 'YES'
