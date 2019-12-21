CREATE OR REPLACE PACKAGE DWH.pkg_normalize_ref_table
  IS
vOwner CONSTANT VARCHAR2(256) := 'DWH'; 
    
--TYPE recStr IS RECORD (str VARCHAR2(4000));
TYPE recStr IS RECORD (ord NUMBER,str VARCHAR2(4000));
TYPE tabStr IS TABLE OF recStr;

TYPE TRecCHBuilder IS RECORD 
  (Id VARCHAR2(256),Parent_id VARCHAR2(256),Unit VARCHAR2(256),Params VARCHAR2(4000));
TYPE TTabCHBuilder IS TABLE OF TRecCHBuilder;

FUNCTION get_ti_as_hms (inInterval IN NUMBER /*интервал в днях*/) RETURN VARCHAR2;  
PROCEDURE pr_log_write(inUnit IN VARCHAR2,inMessage IN VARCHAR2);
PROCEDURE MyExecute(inScript IN VARCHAR2); 

FUNCTION parse_str(inStr VARCHAR2,inSeparator IN VARCHAR2) RETURN tabStr PIPELINED;
FUNCTION isEqual(n1 IN NUMBER,n2 IN NUMBER) RETURN NUMBER;
FUNCTION isEqual(v1 IN VARCHAR2,v2 IN VARCHAR2) RETURN NUMBER;
FUNCTION isEqual(d1 IN DATE,d2 IN DATE) RETURN NUMBER;

PROCEDURE prepare_table
  (inFromTable IN VARCHAR2,inUKColumns IN VARCHAR2
  ,inExcludeColumns IN VARCHAR2,inToTable IN VARCHAR2
  ,outRes OUT VARCHAR2,DoTable BOOLEAN DEFAULT TRUE);
    
PROCEDURE prepare_tools
  (inFromTable IN VARCHAR2,inUKColumns IN VARCHAR2,outRes OUT VARCHAR2); 
  
PROCEDURE load_dwh 
/*************************************************************************
 ** Расшифровка маски обработки (если 1 то делать иначе нет):           **
 ** 1-й символ - Загрузка данных                                        **
 ** 2-й символ - Выполнение финишного скрипта                           **
 *************************************************************************/
  (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB DEFAULT NULL,inWorkMask IN VARCHAR2 DEFAULT '10');
PROCEDURE load_dwh_daily
/*************************************************************************
 ** Расшифровка маски обработки (если 1 то делать иначе нет):           **
 ** 1-й символ - Загрузка данных                                        **
 ** 2-й символ - Выполнение финишного скрипта                           **
 *************************************************************************/
  (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inDate IN DATE,inWorkMask IN VARCHAR2 DEFAULT '10');

/*PROCEDURE load_dwh_daily
  (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2
  ,inStartDateColName IN VARCHAR2 DEFAULT 'effective_start' 
  ,inFilter IN VARCHAR2 DEFAULT 'WHERE 1 = 1'
  ,status_out     OUT varchar2
  ,descr_out      OUT VARCHAR2
  ,inWorkMask IN VARCHAR2 DEFAULT '11');*/

PROCEDURE load_column(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB DEFAULT NULL);
PROCEDURE load_column_daily(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inDate IN DATE);
PROCEDURE load_dwh_new 
/*************************************************************************
 ** Расшифровка маски обработки (если 1 то делать иначе нет):           **
 ** 1-й символ - Загрузка данных                                        **
 ** 2-й символ - Выполнение финишного скрипта                           **
 *************************************************************************/
  (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB DEFAULT NULL,inWorkMask IN VARCHAR2 DEFAULT '10');
PROCEDURE reload_column(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2);
PROCEDURE reload_dwh(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2); 
---

PROCEDURE Finishing(inPLSQL IN CLOB,inColName IN VARCHAR2);
FUNCTION Loading(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB,inFinish BOOLEAN DEFAULT FALSE) RETURN VARCHAR2;
FUNCTION Loading_Daily(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inDate IN DATE,inFinish BOOLEAN DEFAULT FALSE) RETURN VARCHAR2;
--FUNCTION Loading(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB,inFinish BOOLEAN DEFAULT FALSE) RETURN VARCHAR2;  


FUNCTION  GetChainList(inSQL IN CLOB) RETURN TTabCHBuilder PIPELINED;
FUNCTION  ChainBuilder(inSQL CLOB) RETURN VARCHAR2;
FUNCTION  ChainStarter(inChainName IN VARCHAR2,inHeadJobName IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;
PROCEDURE ChainKiller(inChainName VARCHAR2);

PROCEDURE LoadNew(inSQL IN CLOB,inJobName IN VARCHAR2 DEFAULT NULL);
PROCEDURE HistTableService(inTableName IN VARCHAR2,inMask IN VARCHAR2
  ,inColumnName VARCHAR2 DEFAULT NULL, inIdxRebuildParallel IN INTEGER DEFAULT 8, inGatherStatsDegree IN INTEGER DEFAULT 2);

END pkg_normalize_ref_table;
/
CREATE OR REPLACE PACKAGE BODY DWH.pkg_normalize_ref_table
  IS

FUNCTION get_ti_as_hms (inInterval IN NUMBER /*интервал в днях*/) RETURN VARCHAR2
  IS
BEGIN
  RETURN TO_CHAR(TRUNC(inInterval*24*60*60/3600))||'h '||TO_CHAR(TRUNC(MOD(inInterval*24*60*60,3600)/60))||'m '||TO_CHAR(ROUND(MOD(MOD(inInterval*24*60*60,3600),60),0))||'s';
END get_ti_as_hms;   
   
PROCEDURE pr_log_write(inUnit IN VARCHAR2,inMessage IN VARCHAR2)
  IS  
    vBuff VARCHAR2(32700);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   vBuff :=
   'BEGIN'||CHR(10)||
   'INSERT INTO '||lower(vOwner)||'.t_log (dat, unit, message) VALUES (SYSDATE,:1,:2);'||CHR(10)||
   'END;';
   EXECUTE IMMEDIATE vBuff USING IN inUnit, IN inMessage;
   COMMIT;
END pr_log_write;

PROCEDURE MyExecute(inScript IN VARCHAR2)  
  IS
BEGIN
  EXECUTE IMMEDIATE inScript;
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.MyExecute','SUCESSFULLY :: '||inScript);
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.MyExecute',SQLERRM);  
END MyExecute;    

FUNCTION parse_str(inStr VARCHAR2,inSeparator IN VARCHAR2) RETURN tabStr PIPELINED
  IS
    rec recStr;
    vExpr VARCHAR2(4000) := inSeparator||inStr||inSeparator;
    vPartCount INTEGER := (LENGTH(inStr) - LENGTH(REPLACE(inStr,inSeparator,'')))/LENGTH(inSeparator) + 1;
BEGIN
  FOR idx IN (
    SELECT LEVEL AS ord
          ,SUBSTR(
             SUBSTR(vExpr
                   ,INSTR(vExpr,inSeparator,1,LEVEL) + LENGTH(inSeparator)
                   ,LENGTH(vExpr))
                 ,1,INSTR(SUBSTR(vExpr
                   ,INSTR(vExpr,inSeparator,1,LEVEL) + LENGTH(inSeparator)
                   ,LENGTH(vExpr)),inSeparator,1,1) - 1) AS a
      FROM dual
    CONNECT BY LEVEL <= vPartCount
  ) LOOP
    rec.ord := idx.ord;
    rec.Str := idx.a;
    PIPE ROW(rec);
  END LOOP;
END parse_str;

FUNCTION isEqual(n1 IN NUMBER,n2 IN NUMBER) RETURN NUMBER
  IS
BEGIN
  IF n1 = n2 OR n1 IS NULL AND n2 IS NULL THEN RETURN 1; ELSE RETURN 0; END IF;
END isEqual;

FUNCTION isEqual(v1 IN VARCHAR2,v2 IN VARCHAR2) RETURN NUMBER
  IS
BEGIN
  IF v1 = v2 OR v1 IS NULL AND v2 IS NULL THEN RETURN 1; ELSE RETURN 0; END IF;
END isEqual;

FUNCTION isEqual(d1 IN DATE,d2 IN DATE) RETURN NUMBER
  IS
BEGIN
  IF d1 = d2 OR d1 IS NULL AND d2 IS NULL THEN RETURN 1; ELSE RETURN 0; END IF;
END isEqual;

PROCEDURE prepare_table
  (inFromTable IN VARCHAR2,inUKColumns IN VARCHAR2
   ,inExcludeColumns IN VARCHAR2,inToTable IN VARCHAR2
   ,outRes OUT VARCHAR2,DoTable BOOLEAN DEFAULT TRUE)
  IS
    stmt VARCHAR2(32700);
    vFromTable VARCHAR2(256);
    vRecType VARCHAR2(256);
    vTabType VARCHAR2(256);
    vGetFunc VARCHAR2(256);
    vRecDaily VARCHAR2(256);
    vTabDaily VARCHAR2(256);
    vGetDaily VARCHAR2(256);
    vLoadDaily VARCHAR2(256);
    vLoadMass VARCHAR2(256);
    vToTable VARCHAR2(256);
    vDestID  NUMBER;
    vDestOwner VARCHAR2(30);
BEGIN
  vDestOwner := UPPER(SUBSTR(inToTable,1,INSTR(inToTable,'.') - 1));
  -- Сохранение в переменные соответствий типов и функций таблице-источнику
  BEGIN
    SELECT lower(owner)||'.'||lower(object_name) AS from_table
          ,vDestOwner||'.'||'rec_getfunc_'||object_id AS rec_type
          ,vDestOwner||'.'||'tab_getfunc_'||object_id AS tab_type
          ,vDestOwner||'.'||'getfunc_'||object_id AS get_func
          ,lower(inToTable) AS to_table
          ,vDestOwner||'.'||'rec_getdaily_'||object_id AS rec_daily_type
          ,vDestOwner||'.'||'tab_getdaily_'||object_id AS tab_daily_type
          ,vDestOwner||'.'||'getdaily_'||object_id AS get_daily
          ,vDestOwner||'.'||'loaddaily_'||object_id AS load_daily
          ,vDestOwner||'.'||'loadmass_'||object_id AS load_mass
      INTO vFromTable,vRecType,vTabType,vGetFunc,vToTable,vRecDaily,vTabDaily,vGetDaily,vLoadDaily,vLoadMass
      FROM all_objects
      WHERE LOWER(owner||'.'||object_name) = lower(inFromTable)
        AND object_type = 'TABLE';
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Указанная таблица-источник "'||lower(inFromTable)||'" не найдена');
  END;
  -- Формирование и сохранение соответствий типов и функций таблице-источнику
  MERGE INTO tb_norm_table dest
    USING (
      SELECT lower(owner)||'.'||lower(object_name) AS from_table
            ,vDestOwner||'.'||'rec_getfunc_'||object_id AS rec_type
            ,vDestOwner||'.'||'tab_getfunc_'||object_id AS tab_type
            ,vDestOwner||'.'||'getfunc_'||object_id AS get_func
            ,lower(inToTable) AS to_table
            ,vDestOwner||'.'||'rec_getdaily_'||object_id AS rec_daily_type
            ,vDestOwner||'.'||'tab_getdaily_'||object_id AS tab_daily_type
            ,vDestOwner||'.'||'getdaily_'||object_id AS get_daily
            ,vDestOwner||'.'||'loaddaily_'||object_id AS load_daily
            ,vDestOwner||'.'||'loadmass_'||object_id AS load_mass
        FROM all_objects
        WHERE LOWER(owner||'.'||object_name) = lower(vFromTable)
          AND object_type = 'TABLE'
    ) src ON (dest.from_table = src.from_table)
    WHEN MATCHED THEN
      UPDATE SET dest.rec_type = src.rec_type
                ,dest.tab_type = src.tab_type
                ,dest.get_func = src.get_func
                ,dest.to_table = src.to_table
                ,dest.rec_daily_type = src.rec_daily_type
                ,dest.tab_daily_type = src.tab_daily_type
                ,dest.get_daily = src.get_daily
                ,dest.load_daily = src.load_daily
                ,dest.load_mass = src.load_mass
        WHERE NVL(dest.rec_type,'0') != NVL(src.rec_type,'0') OR
              NVL(dest.tab_type,'0') != NVL(src.tab_type,'0') OR
              NVL(dest.get_func,'0') != NVL(src.get_func,'0') OR
              NVL(dest.to_table,'0') != NVL(src.to_table,'0') OR
              NVL(dest.rec_daily_type,'0') != NVL(src.rec_daily_type,'0') OR
              NVL(dest.tab_daily_type,'0') != NVL(src.tab_daily_type,'0') OR
              NVL(dest.get_daily,'0') != NVL(src.get_daily,'0') OR
              NVL(dest.load_daily,'0') != NVL(src.load_daily,'0') OR
              NVL(dest.load_mass,'0') != NVL(src.load_mass,'0')
    WHEN NOT MATCHED THEN
      INSERT (dest.from_table,dest.rec_type,dest.tab_type,dest.get_func,dest.to_table,dest.rec_daily_type,dest.tab_daily_type,dest.get_daily,dest.load_daily,dest.load_mass)
        VALUES (src.from_table,src.rec_type,src.tab_type,src.get_func,src.to_table,src.rec_daily_type,src.tab_daily_type,src.get_daily,src.load_daily,src.load_mass);
  COMMIT;
  outRes := 'SUCCESSFULLY :: Links saved into table "'||lower(vOwner)||'.tb_norm_table"'||Chr(10);

  ---
  stmt :=
    'CREATE TABLE '||vToTable||Chr(10)||'('||
    'column_name VARCHAR2(256),'||Chr(10)||
    'start_date DATE,'||Chr(10)||'end_date DATE,'||Chr(10)||
    'effective_start DATE,'||Chr(10)||'effective_end DATE,'||Chr(10);
  FOR idx IN (
    SELECT column_name
          ,data_type
          ,data_length
      FROM all_tab_columns
      WHERE owner||'.'||table_name = UPPER(vFromTable)
        AND column_name IN (SELECT str FROM TABLE(parse_str(inUKColumns,',')))
  ) LOOP
    stmt := stmt||LOWER(idx.column_name)||' '||idx.data_type||CASE WHEN idx.data_type = 'VARCHAR2' THEN '('||idx.data_length||'),'||Chr(10) ELSE ','||Chr(10) END;
  END LOOP;
  stmt := stmt||'val_num NUMBER,'||Chr(10)||'val_str VARCHAR2(4000),'||Chr(10)||'val_date DATE'||Chr(10)||')'||chr(10);
  stmt := stmt||'PARTITION BY LIST(column_name)'||Chr(10)||'SUBPARTITION BY LIST(end_date)'||Chr(10)||'(';
  FOR idx IN (
    SELECT column_name
          ,data_type
          ,DECODE(data_type,'NUMBER','число','VARCHAR2','строка','CHAR','строка','DATE','дата') AS data_descr
          ,data_length
          ,column_id
      FROM all_tab_columns
      WHERE owner||'.'||table_name = UPPER(vFromTable)
        AND NOT(column_name IN (SELECT str FROM TABLE(parse_str(inUKColumns,','))))
        AND NOT(column_name IN ('START_DATE','END_DATE','EFFECTIVE_START','EFFECTIVE_END'))
        AND NOT(column_name IN (SELECT str FROM TABLE(parse_str(inExcludeColumns,','))))
        AND data_type IN ('NUMBER','VARCHAR2','DATE','CHAR')
  )
  LOOP
    stmt := stmt||Chr(10)||'PARTITION '||idx.column_name||' VALUES('''||idx.column_name||''') STORAGE (INITIAL 64K NEXT 64K)COMPRESS'||Chr(10)||
      ' (SUBPARTITION SP'||idx.column_id||'_59991231 VALUES(to_date(''31.12.5999'',''DD.MM.YYYY'')) COMPRESS,'||
      'SUBPARTITION SP'||idx.column_id||'_POTHERS VALUES(DEFAULT) COMPRESS),';
  END LOOP;
  stmt := SUBSTR(stmt,1,LENGTH(stmt)-1)||Chr(10)||') COMPRESS ENABLE ROW MOVEMENT'||Chr(10)||Chr(10);
  IF DoTable THEN 
    BEGIN
      EXECUTE IMMEDIATE stmt;
      outRes := outRes||'SUCCESSFULLY :: Table "'||vToTable||'" created'||Chr(10);
    EXCEPTION WHEN OTHERS THEN 
      outRes := 'ERROR :: '||SQLERRM||Chr(10);
    END;
  END IF;  
  -- Получение id и владельца таблицы-приемника
  BEGIN
    SELECT object_id
          ,owner
      INTO vDestID,vDestOwner
      FROM all_objects
      WHERE LOWER(owner||'.'||object_name) = lower(vToTable)
        AND object_type = 'TABLE';
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Таблица-приемник "'||lower(vToTable)||'" не найдена');
  END;        

  stmt := 'CREATE UNIQUE INDEX '||lower(vDestOwner)||'.uix_'||vDestID||' ON '||lower(vToTable)||' (COLUMN_NAME,END_DATE,';
  FOR idx IN (
    SELECT str FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    stmt := stmt||idx.str||',';
  END LOOP;
  stmt := stmt||'EFFECTIVE_END) LOCAL COMPRESS 3 NOLOGGING';
  EXECUTE IMMEDIATE stmt;
  outRes := outRes||'SUCCESSFULLY :: Unique index "'||lower(vDestOwner)||'.uix_'||vDestID||'" created'||Chr(10);
EXCEPTION WHEN OTHERS THEN
  outRes := 'ERROR :: '||SQLERRM||Chr(10);
END prepare_table;

PROCEDURE prepare_tools
  (inFromTable IN VARCHAR2, inUKColumns IN VARCHAR2, outRes OUT VARCHAR2)
  IS
    stmt CLOB;
    vStr VARCHAR2(32700);
    vFromTable VARCHAR2(256) := lower(inFromTable);
    vRecType VARCHAR2(256);
    vTabType VARCHAR2(256);
    vGetFunc VARCHAR2(256);
    vToTable VARCHAR2(256);
    vRecDailyType VARCHAR2(256);
    vTabDailyType VARCHAR2(256);
    vGetDaily VARCHAR2(256);
    vLoadDaily VARCHAR2(256);
    vLoadMass VARCHAR2(256);
    vUKColumnsINS VARCHAR2(2000);
    vUKColumnsUPD VARCHAR2(2000);
    vUKColumnsSEL1 VARCHAR2(2000);
    vUKColumnsSEL2 VARCHAR2(2000);
    vUKColumnsSEL3 VARCHAR2(2000);
    --
    vCou INTEGER;
BEGIN
  OutRes := '';
  -- Получение данных из таблицы связей tb_norm_table
  BEGIN
    SELECT rec_type,tab_type,get_func,to_table,rec_daily_type,tab_daily_type,get_daily,load_daily,load_mass
      INTO vRecType,vTabType,vGetFunc,vToTable,vRecDailyType,vTabDailyType,vGetDaily,vLoadDaily,vLoadMass
      FROM tb_norm_table
      WHERE from_table = vFromTable;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    outRes := Chr(10)||outRes||'ERROR :: No data exists in table "'||lower(vOwner)||'.ref_norm_table"'; 
  END;  
    
  -- Компиляция типов
  -- Типы для массовых загрузок
  vStr :=
  'DROP TYPE '||vTabType||Chr(10);
  BEGIN
    EXECUTE IMMEDIATE vStr;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vTabType||'" dropped'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vTabType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(vStr);
  END;
  
  vStr :=
  'DROP TYPE '||vRecType||Chr(10);
  BEGIN
    EXECUTE IMMEDIATE vStr;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vRecType||'" dropped'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vRecType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(vStr);
  END;
  
  dbms_lob.createtemporary(stmt,FALSE);
  vStr :=
    'CREATE OR REPLACE TYPE '||vRecType||' AS OBJECT'||Chr(10)||'('||
    'column_name VARCHAR2(256),'||Chr(10)||
    'start_date DATE,'||Chr(10)||'end_date DATE,'||Chr(10)||
    'effective_start DATE,'||Chr(10)||'effective_end DATE,'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  FOR idx IN (
    SELECT column_name
          ,data_type
          ,data_length
      FROM TABLE(parse_str(inUKColumns,',')) t
           INNER JOIN all_tab_columns a ON a.COLUMN_NAME = t.str
      WHERE owner||'.'||table_name = UPPER(vFromTable)
  ) LOOP
    vStr := LOWER(idx.column_name)||' '||idx.data_type||CASE WHEN idx.data_type IN ('VARCHAR2','CHAR') THEN '('||idx.data_length||'),'||Chr(10) ELSE ','||Chr(10) END;
    dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  END LOOP;
  vStr := 'val_num NUMBER,'||Chr(10)||'val_str VARCHAR2(4000),'||Chr(10)||'val_date DATE'||Chr(10)||')'||chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  
  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vRecType||'" compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vRecType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
  dbms_lob.createtemporary(stmt,FALSE);
  vStr := 'CREATE OR REPLACE TYPE '||vTabType||' AS TABLE OF '||vRecType||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  
  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vTabType||'" compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vTabType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
  --Типы для ежедневных загрузок
  vStr :=
  'DROP TYPE '||vTabDailyType||Chr(10);
  BEGIN
    EXECUTE IMMEDIATE vStr;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vTabDailyType||'" dropped'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vTabDailyType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(vStr);
  END;
  
  vStr :=
  'DROP TYPE '||vRecDailyType||Chr(10);
  BEGIN
    EXECUTE IMMEDIATE vStr;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vRecDailyType||'" dropped'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vRecDailyType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(vStr);
  END;
  
  
  dbms_lob.createtemporary(stmt,FALSE);
  vStr :=
    'CREATE OR REPLACE TYPE '||vRecDailyType||' AS OBJECT'||Chr(10)||'('||
    'column_name VARCHAR2(256),'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  FOR idx IN (
    SELECT column_name
          ,data_type
          ,data_length
      FROM TABLE(parse_str(inUKColumns,',')) t
           INNER JOIN all_tab_columns a ON a.COLUMN_NAME = t.str
      WHERE owner||'.'||table_name = UPPER(vFromTable)
  ) LOOP
    vStr := LOWER(idx.column_name)||' '||idx.data_type||CASE WHEN idx.data_type IN ('VARCHAR2','CHAR') THEN '('||idx.data_length||'),'||Chr(10) ELSE ','||Chr(10) END;
    dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  END LOOP;
  vStr :=
    'src_start DATE,'||Chr(10)||'src_end DATE,'||Chr(10)||
    'src_eff_start DATE,'||Chr(10)||'src_eff_end DATE,'||Chr(10)||
    'src_val_num NUMBER,'||Chr(10)||'src_val_str VARCHAR2(4000),'||Chr(10)||'src_val_date DATE,'||Chr(10)||
    'dest_column_name VARCHAR2(256),'||Chr(10)||
    'dest_start DATE,'||Chr(10)||'dest_end DATE,'||Chr(10)||
    'dest_eff_start DATE,'||Chr(10)||'dest_eff_end DATE,'||Chr(10)||
    'dest_val_num NUMBER,'||Chr(10)||'dest_val_str VARCHAR2(4000),'||Chr(10)||'dest_val_date DATE'||Chr(10)||')'||chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  
  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vRecDailyType||'" compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vRecDailyType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
  dbms_lob.createtemporary(stmt,FALSE);
  vStr := 'CREATE OR REPLACE TYPE '||vTabDailyType||' AS TABLE OF '||vRecDailyType||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Type "'||vTabDailyType||'" compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Type "'||vTabDailyType||'" :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
  -- Формирование кода конвейерной функции для массовых загрузок
  dbms_lob.createtemporary(stmt,FALSE);
  vStr := 'CREATE OR REPLACE FUNCTION '||vGetFunc||'(inColName IN VARCHAR2, inColDataType IN VARCHAR2, inWithNulls IN INTEGER DEFAULT 0,inGidsSQL IN CLOB) RETURN '||vTabType||' PIPELINED'||Chr(10)||'  IS'||Chr(10)||
          '    column_name VARCHAR2(256);'||Chr(10)||'    start_date DATE;'||Chr(10)||'    end_date DATE;'||Chr(10)||
          '    effective_start DATE;'||Chr(10)||'    effective_end DATE;'||Chr(10);
  FOR idx IN (
    SELECT column_name
          ,data_type
          ,data_length
      FROM all_tab_columns
      WHERE owner||'.'||table_name = UPPER(vFromTable)
        AND column_name IN (SELECT str FROM TABLE(parse_str(inUKColumns,',')))
  ) LOOP
    vStr := vStr||'    '||LOWER(idx.column_name)||' '||idx.data_type||CASE WHEN idx.data_type = 'VARCHAR2' THEN '('||idx.data_length||');' ELSE ';' END||Chr(10);
  END LOOP;
  vStr := vStr||'    val_num NUMBER;'||Chr(10)||'    val_str VARCHAR2(4000);'||Chr(10)||'    val_date DATE;'||Chr(10)||
          '    vSQL VARCHAR2(32700);'||Chr(10)||'    cur INTEGER;'||Chr(10)||'    ret INTEGER;'||Chr(10)||
          '    rec '||vRecType||';'||Chr(10)||
          'BEGIN'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  ----
  vStr := 
  'vSQL :='||Chr(10)||
  'CASE WHEN inGidsSQL IS NOT NULL THEN ''WITH gids AS (''||inGidsSQL||'')'' END||'||Chr(10)||
  ''''||Chr(10)||
    'SELECT column_name'||Chr(10)||
    '      ,SYSDATE AS start_date'||Chr(10)||
    '      ,to_date(''''31.12.5999'''',''''DD.MM.YYYY'''') AS end_date'||Chr(10)||
    '      ,MIN(effective_start) AS effective_start'||Chr(10)||
    '      ,effective_end'||Chr(10)||
    '      ,'||lower(inUKColumns)||Chr(10)||
    '      ,''||CASE WHEN lower(inColDataType) = ''число'' THEN ''val'' ELSE ''NULL'' END||'' AS val_num'||Chr(10)||
    '      ,''||CASE WHEN lower(inColDataType) = ''строка'' THEN ''val'' ELSE ''NULL'' END||'' AS val_str'||Chr(10)||
    '      ,''||CASE WHEN lower(inColDataType) = ''дата'' THEN ''val'' ELSE ''NULL'' END||'' AS val_date'||Chr(10)||
    '  FROM ('||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
    '        SELECT column_name'||Chr(10)||
    '        ,effective_start'||Chr(10)||
    '        ,NVL2(NVL2(LEAD(next_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start)'||Chr(10)||
    '                  ,LEAD(effective_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) - 1'||Chr(10)||
    '                  ,LEAD(effective_end) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start)),'||Chr(10)||
    '         CASE WHEN next_start - effective_end = 1 THEN'||Chr(10)||
    '             CASE WHEN '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(LEAD(val) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start), val) = 1'||Chr(10)||
    '                THEN LEAD(effective_end) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start)'||Chr(10)||
    '               ELSE LEAD(effective_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) - 1'||Chr(10)||
    '             END'||Chr(10)||
    '           ELSE effective_end END,effective_end) AS effective_end'||Chr(10)||
    '        ,'||lower(inUKColumns)||Chr(10)||
    '        ,val'||Chr(10)||
    '        FROM (SELECT '||lower(inUKColumns)||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
    '                    ,''''''||UPPER(inColName)||'''''' AS column_name'||Chr(10)||
    '                    ,effective_start'||Chr(10)||
    '                    ,LEAD(effective_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) AS next_start'||Chr(10)||
    '                    ,effective_end'||Chr(10)||
    '                    ,''||lower(inColName)||'' AS val'||Chr(10)||
    '                    ,CASE WHEN '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(LAG(''||lower(inColName)||'') OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start), ''||lower(inColName)||'') = 0'||Chr(10)||
    '                       OR effective_start - LAG(effective_end) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) > 1'||Chr(10)||
    '                       OR LEAD(effective_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) - effective_end > 1'||Chr(10)||
    '                    OR LEAD(effective_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) IS NULL'||Chr(10)||
    '                    OR LAG(effective_start) OVER (PARTITION BY '||lower(inUKColumns)||' ORDER BY effective_start) IS NULL THEN 1 ELSE 0 END AS flg'||Chr(10)||
    '                FROM '||vFromTable||Chr(10)||
    '                WHERE end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')''||'||Chr(10)||
    '            CASE WHEN inGidsSQL IS NOT NULL THEN '' AND ('||lower(inUKColumns)||') IN (SELECT '||lower(inUKColumns)||' FROM gids)'' END'||Chr(10)||
    '||'') WHERE flg = 1) WHERE effective_end IS NOT NULL''||CASE WHEN inWithNulls = 0 THEN  '' AND val IS NOT NULL'' END||'''||Chr(10)||
    'GROUP BY column_name,'||lower(inUKColumns)||',effective_end,val'';'||Chr(10);

  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  'cur := dbms_sql.open_cursor;'||Chr(10)||
  'dbms_sql.parse(cur, vSQL, dbms_sql.v7);'||Chr(10)||
  'dbms_sql.define_column(cur,1,column_name,256);'||Chr(10)||
  'dbms_sql.define_column(cur,2,start_date);'||Chr(10)||
  'dbms_sql.define_column(cur,3,end_date);'||Chr(10)||
  'dbms_sql.define_column(cur,4,effective_start);'||Chr(10)||
  'dbms_sql.define_column(cur,5,effective_end);'||Chr(10);
  vCou := 6;
  FOR idx IN (
    SELECT a.str,tc.data_type,tc.data_length 
      FROM TABLE(parse_str(inUKColumns,',')) a
           LEFT JOIN all_tab_columns tc
             ON lower(tc.owner||'.'||tc.table_name) = lower(vFromTable)
                AND tc.column_name = UPPER(a.str)
  ) LOOP
    vStr := vStr||'dbms_sql.define_column(cur,'||to_char(vCou)||','||lower(idx.str)||CASE WHEN idx.data_type IN ('VARCHAR2','CHAR') THEN ','||idx.data_length ELSE '' END||');'||Chr(10);
    vCou := vCou + 1;
  END LOOP;
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  'dbms_sql.define_column(cur,'||to_char(vCou)||',val_num);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+1)||',val_str,4000);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+2)||',val_date);'||Chr(10)||
  'ret := dbms_sql.execute(cur);'||Chr(10)||
  'rec := NEW '||vRecType||'(NULL,NULL,NULL,NULL,NULL,';
  FOR idx IN (SELECT NULL FROM TABLE(parse_str(inUKColumns,','))) LOOP
    vStr := vStr||'NULL,';
  END LOOP;
  vStr := vStr||'NULL,NULL,NULL);'||Chr(10)||
  'LOOP'||Chr(10)||
  'IF  dbms_sql.fetch_rows(cur) > 0   THEN'||Chr(10)||
  'dbms_sql.column_value(cur,1,rec.column_name);'||Chr(10)||
  'dbms_sql.column_value(cur,2,rec.start_date);'||Chr(10)||
  'dbms_sql.column_value(cur,3,rec.end_date);'||Chr(10)||
  'dbms_sql.column_value(cur,4,rec.effective_start);'||Chr(10)||
  'dbms_sql.column_value(cur,5,rec.effective_end);'||Chr(10);
  vCou := 6;
  FOR idx IN (
    SELECT str FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    vStr := vStr||'dbms_sql.column_value(cur,'||to_char(vCou)||',rec.'||lower(idx.str)||');'||Chr(10);
    vCou := vCou + 1;
  END LOOP;
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  'dbms_sql.column_value(cur,'||to_char(vCou)||',rec.val_num);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+1)||',rec.val_str);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+2)||',rec.val_date);'||Chr(10)||
  'PIPE ROW(rec); ELSE EXIT; END IF;'||Chr(10)||
  'END LOOP;'||Chr(10)||
  'dbms_sql.close_cursor(cur);'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr := 'END '||SUBSTR(vGetFunc,INSTR(vGetFunc,'.',1)+1,length(vGetFunc)-INSTR(vGetFunc,'.',1))||';';
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);

  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Function '||vGetFunc||' compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Function '||vGetFunc||' not compiled :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);

  -- Формирование кода конвейерной функции для ежедневных загрузок
  dbms_lob.createtemporary(stmt,FALSE);
  vStr := 'CREATE OR REPLACE FUNCTION '||vGetDaily||'(inColName IN VARCHAR2, inColDataType IN VARCHAR2, inStartDateColName IN VARCHAR2,inFilter IN VARCHAR2) RETURN '||vTabDailyType||' PIPELINED'||Chr(10)||'  IS'||Chr(10)||
          '    column_name VARCHAR2(256);'||Chr(10);
  FOR idx IN (
    SELECT column_name
          ,data_type
          ,data_length
      FROM all_tab_columns
      WHERE owner||'.'||table_name = UPPER(vFromTable)
        AND column_name IN (SELECT str FROM TABLE(parse_str(inUKColumns,',')))
  ) LOOP
    vStr := vStr||'    '||LOWER(idx.column_name)||' '||idx.data_type||CASE WHEN idx.data_type = 'VARCHAR2' THEN '('||idx.data_length||');' ELSE ';' END||Chr(10);
  END LOOP;
  vStr := vStr||
          '    src_start DATE;'||Chr(10)||'    src_end DATE;'||Chr(10)||
          '    src_eff_start DATE;'||Chr(10)||'    src_eff_end DATE;'||Chr(10)||
          '    src_val_num NUMBER;'||Chr(10)||'    src_val_str VARCHAR2(4000);'||Chr(10)||'    src_val_date DATE;'||Chr(10)||
          '    dest_column_name VARCHAR2(256);'||Chr(10)||
          '    dest_start DATE;'||Chr(10)||'    dest_end DATE;'||Chr(10)||
          '    dest_eff_start DATE;'||Chr(10)||'    dest_eff_end DATE;'||Chr(10)||
          '    dest_val_num NUMBER;'||Chr(10)||'    dest_val_str VARCHAR2(4000);'||Chr(10)||'    dest_val_date DATE;'||Chr(10)||
          '    rec '||vRecDailyType||';'||Chr(10)||
          '    vSQL VARCHAR2(32700);'||Chr(10)||'    cur INTEGER;'||Chr(10)||'    ret INTEGER;'||Chr(10)||
          'BEGIN'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  ----
  vStr := 
  'vSQL :='||Chr(10)||
  ''''||Chr(10)||
  '    SELECT src.column_name AS column_name'||CHR(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  FOR col IN (
    SELECT str FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    vStr := '          ,src.'||lower(col.str)||CHR(10);
    dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  END LOOP;
  vStr :=
  '          ,src.start_date AS src_start'||CHR(10)||
  '          ,src.end_date AS src_end'||CHR(10)||
  '          ,TRUNC(src.effective_start,''''DD'''') AS src_eff_start'||CHR(10)||
  '          ,TRUNC(src.effective_end,''''DD'''') AS src_eff_end'||CHR(10)||
  '          ,src.val_num AS src_val_num'||CHR(10)||
  '          ,src.val_str AS src_val_str'||CHR(10)||
  '          ,src.val_date'||CHR(10)||
  '          ,dest.column_name AS dest_column_name'||CHR(10)||
  '          ,dest.start_date AS dest_start'||CHR(10)||
  '          ,dest.end_date AS dest_end'||CHR(10)||
  '          ,TRUNC(dest.effective_start,''''DD'''') AS dest_eff_start'||CHR(10)||
  '          ,TRUNC(dest.effective_end,''''DD'''') AS dest_eff_end'||CHR(10)||
  '          ,dest.val_num'||CHR(10)||
  '          ,dest.val_str'||CHR(10)||
  '          ,dest.val_date'||CHR(10)||
  '      FROM ('||CHR(10)||
  '        SELECT ''''''||UPPER(inColName)||'''''' AS column_name'||CHR(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  FOR col IN (
    SELECT str FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    vStr := '              ,'||lower(col.str)||CHR(10);
    dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  END LOOP;
  vStr :=
  '              ,SYSDATE AS start_date'||CHR(10)||
  '              ,to_date(''''31.12.5999'''',''''DD.MM.YYYY'''') AS end_date'||CHR(10)||
  '              ,''||lower(inStartDateColName)||'' AS effective_start'||CHR(10)||
  '              ,effective_end'||CHR(10)||
  '            ,''||CASE WHEN inColDataType = ''число'' THEN inColName ELSE ''NULL'' END||'' AS val_num'||CHR(10)||
  '            ,''||CASE WHEN inColDataType = ''строка'' THEN inColName ELSE ''NULL'' END||'' AS val_str'||CHR(10)||
  '            ,''||CASE WHEN inColDataType = ''дата'' THEN inColName ELSE ''NULL'' END||'' AS val_date'||CHR(10)||
  '          FROM '||inFromTable||' ''||inFilter||'''||CHR(10)||
  '    ) src LEFT JOIN '||vToTable||' dest'||CHR(10)||
  '      ON dest.column_name = ''''''||UPPER(inColName)||'''''''||CHR(10)||
  '         AND dest.end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')'||CHR(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  FOR col IN (
    SELECT str FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    vStr := '         AND dest.'||lower(col.str)||' = src.'||lower(col.str)||CHR(10);
    dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  END LOOP;
  vStr :=
  '         AND src.effective_start BETWEEN dest.effective_start AND dest.effective_end'||CHR(10)||
  '      WHERE ''||CASE WHEN inColDataType = ''число'' THEN ''NVL(dest.val_num,0) != NVL(src.val_num,0)'''||Chr(10)||
  '                     WHEN inColDataType = ''строка'' THEN ''NVL(dest.val_str,''''###'''') != NVL(src.val_str,''''###'''')'''||Chr(10)||
  '                ELSE ''NVL(dest.val_date,to_date(''''01.01.0001'''',''''DD.MM.YYYY'''')) != NVL(src.val_date,to_date(''''01.01.0001'''',''''DD.MM.YYYY''''))'' END;'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  --'dbms_output.put_line(vSQL);'||Chr(10)||
  'cur := dbms_sql.open_cursor;'||Chr(10)||
  'dbms_sql.parse(cur, vSQL, dbms_sql.v7);'||Chr(10)||
  'dbms_sql.define_column(cur,1,column_name,256);'||Chr(10);
  vCou := 2;
  FOR idx IN (
    SELECT a.str,tc.data_type,tc.data_length 
      FROM TABLE(parse_str(inUKColumns,',')) a
           LEFT JOIN all_tab_columns tc
             ON lower(tc.owner||'.'||tc.table_name) = lower(vFromTable)
                AND tc.column_name = UPPER(a.str)
  ) LOOP
    vStr := vStr||'dbms_sql.define_column(cur,'||to_char(vCou)||','||lower(idx.str)||CASE WHEN idx.data_type IN ('VARCHAR2','CHAR') THEN ','||idx.data_length ELSE '' END||');'||Chr(10);
    vCou := vCou + 1;
  END LOOP;
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  'dbms_sql.define_column(cur,'||to_char(vCou)||',src_start);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+1)||',src_end);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+2)||',src_eff_start);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+3)||',src_eff_end);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+4)||',src_val_num);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+5)||',src_val_str,4000);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+6)||',src_val_date);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+7)||',dest_column_name,256);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+8)||',dest_start);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+9)||',dest_end);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+10)||',dest_eff_start);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+11)||',dest_eff_end);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+12)||',dest_val_num);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+13)||',dest_val_str,4000);'||Chr(10)||
  'dbms_sql.define_column(cur,'||to_char(vCou+14)||',dest_val_date);'||Chr(10)||
  'ret := dbms_sql.execute(cur);'||Chr(10)||
  'rec := NEW '||vRecDailyType||'(NULL,';
  FOR idx IN (
    SELECT NULL FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    vStr := vStr||'NULL,';
  END LOOP;
  vStr := vStr||'NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);'||Chr(10)||
  'LOOP'||Chr(10)||
  'IF  dbms_sql.fetch_rows(cur) > 0   THEN'||Chr(10)||
  'dbms_sql.column_value(cur,1,rec.column_name);'||Chr(10);
  vCou := 2;
  FOR idx IN (
    SELECT str FROM TABLE(parse_str(inUKColumns,','))
  ) LOOP
    vStr := vStr||'dbms_sql.column_value(cur,'||to_char(vCou)||',rec.'||lower(idx.str)||');'||Chr(10);
    vCou := vCou + 1;
  END LOOP;
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  'dbms_sql.column_value(cur,'||to_char(vCou)||',rec.src_start);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+1)||',rec.src_end);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+2)||',rec.src_eff_start);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+3)||',rec.src_eff_end);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+4)||',rec.src_val_num);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+5)||',rec.src_val_str);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+6)||',rec.src_val_date);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+7)||',rec.dest_column_name);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+8)||',rec.dest_start);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+9)||',rec.dest_end);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+10)||',rec.dest_eff_start);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+11)||',rec.dest_eff_end);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+12)||',rec.dest_val_num);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+13)||',rec.dest_val_str);'||Chr(10)||
  'dbms_sql.column_value(cur,'||to_char(vCou+14)||',rec.dest_val_date);'||Chr(10)||
  'PIPE ROW(rec); ELSE EXIT; END IF;'||Chr(10)||
  'END LOOP;'||Chr(10)||
  'dbms_sql.close_cursor(cur);'||Chr(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr := 'END '||SUBSTR(vGetDaily,INSTR(vGetDaily,'.',1)+1,length(vGetDaily)-INSTR(vGetDaily,'.',1))||';';
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);

  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Function '||vGetDaily||' compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Function '||vGetDaily||' not compiled :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
  -- Формирование процедуры загрузки для ежедневных загрузок
  FOR idx IN (
    SELECT a.str,tc.data_type,tc.data_length 
      FROM TABLE(parse_str(inUKColumns,',')) a
           LEFT JOIN all_tab_columns tc
             ON lower(tc.owner||'.'||tc.table_name) = lower(vFromTable)
                AND tc.column_name = UPPER(a.str)
  ) LOOP
    
    vUKColumnsINS := vUKColumnsINS||CASE WHEN idx.data_type IN ('VARCHAR2','CHAR') THEN '''''''||idx.'||LOWER(idx.str)||'||''''''''||'''
                                         WHEN idx.data_type = 'DATE' THEN 'to_date(''''''||to_char(idx.'||LOWER(idx.str)||',''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS'''')'
                                      ELSE '''||idx.'||LOWER(idx.str)||'||''' END||',';
    vUKColumnsUPD := vUKColumnsUPD||LOWER(idx.str)||' = '||CASE WHEN idx.data_type IN ('VARCHAR2','CHAR') THEN '''''''||idx.'||LOWER(idx.str)||'||'''''''
                                                                WHEN idx.data_type = 'DATE' THEN 'to_date(''''''||to_char(idx.'||LOWER(idx.str)||',''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS'''')'
                                                             ELSE '''||idx.'||LOWER(idx.str)||'||''' END||' AND ';
    vUKColumnsSEL1 := vUKColumnsSEL1||'s.'||LOWER(idx.str)||' = d.'||LOWER(idx.str)||' AND ';
    vUKColumnsSEL2 := vUKColumnsSEL2||'p.'||LOWER(idx.str)||' = d.'||LOWER(idx.str)||' AND ';
    vUKColumnsSEL3 := vUKColumnsSEL3||'d.'||LOWER(idx.str)||',';
  END LOOP;
  vUKColumnsINS := SUBSTR(vUKColumnsINS,1,LENGTH(vUKColumnsINS) - 2);
  vUKColumnsUPD := SUBSTR(vUKColumnsUPD,1,LENGTH(vUKColumnsUPD) - 5);
  vUKColumnsSEL1 := SUBSTR(vUKColumnsSEL1,1,LENGTH(vUKColumnsSEL1) - 5);
  vUKColumnsSEL2 := SUBSTR(vUKColumnsSEL2,1,LENGTH(vUKColumnsSEL2) - 5);
  vUKColumnsSEL3 := SUBSTR(vUKColumnsSEL3,1,LENGTH(vUKColumnsSEL3) - 1);

  dbms_lob.createtemporary(stmt,FALSE);
  vStr :=
  'CREATE OR REPLACE PROCEDURE '||vLoadDaily||CHR(10)||
  ' (inColName IN VARCHAR2,'||CHR(10)||
  '  inColDataType IN VARCHAR2,'||CHR(10)||
  '  inStartDateColName IN VARCHAR2,'||CHR(10)||
  '  vStat OUT VARCHAR2,'||CHR(10)||
  '  vDescr OUT VARCHAR2,'||CHR(10)||
  '  inFilter IN VARCHAR2 DEFAULT ''WHERE 1 = 1'','||CHR(10)||
  '  inColsWithNulls VARCHAR2 DEFAULT NULL)'||CHR(10)||
  '  IS'||CHR(10)||
  '    buff VARCHAR2(32700);'||CHR(10)||
  '    vCou INTEGER := 0;'||CHR(10)||
  'BEGIN'||CHR(10)||
  '  FOR idx IN ('||CHR(10)||
  '    SELECT d.column_name'||CHR(10)||
  '          ,'||lower(vUKColumnsSEL3)||CHR(10)||
  '          ,src_start'||CHR(10)||
  '          ,src_end'||CHR(10)||
  '          ,src_eff_start'||CHR(10)||
  '          ,src_eff_end'||CHR(10)||
  '          ,REPLACE(to_char(src_val_num,''FM999999999999999D999999999'',''nls_numeric_characters='''', ''''''),'','',''.'') as src_val_num'||CHR(10)||
  '          ,REPLACE(src_val_str,'''''''',''''''||CHR(39)||'''''') AS src_val_str'||CHR(10)||
  '          ,src_val_date'||CHR(10)||
  '          ,dest_column_name'||CHR(10)||
  '          ,dest_start'||CHR(10)||
  '          ,dest_end'||CHR(10)||
  '          ,dest_eff_start'||CHR(10)||
  '          ,dest_eff_end'||CHR(10)||
  '          ,dest_val_num'||CHR(10)||
  '          ,dest_val_str'||CHR(10)||
  '          ,dest_val_date'||CHR(10)||
  '          ,MIN(s.effective_start) AS vNextEff'||CHR(10)||
  '          ,REPLACE(to_char(MIN(s.val_num) KEEP (dense_rank FIRST ORDER BY s.effective_start),''FM999999999999999D999999999'',''nls_numeric_characters='''', ''''''),'','',''.'') AS vNextNum'||CHR(10)||
  '          ,MIN(s.val_str) KEEP (dense_rank FIRST ORDER BY s.effective_start) AS vNextStr'||CHR(10)||
  '          ,MIN(s.val_date) KEEP (dense_rank FIRST ORDER BY s.effective_start) AS vNextDate'||CHR(10)||
  '          ,MAX(p.effective_end) AS vPrevEff'||CHR(10)||
  '          ,REPLACE(to_char(MAX(p.val_num) KEEP (dense_rank LAST ORDER BY p.effective_start),''FM999999999999999D999999999'',''nls_numeric_characters='''', ''''''),'','',''.'') AS vPrevNum'||CHR(10)||
  '          ,MAX(p.val_str) KEEP (dense_rank LAST ORDER BY p.effective_start) AS vPrevStr'||CHR(10)||
  '          ,MAX(p.val_date) KEEP (dense_rank LAST ORDER BY p.effective_start) AS vPrevDate'||CHR(10)||
  '      FROM TABLE('||vGetDaily||'(LOWER(inColName),LOWER(inColDataType)'||CHR(10)||
  '                                     ,LOWER(inStartDateColName),inFilter)) d'||CHR(10)||
  '           LEFT JOIN '||vToTable||' s '||CHR(10)||
  '             ON s.column_name = UPPER(d.column_name)'||CHR(10)||
  '                AND s.end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
  '                AND '||vUKColumnsSEL1||CHR(10)||
  '                AND s.effective_start > d.src_eff_start'||CHR(10)||
  '           LEFT JOIN '||vToTable||' p '||CHR(10)||
  '             ON p.column_name = UPPER(d.column_name)'||CHR(10)||
  '                AND p.end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
  '                AND '||vUKColumnsSEL2||CHR(10)||
  '                AND p.effective_end < d.src_eff_start'||CHR(10)||
  '    GROUP BY d.column_name'||CHR(10)||
  '          ,'||lower(vUKColumnsSEL3)||CHR(10)||
  '          ,src_start'||CHR(10)||
  '          ,src_end'||CHR(10)||
  '          ,src_eff_start'||CHR(10)||
  '          ,src_eff_end'||CHR(10)||
  '          ,src_val_num'||CHR(10)||
  '          ,src_val_str'||CHR(10)||
  '          ,src_val_date'||CHR(10)||
  '          ,dest_column_name'||CHR(10)||
  '          ,dest_start'||CHR(10)||
  '          ,dest_end'||CHR(10)||
  '          ,dest_eff_start'||CHR(10)||
  '          ,dest_eff_end'||CHR(10)||
  '          ,dest_val_num'||CHR(10)||
  '          ,dest_val_str'||CHR(10)||
  '          ,dest_val_date'||CHR(10)||
  '  ) LOOP'||CHR(10)||
  '    IF idx.dest_column_name IS NULL THEN'||CHR(10)||
  '      IF idx.vNextEff - idx.src_eff_end <= 1'||CHR(10)||
  '         AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_num,idx.vNextNum) = 1 '||Chr(10)||
  '         AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_str,idx.vNextStr) = 1 '||Chr(10)||
  '         AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_date,idx.vNextDate) = 1 '||Chr(10)||
  '         THEN'||CHR(10)||
  '           buff :='||CHR(10)||
  '           ''UPDATE '||vToTable||' SET effective_start = to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY''''), start_date = SYSDATE''||CHR(10)||'||CHR(10)||
  '           ''  WHERE column_name = ''''''||UPPER(idx.column_name)||''''''''||CHR(10)||'||CHR(10)||
  '           ''    AND end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '           ''    AND '||vUKColumnsUPD||'''||CHR(10)||'||CHR(10)||
  '           ''    AND to_date(''''''||to_char(idx.vNextEff,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') BETWEEN effective_start AND effective_end'';'||CHR(10)||
  '      ELSIF idx.src_eff_start - idx.vPrevEff = 1'||Chr(10)||
  '            AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_num,idx.vPrevNum) = 1 '||Chr(10)||
  '            AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_str,idx.vPrevStr) = 1 '||Chr(10)||
  '            AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_date,idx.vPrevDate) = 1 '||Chr(10)||
  '         THEN'||CHR(10)||
  '           buff :='||CHR(10)||
  '           ''UPDATE '||vToTable||' SET effective_end = to_date(''''''||NVL(to_char(idx.vNextEff - 1,''DD.MM.YYYY''),to_char(idx.src_eff_end,''DD.MM.YYYY''))||'''''',''''DD.MM.YYYY''''), start_date = SYSDATE''||CHR(10)||'||CHR(10)||
  '           ''  WHERE column_name = ''''''||UPPER(idx.column_name)||''''''''||CHR(10)||'||CHR(10)||
  '           ''    AND end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '           ''    AND '||vUKColumnsUPD||'''||CHR(10)||'||CHR(10)||
  '           ''    AND to_date(''''''||to_char(idx.vPrevEff,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') BETWEEN effective_start AND effective_end'';'||CHR(10)||
  '      ELSE'||CHR(10)||
  '        IF idx.src_val_num IS NOT NULL OR idx.src_val_str IS NOT NULL OR idx.src_val_date IS NOT NULL OR INSTR(UPPER(inColsWithNulls),UPPER(inColName),1) > 0 THEN'||CHR(10)||
  '          buff :='||CHR(10)||
  '          ''INSERT INTO '||vToTable||' (column_name,start_date,end_date,effective_start,effective_end,'||lower(inUKColumns)||',val_num,val_str,val_date)''||CHR(10)||'||CHR(10)||
  '          ''  VALUES (''''''||UPPER(idx.column_name)||'''''',to_date(''''''||to_char(idx.src_start,''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS'''')''||CHR(10)||'||CHR(10)||
  '          ''         ,to_date(''''''||to_char(idx.src_end,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '          ''         ,to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '          ''         ,to_date(''''''||NVL(to_char(idx.vNextEff - 1,''DD.MM.YYYY''),to_char(idx.src_eff_end,''DD.MM.YYYY''))||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '          ''         ,'||vUKColumnsINS||'CHR(10)||'||CHR(10)||
  '          CASE WHEN LOWER(inColDataType) = ''число'' THEN'||CHR(10)||
  '          ''         ,''||idx.src_val_num||CHR(10)||'||CHR(10)||
  '          ''         ,NULL''||CHR(10)||'||CHR(10)||
  '          ''         ,NULL)'''||CHR(10)||
  '               WHEN LOWER(inColDataType) = ''строка'' THEN'||CHR(10)||
  '          ''         ,NULL''||CHR(10)||'||CHR(10)||
  '          ''         ,''''''||idx.src_val_str||''''''''||CHR(10)||'||CHR(10)||
  '          ''         ,NULL)'''||CHR(10)||
  '          ELSE'||CHR(10)||
  '          ''         ,NULL''||CHR(10)||'||CHR(10)||
  '          ''         ,NULL''||CHR(10)||'||CHR(10)||
  '          ''         ,to_date(''''''||to_char(idx.src_val_date,''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS''''))'''||CHR(10)||
  '          END;'||CHR(10)||
  '        END IF;'||CHR(10)||
  '      END IF;'||CHR(10)||
--  '      dbms_output.put_line(buff);'||CHR(10)||
  '      EXECUTE IMMEDIATE buff;'||CHR(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  '    ELSE'||CHR(10)||
  '      IF idx.src_eff_start = idx.dest_eff_start THEN'||CHR(10)||
  '        buff :='||CHR(10)||
  '        ''UPDATE '||vToTable||' SET end_date = SYSDATE''||CHR(10)||'||CHR(10)||
  '        ''  WHERE column_name = ''''''||UPPER(idx.column_name)||''''''''||CHR(10)||'||CHR(10)||
  '        ''    AND end_date = to_date(''''31.12.5999'''')''||CHR(10)||'||CHR(10)||
  '        ''    AND '||vUKColumnsUPD||'''||CHR(10)||'||CHR(10)||
  '        ''    AND to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') BETWEEN effective_start AND effective_end'';'||CHR(10)||
  '        EXECUTE IMMEDIATE buff;'||CHR(10)||
  '        IF idx.vNextEff - idx.src_eff_end <= 1 '||Chr(10)||
  '           AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_num,idx.vNextNum) = 1 '||Chr(10)||
  '           AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_str,idx.vNextStr) = 1 '||Chr(10)||
  '           AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_date,idx.vNextDate) = 1 THEN'||CHR(10)||
  '          buff :='||CHR(10)||
  '          ''UPDATE '||vToTable||' SET effective_start = to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY''''), start_date = SYSDATE''||CHR(10)||'||CHR(10)||
  '          ''  WHERE column_name = ''''''||UPPER(idx.column_name)||''''''''||CHR(10)||'||CHR(10)||
  '          ''    AND end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '          ''    AND '||vUKColumnsUPD||'''||CHR(10)||'||CHR(10)||
  '          ''    AND to_date(''''''||to_char(idx.vNextEff,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') BETWEEN effective_start AND effective_end'';'||CHR(10)||
  '        ELSE'||CHR(10)||
  '          IF idx.src_val_num IS NOT NULL OR idx.src_val_str IS NOT NULL OR idx.src_val_date IS NOT NULL OR INSTR(UPPER(inColsWithNulls),UPPER(inColName),1) > 0 THEN'||CHR(10)||
  '            buff :='||CHR(10)||
  '            ''INSERT INTO '||vToTable||' (column_name,start_date,end_date,effective_start,effective_end,'||lower(inUKColumns)||',val_num,val_str,val_date)''||CHR(10)||'||CHR(10)||
  '            ''  VALUES (''''''||UPPER(idx.column_name)||'''''',to_date(''''''||to_char(idx.src_start,''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||to_char(idx.src_end,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||NVL(to_char(idx.vNextEff - 1,''DD.MM.YYYY''),to_char(idx.src_eff_end,''DD.MM.YYYY''))||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,'||vUKColumnsINS||'CHR(10)||'||CHR(10)||
  '            CASE WHEN LOWER(inColDataType) = ''число'' THEN'||CHR(10)||
  '            ''         ,''||idx.src_val_num||CHR(10)||'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,NULL)''||CHR(10)'||CHR(10)||
  '                 WHEN LOWER(inColDataType) = ''строка'' THEN'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,''''''||idx.src_val_str||''''''''||CHR(10)||'||CHR(10)||
  '            ''         ,NULL)''||CHR(10)'||CHR(10)||
  '            ELSE'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||to_char(idx.src_val_date,''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS''''))'''||CHR(10)||
  '            END;'||CHR(10)||
  '          END IF;'||CHR(10)||
  '        END IF;'||CHR(10)||
  '        EXECUTE IMMEDIATE buff;'||CHR(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  vStr :=
  '      ELSE'||CHR(10)||
  '        buff :='||CHR(10)||
  '        ''UPDATE '||vToTable||'''||CHR(10)||'||CHR(10)||
  '        ''  SET effective_end = to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') - 1''||CHR(10)||'||CHR(10)||
  '        ''     ,start_date = SYSDATE''||CHR(10)||'||CHR(10)||
  '        ''  WHERE column_name = ''''''||UPPER(idx.column_name)||''''''''||CHR(10)||'||CHR(10)||
  '        ''    AND end_date = to_date(''''31.12.5999'''')''||CHR(10)||'||CHR(10)||
  '        ''    AND '||vUKColumnsUPD||'''||CHR(10)||'||CHR(10)||
  '        ''    AND to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') BETWEEN effective_start AND effective_end'';'||CHR(10)||
  '        EXECUTE IMMEDIATE buff;'||CHR(10)||
  '        IF idx.vNextEff - idx.src_eff_end <= 1 '||Chr(10)||
  '           AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_num,idx.vNextNum) = 1 '||Chr(10)||
  '           AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_str,idx.vNextStr) = 1 '||Chr(10)||
  '           AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val_date,idx.vNextDate) = 1 THEN'||CHR(10)||
  '          buff :='||CHR(10)||
  '          ''UPDATE '||vToTable||' SET effective_start = to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY''''), start_date = SYSDATE''||CHR(10)||'||CHR(10)||
  '          ''  WHERE column_name = ''''''||UPPER(idx.column_name)||''''''''||CHR(10)||'||CHR(10)||
  '          ''    AND end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '          ''    AND '||vUKColumnsUPD||'''||CHR(10)||'||CHR(10)||
  '          ''    AND to_date(''''''||to_char(idx.vNextEff,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''') BETWEEN effective_start AND effective_end'';'||CHR(10)||
  '        ELSE'||CHR(10)||
  '          IF idx.src_val_num IS NOT NULL OR idx.src_val_str IS NOT NULL OR idx.src_val_date IS NOT NULL OR INSTR(UPPER(inColsWithNulls),UPPER(inColName),1) > 0 THEN'||CHR(10)||
  '            buff :='||CHR(10)||
  '            ''INSERT INTO '||vToTable||' (column_name,start_date,end_date,effective_start,effective_end,'||lower(inUKColumns)||',val_num,val_str,val_date)''||CHR(10)||'||CHR(10)||
  '            ''  VALUES (''''''||UPPER(idx.column_name)||'''''',to_date(''''''||to_char(idx.src_start,''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||to_char(idx.src_end,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||to_char(idx.src_eff_start,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||NVL(to_char(idx.vNextEff - 1,''DD.MM.YYYY''),to_char(idx.src_eff_end,''DD.MM.YYYY''))||'''''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '            ''         ,'||vUKColumnsINS||'CHR(10)||'||CHR(10)||
  '            CASE WHEN LOWER(inColDataType) = ''число'' THEN'||CHR(10)||
  '            ''         ,''||idx.src_val_num||CHR(10)||'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,NULL)'''||CHR(10)||
  '                 WHEN LOWER(inColDataType) = ''строка'' THEN'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,''''''||idx.src_val_str||''''''''||CHR(10)||'||CHR(10)||
  '            ''         ,NULL)'''||CHR(10)||
  '            ELSE'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,NULL''||CHR(10)||'||CHR(10)||
  '            ''         ,to_date(''''''||to_char(idx.src_val_date,''DD.MM.YYYY HH24:MI:SS'')||'''''',''''DD.MM.YYYY HH24:MI:SS''''))'''||CHR(10)||
  '            END;'||CHR(10)||
  '          END IF;'||CHR(10)||
  '        END IF;'||CHR(10)||
  '        EXECUTE IMMEDIATE buff;'||CHR(10)||
  '      END IF;'||CHR(10)||
  '    END IF;'||CHR(10)||
  '    vCou := vCou + 1;'||CHR(10)||
  '  END LOOP;'||CHR(10)||
  '  COMMIT;'||CHR(10)||
  '  vStat := ''SUCCESSFULLY'';'||Chr(10)||
  '  vDescr := ''"''||UPPER(inColName)||''" - ''||to_char(vCou)||'' rows proccessed in table '||vToTable||''';'||CHR(10)||
  'EXCEPTION WHEN OTHERS THEN'||CHR(10)||
  '  vStat := ''ERROR'';'||Chr(10)||
  '  vDescr := SQLERRM||Chr(10)||buff;'||CHR(10)||
  'END;'||CHR(10);
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  
  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Procedure '||vLoadDaily||' compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Procedure '||vLoadDaily||' not compiled :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
  -- Формирование процедуры загрузки для массовых загрузок
  dbms_lob.createtemporary(stmt,FALSE);
  vStr :=
  'CREATE OR REPLACE PROCEDURE '||vLoadMass||CHR(10)||
  ' (inColName IN VARCHAR2,'||CHR(10)||
  '  inColDataType IN VARCHAR2,'||CHR(10)||
  --'  vOut OUT VARCHAR2,'||CHR(10)||
  '  inColsWithNulls IN VARCHAR2 DEFAULT NULL,'||CHR(10)||
  '  inGidsSQL IN CLOB DEFAULT NULL)'||CHR(10)||
  '  IS'||CHR(10)||
  'BEGIN'||CHR(10)||
  'IF inGidsSQL IS NOT NULL THEN'||CHR(10)||
  '  EXECUTE IMMEDIATE'||CHR(10)||
  '  ''BEGIN''||CHR(10)||'||CHR(10)||
  '  ''  DELETE FROM '||vToTable||' WHERE column_name = ''''''||UPPER(inColName)||'''''' AND end_date = to_date(''''31.12.5999'''',''''DD.MM.YYYY'''')''||CHR(10)||'||CHR(10)||
  '  ''    AND ('||lower(inUKColumns)||') IN (''||inGidsSQL||'');''||CHR(10)||'||CHR(10)||
  '  '' '||LOWER(vOwner)||'.pkg_normalize_ref_table.pr_log_write('''''||vLoadMass||''''',''''SUCCESSFULLY :: "''||UPPER(inColName)||''" - ''''||SQL%ROWCOUNT||'''' rows deleted from "'||vToTable||'"'''');''||CHR(10)||'||CHR(10)||
  '  '' COMMIT;''||CHR(10)||'||CHR(10)||
  '  '' END;'';'||CHR(10)||
  'ELSE'||CHR(10)||
  '  EXECUTE IMMEDIATE ''ALTER TABLE '||vToTable||' TRUNCATE PARTITION ''||UPPER(inColName);'||CHR(10)||
  '  EXECUTE IMMEDIATE ''BEGIN '||LOWER(vOwner)||'.pkg_normalize_ref_table.pr_log_write('''''||vLoadMass||''''',''''SUCCESSFULLY :: Partition "''||UPPER(inColName)||''" truncated in "'||vToTable||'"''''); END;'';'||CHR(10)||
  'END IF;';
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);

  vStr :=
  'INSERT INTO '||vToTable||CHR(10)||
  ' (column_name'||CHR(10)||
  ' ,start_date'||CHR(10)||
  ' ,end_date'||CHR(10)||
  ' ,effective_start'||CHR(10)||
  ' ,effective_end'||CHR(10)||
  ' ,'||lower(inUKColumns)||CHR(10)||
  ' ,val_num'||CHR(10)||
  ' ,val_str'||CHR(10)||
  ' ,val_date)'||CHR(10)||
  '  SELECT column_name'||CHR(10)||
  '        ,start_date'||CHR(10)||
  '        ,end_date'||CHR(10)||
  '        ,effective_start'||CHR(10)||
  '        ,effective_end'||CHR(10)||
  '        ,'||lower(inUKColumns)||CHR(10)||
  '        ,val_num'||CHR(10)||
  '        ,val_str'||CHR(10)||
  '        ,val_date'||CHR(10)||
  '            FROM TABLE('||vGetFunc||'(lower(inColName),lower(inColDataType),SIGN(NVL(INSTR(UPPER(inColsWithNulls),UPPER(inColName)),0)),inGidsSQL));'||CHR(10)||
  LOWER(vOwner)||'.pkg_normalize_ref_table.pr_log_write('''||vLoadMass||''',''SUCCESSFULLY :: "''||UPPER(inColName)||''" - ''||SQL%ROWCOUNT||'' rows inserted into "'||vToTable||'"'');'||CHR(10)||
--  '  vOut := to_char(SQL%ROWCOUNT)||'' rows proccessed in table '||vToTable||''';'||CHR(10)||
  'COMMIT;'||CHR(10)||
  'EXCEPTION WHEN OTHERS THEN'||CHR(10)||
  LOWER(vOwner)||'.pkg_normalize_ref_table.pr_log_write('''||vLoadMass||''',''ERROR :: ''||SQLERRM);'||CHR(10)||
--  '  vOut := SQLERRM;'||CHR(10)||
  'END;';
  dbms_lob.writeappend(stmt,LENGTH(vStr),vStr);
  
  BEGIN
    EXECUTE IMMEDIATE stmt;
    outRes := outRes||'SUCCESSFULLY :: Procedure '||vLoadMass||' compiled'||Chr(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'ERROR :: Procedure '||vLoadMass||' not compiled :: '||SQLERRM||Chr(10);
    dbms_output.put_line(stmt);
  END;
  dbms_lob.freetemporary(stmt);
  
EXCEPTION WHEN OTHERS THEN
  outRes := 'ERROR :: '||SQLERRM;
END prepare_tools;

PROCEDURE load_dwh (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB DEFAULT NULL
         ,inWorkMask IN VARCHAR2 DEFAULT '10')
  IS
    vFromTable VARCHAR2(256);
    vLoadMass VARCHAR2(256);
    vToTable VARCHAR2(256);
    vDoLoad BOOLEAN := SUBSTR(inWorkMask,1,1) = 1;
    vDoFinish BOOLEAN := SUBSTR(inWorkMask,2,1) = 1;
    -- Для логирования
    vMes VARCHAR2(32700);
    vStageBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  -- Сохранение в переменные соответствий типов и функций таблице-источнику
  BEGIN
    SELECT from_table,load_mass,to_table
      INTO vFromTable,vLoadMass,vToTable
      FROM tb_norm_table
      WHERE from_table = lower(inFromTable) AND to_table = lower(inToTable);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Загрузка "'||lower(inFromTable)||' -> '||lower(inToTable)||'" не подготовлена');
  END;
  
  vMes := 'START :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" started.';
  pr_log_write(vLoadMass,vMes);
  
  IF vDoLoad THEN
    vMes := 'CONTINUE :: ---- Начало загрузки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" ----';
    pr_log_write(vLoadMass,vMes);
    
    vStageBegin := SYSDATE;
    ChainKiller(Loading(inFromTable,inToTable,inColName,inGidsSQL,FALSE));
    
    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ---- Окончание загрузки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'". Время выполнения '||get_ti_as_hms(vEndTime - vStageBegin)||' ----';
    pr_log_write(vLoadMass,vMes);
  END IF;
  
  IF vDoFinish THEN
    vMes := 'CONTINUE :: ---- Начало финишной обработки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" ----';
    pr_log_write(vLoadMass,vMes);
    
    vStageBegin := SYSDATE;
    ChainKiller(Loading(inFromTable,inToTable,inColName,inGidsSQL,TRUE));
    
    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ---- Окончание финишной обработки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'". Время выполнения '||get_ti_as_hms(vEndTime - vStageBegin)||' ----';
    pr_log_write(vLoadMass,vMes);
  END IF;
    
  vMes := 'FINISH :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(vLoadMass,vMes);
EXCEPTION WHEN OTHERS THEN 
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" :: '||SQLERRM;
  pr_log_write(vLoadMass,vMes);
  vMes := 'FINISH :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(vLoadMass,vMes);
END load_dwh;

PROCEDURE load_dwh_daily (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inDate IN DATE
         ,inWorkMask IN VARCHAR2 DEFAULT '10')
  IS
    vFromTable VARCHAR2(256);
    --vLoadMass VARCHAR2(256);
    vToTable VARCHAR2(256);
    vDoLoad BOOLEAN := SUBSTR(inWorkMask,1,1) = 1;
    vDoFinish BOOLEAN := SUBSTR(inWorkMask,2,1) = 1;
    -- Для логирования
    vMes VARCHAR2(32700);
    vStageBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  -- Сохранение в переменные соответствий типов и функций таблице-источнику
  BEGIN
    SELECT from_table/*,load_mass*/,to_table
      INTO vFromTable/*,vLoadMass*/,vToTable
      FROM tb_norm_table
      WHERE from_table = lower(inFromTable) AND to_table = lower(inToTable);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Загрузка "'||lower(inFromTable)||' -> '||lower(inToTable)||'" не подготовлена');
  END;
  
  vMes := 'START :: Daily load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" started.';
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
  
  IF vDoLoad THEN
    vMes := 'CONTINUE :: ---- Начало загрузки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" ----';
    pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
    
    vStageBegin := SYSDATE;
    ChainKiller(Loading_Daily(inFromTable,inToTable,inColName,inDate,FALSE));
    
    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ---- Окончание загрузки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'". Время выполнения '||get_ti_as_hms(vEndTime - vStageBegin)||' ----';
    pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
  END IF;
  
  IF vDoFinish THEN
    vMes := 'CONTINUE :: ---- Начало финишной обработки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" ----';
    pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
    
    vStageBegin := SYSDATE;
    ChainKiller(Loading_Daily(inFromTable,inToTable,inColName,inDate,TRUE));
    
    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ---- Окончание финишной обработки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'". Время выполнения '||get_ti_as_hms(vEndTime - vStageBegin)||' ----';
    pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
  END IF;
    
  vMes := 'FINISH :: Daily load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
EXCEPTION WHEN OTHERS THEN 
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Daily load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
  vMes := 'FINISH :: Daily load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.load_dwh_daily',vMes);
END load_dwh_daily;

/*PROCEDURE load_dwh_daily 
  (inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2
  ,inStartDateColName IN VARCHAR2 DEFAULT 'effective_start' 
  ,inFilter IN VARCHAR2 DEFAULT 'WHERE 1 = 1'
  ,status_out     OUT varchar2
  ,descr_out      OUT VARCHAR2
  ,inWorkMask IN VARCHAR2 DEFAULT '11')
  IS
    vTask VARCHAR2(256) := dbms_parallel_execute.generate_task_name;
    vFromTable VARCHAR2(256);
    vLoadDaily VARCHAR2(256);
    vFilter VARCHAR2(4000) := REPLACE(inFilter,'''','''||CHR(39)||CHR(39)||''');
    vToTable VARCHAR2(256);
    vPLev NUMBER;
    vTry NUMBER;
    vStatus NUMBER;
    --dtStartLoad date := sysdate;
    vcnt varchar2(1000);
    vSQL CLOB;
    vColsWithNulls VARCHAR2(4000);
    vPrev BOOLEAN := SUBSTR(inWorkMask,1,1) = '1';
    vPost BOOLEAN := SUBSTR(inWorkMask,2,1) = '1';
BEGIN
  -- Парсинг наименований колонок для загрузки, выделение тех, которые надо грузить с NULL'ами
  BEGIN
    SELECT LISTAGG(REPLACE(str,'::WITHNULLS',NULL),',') WITHIN GROUP (ORDER BY str)
      INTO vColsWithNulls
      FROM TABLE(parse_str(inColName,','))
      WHERE str LIKE '%::WITHNULLS';
  EXCEPTION WHEN NO_DATA_FOUND THEN
    vColsWithNulls := ''; 
  END;
  -- Сохранение в переменные соответствий типов и функций таблице-источнику
  BEGIN
    SELECT from_table,load_daily,to_table,post_plsql
      INTO vFromTable,vLoadDaily,vToTable,vSQL
      FROM tb_norm_table
      WHERE from_table = lower(inFromTable) AND to_table = lower(inToTable);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Загрузка "'||lower(inFromTable)||' -> '||lower(inToTable)||'" не подготовлена');
  END;
  
  vSQL := REPLACE(vSQL,'''','''||CHR(39)||CHR(39)||''');
  
  IF vPrev THEN
    -- Основная обработка данных
    pr_log_write(lower(inToTable),'CONTINUE :: ---------- "'||lower(inToTable)||'" - начало основной загрузки ---------------');
    -- Создание временной таблицы
    EXECUTE IMMEDIATE 
    --dbms_output.put_line(
      'CREATE TABLE '||lower(vOwner)||'.tmp_'||vTask||' AS'||Chr(10)||
      'SELECT rownum as id,
              ''DECLARE vStat VARCHAR2(32700); vDescr VARCHAR2(32700); BEGIN '||vLoadDaily||'(''''''||lower(c.column_name)||'''''',''''''||CASE WHEN data_type IN (''VARCHAR2'',''CHAR'') THEN ''строка'' WHEN data_type IN (''NUMBER'',''INTEGER'') THEN ''число'' ELSE ''дата'' END||'''''','''''||lower(inStartDateColName)||''''',vStat,vDescr,'''''||vFilter||''''''||CASE WHEN vColsWithNulls IS NOT NULL THEN ','''''||vColsWithNulls||'''''' ELSE '' END||'); :1 := vStat; :2 := vDescr; END;'' as exec_sql,'||Chr(10)||
      '''"UNKNOWN COLUMN NAME PREPARED" - 0 rows proccessed in table '||vToTable||''' as descr'||Chr(10)||       
      '    FROM all_tab_columns c
               INNER JOIN all_tab_partitions a
                 ON c.column_name = a.partition_name
                    AND lower(a.table_owner||''.''||a.table_name) = '''||vToTable||'''
          WHERE lower(c.owner||''.''||c.table_name) = '''||vFromTable||'''
            AND ('''||UPPER(inColName)||''' IS NULL OR '''||UPPER(inColName)||''' IS NOT NULL AND c.column_name IN (SELECT str FROM TABLE('||LOWER(vOwner)||'.pkg_normalize_ref_table.parse_str('''||REPLACE(UPPER(inColName),'::WITHNULLS','')||''','',''))))' 
      --)
      ;
          
      --Наименование задачи
      DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => vTask);
      -- Вычисление количества потоков
      SELECT TRUNC(to_number(VALUE)/5*4) INTO vPLev FROM v$parameter WHERE NAME = 'job_queue_processes';
      --Раскладка по потокам
      DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL
        (task_name => vTask
        ,sql_stmt =>'SELECT id,id FROM '||lower(vOwner)||'.tmp_'||vTask||' ORDER BY 1'
        ,by_rowid => FALSE
        );
        
      --Запуск задачи на выполнение
      DBMS_PARALLEL_EXECUTE.RUN_TASK (task_name => vTask,
         sql_stmt => 'declare
                        vSQL VARCHAR2(4000);
                        vStat VARCHAR2(32700);
                        vDescr VARCHAR2(32700);
                      begin
                         SELECT exec_sql INTO vSQL
                           FROM '||lower(vOwner)||'.tmp_'||vTask||'
                           WHERE id = :start_id AND id = :end_id
                         ;
                        execute immediate vSQL using OUT vStat, OUT vDescr;
                        UPDATE '||lower(vOwner)||'.tmp_'||vTask||' SET descr = vDescr WHERE id = :start_id;
                        '||LOWER(vOwner)||'.pkg_normalize_ref_table.pr_log_write('''||lower(inToTable)||''',vStat||'' :: ''||vDescr);
                        commit;
                      end;'
         ,language_flag => DBMS_SQL.NATIVE
         , parallel_level => vPLev );

      --Финишный контроль и удаление задачи
      vTry := 0;
      vStatus := DBMS_PARALLEL_EXECUTE.task_status(vTask);

      WHILE(vTry < 2 and vStatus != DBMS_PARALLEL_EXECUTE.FINISHED)
      LOOP
        vTry := vTry + 1;
        DBMS_PARALLEL_EXECUTE.resume_task(vTask);
        vStatus := DBMS_PARALLEL_EXECUTE.task_status(vTask);
      END LOOP;

      DBMS_PARALLEL_EXECUTE.drop_task(vTask);

    begin
     EXECUTE IMMEDIATE 'select SUM(to_number(SUBSTR(descr,INSTR(descr,''- '')+2,INSTR(descr,'' rows'')-INSTR(descr,''- '') - 2))) from '||lower(vOwner)||'.tmp_'||vTask
       INTO vCnt;
     
    exception
      when others then 
        vcnt := 'unknown';
    end;
    
    -- Удаление временной таблицы
    EXECUTE IMMEDIATE 'DROP TABLE '||lower(vOwner)||'.tmp_'||vTask;

    status_out := 'SUCCESS';
    descr_out := 'SUCCESS :: MAIN loading :: Load new rows: ' || vcnt;
    
    pr_log_write(lower(inToTable),'CONTINUE :: ---------- "'||lower(inToTable)||'" - окончание основной загрузки ---------------');
  END IF;
  IF vPost THEN
    IF vSQL IS NOT NULL THEN
      -- Финишная обработка (закрытие effective_end например)
      pr_log_write(lower(inToTable),'CONTINUE :: ---------- "'||lower(inToTable)||'" - начало финишной обработки ---------------');
      vTask := dbms_parallel_execute.generate_task_name;
      -- Создание временной таблицы
      EXECUTE IMMEDIATE 
      --dbms_output.put_line(
        'CREATE TABLE '||lower(vOwner)||'.tmp_'||vTask||' AS'||Chr(10)||
        'SELECT rownum as id,
                ''DECLARE vStat VARCHAR2(32700); vDescr VARCHAR2(32700); BEGIN '||CHR(10)||
                 '  EXECUTE IMMEDIATE ''''''||'''||vSQL||''''' USING IN ''''''||c.column_name||'''''',OUT vStat,OUT vDescr;  :1 := vStat; :2 := vDescr; '||CHR(10)||
                 --'  :1 := vStat; :2 := vDescr;'||CHR(10)||
                 'END;'' as exec_sql,'||Chr(10)||
        '''"UNKNOWN COLUMN NAME PREPARED" - 0 rows proccessed in table '||vToTable||''' as descr'||Chr(10)||       
        '    FROM all_tab_columns c
                 INNER JOIN all_tab_partitions a
                   ON c.column_name = a.partition_name
                      AND lower(a.table_owner||''.''||a.table_name) = '''||vToTable||'''
            WHERE lower(c.owner||''.''||c.table_name) = '''||vFromTable||'''
              AND ('''||UPPER(inColName)||''' IS NULL OR '''||UPPER(inColName)||''' IS NOT NULL AND c.column_name IN (SELECT str FROM TABLE('||LOWER(vOwner)||'.pkg_normalize_ref_table.parse_str('''||REPLACE(UPPER(inColName),'::WITHNULLS','')||''','',''))))' 
        --)
        ;
       
        --Наименование задачи
        DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => vTask);
        -- Вычисление количества потоков
        SELECT TRUNC(to_number(VALUE)/5*4) INTO vPLev FROM v$parameter WHERE NAME = 'job_queue_processes';
        --Раскладка по потокам
        
        DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL
          (task_name => vTask
          ,sql_stmt =>'SELECT id,id FROM '||lower(vOwner)||'.tmp_'||vTask||' ORDER BY 1'
          ,by_rowid => FALSE
          );
          
        --Запуск задачи на выполнение
        DBMS_PARALLEL_EXECUTE.RUN_TASK (task_name => vTask,
           sql_stmt => 'declare
                          vSQL VARCHAR2(4000);
                          vStat VARCHAR2(32700);
                          vDescr VARCHAR2(32700);
                        begin
                           SELECT exec_sql INTO vSQL
                             FROM '||lower(vOwner)||'.tmp_'||vTask||'
                             WHERE id = :start_id AND id = :end_id
                           ;
                          execute immediate vSQL using OUT vStat, OUT vDescr;
                          UPDATE '||lower(vOwner)||'.tmp_'||vTask||' SET descr = vDescr WHERE id = :start_id;
                          '||LOWER(vOwner)||'.pkg_normalize_ref_table.pr_log_write('''||lower(inToTable)||''',vStat||'' :: ''||vDescr);
                          commit;
                        end;'
           ,language_flag => DBMS_SQL.NATIVE
           , parallel_level => vPLev );

        --Финишный контроль и удаление задачи
        vTry := 0;
        vStatus := DBMS_PARALLEL_EXECUTE.task_status(vTask);

        WHILE(vTry < 2 and vStatus != DBMS_PARALLEL_EXECUTE.FINISHED)
        LOOP
          vTry := vTry + 1;
          DBMS_PARALLEL_EXECUTE.resume_task(vTask);
          vStatus := DBMS_PARALLEL_EXECUTE.task_status(vTask);
        END LOOP;

        DBMS_PARALLEL_EXECUTE.drop_task(vTask);

      begin
       EXECUTE IMMEDIATE 'select SUM(to_number(SUBSTR(descr,INSTR(descr,''- '')+2,INSTR(descr,'' rows'')-INSTR(descr,''- '') - 2))) from '||lower(vOwner)||'.tmp_'||vTask
         INTO vCnt;
       
      exception
        when others then 
          vcnt := 'unknown';
      end;
      
      -- Удаление временной таблицы
      EXECUTE IMMEDIATE 'DROP TABLE '||lower(vOwner)||'.tmp_'||vTask;

      status_out := 'SUCCESS';
      descr_out := descr_out||CHR(10)||'SUCCESS :: POST proccessing :: Proccessed rows: ' || vcnt;
      pr_log_write(lower(inToTable),'CONTINUE :: ---------- "'||lower(inToTable)||'" - окончание финишной обработки ---------------');
    END IF;
  END IF;  
EXCEPTION WHEN OTHERS THEN 
  DBMS_PARALLEL_EXECUTE.drop_task(vTask);
  EXECUTE IMMEDIATE 'DROP TABLE '||lower(vOwner)||'.tmp_'||vTask; 
  status_out := 'ERROR';
  descr_out := '';
END load_dwh_daily;*/

PROCEDURE load_column(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB DEFAULT NULL)
  IS
    vFromTable VARCHAR2(256) := LOWER(inFromTable);
    vToTable VARCHAR2(256) := LOWER(inToTable);
    vColName VARCHAR2(4000) := REPLACE(UPPER(inColName),'::WITHNULLS','');
    vDataType VARCHAR2(256);
    vTableOwner VARCHAR2(30) := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1));
    vTableName VARCHAR2(30) := UPPER(SUBSTR(vToTable,INSTR(vToTable,'.',1,1) + 1));
    vFromTableOwner VARCHAR2(30) := UPPER(SUBSTR(vFromTable,1,INSTR(vFromTable,'.',1,1) - 1));
    vFromTableName VARCHAR2(30) := UPPER(SUBSTR(vFromTable,INSTR(vFromTable,'.',1,1) + 1));
    vCol VARCHAR2(1000);
    vSrcCol VARCHAR2(2000);
    vJoinCol VARCHAR2(4000);
    vSQL CLOB;
    --
    vRes INTEGER;
    vMes VARCHAR2(4000);
    vStageBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Mass load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" started.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);

  -- Ключевые поля
  SELECT LOWER(LISTAGG(c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('src.'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('dest.'||c.column_name||' = src.'||c.column_name,' AND ') WITHIN GROUP (ORDER BY c.column_position))
        --,LOWER(i.table_owner||'.TMP_'||i.index_name)
    INTO vCol,vSrcCol,vJoinCol
    FROM all_indexes i
         INNER JOIN all_ind_columns c
           ON c.index_owner = i.owner
              AND c.index_name = i.index_name
              AND NOT c.column_name IN ('COLUMN_NAME','END_DATE','EFFECTIVE_END')
    WHERE i.table_owner = vTableOwner
      AND i.table_name = vTableName
      AND i.uniqueness = 'UNIQUE';
  
  -- Тип данных колонки
  SELECT data_type INTO vDataType
    FROM all_tab_columns
    WHERE owner = vFromTableOwner AND table_name = vFromTableName AND column_name = vColName;

  IF inGidsSQL IS NOT NULL THEN
    vStageBegin := SYSDATE;
    vSQL :=
    'BEGIN'||CHR(10)||
    '  DELETE FROM '||vToTable||CHR(10)||
    '    WHERE column_name = '''||vColName||''''||CHR(10)||
    '      AND end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
    '      AND ('||vCol||') IN ('||inGidsSQL||');'||CHR(10)||
    '  :1 := SQL%ROWCOUNT;'||CHR(10)||
    '  COMMIT;'||CHR(10)||
    'END;';
    
    EXECUTE IMMEDIATE vSQL USING OUT vRes;
    --dbms_output.put_line(vSQL);

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||lower(vFromTable)||' -> '||lower(vToTable)||'" - column "'||UPPER(vColName)||'" - '||vRes||' rows deleted from table "'||vToTable||'" in '||get_ti_as_hms(vEndTime - vStageBegin);
    pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);
  ELSE
    vStageBegin := SYSDATE;
    vSQL := 'ALTER TABLE '||vToTable||' TRUNCATE PARTITION '||vColName;
    EXECUTE IMMEDIATE vSQL;
    --dbms_output.put_line(vSQL);

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||lower(vFromTable)||' -> '||lower(vToTable)||'" - Partition '||UPPER(vColName)||' truncated in '||get_ti_as_hms(vEndTime - vStageBegin);
    pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);
  END IF;

  vStageBegin := SYSDATE;
  vSQL :=
  'BEGIN'||CHR(10)||
  '  INSERT INTO '||vToTable||CHR(10)||
  '    (column_name'||CHR(10)||
  '    ,start_date'||CHR(10)||
  '    ,end_date'||CHR(10)||
  '    ,effective_start'||CHR(10)||
  '    ,effective_end'||CHR(10)||
  '    ,'||vCol||CHR(10)||
  '    ,val_num'||CHR(10)||
  '    ,val_str'||CHR(10)||
  '    ,val_date)'||CHR(10)||
  CASE WHEN inGidsSQL IS NOT NULL THEN 'WITH gids AS ('||inGidsSQL||')' END||
  '  SELECT column_name
           ,SYSDATE AS start_date
           ,to_date(''31.12.5999'',''DD.MM.YYYY'') AS end_date
           ,MIN(effective_start) AS effective_start
           ,effective_end
           ,'||vCol||'
           ,'||CASE WHEN vDataType IN ('INTEGER','NUMBER') THEN 'val' ELSE 'NULL' END||' AS val_num
           ,'||CASE WHEN vDataType IN ('VARCHAR2') THEN 'val' ELSE 'NULL' END||' AS val_str
           ,'||CASE WHEN vDataType IN ('DATE') THEN 'val' ELSE 'NULL' END||' AS val_date
       FROM (SELECT column_name
                   ,effective_start
                   ,NVL2(NVL2(LEAD(next_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start)
                      ,LEAD(effective_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) - 1
                      ,LEAD(effective_end) OVER (PARTITION BY '||vCol||' ORDER BY effective_start)),
             CASE WHEN next_start - effective_end = 1 THEN
                 CASE WHEN dwh.pkg_normalize_ref_table.isEqual(LEAD(val) OVER (PARTITION BY '||vCol||' ORDER BY effective_start), val) = 1
                    THEN LEAD(effective_end) OVER (PARTITION BY '||vCol||' ORDER BY effective_start)
                   ELSE LEAD(effective_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) - 1
                 END
               ELSE effective_end END,effective_end) AS effective_end
            ,'||vCol||'
            ,val
            FROM (SELECT /*+ no_index(a) */
                         '||vCol||'
                        ,'''||vColName||''' AS column_name
                        ,effective_start
                        ,LEAD(effective_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) AS next_start
                        ,effective_end
                        ,'||lower(vColName)||' AS val
                        ,CASE WHEN dwh.pkg_normalize_ref_table.isEqual(LAG('||lower(vColName)||') OVER (PARTITION BY '||vCol||' ORDER BY effective_start), '||lower(vColName)||') = 0
                           OR effective_start - LAG(effective_end) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) > 1
                           OR LEAD(effective_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) - effective_end > 1
                        OR LEAD(effective_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) IS NULL
                        OR LAG(effective_start) OVER (PARTITION BY '||vCol||' ORDER BY effective_start) IS NULL THEN 1 ELSE 0 END AS flg
                    FROM '||vFromTable||' a
                    WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||
                CASE WHEN inGidsSQL IS NOT NULL THEN ' AND ('||vCol||') IN (SELECT '||vCol||' FROM gids)' END
    ||') WHERE flg = 1) WHERE effective_end IS NOT NULL'||CASE WHEN INSTR(UPPER(inColName),'::WITHNULLS',1,1) = 0 THEN  ' AND val IS NOT NULL' END||'
     GROUP BY column_name,'||vCol||',effective_end,val;'||CHR(10)||
  '  :1 := SQL%ROWCOUNT;'||CHR(10)||
  '  COMMIT;'||CHR(10)||
  'END;';

  EXECUTE IMMEDIATE vSQL USING OUT vRes;
  --dbms_output.put_line(vSQL);

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: "'||lower(vFromTable)||' -> '||lower(vToTable)||'" - column "'||UPPER(vColName)||'" - '||vRes||' rows inserted into table "'||vToTable||'" in '||get_ti_as_hms(vEndTime - vStageBegin);
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);
  
  vMes := 'FINISH :: Mass load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);
EXCEPTION WHEN OTHERS THEN 
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Mass load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" :: '||SQLERRM||CHR(10)||'---'||CHR(10)||vSQL;
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);
  vMes := 'FINISH :: Mass load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column',vMes);
END load_column;

PROCEDURE load_column_daily(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inDate IN DATE)
  IS
    vFromTable VARCHAR2(256) := LOWER(inFromTable);
    vToTable VARCHAR2(256) := LOWER(inToTable);
    vColName VARCHAR2(4000) := REPLACE(UPPER(inColName),'::WITHNULLS','');
    vValColName VARCHAR2(256);
    vTableOwner VARCHAR2(30) := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1));
    vTableName VARCHAR2(30) := UPPER(SUBSTR(vToTable,INSTR(vToTable,'.',1,1) + 1));
    vFromTableOwner VARCHAR2(30) := UPPER(SUBSTR(vFromTable,1,INSTR(vFromTable,'.',1,1) - 1));
    vFromTableName VARCHAR2(30) := UPPER(SUBSTR(vFromTable,INSTR(vFromTable,'.',1,1) + 1));
    vCol VARCHAR2(1000);
    vColSimple VARCHAR2(1000);
    vSrcSimple VARCHAR2(1000);
    vIdxSimple VARCHAR2(1000);
    vSrcCol VARCHAR2(2000);
    vChCol VARCHAR2(2000);
    vJoinCol VARCHAR2(4000);
    vSJoinCol VARCHAR2(4000);
    vPJoinCol VARCHAR2(4000);
    vUpdJoinCol VARCHAR2(4000);
    vBuff VARCHAR2(32700);
    vSQL CLOB;
    --
    vRes INTEGER;
    vMes VARCHAR2(4000);
    vStageBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Daily load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" started.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column_daily',vMes);

  -- Ключевые поля
  SELECT LOWER(LISTAGG('src.'||c.column_name||' AS SRC_'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG(c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('src_'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('src.src_'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('idx.src_'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('ch.src_'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('dest.'||c.column_name||' = src.'||c.column_name,' AND ') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('s.'||c.column_name||' = ch.src_'||c.column_name,' AND ') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('p.'||c.column_name||' = ch.src_'||c.column_name,' AND ') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG(c.column_name||' = idx.src_'||c.column_name,' AND ') WITHIN GROUP (ORDER BY c.column_position))
        --,LOWER(i.table_owner||'.TMP_'||i.index_name)
    INTO vCol,vColSimple,vSrcSimple,vSrcCol,vIdxSimple,vChCol,vJoinCol,vSJoinCol,vPJoinCol,vUpdJoinCol
    FROM all_indexes i
         INNER JOIN all_ind_columns c
           ON c.index_owner = i.owner
              AND c.index_name = i.index_name
              AND NOT c.column_name IN ('COLUMN_NAME','END_DATE','EFFECTIVE_END')
    WHERE i.table_owner = vTableOwner
      AND i.table_name = vTableName
      AND i.uniqueness = 'UNIQUE';
  
  -- Тип данных колонки
  SELECT CASE WHEN data_type IN ('INTEGER','NUMBER') THEN 'VAL_NUM'
              WHEN data_type = 'DATE' THEN 'VAL_DATE'
           ELSE 'VAL_STR'
         END         
    INTO vValColName
    FROM all_tab_columns
    WHERE owner = vFromTableOwner AND table_name = vFromTableName AND column_name = vColName;

  vStageBegin := SYSDATE;

    dbms_lob.createtemporary(vSQL,FALSE);
    vBuff :=
    'DECLARE'||CHR(10)||
    '  vStr VARCHAR2(4000);'||CHR(10)||
    '  vCou INTEGER := 0;'||CHR(10)||
    --'  vLogged BOOLEAN := FALSE;'||CHR(10)||
    'BEGIN'||CHR(10)||
    'EXECUTE IMMEDIATE ''ALTER SESSION SET nls_date_format = ''''DD.MM.RRRR HH24:MI:SS'''''';'||CHR(10)||
    'FOR idx IN ('||CHR(10)||
    '  WITH'||CHR(10)||
    '    ch AS ('||CHR(10)||
    '      SELECT /*+ MATERIALIZE LEADING(SRC) NO_INDEX(DEST) NO_INDEX(SRC)*/'||CHR(10)||
    '             :1 AS SRC_EFFECTIVE_START,'||CHR(10)||
    '             to_date(''31.12.5999'',''DD.MM.YYYY'') AS SRC_EFFECTIVE_END,'||CHR(10)||
    '             '||vCol||','||CHR(10)||
    '             :2 AS SRC_COLUMN_NAME,'||CHR(10)||
    '             SRC.'||vColName||' AS SRC_VAL,'||CHR(10)||
    '             DEST.COLUMN_NAME AS D_COLUMN_NAME,'||CHR(10)||
    '             DEST.EFFECTIVE_START AS D_EFFECTIVE_START,'||CHR(10)||
    '             DEST.'||vValColName||' AS D_VAL'||CHR(10)||
    '       FROM '||vFromTable||' src'||CHR(10)||
    '            LEFT JOIN '||vToTable||' PARTITION('||vColName||') DEST'||CHR(10)||
    '              ON DEST.COLUMN_NAME = :2'||CHR(10)||
    '                 AND dest.end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
    '                 AND '||vJoinCol||CHR(10)||
    '                 AND :1 BETWEEN DEST.EFFECTIVE_START AND DEST.EFFECTIVE_END'||CHR(10)||
    '       WHERE '||UPPER(vOwner)||'.PKG_NORMALIZE_REF_TABLE.ISEQUAL(DEST.'||vValColName||', SRC.'||vColName||') = 0'||CHR(10)||
    '         AND src.effective_start = :1'||CHR(10)||
    '    )'||CHR(10)|| 
    ' ,s AS ('||CHR(10)||
    '  SELECT '||vColSimple||CHR(10)||
    '         ,MIN(EFFECTIVE_START) AS VNEXTEFF'||CHR(10)||
    '         ,MIN('||vValColName||') KEEP(DENSE_RANK FIRST ORDER BY COLUMN_NAME,EFFECTIVE_START) AS VNEXTVAL'||CHR(10)||
    '     FROM '||vToTable||' PARTITION('||vColName||')'||CHR(10)||
    '     WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND EFFECTIVE_START > :1'||CHR(10)||
    '       AND ('||vColSimple||') IN (SELECT '||vSrcSimple||' FROM ch)'||CHR(10)||
    '   GROUP BY '||vColSimple||')'||CHR(10)||
    ' ,p AS ('||CHR(10)||
    '   SELECT '||vColSimple||CHR(10)||
    '         ,MAX(EFFECTIVE_END) AS VPREVEFF'||CHR(10)||
    '         ,MAX('||vValColName||') KEEP(DENSE_RANK LAST ORDER BY COLUMN_NAME,EFFECTIVE_START) AS VPREVVAL'||CHR(10)||
    '     FROM '||vToTable||' PARTITION('||vColName||')'||CHR(10)||
    '     WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND EFFECTIVE_END < :1'||CHR(10)||
    '       AND ('||vColSimple||') IN (SELECT '||vSrcSimple||' FROM CH WHERE D_COLUMN_NAME IS NULL)'||CHR(10)||
    '   GROUP BY '||vColSimple||')'||CHR(10)||
    'SELECT'||CHR(10)||
    '   CH.SRC_EFFECTIVE_START,'||CHR(10)||
    '   CH.SRC_EFFECTIVE_END,'||CHR(10)||
    '   '||vChCol||','||CHR(10)||
    '   CH.SRC_COLUMN_NAME,'||CHR(10)||
    '   CH.SRC_VAL,'||CHR(10)||
    '   CH.D_COLUMN_NAME,'||CHR(10)||
    '   CH.D_EFFECTIVE_START,'||CHR(10)||
    '   CH.D_VAL,'||CHR(10)||
    '   p.VPREVEFF,'||CHR(10)||
    '   p.VPREVVAL,'||CHR(10)||
    '   s.VNEXTEFF,'||CHR(10)||
    '   s.VNEXTVAL'||CHR(10)||
    '  FROM CH'||CHR(10)||
    '  LEFT JOIN S'||CHR(10)||
    '    ON '||vSJoinCol||CHR(10)||
    '  LEFT JOIN P'||CHR(10)||
    '    ON '||vPJoinCol||CHR(10)||') LOOP';
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
    vBuff :=
    '  BEGIN'||CHR(10)||
    '    IF idx.src_effective_start = idx.d_effective_start THEN'||CHR(10)||
    '      vStr := ''DDel_1'';'||CHR(10)||
    '      DELETE FROM /*+ index(a) */ '||vToTable||' a'||CHR(10)||
    '        WHERE column_name = UPPER(idx.src_column_name)'||CHR(10)||
    '          AND '||vUpdJoinCol||CHR(10)||
    '          AND idx.src_effective_start BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    ELSE'||CHR(10)||
    '      vStr := ''DUpd_1'';'||CHR(10)||
    '      UPDATE /*+ index(a) */ '||vToTable||' a'||CHR(10)||
    '        SET effective_end = idx.src_effective_start - 1'||CHR(10)||
    '        WHERE column_name = UPPER(idx.src_column_name)'||CHR(10)||
    '          AND '||vUpdJoinCol||CHR(10)||
    '          AND idx.src_effective_start BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    END IF; '||CHR(10)||
        --
    '    IF idx.vNextEff < to_date(''31.12.5999'',''DD.MM.YYYY'') AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val,idx.vNextVal) = 1 THEN'||CHR(10)||
    '      vStr := ''DUpd_2'';'||CHR(10)||
    '      UPDATE /*+ index(a) */'||vToTable||' a SET effective_start = idx.src_effective_start'||CHR(10)||
    '        WHERE column_name = UPPER(idx.src_column_name)'||CHR(10)||
    '          AND '||vUpdJoinCol||CHR(10)||
    '          AND idx.vNextEff BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    ELSIF idx.src_effective_start - idx.vPrevEff = 1  AND '||lower(vOwner)||'.pkg_normalize_ref_table.isEqual(idx.src_val,idx.vPrevVal) = 1 THEN'||CHR(10)||
    '      vStr := ''DUpd_4'';'||CHR(10)||
    '      UPDATE /*+ index(a) */'||vToTable||' a SET effective_end = NVL(idx.vNextEff - 1,idx.src_effective_end)'||CHR(10)||
    '        WHERE column_name = UPPER(idx.src_column_name)'||CHR(10)||
    '          AND '||vUpdJoinCol||CHR(10)||
    '          AND idx.vPrevEff BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    ELSE'||CHR(10)||
    '      IF idx.src_val IS NOT NULL THEN'||CHR(10)||
    '        vStr := ''DIns_2'';'||CHR(10)||
    '        INSERT INTO '||vToTable||CHR(10)||
    '          (start_date,end_date,effective_start,effective_end,'||vColSimple||',column_name,'||vValColName||')'||CHR(10)||
    '          VALUES (SYSDATE,to_date(''31.12.5999'',''DD.MM.YYYY''),idx.src_effective_start'||CHR(10)||
    '                 ,NVL(idx.vNextEff - 1,idx.src_effective_end)'||CHR(10)||
    '                 ,'||vIdxSimple||CHR(10)||
    '                 ,UPPER(idx.src_column_name)'||CHR(10)||
    '                 ,idx.src_val);'||CHR(10)||
    '      END IF;  '||CHR(10)||
    '    END IF;'||CHR(10)||
    '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
    '      vStr := ''ERROR :: "'||vColName||'" - "''||to_char(idx.src_effective_start,''DD.MM.YYYY'')||''" :: ''||SQLERRM||Chr(10)||vStr;'||CHR(10)||
    '  END;'||CHR(10)||
    '  vCou := vCou + 1;'||CHR(10)||
    'END LOOP;'||CHR(10)||
    ':3 := vCou;'||CHR(10)||
    'END;';
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
    EXECUTE IMMEDIATE vSQL USING IN inDate
               ,IN vColName
               ,OUT vRes;
    COMMIT;
    --dbms_output.put_line(vSQL);

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: "'||lower(vFromTable)||' -> '||lower(vToTable)||'" - column "'||UPPER(vColName)||'" - '||vRes||' rows proccessed in table "'||vToTable||'" in '||get_ti_as_hms(vEndTime - vStageBegin);
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column_daily',vMes);
  
  vMes := 'FINISH :: Daily load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column_daily',vMes);
EXCEPTION WHEN OTHERS THEN 
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Daily load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" :: '||SQLERRM;
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column_daily',vMes);
  vMes := 'FINISH :: Daily load "'||lower(vFromTable)||' -> '||lower(vToTable)||'" of column "'||UPPER(vColName)||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_column_daily',vMes);
END load_column_daily;

PROCEDURE load_dwh_new(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB DEFAULT NULL,inWorkMask IN VARCHAR2 DEFAULT '10')
  IS
    vSQL CLOB;
    vPLSQL CLOB;
    vColName VARCHAR2(4000);
    vDoLoad BOOLEAN := SUBSTR(inWorkMask,1,1) = 1;
    vDoFinish BOOLEAN := SUBSTR(inWorkMask,2,1) = 1;
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.MASSLOADJOB_'||job_id_seq.nextval;
    --
    vMes VARCHAR2(32700);
    vStageBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  IF inColName IS NULL THEN
    SELECT DISTINCT LISTAGG(partition_name,',') WITHIN GROUP (ORDER BY a.partition_position) OVER () AS part_name
      INTO vColName
      FROM all_tab_partitions a 
      WHERE lower(table_owner||'.'||table_name) = LOWER(inToTable)
        AND partition_name != 'DELETED_BY';
  ELSE vColName := inColName;
  END IF;

  vMes := 'START :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" started.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
  
  IF vDoLoad THEN
    vStageBegin := SYSDATE;
    vMes := 'CONTINUE :: ---- Начало загрузки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" ----';
    pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
    
    vSQL :=
    'SELECT str AS ID'||CHR(10)||
    '      ,NULL AS parent_id'||CHR(10)||
    '      ,'''||LOWER(vOwner)||'.pkg_normalize_ref_table.load_column'' AS unit'||CHR(10)||
    '      ,'''||LOWER(inFromTable)||'#!#'||LOWER(inToTable)||'#!#''||str||q''[#!#'||inGidsSQL||']'' AS params'||CHR(10)||
    'FROM TABLE('||LOWER(vOwner)||'.pkg_normalize_ref_table.parse_str('''||vColName||''','',''))';
  
    LoadNew(vSQL,vJobName);
    --dbms_output.put_line(vSQL);
    
    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ---- Окончание загрузки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'". Время выполнения '||get_ti_as_hms(vEndTime - vStageBegin)||' ----';
    pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
  END IF;
  
  IF vDoFinish THEN
    vStageBegin := SYSDATE;
    -- Получение PLSQL для финишной обработки
    BEGIN
      SELECT post_plsql INTO vPLSQL
        FROM tb_norm_table
        WHERE from_table = lower(inFromTable) AND to_table = lower(inToTable);
    EXCEPTION WHEN NO_DATA_FOUND THEN
      raise_application_error(-20000,'Загрузка "'||lower(inFromTable)||' -> '||lower(inToTable)||'" не подготовлена');
    END;
    
    IF vPLSQL IS NOT NULL THEN
      vMes := 'CONTINUE :: ---- Начало финишной обработки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" ----';
      pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
      
      vSQL :=
      'SELECT str AS ID'||CHR(10)||
      '      ,NULL AS parent_id'||CHR(10)||
      '      ,'''||LOWER(vOwner)||'.pkg_normalize_ref_table.Finishing'' AS unit'||CHR(10)||
      '      ,q''['||vPLSQL||'#!#]''||str AS params'||CHR(10)||
      'FROM TABLE('||LOWER(vOwner)||'.pkg_normalize_ref_table.parse_str('''||vColName||''','',''))';

      LoadNew(vSQL,vJobName);
      dbms_output.put_line(vSQL);
      
      vEndTime := SYSDATE;
      vMes := 'CONTINUE :: ---- Окончание финишной обработки "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'". Время выполнения '||get_ti_as_hms(vEndTime - vStageBegin)||' ----';
      pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
    END IF;  
  END IF;
    
  vMes := 'FINISH :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
EXCEPTION WHEN OTHERS THEN 
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" :: '||SQLERRM;
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
  vMes := 'FINISH :: Mass load "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.load_dwh',vMes);
END load_dwh_new;

PROCEDURE reload_column(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2)
  IS
    vFromTable VARCHAR2(256) := LOWER(inFromTable);
    vToTable VARCHAR2(256) := LOWER(inToTable);
    vColName VARCHAR2(4000) := REPLACE(UPPER(inColName),'::WITHNULLS','');
    vTableOwner VARCHAR2(30) := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1));
    vTableName VARCHAR2(30) := UPPER(SUBSTR(vToTable,INSTR(vToTable,'.',1,1) + 1));
    vTmpTableName VARCHAR2(30);
    vCol VARCHAR2(1000);
    vACol VARCHAR2(1000);
    vJoinCol VARCHAR2(4000);
    vBuff VARCHAR2(32700);
    vFind CLOB;
    --
    vRes INTEGER;
    vMes VARCHAR2(4000);
    vStageBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Reloading GID''s "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" started.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.reload_dwh',vMes);
  
  vStageBegin := SYSDATE;
  SELECT LOWER(LISTAGG(c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('a.'||c.column_name,',') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(LISTAGG('b.'||c.column_name||' = a.'||c.column_name,' AND ') WITHIN GROUP (ORDER BY c.column_position))
        ,LOWER(i.table_owner||'.TMP_R_'||ORA_HASH(vFromTable||'.'||vColName))
    INTO vCol,vACol,vJoinCol/*,vBCol*/,vTmpTableName
    FROM all_indexes i
         INNER JOIN all_ind_columns c
           ON c.index_owner = i.owner
              AND c.index_name = i.index_name
              AND NOT c.column_name IN ('COLUMN_NAME','END_DATE','EFFECTIVE_END')
    WHERE i.table_owner = vTableOwner
      AND i.table_name = vTableName
      AND i.uniqueness = 'UNIQUE'
  GROUP BY LOWER(i.table_owner||'.TMP_R_'||ORA_HASH(vFromTable||'.'||vColName));
      
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE '||vTmpTableName;
  EXCEPTION WHEN OTHERS THEN
      NULL;
  END;

  EXECUTE IMMEDIATE 'CREATE TABLE '||vTmpTableName||' AS SELECT '||vCol||' FROM '||vToTable||' WHERE rownum < 1';
   
  dbms_lob.createtemporary(vFind,FALSE);
  vBuff :=
  'BEGIN'||CHR(10)||
  '  INSERT INTO '||vTmpTableName||' ('||vCol||')'||CHR(10)||
  '    WITH'||CHR(10)||
  '      a AS ('||CHR(10)||
  '        SELECT /*+ materialize */ *'||CHR(10)||
  '          FROM ('||CHR(10)||
  '            SELECT '||vCol||CHR(10)||
  '              FROM '||vFromTable||CHR(10)||
  '              WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
  CASE WHEN INSTR(UPPER(inColName),'::WITHNULLS',1,1) = 0 THEN '                AND '||vColName||' IS NOT NULL' END||CHR(10)||
  '            GROUP BY '||vCol||CHR(10)||
  '            MINUS'||CHR(10)||
  '            SELECT '||vCol||CHR(10)||
  '              FROM '||vToTable||CHR(10)||
  '              WHERE column_name = '''||vColName||''''||CHR(10)||
  '                AND end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
  '            GROUP BY '||vCol||'))'||CHR(10)||
  '  SELECT '||vACol||CHR(10)||
  '    FROM a'||CHR(10)||
  '         INNER JOIN '||vFromTable||' b'||CHR(10)||
  '           ON b.end_date = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
  '              AND '||vJoinCol||CHR(10)||CHR(10)||
  '  GROUP BY '||vACol||';'||CHR(10)||
  '  :1 := SQL%ROWCOUNT;'||CHR(10)||
  '  COMMIT;'||CHR(10)||
  'END;';
  dbms_lob.writeappend(vFind,LENGTH(vBuff),vBuff);
  
  EXECUTE IMMEDIATE vFind USING OUT vRes;
  --dbms_output.put_line(vFind);
  
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: "'||lower(inFromTable)||' -> '||lower(inToTable)||'" - '||vRes||' rows inserted into TEMP table "'||vTmpTableName||'" in '||get_ti_as_hms(vEndTime - vStageBegin);
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.reload_dwh',vMes);
 
  IF vRes > 0 THEN
    load_column(vFromTable,vToTable,inColName,'SELECT '||vCol||' FROM '||vTmpTableName);
  ELSE
    vMes := 'SUCCESSFULLY :: Reloading GID''s "'||lower(inFromTable)||' -> '||lower(inToTable)||'" not required';
    pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.reload_dwh',vMes);
  END IF;  

  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE '||vTmpTableName;
  EXCEPTION WHEN OTHERS THEN
      NULL;
  END;

  vMes := 'FINISH :: Reloading GID''s "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.reload_dwh',vMes);
EXCEPTION WHEN OTHERS THEN
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Reloading GID''s "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" :: '||SQLERRM;
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.reload_dwh',vMes);

  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE '||vTmpTableName;
  EXCEPTION WHEN OTHERS THEN
      NULL;
  END;

  vMes := 'FINISH :: Reloading GID''s "'||lower(inFromTable)||' -> '||lower(inToTable)||'" of columns "'||NVL(UPPER(inColName),'ALL')||'" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(LOWER(vOwner)||'.pkg_normalize_ref_table.reload_dwh',vMes);
END reload_column;

PROCEDURE reload_dwh(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2)
  IS
    vSQL VARCHAR2(32700);
    vColName VARCHAR2(4000);
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.RELOADJOB_'||job_id_seq.nextval;
BEGIN
  IF inColName IS NULL THEN
    SELECT DISTINCT LISTAGG(partition_name,',') WITHIN GROUP (ORDER BY a.partition_position) OVER () AS part_name
      INTO vColName
      FROM all_tab_partitions a 
      WHERE lower(table_owner||'.'||table_name) = LOWER(inToTable)
        AND partition_name != 'DELETED_BY';
  ELSE vColName := inColName;
  END IF;

  vSQL :=
  'SELECT str AS ID'||CHR(10)||
  '      ,NULL AS parent_id'||CHR(10)||
  '      ,'''||LOWER(vOwner)||'.pkg_normalize_ref_table.reload_column'' AS unit'||CHR(10)||
  '      ,'''||LOWER(inFromTable)||'#!#'||LOWER(inToTable)||'#!#''||str AS params'||CHR(10)||
  'FROM TABLE('||LOWER(vOwner)||'.pkg_normalize_ref_table.parse_str('''||vColName||''','',''))';
  
  LoadNew(vSQL,vJobName);
  --dbms_output.put_line(vSQL);
END reload_dwh;

PROCEDURE Finishing(inPLSQL IN CLOB,inColName IN VARCHAR2)
  IS
    vMes VARCHAR2(4000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    ---
    vRes VARCHAR2(4000);
    vStat VARCHAR2(256);
BEGIN
  
  EXECUTE IMMEDIATE 'ALTER SESSION SET nls_date_format = ''DD.MM.RRRR HH24:MI:SS''';
  
  EXECUTE IMMEDIATE inPLSQL USING IN inColName,OUT vStat,OUT vRes;

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: Finishing '||vRes||' in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.finishing',vMes);
  
EXCEPTION WHEN OTHERS THEN
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Finishing '||vRes||' in '||get_ti_as_hms(vEndTime - vBegTime)||' :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.finishing',vMes);
END Finishing;

FUNCTION Loading(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inGidsSQL IN CLOB,inFinish BOOLEAN DEFAULT FALSE)
   RETURN VARCHAR2
  IS
    vFromTable VARCHAR2(256) := LOWER(inFromTable);
    vToTable VARCHAR2(256) := LOWER(inToTable);
    vToTableHASH INTEGER;
    vColName VARCHAR2(4000) := UPPER(inColName);
    vLoadMass VARCHAR2(256) := LOWER(vOwner)||'.pkg_normalize_ref_table.load_column';
    vFinishMass CLOB;
    --vID VARCHAR2(256);
    vChainName VARCHAR2(256);
    vProgramName VARCHAR2(256);
    vPrgFinalName VARCHAR2(256);
    vStpName VARCHAR2(256);
    vRulName VARCHAR2(256);
    vJobName VARCHAR2(256);
    vCompl VARCHAR2(4000);
    vStartSteps VARCHAR2(32700);
BEGIN
  BEGIN
    SELECT ORA_HASH(vToTable) AS ToTableHASH, post_plsql
      INTO vToTableHASH,vFinishMass
      FROM tb_norm_table
      WHERE from_table = vFromTable AND to_table = vToTable;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Загрузка "'||lower(inFromTable)||' -> '||lower(inToTable)||'" не подготовлена');
  END;
  
  -- Если колонки для загрузки явно не указаны (inColName IS NULL), то загружаем все колонки,
  -- по которым в ...NEW - таблице существуют партиции
  IF vColName IS NULL THEN
    SELECT DISTINCT LISTAGG(partition_name,',') WITHIN GROUP (ORDER BY a.partition_position) OVER () AS part_name
      INTO vColName
      FROM all_tab_partitions a 
      WHERE lower(table_owner||'.'||table_name) = vToTable
        AND partition_name != 'DELETED_BY';
  END IF;

  --Цепь
  vChainName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.MLCHAIN_'||vToTableHASH;
  sys.dbms_scheduler.create_chain(chain_name => vChainName,comments => 'Таблица '||vToTable);

  -- Программы, Шаги и Правила
  FOR idx IN (
    WITH
      a AS (
        SELECT str AS col_name
          FROM TABLE(parse_str(UPPER(vColName),','))
      )
      SELECT a.col_name
            ,clmn.column_id
            ,LISTAGG('STP_'||clmn.column_id||' COMPLETED',' AND ') WITHIN GROUP (ORDER BY clmn.column_id) OVER () AS compl
            ,LISTAGG('STP_'||clmn.column_id,',') WITHIN GROUP (ORDER BY clmn.column_id) OVER () AS stps
        FROM a 
        INNER JOIN all_tab_columns clmn
          ON clmn.owner = UPPER(SUBSTR(vFromTable,1,INSTR(vFromTable,'.',1,1) - 1))
             AND clmn.table_name = UPPER(SUBSTR(vFromTable,INSTR(vFromTable,'.',1,1) + 1))
             AND clmn.column_name = REPLACE(a.col_name,'::WITHNULLS','')
  ) LOOP
    IF NOT inFinish THEN
      -- Программа для загрузки
      vProgramName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.PRG_'||idx.column_id||'_'||vToTableHASH;
      sys.dbms_scheduler.create_program(program_name        => vProgramName,
                                        program_type        => 'STORED_PROCEDURE',
                                        program_action      => vLoadMass,
                                        number_of_arguments => 4,
                                        enabled             => false,
                                        comments            => 'Загрузка колонки '||idx.col_name);
     -- Параметры программы для загрузки
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 1,
                                                 argument_name     => 'INFROMTABLE',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => vFromTable,
                                                 out_argument      => FALSE);
                                                 
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 2,
                                                 argument_name     => 'INTOTABLE',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => vToTable,
                                                 out_argument      => FALSE);

     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 3,
                                                 argument_name     => 'INCOLNAME',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => idx.col_name,
                                                 out_argument      => FALSE);
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 4,
                                                 argument_name     => 'INGIDSSQL',
                                                 argument_type     => 'CLOB',
                                                 default_value     => inGidsSQL,
                                                 out_argument      => FALSE);
    ELSE
      -- Программа для финишной обработки
      vProgramName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.PRG_'||idx.column_id||'_'||vToTableHASH;
      sys.dbms_scheduler.create_program(program_name        => vProgramName,
                                        program_type        => 'STORED_PROCEDURE',
                                        program_action      => lower(vOwner)||'.pkg_normalize_ref_table.finishing',
                                        number_of_arguments => 2,
                                        enabled             => false,
                                        comments            => 'Финишная обработка колонки '||idx.col_name);
      -- Параметры программы для финишной обработки
      sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 1,
                                                 argument_name     => 'INPLSQL',
                                                 argument_type     => 'CLOB',
                                                 default_value     => vFinishMass,
                                                 out_argument      => FALSE);
                                                 
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 2,
                                                 argument_name     => 'INCOLNAME',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => idx.col_name,
                                                 out_argument      => FALSE);
    END IF;
  
  sys.dbms_scheduler.enable(name => vProgramName);
  
  --Шaги
  vStpName := 'STP_'||idx.column_id;

  sys.dbms_scheduler.define_chain_step(chain_name   => vChainName,
                                         step_name    => vStpName,
                                         program_name => vProgramName);
  
  --Правила
  vRulName := 'RUL_'||idx.column_id||'_'||vToTableHASH;
  sys.dbms_scheduler.define_chain_rule(chain_name => vChainName,
                                       rule_name  => vRulName,
                                       condition  => 'TRUE',
                                       action     => 'START "'||vStpName||'"',
                                       comments   => 'Колонка '||idx.col_name);
  
  vCompl := idx.compl;
  vStartSteps := idx.stps;
  END LOOP;
  
  --Финальные программа, шаг и правило
  vPrgFinalName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.PRG_FINAL_'||vToTableHASH;
  sys.dbms_scheduler.create_program(program_name        => vPrgFinalName,
                                    program_type        => 'PLSQL_BLOCK',
                                    program_action      => 'BEGIN NULL; END;',
                                    number_of_arguments => 0,
                                    enabled             => TRUE,
                                    comments            => 'Финал');

  sys.dbms_scheduler.define_chain_step(chain_name     => vChainName,
                                         step_name    => 'STP_FINAL',
                                         program_name => vPrgFinalName);

  sys.dbms_scheduler.define_chain_rule(chain_name => vChainName,
                                       rule_name  => 'RUL_'||vToTableHASH||'_FINAL',
                                       condition  => vCompl,
                                       action     => 'END',
                                       comments   => 'Финиш');
                                       
  -- Выставление свойства ENABLE для цепи
  sys.dbms_scheduler.enable(vChainName);
    
  -- Старт загрузки
  vJobName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.JOBCHAIN_'||job_id_seq.nextval;
  sys.dbms_scheduler.run_chain(vChainNAme,vStartSteps,vJobName);
     
  RETURN vChainName;
EXCEPTION WHEN OTHERS THEN
  RETURN vChainName;
END Loading;

FUNCTION Loading_Daily(inFromTable IN VARCHAR2,inToTable IN VARCHAR2,inColName IN VARCHAR2,inDate IN DATE,inFinish BOOLEAN DEFAULT FALSE)
   RETURN VARCHAR2
  IS
    vFromTable VARCHAR2(256) := LOWER(inFromTable);
    vToTable VARCHAR2(256) := LOWER(inToTable);
    vToTableHASH INTEGER;
    vColName VARCHAR2(4000) := UPPER(inColName);
    vLoad VARCHAR2(256) := LOWER(vOwner)||'.pkg_normalize_ref_table.load_column_daily';
    vFinishMass CLOB;
    --vID VARCHAR2(256);
    vChainName VARCHAR2(256);
    vProgramName VARCHAR2(256);
    vPrgFinalName VARCHAR2(256);
    vStpName VARCHAR2(256);
    vRulName VARCHAR2(256);
    vJobName VARCHAR2(256);
    vCompl VARCHAR2(4000);
    vStartSteps VARCHAR2(32700);
BEGIN
  BEGIN
    SELECT ORA_HASH(vToTable) AS ToTableHASH, post_plsql
      INTO vToTableHASH,vFinishMass
      FROM tb_norm_table
      WHERE from_table = vFromTable AND to_table = vToTable;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Загрузка "'||lower(inFromTable)||' -> '||lower(inToTable)||'" не подготовлена');
  END;
  
  -- Если колонки для загрузки явно не указаны (inColName IS NULL), то загружаем все колонки,
  -- по которым в ...NEW - таблице существуют партиции
  IF vColName IS NULL THEN
    SELECT DISTINCT LISTAGG(partition_name,',') WITHIN GROUP (ORDER BY a.partition_position) OVER () AS part_name
      INTO vColName
      FROM all_tab_partitions a 
      WHERE lower(table_owner||'.'||table_name) = vToTable
        AND partition_name != 'DELETED_BY';
  END IF;

  --Цепь
  vChainName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.DLCHAIN_'||vToTableHASH;
  sys.dbms_scheduler.create_chain(chain_name => vChainName,comments => 'Таблица '||vToTable);

  -- Программы, Шаги и Правила
  FOR idx IN (
    WITH
      a AS (
        SELECT str AS col_name
          FROM TABLE(parse_str(UPPER(vColName),','))
      )
      SELECT a.col_name
            ,clmn.column_id
            ,LISTAGG('STP_'||clmn.column_id||' COMPLETED',' AND ') WITHIN GROUP (ORDER BY clmn.column_id) OVER () AS compl
            ,LISTAGG('STP_'||clmn.column_id,',') WITHIN GROUP (ORDER BY clmn.column_id) OVER () AS stps
        FROM a 
        INNER JOIN all_tab_columns clmn
          ON clmn.owner = UPPER(SUBSTR(vFromTable,1,INSTR(vFromTable,'.',1,1) - 1))
             AND clmn.table_name = UPPER(SUBSTR(vFromTable,INSTR(vFromTable,'.',1,1) + 1))
             AND clmn.column_name = REPLACE(a.col_name,'::WITHNULLS','')
  ) LOOP
    IF NOT inFinish THEN
      -- Программа для загрузки
      vProgramName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.PRG_'||idx.column_id||'_'||vToTableHASH;
      sys.dbms_scheduler.create_program(program_name        => vProgramName,
                                        program_type        => 'STORED_PROCEDURE',
                                        program_action      => vLoad,
                                        number_of_arguments => 4,
                                        enabled             => false,
                                        comments            => 'Загрузка колонки '||idx.col_name);
     -- Параметры программы для загрузки
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 1,
                                                 argument_name     => 'INFROMTABLE',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => vFromTable,
                                                 out_argument      => FALSE);
                                                 
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 2,
                                                 argument_name     => 'INTOTABLE',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => vToTable,
                                                 out_argument      => FALSE);

     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 3,
                                                 argument_name     => 'INCOLNAME',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => idx.col_name,
                                                 out_argument      => FALSE);
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 4,
                                                 argument_name     => 'INDATE',
                                                 argument_type     => 'DATE',
                                                 default_value     => inDate,
                                                 out_argument      => FALSE);
    ELSE
      -- Программа для финишной обработки
      vProgramName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.PRG_'||idx.column_id||'_'||vToTableHASH;
      sys.dbms_scheduler.create_program(program_name        => vProgramName,
                                        program_type        => 'STORED_PROCEDURE',
                                        program_action      => lower(vOwner)||'.pkg_normalize_ref_table.finishing',
                                        number_of_arguments => 2,
                                        enabled             => false,
                                        comments            => 'Финишная обработка колонки '||idx.col_name);
      -- Параметры программы для финишной обработки
      sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 1,
                                                 argument_name     => 'INPLSQL',
                                                 argument_type     => 'CLOB',
                                                 default_value     => vFinishMass,
                                                 out_argument      => FALSE);
                                                 
     sys.dbms_scheduler.define_program_argument(program_name => vProgramName,
                                                 argument_position => 2,
                                                 argument_name     => 'INCOLNAME',
                                                 argument_type     => 'VARCHAR2',
                                                 default_value     => idx.col_name,
                                                 out_argument      => FALSE);
    END IF;
  
  sys.dbms_scheduler.enable(name => vProgramName);
  
  --Шaги
  vStpName := 'STP_'||idx.column_id;

  sys.dbms_scheduler.define_chain_step(chain_name   => vChainName,
                                         step_name    => vStpName,
                                         program_name => vProgramName);
  
  --Правила
  vRulName := 'RUL_'||idx.column_id||'_'||vToTableHASH;
  sys.dbms_scheduler.define_chain_rule(chain_name => vChainName,
                                       rule_name  => vRulName,
                                       condition  => 'TRUE',
                                       action     => 'START "'||vStpName||'"',
                                       comments   => 'Колонка '||idx.col_name);
  
  vCompl := idx.compl;
  vStartSteps := idx.stps;
  END LOOP;
  
  --Финальные программа, шаг и правило
  vPrgFinalName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.PRG_FINAL_'||vToTableHASH;
  sys.dbms_scheduler.create_program(program_name        => vPrgFinalName,
                                    program_type        => 'PLSQL_BLOCK',
                                    program_action      => 'BEGIN NULL; END;',
                                    number_of_arguments => 0,
                                    enabled             => TRUE,
                                    comments            => 'Финал');

  sys.dbms_scheduler.define_chain_step(chain_name     => vChainName,
                                         step_name    => 'STP_FINAL',
                                         program_name => vPrgFinalName);

  sys.dbms_scheduler.define_chain_rule(chain_name => vChainName,
                                       rule_name  => 'RUL_'||vToTableHASH||'_FINAL',
                                       condition  => vCompl,
                                       action     => 'END',
                                       comments   => 'Финиш');
                                       
  -- Выставление свойства ENABLE для цепи
  sys.dbms_scheduler.enable(vChainName);
    
  -- Старт загрузки
  vJobName := UPPER(SUBSTR(vToTable,1,INSTR(vToTable,'.',1,1) - 1))||'.D_JOBCHAIN_'||job_id_seq.nextval;
  sys.dbms_scheduler.run_chain(vChainNAme,vStartSteps,vJobName);
     
  RETURN vChainName;
EXCEPTION WHEN OTHERS THEN
  RETURN vChainName;
END Loading_Daily;

FUNCTION GetChainList(inSQL IN CLOB) RETURN TTabCHBuilder PIPELINED
  IS
    rec TRecCHBuilder;
    cur INTEGER;       -- хранит идентификатор (ID) курсора
    ret INTEGER;       -- хранит возвращаемое по вызову значение
BEGIN
    cur := dbms_sql.open_cursor;
    dbms_sql.parse(cur, inSQL, dbms_sql.native);
    dbms_sql.define_column(cur,1,rec.id,4000);
    dbms_sql.define_column(cur,2,rec.parent_id,4000);
    dbms_sql.define_column(cur,3,rec.unit,4000);
    dbms_sql.define_column(cur,4,rec.params,4000);

    ret := dbms_sql.execute(cur);

    LOOP
      EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
      dbms_sql.column_value(cur,1,rec.id);
      dbms_sql.column_value(cur,2,rec.parent_id);
      dbms_sql.column_value(cur,3,rec.unit);
      dbms_sql.column_value(cur,4,rec.params);
      PIPE ROW(rec); 
    END LOOP;
    dbms_sql.close_cursor(cur);
END GetChainList;
  
FUNCTION ChainBuilder(inSQL CLOB) RETURN VARCHAR2
  IS
    vID VARCHAR2(30) := to_char(job_id_seq.nextval);
    vChainName VARCHAR2(256) := vOwner||'.CHAIN_'||vID;--inID;
    vBuff VARCHAR2(32700);
    vPrg CLOB;
    vArg CLOB;
    vStp CLOB;
    vRul CLOB;
    vAct CLOB;
    vCompl VARCHAR2(32700);
    vPrgFinalName VARCHAR2(256) := vOwner||'.PRG_FINAL_'||vID;
BEGIN
  -- Программы
  dbms_lob.createtemporary(vPrg,FALSE);
  dbms_lob.writeappend(vPrg,LENGTH('BEGIN'||CHR(10)),'BEGIN'||CHR(10));
  
  vBuff :=
  '  sys.dbms_scheduler.create_program(program_name        => '''||vOwner||'.PRG_START_'||vID||''','||CHR(10)||
  '                                    program_type        => ''PLSQL_BLOCK'','||CHR(10)||
  '                                    program_action      => ''BEGIN NULL; END;'','||CHR(10)||
  '                                    enabled             => true,'||CHR(10)||
  '                                    comments            => ''Старт'');'||CHR(10);
  dbms_lob.writeappend(vPrg,LENGTH(vBuff),vBuff);
  
  FOR idx IN (
    SELECT DISTINCT 
           vOwner||'.PRG_'||ora_hash(ID)||'_'||vID AS prg_name
          ,lower(p.unit) AS action
          ,ID AS comm
          ,SUM(NVL2(a.OBJECT_ID,1,0)) OVER (PARTITION BY p.id,p.parent_id) AS arg_cou
      FROM TABLE(GetChainList(inSQL)) p
           LEFT JOIN all_procedures prc
             ON lower(prc.owner||NVL2(prc.object_name,'.'||prc.object_name,NULL)||NVL2(prc.procedure_name,'.'||prc.procedure_name,NULL)) = lower(p.unit)
           LEFT JOIN all_arguments a 
             ON a.OBJECT_ID = prc.object_id AND a.argument_name IS NOT NULL
                AND a.object_name = NVL(prc.procedure_name,prc.object_name)
  ) LOOP
      vBuff :=
      '  sys.dbms_scheduler.create_program(program_name        => '''||idx.prg_name||''','||CHR(10)||
      '                                    program_type        => ''STORED_PROCEDURE'','||CHR(10)||
      '                                    program_action      => '''||idx.action||''','||CHR(10)||
      '                                    number_of_arguments => '||idx.arg_cou||','||CHR(10)||
      '                                    enabled             => false,'||CHR(10)||
      '                                    comments            => '''||idx.comm||''');'||CHR(10);
      dbms_lob.writeappend(vPrg,length(vBuff),vBuff);
  END LOOP;
  -- Финальная программа
  vBuff :=
  'sys.dbms_scheduler.create_program(program_name        => '''||vPrgFinalName||''',
                                    program_type        => ''PLSQL_BLOCK'',
                                    program_action      => ''BEGIN NULL; END;'',
                                    number_of_arguments => 0,
                                    enabled             => TRUE,
                                    comments            => ''Финал'');'||CHR(10);
  dbms_lob.writeappend(vPrg,length(vBuff),vBuff);
  dbms_lob.writeappend(vPrg,LENGTH('END;'),'END;');
  
  -- Параметры программ
  dbms_lob.createtemporary(vArg,FALSE);
  dbms_lob.writeappend(vArg,LENGTH('BEGIN'||CHR(10)),'BEGIN'||CHR(10));
  FOR idx IN (
    SELECT vOwner||'.PRG_'||ora_hash(ID)||'_'||vID AS prg_name
          ,v.ord AS arg_position
          ,a.argument_name AS arg_name
          ,a.data_type arg_type
          ,v.str AS arg_value
      FROM TABLE(GetChainList(inSQL)) p
           CROSS JOIN TABLE(parse_str(p.params,'#!#')) v
           LEFT JOIN all_procedures prc
             ON lower(prc.owner||NVL2(prc.object_name,'.'||prc.object_name,NULL)||NVL2(prc.procedure_name,'.'||prc.procedure_name,NULL)) = lower(p.unit)
           LEFT JOIN all_arguments a 
             ON a.OBJECT_ID = prc.object_id
                AND a.object_name = NVL(prc.procedure_name,prc.object_name)
                AND a.position = v.ord
      WHERE a.argument_name IS NOT NULL
    GROUP BY v.ord,p.id,a.argument_name,a.data_type,v.ord,v.str
    ORDER BY p.id,v.ord
  ) LOOP
      vBuff :=
      '  sys.dbms_scheduler.define_program_argument(program_name => '''||idx.prg_name||''','||CHR(10)||
      '                                             argument_position => '||idx.arg_position||','||CHR(10)||
      '                                             argument_name     => '''||idx.arg_name||''','||CHR(10)||
      '                                             argument_type     => '''||idx.arg_type||''','||CHR(10)||
      '                                             default_value     => '''||idx.arg_value||''');'||CHR(10);
      dbms_lob.writeappend(vArg,length(vBuff),vBuff);
  END LOOP;
  dbms_lob.writeappend(vArg,LENGTH('END;'),'END;');
  
  -- Цепь и шаги
  dbms_lob.createtemporary(vStp,FALSE);
  dbms_lob.writeappend(vStp,LENGTH('BEGIN'||CHR(10)),'BEGIN'||CHR(10));
  
  vBuff := 
  '  sys.dbms_scheduler.create_chain(chain_name          => '''||vChainName||''','||CHR(10)||
  '                                  evaluation_interval => INTERVAL ''3'' MINUTE,'||CHR(10)||
  '                                  comments            => ''Головной CHAIN'');'||CHR(10);
  dbms_lob.writeappend(vStp,length(vBuff),vBuff);

  vBuff :=
  '  sys.dbms_scheduler.define_chain_step(chain_name   => '''||vChainName||''','||CHR(10)||
  '                                       step_name    => ''STP_START'','||CHR(10)||
  '                                       program_name => '''||vOwner||'.PRG_START_'||vID||''');'||CHR(10);
  dbms_lob.writeappend(vStp,length(vBuff),vBuff);

  FOR idx IN (
    SELECT DISTINCT
           'STP_'||ora_hash(ID) AS stp_name 
          ,vOwner||'.PRG_'||ora_hash(ID)||'_'||vID AS prg_name
      FROM TABLE(GetChainList(inSQL)) p
  ) LOOP
    vBuff :=
    '  sys.dbms_scheduler.define_chain_step(chain_name   => '''||vChainName||''','||CHR(10)||
    '                                       step_name    => '''||idx.stp_name||''','||CHR(10)||
    '                                       program_name => '''||idx.prg_name||''');'||CHR(10);
    dbms_lob.writeappend(vStp,length(vBuff),vBuff);
  END LOOP;
  -- Финальный шаг
  vBuff :=
  'sys.dbms_scheduler.define_chain_step(chain_name     => '''||vChainName||''',
                                         step_name    => ''STP_FINAL'',
                                         program_name => '''||vPrgFinalName||''');'||CHR(10);
  dbms_lob.writeappend(vStp,length(vBuff),vBuff);
  dbms_lob.writeappend(vStp,LENGTH('END;'),'END;');
  
  -- Правила
  dbms_lob.createtemporary(vRul,FALSE);
  dbms_lob.writeappend(vRul,LENGTH('BEGIN'||CHR(10)),'BEGIN'||CHR(10));
  
  vBuff :=
  '  sys.dbms_scheduler.define_chain_rule(chain_name => '''||vChainName||''','||CHR(10)||
  '                                       rule_name  => '''||vOwner||'.RUL_START_'||vID||''','||CHR(10)||
  '                                       condition  => ''TRUE'','||CHR(10)||
  '                                       action     => ''START "STP_START"'','||CHR(10)||
  '                                       comments   => ''Старт'');'||CHR(10);
  dbms_lob.writeappend(vRul,length(vBuff),vBuff);

  FOR idx IN (
    SELECT 'STP_'||ora_hash(ID) AS stp_name 
          ,vOwner||'.RUL_'||ora_hash(ID)||'_'||vID AS rul_name
          ,LISTAGG(CASE WHEN parent_id IS NOT NULL THEN 'STP_'||ora_hash(parent_id)||' COMPLETED' END,' AND ') WITHIN GROUP (ORDER BY ora_hash(parent_id)) AS cond
          ,LISTAGG('STP_'||ora_hash(ID)||' COMPLETED',' AND ') WITHIN GROUP (ORDER BY ora_hash(ID)) OVER () AS compl
          ,p.id
      FROM TABLE(GetChainList(inSQL)) p
    GROUP BY p.id  
  ) LOOP
    vBuff :=
    '  sys.dbms_scheduler.define_chain_rule(chain_name => '''||vChainName||''','||CHR(10)||
    '                                       rule_name  => '''||idx.rul_name||''','||CHR(10)||
    '                                       condition  => '''||NVL(idx.cond,'STP_START COMPLETED')||''','||CHR(10)||
    '                                       action     => ''START "'||idx.stp_name||'"'','||CHR(10)||
    '                                       comments   => '''||idx.id||''');'||CHR(10);
    dbms_lob.writeappend(vRul,length(vBuff),vBuff);
    vCompl := idx.compl;
  END LOOP;
  -- Финальное правило
  vBuff :=
  'sys.dbms_scheduler.define_chain_rule(chain_name => '''||vChainName||''',
                                       rule_name  => ''RUL_'||vID||'_FINAL'',
                                       condition  => '''||vCompl||''',
                                       action     => ''END'',
                                       comments   => ''Финиш'');'||CHR(10);
  dbms_lob.writeappend(vRul,length(vBuff),vBuff);
  dbms_lob.writeappend(vRul,LENGTH('END;'),'END;');
  
  -- Активация программ и цепи
  dbms_lob.createtemporary(vAct,FALSE);
  dbms_lob.writeappend(vAct,LENGTH('BEGIN'||CHR(10)),'BEGIN'||CHR(10));
  
  FOR idx IN (
    SELECT DISTINCT 
           vOwner||'.PRG_'||ora_hash(ID)||'_'||vID AS prg_name
      FROM TABLE(GetChainList(inSQL)) p
  ) LOOP
      vBuff :=
      '  sys.dbms_scheduler.enable('''||idx.prg_name||''');'||CHR(10);
      dbms_lob.writeappend(vAct,length(vBuff),vBuff);
  END LOOP;
  
  vBuff :=
  '  sys.dbms_scheduler.enable('''||vChainName||''');'||CHR(10);
  dbms_lob.writeappend(vAct,length(vBuff),vBuff);

  dbms_lob.writeappend(vAct,LENGTH('END;'),'END;');
  
  EXECUTE IMMEDIATE vPrg;
  --dbms_output.put_line(vPrg);
  EXECUTE IMMEDIATE vArg;
  --dbms_output.put_line(vArg);
  EXECUTE IMMEDIATE vStp;
  --dbms_output.put_line(vStp);
  EXECUTE IMMEDIATE vRul;
  --dbms_output.put_line(vRul);
  EXECUTE IMMEDIATE vAct;
  --dbms_output.put_line(vAct);
  
  RETURN vChainName;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.ChainBuilder','ERROR :: '||SQLERRM);
  --vChainName := NULL;
  RETURN vChainName;
END ChainBuilder;

FUNCTION ChainStarter(inChainName IN VARCHAR2,inHeadJobName IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
  IS
    vRes VARCHAR2(4000);
    vJobName VARCHAR2(256) := NVL(inHeadJobName,vOwner||'.CHAINJOB_'||job_id_seq.nextval);
BEGIN
  vRes := inChainName;
  sys.dbms_scheduler.run_chain(inChainName,'STP_START',vJobName);
  RETURN vRes;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.ChainStarter','ERROR :: '||SQLERRM);
  RETURN vRes;
END ChainStarter;

PROCEDURE ChainKiller(inChainName VARCHAR2)
  IS
  vRunChCou INTEGER := 1;
  curPrg SYS_REFCURSOR;
  vPrgName VARCHAR2(256);
BEGIN
  -- Ожидание пока отработает цепь
  LOOP
    SELECT COUNT(1) INTO vRunChCou 
      FROM all_scheduler_running_chains 
      WHERE lower(owner)||'.'||lower(chain_name) = LOWER(inChainName);
    EXIT WHEN vRunChCou = 0;
    -- ждем 10 секунд, затем проверяем снова
    stage.mysleep(10);  
  END LOOP;  
  
  -- Открытие курсора с наименованиями программ
  OPEN curPrg FOR
    SELECT LOWER(owner||'.'||program_name) AS prg_name 
      FROM all_scheduler_chain_steps
      WHERE lower(owner)||'.'||lower(chain_name) = LOWER(inChainName);

  -- Удаление цепи
  sys.dbms_scheduler.drop_chain(LOWER(inChainName),TRUE);
  
  -- Удаление программ
  LOOP 
    FETCH curPrg INTO vPrgName;
    EXIT WHEN curPrg%NOTFOUND;
    sys.dbms_scheduler.drop_program(vPrgName,TRUE);
  END LOOP;
  
  CLOSE curPrg;
END ChainKiller;
  
PROCEDURE LoadNew(inSQL IN CLOB,inJobName IN VARCHAR2 DEFAULT NULL)
  IS
    vJobName VARCHAR2(256) := NVL(inJobName,UPPER(vOwner)||'.'||'LOADJOB_'||job_id_seq.nextval);
BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION SET nls_date_format = ''DD.MM.RRRR HH24:MI:SS''';
  ChainKiller(ChainStarter(ChainBuilder(inSQL),vJobName));
  
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.LoadNew',SQLERRM);  
END LoadNew;

PROCEDURE HistTableService(inTableName IN VARCHAR2,inMask IN VARCHAR2
  ,inColumnName VARCHAR2 DEFAULT NULL, inIdxRebuildParallel IN INTEGER DEFAULT 8, inGatherStatsDegree IN INTEGER DEFAULT 2)
  IS
    vDDL CLOB;
    vIDX CLOB;
    vStats CLOB;
    vBuff VARCHAR2(32700);
    vCou INTEGER := 0;
    vJobName VARCHAR2(256);
    --vTableNameHash INTEGER;
    vCompress BOOLEAN := SUBSTR(inMask,1,1) = '1';
    vRebuildIdx BOOLEAN := SUBSTR(inMask,2,1) = '1';
    vGatherStats BOOLEAN := SUBSTR(inMask,3,1) = '1';
    vIdxRebuildParallel INTEGER := NVL(inIdxRebuildParallel,8);
    vGatherStatsDegree INTEGER := NVL(inGatherStatsDegree,2);
    --
    vMes VARCHAR2(32700);
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_normalize_ref_table.HistTableService" started.';
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
  
  -- Если необходим сбор статистики
  IF vGatherStats THEN
    vTIBegin := SYSDATE;
    vJobName := UPPER(vOwner)||'.GATHERSTATSJOB_'||job_id_seq.nextval;
    vCou := 0;

    dbms_lob.createtemporary(vStats,FALSE);
    FOR idx IN (
      SELECT p.table_owner||'.'||p.table_name AS table_name
            ,p.partition_name AS partition_name
        FROM all_tab_partitions p
        WHERE p.table_owner = UPPER(vOwner)
          AND p.table_name = UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))
          AND (UPPER(inColumnName) IS NULL OR
               UPPER(inColumnName) IS NOT NULL AND p.partition_name IN (SELECT str FROM TABLE(parse_str(UPPER(inColumnName),',')))
              )
    ) LOOP
      vBuff :=
      CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.table_name||'|'||idx.partition_name||''' AS id'||CHR(10)||
      '      ,NULL AS parent_id'||CHR(10)||
      '      ,'''||LOWER(vOwner)||'.pkg_normalize_ref_table.MyExecute'' AS unit'||CHR(10)||
      '      ,q''[BEGIN dbms_stats.gather_table_stats(ownname => '''''||UPPER(vOwner)||''''', tabname => '''''||UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))||''''', partname => '''''||idx.partition_name||''''', degree => '||vGatherStatsDegree||', granularity => ''''SUBPARTITION''''); END;]'' AS params'||CHR(10)||
      '  FROM dual';
      dbms_lob.writeappend(vStats,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;
    LoadNew(vStats,vJobName);
    --dbms_output.put_line(vStats);
    
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: Table "'||inTableName||'" - stats gathered in '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
  END IF;    

  -- Если необходимо сжатие
  IF vCompress THEN
    vTIBegin := SYSDATE;
    --SELECT ORA_HASH(inTableName) INTO vTableNameHash FROM dual;
    vJobName := UPPER(vOwner)||'.COMPRESSTABLEJOB_'||job_id_seq.nextval;
    -- После сжатия необходимо обязательное перестроение индексов,
    -- т.к. они становятся UNUSABLE
    -- Устанавливаем соответствующий флаг принудительно
    vRebuildIdx := TRUE;
    vCou := 0;
    
    dbms_lob.createtemporary(vDDL,FALSE);
    FOR idx IN (
      SELECT LOWER(p.table_owner||'.'||p.table_name) AS table_name
            ,LOWER(p.partition_name) AS partition_name
            ,LOWER(s.subpartition_name) AS subpartition_name
        FROM all_tab_partitions p
             LEFT JOIN all_tab_subpartitions s
               ON s.table_owner = p.table_owner
                  AND s.table_name = p.table_name
                  AND s.partition_name = p.partition_name
                  AND NOT(s.subpartition_name LIKE '%POTHERS')
        WHERE p.table_owner = UPPER(vOwner)
          AND p.table_name = UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))
          AND NVL(p.num_rows,0) + NVL(s.num_rows,0) > 0
          AND (UPPER(inColumnName) IS NULL OR
               UPPER(inColumnName) IS NOT NULL AND p.partition_name IN (SELECT str FROM TABLE(parse_str(UPPER(inColumnName),',')))
              )
    ) LOOP
      vBuff :=
      CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.table_name||'|'||CASE WHEN idx.subpartition_name IS NULL THEN idx.partition_name ELSE idx.subpartition_name END||''' AS id'||CHR(10)||
      '      ,NULL AS parent_id'||CHR(10)||
      '      ,'''||LOWER(vOwner)||'.pkg_normalize_ref_table.MyExecute'' AS unit'||CHR(10)||
      '      ,''ALTER TABLE '||idx.table_name||' MOVE'||CASE WHEN idx.subpartition_name IS NULL THEN ' PARTITION '||idx.partition_name ELSE ' SUBPARTITION '||idx.subpartition_name END||' COMPRESS'' AS params'||CHR(10)||
      '  FROM dual';
      dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;
    
    --dbms_output.put_line(vDDL);
    LoadNew(vDDL,vJobName);

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: Table "'||inTableName||'" - '||vCou||' partitions compressed in '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
  END IF;
  
  -- Если необходимо перестроение индексов
  IF vRebuildIdx THEN
    vTIBegin := SYSDATE;
    dbms_lob.createtemporary(vIDX,FALSE);
    vBuff := 'BEGIN'||CHR(10);
    dbms_lob.writeappend(vIDX,LENGTH(vBuff),vBuff);
    vCou := 0;
    FOR idx IN (
      SELECT LOWER(i.owner||'.'||i.index_name) AS index_name
            ,LOWER(ip.partition_name) AS partition_name
            ,LOWER(sp.subpartition_name) AS subpartition_name 
        FROM all_indexes i
             LEFT JOIN all_ind_partitions ip
               ON ip.index_owner = i.owner
                  AND ip.index_name = i.index_name
                  AND (UPPER(inColumnName) IS NULL OR
                       UPPER(inColumnName) IS NOT NULL AND ip.partition_name IN (SELECT str FROM TABLE(parse_str(UPPER(inColumnName),',')))
                      )
             LEFT JOIN all_ind_subpartitions sp
               ON sp.index_owner = ip.index_owner
                  AND sp.index_name = ip.index_name
                  AND sp.partition_name = ip.partition_name
                  AND NOT(sp.subpartition_name LIKE '%POTHERS')
        WHERE i.owner = UPPER(vOwner)
          AND i.table_name = UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))
          AND (ip.status = 'UNUSABLE' OR sp.status = 'UNUSABLE')
    ) LOOP
      vBuff := 'EXECUTE IMMEDIATE ''ALTER INDEX '||idx.index_name||' REBUILD'||CASE WHEN idx.subpartition_name IS NULL THEN ' PARTITION '||idx.partition_name ELSE ' SUBPARTITION '||idx.subpartition_name END||' PARALLEL '||vIdxRebuildParallel||'''; '||CHR(10);
      dbms_lob.writeappend(vIDX,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;  
    vBuff := 'END;';
    dbms_lob.writeappend(vIDX,LENGTH(vBuff),vBuff);

    BEGIN
      EXECUTE IMMEDIATE vIDX;
      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: Table "'||inTableName||'" - '||vCou||' partitions rebuilded in '||get_ti_as_hms(vEndTime - vTIBegin);
      pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
    EXCEPTION WHEN OTHERS THEN  
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Table "'||inTableName||'" :: Rebuild of indexses finished in '||get_ti_as_hms(vEndTime - vTIBegin)||' with error:'||CHR(10)||SQLERRM;
      pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
    END;
  END IF;
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_normalize_ref_table.HistTableService" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_normalize_ref_table.HistTableService" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_normalize_ref_table.HistTableService" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_normalize_ref_table.HistTableService',vMes);
END HistTableService;

END pkg_normalize_ref_table;
/
