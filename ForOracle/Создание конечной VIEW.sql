DECLARE
  inGroupID NUMBER := 7;
  vOwner VARCHAR2(30) := 'DM_SKB';

  vSQL CLOB;
  vBuff VARCHAR2(32700);
  vCou INTEGER := 0;
BEGIN
  dbms_lob.createtemporary(vSQL,FALSE);
  vBuff :=
  'WITH'||CHR(10)||
  '  dt AS ('||CHR(10)||
  '    SELECT TRUNC(SYSDATE - 1,''DD'') - LEVEL + 1 AS as_of_date FROM dual'||CHR(10)||
  '    CONNECT BY LEVEL <= TRUNC(SYSDATE - 1,''DD'') - ADD_MONTHS(TRUNC(SYSDATE - 1,''RRRR''),-108) + 1'||CHR(10)||
  '    ORDER BY 1'||CHR(10)||
  '  )'||CHR(10);
  dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);

  FOR idx IN (
    SELECT table_name
          ,LISTAGG(CHR(10)||''''||sign_name||'''',',') WITHIN GROUP (ORDER BY NULL) AS Fields
          ,LISTAGG(CHR(10)||''''||sign_name||''' AS '||sign_name,',') WITHIN GROUP (ORDER BY NULL) AS Fields_A
          ,LISTAGG(CHR(10)||
             CASE WHEN data_type = 'Строка' THEN '        '||LOWER(sign_name)
                  WHEN data_type = 'Число' THEN '        to_number('||LOWER(sign_name)||',''FM999999999999999D999999999'',''nls_numeric_characters='''', '''''')'
               ELSE '        to_date('||LOWER(sign_name)||',''DD.MM.RRRR HH24:MI:SS'')'
             END||' AS '||LOWER(sign_name),',') WITHIN GROUP (ORDER BY NULL) AS Fields_S
          ,hist_flg
          ,entity_id
      FROM (
        SELECT p.sign_name
              ,p.data_type
              ,p.hist_flg
              ,CASE WHEN p.hist_flg = 0 THEN e.fct_table_name ELSE e.hist_table_name END AS table_name
              ,e.id AS entity_id
          FROM tb_signs_2_group s2g
               INNER JOIN tb_signs_pool p
                 ON p.sign_name = s2g.sign_name
               INNER JOIN tb_entity e
                 ON e.id = p.entity_id
          WHERE s2g.group_id = 7--inGroupID
      ) GROUP BY hist_flg,table_name,entity_id
  ) LOOP
    vBuff :=
    ' ,dim_'||idx.entity_id||' AS ('||CHR(10)||
    '    SELECT'||CHR(10)||
    '           as_of_date'||CHR(10)||
    '          ,obj_gid||source_system_id AS obj_sid'||idx.Fields_S||CHR(10)||
    '      FROM ('||CHR(10)||
    '        SELECT dt.as_of_date'||CHR(10)||
    '              ,f.sign_name'||CHR(10)||
    '              ,f.obj_gid'||CHR(10)||
    '              ,f.source_system_id'||CHR(10)||
    '              ,f.sign_val'||CHR(10)||
    '          FROM '||LOWER(vOwner)||'.'||idx.table_name||' f'||CHR(10)||
    '               INNER JOIN dt'||CHR(10)||
    '                 ON dt.as_of_date '||CASE WHEN idx.hist_flg = 1 THEN 'BETWEEN f.effective_start AND f.effective_end' ELSE '= f.as_of_date' END||CHR(10)||
    '          WHERE f.sign_name IN ('||idx.fields||')'||CHR(10)||
    '      ) PIVOT (MAX(sign_val) FOR sign_name IN ('||idx.fields_a||'))'||CHR(10)||
    '  )'||CHR(10);
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
  END LOOP;
  dbms_output.put_line(vSQL);    
END;
