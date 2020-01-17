CREATE OR REPLACE PACKAGE DM_SKB.pkg_etl_signs
  IS
    TYPE recStr IS RECORD (ord NUMBER,str VARCHAR2(4000));
    TYPE tabStr IS TABLE OF recStr;
    TYPE TRec IS RECORD
      (obj_gid NUMBER
      ,source_system_id NUMBER
      ,sign_name VARCHAR2(256)
      ,sign_val VARCHAR2(4000));
    TYPE TTab IS TABLE OF TRec;
    TYPE TRecMass IS RECORD
      (effective_start DATE
      ,effective_end DATE
      ,obj_gid NUMBER
      ,source_system_id NUMBER
      ,sign_name VARCHAR2(256)
      ,sign_val VARCHAR2(4000));
    TYPE TTabMass IS TABLE OF TRecMass;
    TYPE TRecCHBuilder IS RECORD
      (Id VARCHAR2(256),Parent_id VARCHAR2(256),Unit VARCHAR2(256),Params VARCHAR2(4000),Skip NUMBER);
    TYPE TTabCHBuilder IS TABLE OF TRecCHBuilder;
    TYPE TRecTree IS RECORD (Id VARCHAR2(4000),ParentId VARCHAR2(4000));
    TYPE TTabTree IS TABLE OF TRecTree;
    TYPE TRecAnltSpecImp IS RECORD
      (val VARCHAR2(4000)
      ,parent_val VARCHAR2(4000)
      ,name VARCHAR2(4000)
      ,condition CLOB/*VARCHAR2(32700)*/);
    TYPE TTabAnltSpecImp IS TABLE OF TRecAnltSpecImp;
    TYPE TRecLabels IS RECORD
      (id NUMBER,parent_id NUMBER,caption VARCHAR2(4000), ord NUMBER, form_id NUMBER);
    TYPE TTabLabels IS TABLE OF TRecLabels;
    TYPE TRecReports IS RECORD (id NUMBER,query_name VARCHAR2(256), query_descr VARCHAR2(4000), ord NUMBER);
    TYPE TTabReports IS TABLE OF TRecReports;

  FUNCTION GetLabels(inOSUser VARCHAR2) RETURN TTabLabels PIPELINED;
  FUNCTION GetReports(inOSUser VARCHAR2,inFormID NUMBER) RETURN TTabReports PIPELINED;
  PROCEDURE pr_log_write(inUnit IN VARCHAR2,inMessage IN VARCHAR2);
  PROCEDURE pr_stat_write(inSignName IN VARCHAR2,inAnltCode IN VARCHAR2,inSec NUMBER,inAction VARCHAR2);
  FUNCTION get_ti_as_hms (inInterval IN NUMBER /*интервал в днях*/) RETURN VARCHAR2;
  FUNCTION parse_str(inStr VARCHAR2,inSeparator IN VARCHAR2) RETURN tabStr PIPELINED;
  FUNCTION isEqual(n1 IN NUMBER,n2 IN NUMBER) RETURN NUMBER;
  FUNCTION isEqual(v1 IN VARCHAR2,v2 IN VARCHAR2) RETURN NUMBER;
  FUNCTION isEqual(d1 IN DATE,d2 IN DATE) RETURN NUMBER;
  FUNCTION isEqual(c1 IN CLOB,c2 IN CLOB) RETURN NUMBER;
  FUNCTION DBLinkReady(inDBLinkName VARCHAR2) RETURN BOOLEAN;
  FUNCTION GetConditionResult(inCondition IN CLOB) RETURN NUMBER;
  PROCEDURE mass_load_parallel_by_date_pe(inBeg IN DATE, inEnd IN DATE, inUnit IN VARCHAR2 DEFAULT NULL
    ,inParams IN VARCHAR2 DEFAULT NULL);
  PROCEDURE mass_load_parallel_by_month (inBegDate IN DATE, inEndDate IN DATE, inProcedure IN VARCHAR2
    ,inParams VARCHAR2 DEFAULT NULL);
  PROCEDURE mass_load_parallel_by_ydate_pe
    (inBegDate IN DATE, inEndDate IN DATE, inUnit IN VARCHAR2
    ,inParams IN VARCHAR2 DEFAULT NULL
    ,inLastDay BOOLEAN DEFAULT TRUE
    ,inMonthlyDay VARCHAR2 DEFAULT NULL);
  PROCEDURE mass_load_parallel_by_year
    (inBegDate IN DATE, inEndDate IN DATE, inProcedure IN VARCHAR2
    ,inParams VARCHAR2 DEFAULT NULL
    ,inLastDay BOOLEAN DEFAULT TRUE
    ,inMonthlyDay VARCHAR2 DEFAULT NULL
    ,inYearParallel BOOLEAN DEFAULT FALSE
    ,inHeadJobName IN VARCHAR2 DEFAULT NULL);
  PROCEDURE MyExecute(inScript IN VARCHAR2);
  PROCEDURE AnyExecute(inScript IN CLOB,inParams IN VARCHAR2 DEFAULT NULL);
  PROCEDURE prepare_entity(inID IN NUMBER,outRes OUT CLOB);
  PROCEDURE prepare_log_table(outRes OUT VARCHAR2);
  FUNCTION get_sign(inSign IN VARCHAR2,inDate IN DATE, inSQL IN VARCHAR2 DEFAULT NULL) RETURN TTab PIPELINED;
  FUNCTION get_sign_anlt(inSign IN VARCHAR2,inDate IN DATE, inAnltCode IN VARCHAR2, inReverse NUMBER DEFAULT 0) RETURN TTab PIPELINED;
  FUNCTION get_anlt_spec_imp(inDate IN DATE, inAnltCode IN VARCHAR2) RETURN TTabAnltSpecImp PIPELINED;
  FUNCTION get_sign_mass(inSign IN VARCHAR2,inDate IN DATE) RETURN TTabMass PIPELINED;
  -- Подготовка субпартиций в таблицах
  FUNCTION CheckSubpartition(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2) RETURN VARCHAR2;
  PROCEDURE CheckSubpartition(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2);
  FUNCTION CompressSubpartition(inDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2) RETURN VARCHAR2;
  PROCEDURE CompressSubpartition(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2);
  --
  PROCEDURE tb_load_daily(inBegDate IN DATE,inEndDate IN DATE,inSign VARCHAR2,inAnltCode IN VARCHAR2);
  PROCEDURE ptb_load_daily(inBegDate IN DATE,inEndDate IN DATE,inSign VARCHAR2,inAnltCode IN VARCHAR2);
  PROCEDURE load_sign(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inPrepareSegments NUMBER);
  --  ******************  КОНЕЧНЫЕ ПРОЦЕДУРЫ ДЛЯ ЗАПУСКА РАСЧЕТОВ *****************
  --  ******************  ДЛЯ ИСПОЛЬЗОВАНИЯ В РАБОЧЕМ ПОРЯДКЕ *********************
  -- параллельная заливка указанных показателей за одну дату
  -- если параметр inSign не указан, то параллельная заливка ВСЕХ показателей за одну дату
  -- пример параметра inSign:  'ACCOUNT_CUM_COLATERAL,ACCOUNT_SUM_61312,ACOUNT_SUM_91414'
  PROCEDURE load_new(inSQL IN CLOB,inJobName IN VARCHAR2 DEFAULT NULL,inCalcPoolId NUMBER DEFAULT NULL);
  PROCEDURE load (inBegDate IN DATE,inEndDate IN DATE);
  -- *******************************************************************************
  -- *******************************************************************************
  -- Массовая загрузка показателя
  PROCEDURE mass_load(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inPrepareSegments NUMBER);
  -- Склеивание периодов в исторических показателях
  --(необходимо например после "раздельно - массовой" загрузки исторического показателя)
  PROCEDURE sign_gluing(inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inMask IN VARCHAR2 DEFAULT '111');
  PROCEDURE tmp_load_prev(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2);
  PROCEDURE tmp_load_daily(inBegDate IN DATE,inEndDate IN DATE,inSign VARCHAR2,inAnltCode IN VARCHAR2);
  PROCEDURE tb_upd_eff_end(inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inDate IN DATE DEFAULT NULL);
  PROCEDURE tb_load_mass(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2
    ,inMask IN VARCHAR2 DEFAULT '111111');
  /***************************************************************
   * Расшифровка маски:                                          *
   *  1-й символ: Предварительная загрузка 1-х чисел месяца      *
   *              в промежуточную тиаблицу                       *
   *  2-й символ: Прогрузка данных в промежуточной таблице       *
   *              за каждое число месяца, начиная со 2-го        *
   *  3-й символ: Очистка целевой партиции (если 0 то происходит *
   *              подгонка effective_start и effective_end       *
   *              по началу и окончанию периода)                 *
   *  4-й символ: Загрузка данных в целевую таблицу              *
   *  5-й символ: Сжатие данных и перестроение индексов в        *
   *              целевой таблице                                *
   *  6-й символ: Сбор статистики по целевой таблице             *
   ***************************************************************/
  PROCEDURE SignExtProcessing(inSign IN VARCHAR2,inDate IN DATE);
  FUNCTION get_empty_sign_id RETURN NUMBER;
  FUNCTION DropSignPartitions(inSign IN VARCHAR2) RETURN VARCHAR2;
  PROCEDURE drop_sign(inSign IN VARCHAR2,outRes OUT VARCHAR2);
  FUNCTION GetTreeList(inSQL IN CLOB) RETURN TTabTree PIPELINED;
  FUNCTION GetChainList(inSQL IN CLOB) RETURN TTabCHBuilder PIPELINED;
  FUNCTION GetTreeSQL(inFullSQL IN CLOB
                   ,inStartSQL IN CLOB
                   ,inIncludeChilds IN INTEGER DEFAULT 0)
    RETURN CLOB;
  FUNCTION ChainBuilder(/*inID VARCHAR2,*/inSQL CLOB) RETURN VARCHAR2;
  FUNCTION ChainStarter(inChainName IN VARCHAR2,inHeadJobName IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;
  PROCEDURE ChainKiller(inChainName VARCHAR2);
  PROCEDURE calc(inBegDate IN DATE,inEndDate IN DATE);
  PROCEDURE CalcSignsByGroup(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2);
  PROCEDURE CalcSignsByStar(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2);
  PROCEDURE CalcAnltByGroup(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2);
  PROCEDURE CalcAnltByStar(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2);
  /*********  ИМПОРТ - ЭКСПОРТ *************/
  FUNCTION AnltSpecImpGetCondition(inSignName VARCHAR2,inIds VARCHAR2 DEFAULT NULL,inProduct IN NUMBER DEFAULT 0) RETURN CLOB; -- 0 - показатель; 1 - продукт
  PROCEDURE AnltSpecImport(inDate IN DATE,inAnltCode IN VARCHAR2);
 /******  ЗВЁЗДЫ И ВСЁ ЧТО С НИМИ СВЯЗАНО ***************************/
  FUNCTION  GetAnltLineSQL(inSQL IN CLOB,inIDName IN VARCHAR2
    ,inPIDName IN VARCHAR2,inName IN VARCHAR2,inValue IN VARCHAR2) RETURN CLOB;
  PROCEDURE StarPrepareDim(inDate IN DATE,inGroupID IN NUMBER,inEntityID IN NUMBER);
  PROCEDURE StarPrepareFct(inDate IN DATE,inGroupID IN NUMBER);
  PROCEDURE StarFctOnDate(inDate IN DATE,inGroupID IN NUMBER,inEntityID IN NUMBER); -- таблица фактов за дату
  PROCEDURE StarDimOnDate(inDate IN DATE,inGroupID IN NUMBER,inEntityID IN NUMBER); -- таблица измерения за дату
  PROCEDURE StarAnltOnDate(inDate IN DATE,inGroupID IN NUMBER,inAnltAlias IN VARCHAR2); -- таблица измерения - аналитики за дату

  PROCEDURE StarPrepare(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER); -- подготовка таблиц за период
  PROCEDURE StarClear(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER); -- очистка звезды за период
  PROCEDURE
  /************************************
   Описание маски (0 - не выполнять, 1 - выполнять):
   1-й символ - предварительный пересчет всех показателей по кубу
   2-й символ - предварительный пересчет всех аналитик по кубу
  ************************************/
    StarExpand(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inMask VARCHAR2 DEFAULT '00',inCalcPoolId NUMBER DEFAULT NULL); -- разворачивание звезды за период
  PROCEDURE StarCompress(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER); -- сжатие звезды за период
  PROCEDURE StarDropOldParts(inDate IN DATE,inGroupID IN NUMBER);
  /********************************************************************/
  /************************ Техническое обслуживание ******************/
  PROCEDURE HistTableService(inTableName IN VARCHAR2,inMask IN VARCHAR2,inSign IN VARCHAR2 DEFAULT NULL);
  /***************************************************************
   * Расшифровка маски:                                          *
   *  1-й символ: Сжатие данных                                  *
   *  2-й символ: Перестроение индексов                          *
   *  3-й символ: Сбор статистики                                *
   ***************************************************************/
  /********************************************************************/
  FUNCTION GetVarCLOBValue(inVarName VARCHAR2) RETURN CLOB DETERMINISTIC;
  FUNCTION GetVarValue(inVarName VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;
  /********************************************************************/
  FUNCTION call_hist(inTable IN VARCHAR2, inID IN VARCHAR2,inAction VARCHAR2) RETURN VARCHAR2;
  FUNCTION CanHaveHistory(inTable IN VARCHAR2) RETURN BOOLEAN;
  PROCEDURE SetFlag(inName IN VARCHAR2,inDate IN DATE,inVal IN VARCHAR2 DEFAULT NULL,inAction NUMBER DEFAULT 1); -- 1 - UPSERT, 0 - DELETE
  FUNCTION GetFlag(inFlagName IN VARCHAR2, inDate IN DATE) RETURN VARCHAR2;
  -- Грубый анализатор объектов на наличие персональных данных
  FUNCTION PDCA(inObj IN VARCHAR2, inAnalyzeContent IN NUMBER DEFAULT 0) RETURN VARCHAR2;
  FUNCTION SQLasHTML(inSQL IN CLOB,inColNames IN VARCHAR2,inColAliases IN VARCHAR2,inStyle IN VARCHAR2 DEFAULT NULL,inShowLogo BOOLEAN DEFAULT FALSE,inTabHeader VARCHAR2 DEFAULT NULL) RETURN CLOB;
END pkg_etl_signs;
/
CREATE OR REPLACE PACKAGE BODY DM_SKB.pkg_etl_signs
  IS
FUNCTION GetLabels(inOSUser VARCHAR2) RETURN TTabLabels PIPELINED
  IS
    Rec TRecLabels;
BEGIN
  FOR idx IN (
    WITH
      rol AS (
        SELECT r.id
          FROM tb_role_registry r
        CONNECT BY PRIOR r.id = r.parent_id
        START WITH r.id IN (SELECT ur.role_id
                              FROM tb_urole_registry ur
                                   INNER JOIN tb_labrole_registry lr ON lr.role_id = ur.role_id
                                   INNER JOIN tb_user_registry u ON u.id = ur.user_id AND LOWER(u.user_name) = LOWER(inOSUser)
                           )
      )
    SELECT DISTINCT l.id,l.parent_id,l.caption,l.ord,l.form_id
      FROM tb_label_registry l
    CONNECT BY PRIOR l.id = l.parent_id
    START WITH l.id IN (SELECT lr.label_id FROM tb_labrole_registry lr
                          WHERE lr.label_id = l.id
                            AND lr.role_id IN (SELECT ID FROM rol))
  ) LOOP
    Rec.id := idx.id;
    Rec.parent_id := idx.parent_id;
    Rec.caption := idx.caption;
    Rec.ord := idx.ord;
    Rec.form_id := idx.form_id;
    PIPE ROW(Rec);
  END LOOP;
END;

FUNCTION GetReports(inOSUser VARCHAR2,inFormID NUMBER) RETURN TTabReports PIPELINED
  IS
    Rec TRecReports;
BEGIN
  FOR idx IN (
    WITH
      rol AS (
        SELECT r.id
          FROM tb_role_registry r
        CONNECT BY PRIOR r.id = r.parent_id
        START WITH r.id IN (SELECT ur.role_id
                              FROM tb_urole_registry ur
                                   INNER JOIN tb_user_registry u ON u.id = ur.user_id AND LOWER(u.user_name) = LOWER(inOSUser)
                           )
      )
    SELECT q.id,q.query_name,q.query_descr,q.ord
      FROM tb_query_registry q
           INNER JOIN tb_repform_registry rf
             ON rf.query_id = q.id
                AND rf.form_id = inFormID
      WHERE q.id IN (SELECT qr.query_id FROM tb_qrole_registry qr
                          WHERE qr.query_id = q.id
                            AND qr.role_id IN (SELECT ID FROM rol))
        AND q.is_report = 1
  ) LOOP
    Rec.id := idx.id;
    Rec.query_name := idx.query_name;
    Rec.query_descr := idx.query_descr;
    Rec.ord := idx.ord;
    PIPE ROW(Rec);
  END LOOP;
END;

PROCEDURE pr_log_write(inUnit IN VARCHAR2,inMessage IN VARCHAR2)
  IS
    vBuff VARCHAR2(32700);
    PRAGMA AUTONOMOUS_TRANSACTION;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
   vBuff :=
   'BEGIN'||CHR(10)||
   'INSERT INTO '||lower(vOwner)||'.tb_signs_log (dat, unit, message) VALUES (SYSDATE,:1,:2);'||CHR(10)||
   'END;';
   EXECUTE IMMEDIATE vBuff USING IN inUnit, IN inMessage;
   COMMIT;
END pr_log_write;

PROCEDURE pr_stat_write(inSignName IN VARCHAR2,inAnltCode IN VARCHAR2,inSec NUMBER,inAction VARCHAR2)
  IS
    vBuff VARCHAR2(32700);
    PRAGMA AUTONOMOUS_TRANSACTION;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
   vBuff :=
   'BEGIN'||CHR(10)||
   'INSERT INTO '||lower(vOwner)||'.tb_signs_calc_stat (sign_name,anlt_code,sec,action) VALUES (:1,:2,:3,:4);'||CHR(10)||
   'END;';
   EXECUTE IMMEDIATE vBuff USING IN inSignName,IN inAnltCode,IN inSec,IN inAction;
   COMMIT;
END pr_stat_write;

FUNCTION get_ti_as_hms (inInterval IN NUMBER /*интервал в днях*/) RETURN VARCHAR2
  IS
BEGIN
  RETURN LPAD(TO_CHAR(TRUNC(inInterval*24*60*60/3600)),3,' ')||'h '||LPAD(TO_CHAR(TRUNC(MOD(inInterval*24*60*60,3600)/60)),2,' ')||'m '||LPAD(TO_CHAR(ROUND(MOD(MOD(inInterval*24*60*60,3600),60),0)),2,' ')||'s';
END get_ti_as_hms;

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

FUNCTION isEqual(c1 IN CLOB,c2 IN CLOB) RETURN NUMBER
  IS
BEGIN
  IF dbms_lob.compare(c1,c2) = 0 THEN RETURN 1; ELSE RETURN 0; END IF;
END isEqual;

FUNCTION DBLinkReady(inDBLinkName VARCHAR2) RETURN BOOLEAN
  IS
    vRes NUMBER := 0;
BEGIN
  EXECUTE IMMEDIATE 'SELECT 1 FROM dual@'||inDBLinkName INTO vRes;
  RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
  RETURN FALSE;
END DBLinkReady;

FUNCTION GetConditionResult(inCondition IN CLOB) RETURN NUMBER
  IS
    vResult NUMBER;
BEGIN
  IF inCondition IS NULL THEN
    RETURN 1;
  ELSE
    EXECUTE IMMEDIATE 'DECLARE vRes BOOLEAN; BEGIN vRes := '||inCondition||'; IF vRes THEN :1 := 1; ELSE :1 := 0; END IF; END;' USING OUT vResult;
    RETURN vResult;
  END IF;
END;

PROCEDURE mass_load_parallel_by_date_pe(inBeg IN DATE, inEnd IN DATE, inUnit IN VARCHAR2 DEFAULT NULL
  ,inParams IN VARCHAR2 DEFAULT NULL)
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vPLev NUMBER;
    vTry NUMBER;
    vStatus NUMBER;
    vTask VARCHAR2(255) := dbms_parallel_execute.generate_task_name;
    vParams VARCHAR2(32700);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
  BEGIN
    vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe" started.';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe',vMes);

    -- Формирование строки доп. параметров
    IF inParams IS NOT NULL THEN
      FOR idx IN (
        SELECT SUBSTR(str,1,INSTR(str,' ',1,1)-1) AS param_type
              ,SUBSTR(str,INSTR(str,' ',1,1)+1) AS param_value
        FROM TABLE(parse_str(inParams,'::'))
      ) LOOP
        vParams := vParams||
          CASE idx.param_type
            WHEN 'VARCHAR2' THEN ''''''||idx.param_value||''''''
            WHEN 'DATE' THEN 'to_date('''''||idx.param_value||''''',''''DD.MM.YYYY'''')'
          ELSE idx.param_value END||',';
      END LOOP;
      vParams := SUBSTR(vParams,1,LENGTH(vParams) - 1)  ;
    END IF;
    --Вычисление количества потоков
    SELECT TRUNC(to_number(VALUE)/5*4) INTO vPLev FROM v$parameter WHERE NAME = 'job_queue_processes';

    -- Создание временной таблицы
    EXECUTE IMMEDIATE 'CREATE TABLE '||lower(vOwner)||'.tmp_'||vTask||' (id NUMBER,exec_sql VARCHAR2(2000))';
    FOR idx IN (SELECT rownum AS id
               ,'begin '||inUnit||'(to_date('''''||to_char(inBeg+rownum-1,'DD.MM.YYYY')||''''',''''DD.MM.YYYY''''),to_date('''''||to_char(inBeg+rownum-1,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')'||NVL2(vParams,','||vParams,'')||'); end;' AS vSQL
      FROM dual CONNECT BY ROWNUM <= inEnd - inBeg + 1)
    LOOP
      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'INSERT INTO '||lower(vOwner)||'.tmp_'||vTask||' (id,exec_sql)
        VALUES ('||idx.id||','''||idx.vsql||''')'
      --)
      ;
      --dbms_output.put_line(idx.vSQL);
    END LOOP;


      --Наименование задачи
      DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => vTask);

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
                      begin
                         SELECT exec_sql INTO vSQL
                           FROM '||lower(vOwner)||'.tmp_'||vTask||'
                           WHERE id = :start_id AND id = :end_id
                         ;
                        execute immediate vSQL;
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

      -- Удаление временной таблицы
      EXECUTE IMMEDIATE 'DROP TABLE '||lower(vOwner)||'.tmp_'||vTask;

    vEndTime := SYSDATE;
    vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe',vMes);
  EXCEPTION WHEN OTHERS THEN
    DBMS_PARALLEL_EXECUTE.drop_task(vTask);
    vEndTime := SYSDATE;
    vMes := 'ERROR :: '||SQLERRM;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe',vMes);
    vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe',vMes);
  END mass_load_parallel_by_date_pe;

PROCEDURE mass_load_parallel_by_month (inBegDate IN DATE, inEndDate IN DATE, inProcedure IN VARCHAR2
  ,inParams VARCHAR2 DEFAULT NULL)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  FOR idx IN (SELECT MIN(TRUNC(InEndDate,'DD') - ROWNUM +1) min_dt
                    ,MAX(TRUNC(InEndDate,'DD') - ROWNUM +1) max_dt
                    ,'
                      BEGIN
                        '||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_date_pe(to_date('''||TO_CHAR(MIN(TRUNC(InEndDate,'DD') - ROWNUM +1),'DD.MM.YYYY')||''',''DD.MM.YYYY'')
                                                           ,to_date('''||TO_CHAR(MAX(TRUNC(InEndDate,'DD') - ROWNUM +1),'DD.MM.YYYY')||''',''DD.MM.YYYY'')
                                                           ,'''||inProcedure||''','''||inParams||''');
                      END;
                    ' as exec_sql
                  FROM DUAL CONNECT BY ROWNUM < TRUNC(InEndDate,'DD') - TRUNC(inBegDate,'DD') + 2
                  GROUP BY TRUNC(TRUNC(InEndDate,'DD')- ROWNUM +1,'MM')
              ORDER BY 1
             )
  LOOP
    EXECUTE IMMEDIATE idx.exec_sql;
  END LOOP;
END mass_load_parallel_by_month;

PROCEDURE mass_load_parallel_by_ydate_pe
  (inBegDate IN DATE, inEndDate IN DATE, inUnit IN VARCHAR2
  ,inParams IN VARCHAR2 DEFAULT NULL
  ,inLastDay BOOLEAN DEFAULT TRUE
  ,inMonthlyDay VARCHAR2 DEFAULT NULL)
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vPLev NUMBER;
    vTry NUMBER;
    vStatus NUMBER;
    vTask VARCHAR2(255) := dbms_parallel_execute.generate_task_name;
    vParams VARCHAR2(4000);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe',vMes);

  -- Формирование строки доп. параметров
  IF inParams IS NOT NULL THEN
    FOR idx IN (
      SELECT SUBSTR(str,1,INSTR(str,' ',1,1)-1) AS param_type
            ,SUBSTR(str,INSTR(str,' ',1,1)+1) AS param_value
      FROM TABLE(parse_str(inParams,'::'))
    ) LOOP
      vParams := vParams||
        CASE idx.param_type
          WHEN 'VARCHAR2' THEN ''''''||idx.param_value||''''''
          WHEN 'DATE' THEN 'to_date('''''||idx.param_value||''''',''''DD.MM.YYYY'''')'
        ELSE idx.param_value END||',';
    END LOOP;
    vParams := SUBSTR(vParams,1,LENGTH(vParams) - 1)  ;
  END IF;

  --Создание временной таблицы
  EXECUTE IMMEDIATE 'CREATE TABLE '||lower(vOwner)||'.tmp_'||vTask||' (id NUMBER,exec_sql VARCHAR2(2000))';

  IF inLastDay AND NVL(to_number(inMonthlyDay, 'FM99', 'nls_numeric_characters='', '''),0) = 0 THEN
    FOR idx IN (SELECT ROWNUM AS ID
                      ,'BEGIN
                       '||inUnit||'(to_date('''''||TO_CHAR(LAST_DAY(ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1)),'DD.MM.YYYY')||''''',''''DD.MM.YYYY''''),to_date('''''||TO_CHAR(LAST_DAY(ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1)),'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')'||NVL2(vParams,','||vParams,'')||'); END;' as exec_sql
                  FROM DUAL CONNECT BY ROWNUM <= MONTHS_BETWEEN(TRUNC(InEndDate,'MM'),TRUNC(inBegDate,'MM')) + 1
                ORDER BY 1
               )
    LOOP
      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'INSERT INTO '||lower(vOwner)||'.tmp_'||vTask||' (id,exec_sql)
        VALUES ('||idx.id||','''||idx.exec_sql||''')'
      --)
      ;
    END LOOP;
  ELSIF NOT inLastDay AND NVL(to_number(inMonthlyDay, 'FM99', 'nls_numeric_characters='', '''),0) = 0 THEN
    FOR idx IN (SELECT ROWNUM AS ID
                      ,'BEGIN
                         '||inUnit||'(to_date('''''||TO_CHAR(ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1),'DD.MM.YYYY')||''''',''''DD.MM.YYYY''''),to_date('''''||TO_CHAR(ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1),'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')'||NVL2(vParams,','||vParams,'')||'); END;' AS exec_sql
                    FROM DUAL CONNECT BY ROWNUM <= MONTHS_BETWEEN(TRUNC(InEndDate,'MM'),TRUNC(inBegDate,'MM')) + 1
                ORDER BY 1
               )
    LOOP
      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'INSERT INTO '||lower(vOwner)||'.tmp_'||vTask||' (id,exec_sql)
        VALUES ('||idx.id||','''||idx.exec_sql||''')'
      --)
      ;
    END LOOP;
  ELSE
    FOR idx IN (SELECT ROWNUM AS ID
                      ,CASE WHEN EXTRACT(MONTH FROM ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1)) = EXTRACT(MONTH FROM ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1) + NVL(to_number(inMonthlyDay, 'FM99', 'nls_numeric_characters='', '''),0) - 1) THEN
                         'BEGIN
                         '||inUnit||'(to_date('''''||TO_CHAR(ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1) + NVL(to_number(inMonthlyDay, 'FM99', 'nls_numeric_characters='', '''),0) - 1,'DD.MM.YYYY')||''''',''''DD.MM.YYYY''''),to_date('''''||TO_CHAR(ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1) + NVL(to_number(inMonthlyDay, 'FM99', 'nls_numeric_characters='', '''),0) - 1,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')'||NVL2(vParams,','||vParams,'')||'); END;'
                       ELSE 'BEGIN '||lower(vOwner)||'.pkg_etl_signs.pr_log_write('''''||inUnit||''''',''''INFORMATION :: "'||inMonthlyDay||'.'||TRIM(to_char(EXTRACT(MONTH FROM ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1)),'00')||'.'||EXTRACT(YEAR FROM ADD_MONTHS(TRUNC(InEndDate,'MM'),-ROWNUM + 1)))||'" - дата отсутствует в указанном месяце. Расчет не требуется''''); END;'
                       END AS exec_sql
                    FROM DUAL CONNECT BY ROWNUM <= MONTHS_BETWEEN(TRUNC(InEndDate,'MM'),TRUNC(inBegDate,'MM')) + 1
                ORDER BY 1
               )
    LOOP
      BEGIN
      vMes :=
      --dbms_output.put_line(
      'INSERT INTO '||lower(vOwner)||'.tmp_'||vTask||' (id,exec_sql)
        VALUES ('||idx.id||','''||idx.exec_sql||''')'
      --)
      ;
      EXECUTE IMMEDIATE vMes;
      EXCEPTION WHEN OTHERS THEN
        pr_log_write(inUnit,SQLERRM||Chr(10)||vMes);
      END;
    END LOOP;
  END IF;

  --Вычисление количества потоков
  SELECT TRUNC(to_number(VALUE)/5*4) INTO vPLev FROM v$parameter WHERE NAME = 'job_queue_processes';

  --Наименование задачи
  DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => vTask);
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
                  begin
                     SELECT exec_sql INTO vSQL
                       FROM '||lower(vOwner)||'.tmp_'||vTask||'
                       WHERE id = :start_id AND id = :end_id
                     ;
                    execute immediate vSQL;
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

  -- Удаление временной таблицы
  EXECUTE IMMEDIATE 'DROP TABLE '||lower(vOwner)||'.tmp_'||vTask;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe',vMes);
EXCEPTION WHEN OTHERS THEN
  DBMS_PARALLEL_EXECUTE.drop_task(vTask);
  vEndTime := SYSDATE;
  vMes := 'ERROR :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe',vMes);
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load_parallel_by_ydate_pe',vMes);
END mass_load_parallel_by_ydate_pe;

PROCEDURE mass_load_parallel_by_year
  (inBegDate IN DATE, inEndDate IN DATE, inProcedure IN VARCHAR2
  ,inParams VARCHAR2 DEFAULT NULL
  ,inLastDay BOOLEAN DEFAULT TRUE
  ,inMonthlyDay VARCHAR2 DEFAULT NULL
  ,inYearParallel BOOLEAN DEFAULT FALSE
  ,inHeadJobName IN VARCHAR2 DEFAULT NULL)
  IS
    vLstDay VARCHAR2(5);
    vTask VARCHAR2(256);
    vTry NUMBER;
    vStatus NUMBER;
    vPLev NUMBER;
    vSQL_stmt VARCHAR2(32700);
BEGIN
  IF inLastDay THEN vLstDay := 'TRUE'; ELSE vLstDay := 'FALSE'; END IF;
  IF inYearParallel THEN
    --Наименование задачи
    vTask := dbms_parallel_execute.generate_task_name;
    --Создание задачи
    DBMS_PARALLEL_EXECUTE.CREATE_TASK(task_name => vTask);

   -- Вычисление количества потоков
    SELECT TRUNC(to_number(VALUE)/5*4) INTO vPLev FROM v$parameter WHERE NAME = 'job_queue_processes';

    --Раскладка по потокам
    DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL
      (task_name => vTask
      ,sql_stmt =>
        'SELECT ROWNUM AS ID,ROWNUM as ID FROM (
          SELECT EXTRACT(YEAR FROM to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - ROWNUM + 1) as y
            FROM dual CONNECT BY ROWNUM <= to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - to_date('''||to_char(inBegDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') + 1
          GROUP BY EXTRACT(YEAR FROM to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - ROWNUM + 1)
          ORDER BY 1
        )'
      ,by_rowid => FALSE
      );

     vSql_stmt := 'declare
                    vSQL VARCHAR2(4000);
                  begin
                    WITH
                      y as (
                        SELECT ROWNUM AS ID,y_beg,y_end FROM (
                          SELECT MIN(to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - ROWNUM + 1) AS y_beg
                                ,MAX(to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - ROWNUM + 1) AS y_end
                            FROM dual CONNECT BY ROWNUM <= to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - to_date('''||to_char(inBegDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') + 1
                          GROUP BY EXTRACT(YEAR FROM to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') - ROWNUM + 1)
                          ORDER BY 1
                        )
                      )
                     SELECT ''
                      BEGIN
                        mass_load_parallel_by_ydate_pe(to_date(''''''||to_char(y.y_beg,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')
                                                             ,to_date(''''''||to_char(y.y_end,''DD.MM.YYYY'')||'''''',''''DD.MM.YYYY'''')
                                                             ,'''''||inProcedure||'''''
                                                             ,'||CASE WHEN inParams IS NOT NULL THEN ''''''||inParams||'''''' ELSE 'NULL' END||'
                                                             ,'||vLstDay||CASE WHEN inMonthlyDay IS NOT NULL THEN ','''''||inMonthlyDay||'''''' ELSE NULL END||'
                                                             ,'''''||inHeadJobName||''''');
                      END;
                    '' as exec_sql
                       INTO vSQL
                       FROM y
                       WHERE id = :start_id AND id = :end_id
                     ;
                    execute immediate vSQL;
                    commit;
                  end;';

    --Запуск задачи на выполнение
    DBMS_PARALLEL_EXECUTE.RUN_TASK (task_name => vTask
       ,sql_stmt => vSql_stmt
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

  ELSE
    FOR idx IN (SELECT GREATEST(TRUNC(add_months(inEndDate,-(ROWNUM-1)*12),'YYYY'),inBegDate) AS min_dt
                      ,LEAST(add_months(TRUNC(add_months(inEndDate,-(ROWNUM-1)*12),'YYYY'),12) - 1,inEndDate) AS max_dt
                      ,'BEGIN'||Chr(10)||
                       '   mass_load_parallel_by_ydate_pe(to_date('''||TO_CHAR(GREATEST(TRUNC(add_months(inEndDate,-(ROWNUM-1)*12),'YYYY'),inBegDate),'DD.MM.YYYY')||''',''DD.MM.YYYY'')'||Chr(10)||
                       '                                       ,to_date('''||TO_CHAR(LEAST(add_months(TRUNC(add_months(inEndDate,-(ROWNUM-1)*12),'YYYY'),12) - 1,inEndDate),'DD.MM.YYYY')||''',''DD.MM.YYYY'')'||Chr(10)||
                       '                                       ,'''||inProcedure||''''||Chr(10)||
                       '                                       ,'||CASE WHEN inParams IS NOT NULL THEN ''''||inParams||'''' ELSE 'NULL' END||Chr(10)||
                       '                                       ,'||vLstDay||NVL2(inMonthlyDay,','''||inMonthlyDay||'''',NULL)||'
                                                               ,'''''||inHeadJobName||''''');'||Chr(10)||
                       'END;' AS exec_sql

                    FROM DUAL CONNECT BY ROWNUM <= CEIL(MONTHS_BETWEEN(inEndDate+1,TRUNC(inBegDate,'YYYY'))/12)
                ORDER BY 1
               )
    LOOP

      EXECUTE IMMEDIATE idx.exec_sql;
    END LOOP;
  END IF;
EXCEPTION WHEN OTHERS THEN
  BEGIN DBMS_PARALLEL_EXECUTE.drop_task(vTask); EXCEPTION WHEN OTHERS THEN NULL; END;
END mass_load_parallel_by_year;

PROCEDURE MyExecute(inScript IN VARCHAR2)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  EXECUTE IMMEDIATE inScript;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.MyExecute','SUCESSFULLY :: '||inScript);
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.MyExecute',SQLERRM);
END MyExecute;

PROCEDURE AnyExecute(inScript IN CLOB,inParams IN VARCHAR2 DEFAULT NULL)
IS
  vOwner VARCHAR2(4000) := GetVarValue('vOwner');
  vStmt CLOB;
  vParams VARCHAR2(32700);
  vDeclParams VARCHAR2(32700);
  outRes VARCHAR2(32700);
BEGIN
  IF inParams IS NOT NULL THEN
    FOR idx IN (
      SELECT str,ROWNUM AS ord FROM (
        SELECT str
          FROM TABLE(pkg_etl_signs.parse_str(inParams,'#!#'))
      )
    ) LOOP
      vDeclParams := vDeclParams||'  p'||idx.ord||' VARCHAR2(32700) := q''['||idx.str||']'';'||CHR(10);
      vParams := vParams||' IN p'||idx.ord||',';
    END LOOP;
  END IF;  
  vDeclParams := vDeclParams||'  outRes VARCHAR2(32700);';
  vParams := vParams||' OUT outRes';
  vStmt := 'DECLARE'||CHR(10)||vDeclParams||CHR(10)||'BEGIN'||CHR(10)||'EXECUTE IMMEDIATE q''['||inScript||']'' USING '||vParams||';'||CHR(10)||'  :1 := outRes;'||CHR(10)||'END;';
  EXECUTE IMMEDIATE vStmt USING OUT outRes;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.MyExecute',SQLERRM);
END AnyExecute;

PROCEDURE prepare_entity(inId IN NUMBER,outRes OUT CLOB)
  IS
    vBuff                     VARCHAR2(32700);
    vRes                      VARCHAR2(32700);
    --
    vEntityId                 NUMBER;
    vFctTableName             VARCHAR2(256);
    vHistTableName            VARCHAR2(256);
    vHistIdxName              VARCHAR2(256);
    vTmpTableName             VARCHAR2(256);
    vTmpIdxName               VARCHAR2(256);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Получение и сохранение в переменные метаданных сущности
  BEGIN
    SELECT id
          ,fct_table_name
          ,hist_table_name
          ,tmp_table_name
      INTO vEntityID
          ,vFctTableName
          ,vHistTableName
          ,vTmpTableName
      FROM tb_entity
      WHERE id = inId;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    raise_application_error(-20000,'Сущность ID = '||inId||' не найдена в таблице "'||lower(vOwner)||'.tb_entity"');
  END;
  -- Создание таблицы для хранения показателей по датам
  dbms_lob.createtemporary(outRes,FALSE);

  vBuff :=
  'CREATE TABLE '||lower(vOwner)||'.'||lower(vFctTableName)||' ('||CHR(10)||
  '  AS_OF_DATE DATE'||CHR(10)||
  ' ,OBJ_GID NUMBER'||CHR(10)||
  ' ,SOURCE_SYSTEM_ID NUMBER'||CHR(10)||
  ' ,SIGN_NAME VARCHAR2(256)'||CHR(10)||
  ' ,SIGN_VAL VARCHAR2(4000)'||CHR(10)||
  ') PARTITION BY LIST (SIGN_NAME)'||CHR(10)||
  '  SUBPARTITION BY LIST (AS_OF_DATE)'||CHR(10)||
  '  (PARTITION EMPTY_SIGN VALUES (''EMPTY_SIGN'') STORAGE(INITIAL 64K NEXT  8M) NOLOGGING'||CHR(10)||
  '     (SUBPARTITION SPEMPTY_19700101 VALUES(to_date(''01.01.1970'',''DD.MM.YYYY''))))';

  BEGIN
    EXECUTE IMMEDIATE vBuff;
    vRes := 'Table '||lower(vOwner)||'.'||lower(vFctTableName)||' created successfully';
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  EXCEPTION WHEN OTHERS THEN
    vRes := SQLERRM||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;

  -- Создание таблицы для хранения показателей периодами
  vBuff :=
  'CREATE TABLE '||lower(vOwner)||'.'||lower(vHistTableName)||' ('||CHR(10)||
  '  EFFECTIVE_START DATE'||CHR(10)||
  ' ,EFFECTIVE_END DATE'||CHR(10)||
  ' ,OBJ_GID NUMBER'||CHR(10)||
  ' ,SOURCE_SYSTEM_ID NUMBER'||CHR(10)||
  ' ,SIGN_NAME VARCHAR2(256)'||CHR(10)||
  ' ,SIGN_VAL VARCHAR2(4000)'||CHR(10)||
  ') PARTITION BY LIST (SIGN_NAME)'||CHR(10)||
  '  (PARTITION EMPTY_SIGN VALUES (''EMPTY_SIGN'') STORAGE(INITIAL 64K NEXT 4M) NOLOGGING)';

  BEGIN
    EXECUTE IMMEDIATE vBuff;
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||'Table '||lower(vOwner)||'.'||lower(vHistTableName)||' created successfully';
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  EXCEPTION WHEN OTHERS THEN
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||SQLERRM||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;

  -- Создание промежуточной таблицы
  vBuff :=
  'CREATE TABLE '||lower(vOwner)||'.'||lower(vTmpTableName)||' ('||CHR(10)||
  '  EFFECTIVE_START DATE'||CHR(10)||
  ' ,EFFECTIVE_END DATE'||CHR(10)||
  ' ,OBJ_GID NUMBER'||CHR(10)||
  ' ,SOURCE_SYSTEM_ID NUMBER'||CHR(10)||
  ' ,SIGN_NAME VARCHAR2(256)'||CHR(10)||
  ' ,SIGN_VAL VARCHAR2(4000)'||CHR(10)||
  ') PARTITION BY LIST (SIGN_NAME)'||CHR(10)||
  '  SUBPARTITION BY RANGE (EFFECTIVE_END)'||CHR(10)||
  '  (PARTITION EMPTY_SIGN VALUES (''EMPTY_SIGN'') STORAGE(INITIAL 64K NEXT 4M) NOLOGGING'||CHR(10)||
  '     (SUBPARTITION SPEMPTY_POTHERS VALUES LESS THAN (MAXVALUE))) NOLOGGING';

  BEGIN
    EXECUTE IMMEDIATE vBuff;
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||'Table '||lower(vOwner)||'.'||lower(vTmpTableName)||' created successfully';
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  EXCEPTION WHEN OTHERS THEN
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||SQLERRM||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;

  -- Создание уникальных индексов
  -- Формирование наименований индексов
  BEGIN
    SELECT 'uix_'||object_id INTO vHistIdxName
      FROM all_objects
      WHERE owner = UPPER(vOwner)
        AND object_name = UPPER(vHistTableName)
        AND object_type = 'TABLE';
  EXCEPTION WHEN NO_DATA_FOUND THEN
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||'Объект '||lower(vOwner)||'.'||lower(vHistTableName)||' не найден'||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;

  BEGIN
    SELECT 'uix_'||object_id INTO vTmpIdxName
      FROM all_objects
      WHERE owner = UPPER(vOwner)
        AND object_name = UPPER(vTmpTableName)
        AND object_type = 'TABLE';
  EXCEPTION WHEN NO_DATA_FOUND THEN
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||'Объект '||lower(vOwner)||'.'||lower(vTmpTableName)||' не найден'||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;
  -- Формирование набора ключевых колонок, входящих в индекс
  --SELECT LISTAGG(SUBSTR(Str,1,INSTR(Str,' ') - 1),',') WITHIN GROUP (ORDER BY rownum) INTO vKeyIdxColumns
  --  FROM TABLE(parse_str(vKeyColumns,','));

  -- Формирование и запуск DDL
  vBuff := 'CREATE UNIQUE INDEX '||lower(vOwner)||'.'||vHistIdxName||' ON '||lower(vHistTableName)||CHR(10)||
           '  (SIGN_NAME,OBJ_GID,SOURCE_SYSTEM_ID,EFFECTIVE_END)'||CHR(10)||
           'LOCAL COMPRESS NOLOGGING';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||'Unique index '||lower(vOwner)||'.'||lower(vHistIdxName)||' created successfully';
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  EXCEPTION WHEN OTHERS THEN
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||SQLERRM||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;

  vBuff := 'CREATE UNIQUE INDEX '||lower(vOwner)||'.'||vTmpIdxName||' ON '||lower(vTmpTableName)||CHR(10)||
           '  (SIGN_NAME,EFFECTIVE_END,OBJ_GID,SOURCE_SYSTEM_ID)'||CHR(10)||
           'LOCAL COMPRESS NOLOGGING';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||'Unique index '||lower(vOwner)||'.'||lower(vTmpIdxName)||' created successfully';
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  EXCEPTION WHEN OTHERS THEN
    vRes := /*outRes||*/CHR(10)||'-----------------------'||CHR(10)||SQLERRM||CHR(10)||vBuff;
    dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
  END;
EXCEPTION WHEN OTHERS THEN
  vRes := /*outRes||*/CHR(10)||SQLERRM;
  dbms_lob.writeappend(outRes,LENGTH(vRes),vRes);
END prepare_entity;

PROCEDURE prepare_log_table(outRes OUT VARCHAR2)
  IS
    vBuff VARCHAR2(32700);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Создание таблицы
  vBuff :=
  'CREATE TABLE '||lower(vOwner)||'.tb_signs_log'||CHR(10)||
  '  (id NUMBER,dat DATE, unit VARCHAR2(4000), message VARCHAR2(4000)) NOLOGGING';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    outRes := 'Table "'||lower(vOwner)||'.tb_signs_log" created successfully'||CHR(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := 'Table "'||lower(vOwner)||'.tb_signs_log" not created. Error: '||SQLERRM||CHR(10);
  END;
  -- Создание индексов
  vBuff := 'CREATE UNIQUE INDEX '||lower(vOwner)||'.idx_tb_signs_log_u001 ON '||lower(vOwner)||'.tb_signs_log (id) NOLOGGING';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    outRes := outRes||'-------------------------'||CHR(10)||'Unique index "'||lower(vOwner)||'.idx_tb_signs_log_u001" created successfully'||CHR(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'-------------------------'||CHR(10)||'Unique index "'||lower(vOwner)||'.idx_tb_signs_log_u001" not created. Error: '||SQLERRM||CHR(10);
  END;

  vBuff := 'CREATE INDEX '||lower(vOwner)||'.idx_tb_signs_log_002 ON '||lower(vOwner)||'.tb_signs_log (dat) NOLOGGING';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    outRes := outRes||'-------------------------'||CHR(10)||'Index "'||lower(vOwner)||'.idx_tb_signs_log_002" created successfully'||CHR(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'-------------------------'||CHR(10)||'Index "'||lower(vOwner)||'.idx_tb_signs_log_002" not created. Error: '||SQLERRM||CHR(10);
  END;

  vBuff := 'CREATE INDEX '||lower(vOwner)||'.idx_tb_signs_log_003 ON '||lower(vOwner)||'.tb_signs_log (unit) NOLOGGING';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    outRes := outRes||'-------------------------'||CHR(10)||'Index "'||lower(vOwner)||'.idx_tb_signs_log_003" created successfully'||CHR(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'-------------------------'||CHR(10)||'Index "'||lower(vOwner)||'.idx_tb_signs_log_003" not created. Error: '||SQLERRM||CHR(10);
  END;

  -- Создание последовательности
  vBuff := 'CREATE SEQUENCE '||lower(vOwner)||'.tb_signs_log_id_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 START WITH 1 INCREMENT by 1 NOCACHE';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    outRes := outRes||'-------------------------'||CHR(10)||'Sequence "'||lower(vOwner)||'.tb_signs_log_id_seq" created successfully'||CHR(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'-------------------------'||CHR(10)||'Sequence "'||lower(vOwner)||'.tb_signs_log_id_seq" not created. Error: '||SQLERRM||CHR(10);
  END;

  -- Создание триггера
  vBuff :=
  'CREATE OR REPLACE TRIGGER '||lower(vOwner)||'.tb_signs_log_id_trg BEFORE INSERT ON '||lower(vOwner)||'.tb_signs_log FOR EACH ROW'||CHR(10)||
  'BEGIN SELECT '||lower(vOwner)||'.tb_signs_log_id_seq.nextval INTO :NEW.id FROM dual; END tb_signs_log_id_trg;';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
    outRes := outRes||'-------------------------'||CHR(10)||'Trigger "'||lower(vOwner)||'.tb_signs_log_id_trg" compiled successfully'||CHR(10);
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||'-------------------------'||CHR(10)||'Trigger "'||lower(vOwner)||'.tb_signs_log_id_trg" not compiled. Error: '||SQLERRM||CHR(10);
  END;
END prepare_log_table;

FUNCTION get_sign(inSign IN VARCHAR2,inDate IN DATE, inSQL IN VARCHAR2 DEFAULT NULL) RETURN TTab PIPELINED
  IS
    vSQL CLOB;
    rec TRec;
    cur INTEGER;       -- хранит идентификатор (ID) курсора
    ret INTEGER;       -- хранит возвращаемое по вызову значение
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Сохранение метаданных показателя в переменные
  SELECT p.sign_sql
    INTO vSQL
    FROM tb_signs_pool p
    WHERE p.sign_name = UPPER(inSign);

  IF inSQL IS NOT NULL THEN vSQL := inSQL; END IF;

  --dbms_output.put_line(vAnltSQL);

  cur := dbms_sql.open_cursor;
  dbms_sql.parse(cur, vSQL, dbms_sql.native);
  dbms_sql.define_column(cur,1,rec.obj_gid);
  dbms_sql.define_column(cur,2,rec.source_system_id);
  dbms_sql.define_column(cur,3,rec.sign_name,256);
  dbms_sql.define_column(cur,4,rec.sign_val,4000);

  IF inSQL IS NULL THEN
    dbms_sql.bind_variable_char(cur,'inDate',to_char(inDate,'DD.MM.YYYY'));
  END IF;

  ret := dbms_sql.execute(cur);
  LOOP
    EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
    dbms_sql.column_value(cur,1,rec.obj_gid);
    dbms_sql.column_value(cur,2,rec.source_system_id);
    dbms_sql.column_value(cur,3,rec.sign_name);
    dbms_sql.column_value(cur,4,rec.sign_val);
    PIPE ROW(rec);
  END LOOP;
  dbms_sql.close_cursor(cur);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_sign','ERROR :: "'||UPPER(inSign)||'"  - Показатель не найден в таблице "'||lower(vOwner)||'.tb_signs_pool"');
  WHEN OTHERS THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_sign','ERROR :: "'||UPPER(inSign)||'"  - '||SQLERRM||CHR(10)||'----------'||CHR(10)||vSQL);
END get_sign;

FUNCTION get_sign_anlt(inSign IN VARCHAR2, inDate IN DATE, inAnltCode IN VARCHAR2, inReverse NUMBER DEFAULT 0) RETURN TTab PIPELINED
  IS
    rec TRec;
    cur INTEGER;       -- хранит идентификатор (ID) курсора
    ret INTEGER;       -- хранит возвращаемое по вызову значение
    vSQL CLOB;
    vAnltSQL CLOB;
    vAnltID NUMBER;
    vBuff VARCHAR2(32700);
    vWhere VARCHAR2(32700);
    vCou INTEGER;
    --
    vFctTable VARCHAR2(256);
    vHistTable VARCHAR2(256);
    vHistFlg NUMBER;
    vReverse BOOLEAN := inReverse = 1;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
-- Сохранение метаданных показателя в переменные
SELECT a.anlt_sql,a.id,lower(vOwner)||'.'||e.fct_table_name,lower(vOwner)||'.'||e.hist_table_name,p.hist_flg
      ,(SELECT COUNT(1) FROM tb_signs_anlt_spec WHERE anlt_id = a.id) AS cou
  INTO vSQL,vAnltID,vFctTable,vHistTable,vHistFlg,vCou
  FROM tb_signs_pool p
       INNER JOIN tb_entity e ON e.id = p.entity_id
       INNER JOIN tb_signs_anlt a
          ON a.anlt_code = inAnltCode
            AND inDate BETWEEN a.effective_start AND a.effective_end
  WHERE p.sign_name = UPPER(inSign)
    AND a.archive_flg = 0;

  IF vSQL IS NULL THEN
    vSQL := 'SELECT null AS obj_gid,null AS source_system_id,null AS sign_name FROM dual';
  END IF;

  dbms_lob.createtemporary(vAnltSQL,FALSE);
  vBuff :=
  'SELECT /*+ no_index(sgn) */'||CHR(10)||
  '       '||CASE WHEN NOT(vReverse) THEN 'sgn' ELSE 'anlt' END||'.obj_gid'||CHR(10)||
  '      ,'||CASE WHEN NOT(vReverse) THEN 'sgn' ELSE 'anlt' END||'.source_system_id'||CHR(10)||
  '      ,UPPER(:inSign) AS sign_name'||CHR(10);
  dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);

  IF vCou > 0 THEN
      vBuff :=
      '      ,CASE'||CHR(10);
      dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);
      FOR idx IN (
        SELECT ID,anlt_spec_name,LEVEL AS lev
              --,'WHEN '||SUBSTR(REPLACE(sys_connect_by_path('('||NVL(condition,CASE WHEN inReverse = 0 THEN 'sgn' ELSE 'anlt' END||'.sign_name = '''||UPPER(inSign)||'''')||')','-=#=-'),'-=#=-',' AND '),6)||' THEN '''||anlt_spec_val||'''' AS cond
              ,NVL2(condition,'WHEN '||condition||' THEN '''||anlt_spec_val||'''',NULL) AS cond
              ,condition
          FROM tb_signs_anlt_spec
          WHERE anlt_id = vAnltID
        CONNECT BY PRIOR anlt_spec_val = parent_val
        START WITH parent_val IS NULL AND anlt_id = vAnltID
         ORDER BY connect_by_isleaf DESC,lev DESC
      ) LOOP
        IF idx.lev > 1 THEN
          vBuff := idx.cond||CHR(10);
          dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);
        ELSE
          vWhere := CASE WHEN idx.condition IS NOT NULL THEN ' WHERE '||idx.condition ELSE NULL END||CHR(10);
        END IF;

      END LOOP;
      vBuff :=
      'ELSE NULL END AS sign_val'||CHR(10);
      dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);
  ELSE
    vBuff := ',anlt.sign_val'||CHR(10);
    dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);
  END IF;

  vBuff :=
  'FROM '||CASE WHEN NOT(vReverse) THEN CASE vHistFlg WHEN 1 THEN vHistTable ELSE vFctTable END||' sgn LEFT JOIN' END||' ('||CHR(10);

  dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);
  dbms_lob.writeappend(vAnltSQL,LENGTH(vSQL),vSQL);
  IF vWhere IS NOT NULL THEN dbms_lob.writeappend(vAnltSQL,LENGTH(vWhere),vWhere); END IF;

  vBuff :=
  CHR(10)||') anlt'||CASE WHEN NOT(vReverse) THEN
  CHR(10)||'  ON anlt.sign_name = sgn.sign_name AND anlt.obj_gid = sgn.obj_gid AND anlt.source_system_id = sgn.source_system_id'||CHR(10)||
  'WHERE sgn.sign_name = UPPER(:inSign)'||CHR(10)||
  '     AND '||CASE vHistFlg WHEN 1 THEN 'to_date(:inDate,''DD.MM.YYYY'') BETWEEN sgn.effective_start AND sgn.effective_end'
               ELSE 'to_date(:inDate,''DD.MM.YYYY'') = sgn.as_of_date' END||CHR(10) END;
  dbms_lob.writeappend(vAnltSQL,LENGTH(vBuff),vBuff);

  cur := dbms_sql.open_cursor;
  dbms_sql.parse(cur, vAnltSQL, dbms_sql.native);

  dbms_sql.define_column(cur,1,rec.obj_gid);
  dbms_sql.define_column(cur,2,rec.source_system_id);
  dbms_sql.define_column(cur,3,rec.sign_name,256);
  dbms_sql.define_column(cur,4,rec.sign_val,4000);

  dbms_sql.bind_variable_char(cur,'inDate',to_char(inDate,'DD.MM.YYYY'));
  dbms_sql.bind_variable_char(cur,'inSign',UPPER(inSign));

  ret := dbms_sql.execute(cur);
  LOOP
    EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
    dbms_sql.column_value(cur,1,rec.obj_gid);
    dbms_sql.column_value(cur,2,rec.source_system_id);
    dbms_sql.column_value(cur,3,rec.sign_name);
    dbms_sql.column_value(cur,4,rec.sign_val);
    PIPE ROW(rec);
  END LOOP;
  --dbms_sql.close_cursor(cur);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_sign_anlt','ERROR :: "'||UPPER(inSign)||'"  - Показатель не найден в таблице "'||lower(vOwner)||'.tb_signs_pool"');
  WHEN OTHERS THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_sign_anlt','ERROR :: "'||UPPER(inSign)||'"  - '||SQLERRM);

    dbms_output.put_line(SQLERRM||CHR(10)||'-----------'||CHR(10)||vAnltSQL);
END get_sign_anlt;

FUNCTION get_anlt_spec_imp(inDate IN DATE, inAnltCode IN VARCHAR2) RETURN TTabAnltSpecImp PIPELINED
  IS
    vSQL CLOB;
    rec TRecAnltSpecImp;
    cur INTEGER;       -- хранит идентификатор (ID) курсора
    ret INTEGER;       -- хранит возвращаемое по вызову значение
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  SELECT spec_import_sql
    INTO vSQL
    FROM tb_signs_anlt
    WHERE anlt_code = UPPER(inAnltCode)
      AND inDate BETWEEN effective_start AND effective_end;

  cur := dbms_sql.open_cursor;
  dbms_sql.parse(cur, vSQL, dbms_sql.native);
  dbms_sql.define_column(cur,1,rec.val,4000);
  dbms_sql.define_column(cur,2,rec.parent_val,4000);
  dbms_sql.define_column(cur,3,rec.name,4000);
  dbms_sql.define_column(cur,4,rec.condition/*,32700*/);

  dbms_sql.bind_variable_char(cur,'inDate',to_char(inDate,'DD.MM.YYYY'));

  ret := dbms_sql.execute(cur);
  LOOP
    EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
    dbms_sql.column_value(cur,1,rec.val);
    dbms_sql.column_value(cur,2,rec.parent_val);
    dbms_sql.column_value(cur,3,rec.name);
    dbms_sql.column_value(cur,4,rec.condition);
    PIPE ROW(rec);
  END LOOP;
  dbms_sql.close_cursor(cur);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_anlt_spec_imp','ERROR :: "'||UPPER(inAnltCode)||'"  - Аналитика не найдена в таблице "'||lower(vOwner)||'.tb_signs_anlt"');
  WHEN OTHERS THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_anlt_spec_imp','ERROR :: "'||UPPER(inAnltCode)||'"  - '||SQLERRM||CHR(10)||'----------'||CHR(10)||vSQL);
END get_anlt_spec_imp;

FUNCTION get_sign_mass(inSign IN VARCHAR2,inDate IN DATE) RETURN TTabMass PIPELINED
  IS
    vSQL CLOB;
    rec TRecMass;
    cur INTEGER;       -- хранит идентификатор (ID) курсора
    ret INTEGER;       -- хранит возвращаемое по вызову значение
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  SELECT mass_sql INTO vSQL FROM tb_signs_pool WHERE sign_name = UPPER(inSign);

  cur := dbms_sql.open_cursor;
  dbms_sql.parse(cur, vSQL, dbms_sql.native);
  dbms_sql.define_column(cur,1,rec.effective_start);
  dbms_sql.define_column(cur,2,rec.effective_end);
  dbms_sql.define_column(cur,3,rec.obj_gid);
  dbms_sql.define_column(cur,4,rec.source_system_id);
  dbms_sql.define_column(cur,5,rec.sign_name,256);
  dbms_sql.define_column(cur,6,rec.sign_val,4000);

  dbms_sql.bind_variable_char(cur,'inDate',to_char(inDate,'DD.MM.YYYY'));

  ret := dbms_sql.execute(cur);
  LOOP
    EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
    dbms_sql.column_value(cur,1,rec.effective_start);
    dbms_sql.column_value(cur,2,rec.effective_end);
    dbms_sql.column_value(cur,3,rec.obj_gid);
    dbms_sql.column_value(cur,4,rec.source_system_id);
    dbms_sql.column_value(cur,5,rec.sign_name);
    dbms_sql.column_value(cur,6,rec.sign_val);
    PIPE ROW(rec);
  END LOOP;
  dbms_sql.close_cursor(cur);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_sign','ERROR :: "'||UPPER(inSign)||'"  - Показатель не найден в таблице "'||lower(vOwner)||'.tb_signs_pool"');
  WHEN OTHERS THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.get_sign','ERROR :: "'||UPPER(inSign)||'"  - '||SQLERRM);
END get_sign_mass;

FUNCTION CheckSubpartition(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2) RETURN VARCHAR2
  IS
    vMes VARCHAR2(2000);
    vSPCode VARCHAR2(30);
    vHistFlg NUMBER;
    vFCTTable VARCHAR2(256);
    vHistTable VARCHAR2(256);
    vFCTATable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vBuff VARCHAR2(32700);
    vDML CLOB;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Получение кода сабпартиции
  BEGIN
    SELECT p.sp_code,p.hist_flg
          ,lower(vOwner)||'.'||e.fct_table_name AS fct_table_name
          ,lower(vOwner)||'.'||e.hist_table_name AS hist_table_name
          ,lower(vOwner)||'.'||ae.fct_table_name AS fct_a_table_name
          ,lower(vOwner)||'.'||ae.hist_table_name AS hist_a_table_name
      INTO vSPCode,vHistFlg,vFCTTable,vHistTable,vFCTATable,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;
  -- Очистка или создание
  IF vHistFlg = 0 THEN
    dbms_lob.createtemporary(vDML,FALSE);
    vBuff := 'BEGIN'||CHR(10);
    dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
    FOR idx IN (
      SELECT inEndDate - LEVEL + 1 AS dt FROM dual
      CONNECT BY LEVEL <= inEndDate - inBegDate + 1
      ORDER BY 1
    ) LOOP
      vBuff :=
      '  BEGIN'||CHR(10)||
      '    EXECUTE IMMEDIATE ''alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||' truncate subpartition '||vSPCode||'_'||to_char(idx.dt,'YYYYMMDD')||'''; '||CHR(10)||
      '    pkg_etl_signs.pr_log_write('''||lower(vOwner)||'.pkg_etl_signs.CheckSubpartition'',''SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" altered. Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(idx.dt,'YYYYMMDD')||' truncated'');'||CHR(10)||
      '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
      '    BEGIN'||CHR(10)||
      '      EXECUTE IMMEDIATE ''alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||
      ' MODIFY PARTITION '||inSign||' ADD SUBPARTITION '||vSPCode||'_'||to_char(idx.dt,'YYYYMMDD')||' VALUES (to_date('''''||to_char(idx.dt,'DD.MM.YYYY')||''''',''''DD.MM.YYYY''''))'';'||CHR(10)||
      '      pkg_etl_signs.pr_log_write('''||lower(vOwner)||'.pkg_etl_signs.CheckSubpartition'',''SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" altered. Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(idx.dt,'YYYYMMDD')||' added''); '||CHR(10)||
      '    EXCEPTION WHEN OTHERS THEN'||CHR(10)||
      '      EXECUTE IMMEDIATE ''alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||
      ' ADD PARTITION '||inSign||' VALUES('''''||inSign||''''') STORAGE (INITIAL 64k NEXT 4M) NOLOGGING (SUBPARTITION '||vSPCode||'_'||to_char(idx.dt,'YYYYMMDD')||' VALUES (to_date('''''||to_char(idx.dt,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')))''; '||CHR(10)||
      '      pkg_etl_signs.pr_log_write('''||lower(vOwner)||'.pkg_etl_signs.CheckSubpartition'',''SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" altered. Partition '||inSign||' added. Subpartition '||vSPCode||'_'||to_char(idx.dt,'YYYYMMDD')||' added'');'||CHR(10)||
      '    END;'||CHR(10)||
      '  END;'||CHR(10);
      dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
    END LOOP;
    vBuff := 'END;';
    dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
    EXECUTE IMMEDIATE vDML;
    vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" altered. Partition '||UPPER(inSign)||': Subpartitions "'||to_char(inBegDate,'YYYYMMDD')||' - '||to_char(inEndDate,'YYYYMMDD')||'" prepared';
  ELSE
    BEGIN
      EXECUTE IMMEDIATE
        'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' ADD PARTITION '||inSign||' VALUES('''||UPPER(inSign)||''') STORAGE(INITIAL 64K NEXT 4M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" altered. Partition '||UPPER(inSign)||' added.';
    EXCEPTION WHEN OTHERS THEN
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'". Partition '||UPPER(inSign)||'. Clearing of historical subpartition not required.';
    END;
  END IF;


  RETURN vMes;
END CheckSubpartition;

PROCEDURE CheckSubpartition(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2)
  IS
    vMes VARCHAR2(2000);
    vSPCode VARCHAR2(30);
    vHistFlg NUMBER;
    vFCTTable VARCHAR2(256);
    vHistTable VARCHAR2(256);
    vFCTATable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vDays INTEGER;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vDays := inEndDate - inBegDate;
  -- Получение кода сабпартиции
  BEGIN
    SELECT p.sp_code,p.hist_flg
          ,lower(vOwner)||'.'||e.fct_table_name AS fct_table_name
          ,lower(vOwner)||'.'||e.hist_table_name AS hist_table_name
          ,lower(vOwner)||'.'||ae.fct_table_name AS fct_a_table_name
          ,lower(vOwner)||'.'||ae.hist_table_name AS hist_a_table_name
      INTO vSPCode,vHistFlg,vFCTTable,vHistTable,vFCTATable,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;
  -- Очистка или создание
  FOR idx IN 0..vDays LOOP
    IF vHistFlg = 0 THEN
      BEGIN
        EXECUTE IMMEDIATE 'alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'
                           ADD PARTITION '||inSign||' VALUES('''||inSign||''') storage (INITIAL 64k NEXT 4M) NOLOGGING (SUBPARTITION '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' VALUES (to_date('''||to_char(inBegDate+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')))';
        vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" altered. Partition '||inSign||' added. Subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' added.';
      EXCEPTION WHEN OTHERS THEN
        BEGIN
          EXECUTE IMMEDIATE 'alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'
                             MODIFY PARTITION '||inSign||' ADD SUBPARTITION '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' VALUES (to_date('''||to_char(inBegDate+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY''))';
          vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" altered. Partition '||inSign||' modified. Subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' added.';
          EXCEPTION WHEN OTHERS THEN
            EXECUTE IMMEDIATE 'alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||' truncate subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD');
            vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" altered. Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' truncated';
          END;
      END;
    ELSE
      BEGIN
        EXECUTE IMMEDIATE
          'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' ADD PARTITION '||inSign||' VALUES('''||UPPER(inSign)||''') STORAGE(INITIAL 64K NEXT 4M) NOLOGGING';
        vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" altered. Partition '||UPPER(inSign)||' added.';
      EXCEPTION WHEN OTHERS THEN
        vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'". Partition '||UPPER(inSign)||'. Clearing of historical subpartition not required.';
      END;
    END IF;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.CheckSubpartition',vMes);
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.CheckSubpartition',SQLERRM);
END CheckSubpartition;

FUNCTION CompressSubpartition(inDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2) RETURN VARCHAR2
  IS
    vMes VARCHAR2(2000);
    vSPCode VARCHAR2(6);
    vTIBegin DATE;
    vEndTime DATE;
    vHistFlg NUMBER;
    vFCTTable VARCHAR2(256);
    vHistTable VARCHAR2(256);
    vFCTATable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Получение кода сабпартиции
  BEGIN
    SELECT p.sp_code,p.hist_flg
          ,lower(vOwner)||'.'||e.fct_table_name AS fct_table_name
          ,lower(vOwner)||'.'||e.hist_table_name AS hist_table_name
          ,lower(vOwner)||'.'||ae.fct_table_name AS fct_a_table_name
          ,lower(vOwner)||'.'||ae.hist_table_name AS hist_a_table_name
      INTO vSPCode,vHistFlg,vFCTTable,vHistTable,vFCTATable,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;
  -- Сжатие
  vTIBegin := SYSDATE;
  IF vHistFlg = 0 THEN
    EXECUTE IMMEDIATE 'alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||' move subpartition '||vSPCode||'_'||to_char(inDate,'YYYYMMDD')||' compress';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(inDate,'YYYYMMDD')||' compressed in '||get_ti_as_hms(vEndTime - vTIBegin);
  ELSE
    vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" Partition '||inSign||'. Compressing of historical partition not required';
  END IF;
  RETURN vMes;
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(inDate,'YYYYMMDD')||' :: '||SQLERRM;
  RETURN vMes;
END CompressSubpartition;

PROCEDURE CompressSubpartition(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2)
  IS
    vMes VARCHAR2(2000);
    vSPCode VARCHAR2(6);
    vTIBegin DATE;
    vEndTime DATE;
    vHistFlg NUMBER;
    vFCTTable VARCHAR2(256);
    vHistTable VARCHAR2(256);
    vFCTATable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vDays INTEGER;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vDays := inEndDate - inBegDate;
  -- Получение кода сабпартиции
  BEGIN
    SELECT p.sp_code,p.hist_flg
          ,lower(vOwner)||'.'||e.fct_table_name AS fct_table_name
          ,lower(vOwner)||'.'||e.hist_table_name AS hist_table_name
          ,lower(vOwner)||'.'||ae.fct_table_name AS fct_a_table_name
          ,lower(vOwner)||'.'||ae.hist_table_name AS hist_a_table_name
      INTO vSPCode,vHistFlg,vFCTTable,vHistTable,vFCTATable,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;
  -- Сжатие
    IF vHistFlg = 0 THEN
     FOR idx IN 0..vDays LOOP
      BEGIN
        vTIBegin := SYSDATE;
        EXECUTE IMMEDIATE 'alter table '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||' move subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' compress';
        vEndTime := SYSDATE;
        vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' compressed in '||get_ti_as_hms(vEndTime - vTIBegin);
        pr_log_write(lower(vOwner)||'.pkg_etl_signs.CompressSubpartition',vMes);
      EXCEPTION WHEN OTHERS THEN
        vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||'" Partition '||inSign||': Subpartition '||vSPCode||'_'||to_char(inBegDate+idx,'YYYYMMDD')||' :: '||SQLERRM;
        pr_log_write(lower(vOwner)||'.pkg_etl_signs.CompressSubpartition',vMes);
      END;
    END LOOP;
    ELSE
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" Partition '||inSign||'. Compressing of historical partition not required';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.CompressSubpartition',vMes);
    END IF;
END CompressSubpartition;

PROCEDURE tb_load_daily(inBegDate IN DATE,inEndDate IN DATE,inSign VARCHAR2,inAnltCode IN VARCHAR2)
  IS
    vDays INTEGER;
    vMes VARCHAR2(32700);
    vBuff VARCHAR2(32700);
    vSQL CLOB;
    vCou INTEGER := 0;
    vHistTable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vDays := inEndDate - inBegDate;
  -- Получение наименования таблицы для загрузки
  BEGIN
    SELECT UPPER(vOwner||'.'||e.hist_table_name) AS hist_table_name
          ,lower(vOwner)||'.'||ae.hist_table_name AS hist_a_table_name
      INTO vHistTable,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  FOR days IN 0..vDays LOOP
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
    '      SELECT /*+ MATERIALIZE LEADING(SRC) NO_INDEX(DEST)*/'||CHR(10)||
    '             :1 AS SRC_EFFECTIVE_START,'||CHR(10)||
    '             to_date(''31.12.5999'',''DD.MM.YYYY'') AS SRC_EFFECTIVE_END,'||CHR(10)||
    '             SRC.OBJ_GID AS SRC_OBJ_GID,'||CHR(10)||
    '             SRC.SOURCE_SYSTEM_ID AS SRC_SOURCE_SYSTEM_ID,'||CHR(10)||
    '             SRC.SIGN_NAME AS SRC_SIGN_NAME,'||CHR(10)||
    '             SRC.SIGN_VAL AS SRC_SIGN_VAL,'||CHR(10)||
    '             DEST.SIGN_NAME AS D_SIGN_NAME,'||CHR(10)||
    '             DEST.EFFECTIVE_START AS D_EFFECTIVE_START,'||CHR(10)||
    '             DEST.SIGN_VAL AS D_SIGN_VAL'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN
    '       FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign(:2,:1)) src'||CHR(10)
    ELSE
    '       FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign_anlt(:2,:1,:3,'||CASE WHEN UPPER(inSign) = UPPER(inAnltCode) THEN '1' ELSE '0' END||')) src'||CHR(10)
    END||
    '            LEFT JOIN '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' PARTITION('||UPPER(inSign)||') DEST'||CHR(10)||
    '              ON DEST.SIGN_NAME = :2'||CHR(10)||
    '                 AND DEST.OBJ_GID = SRC.OBJ_GID'||CHR(10)||
    '                 AND DEST.SOURCE_SYSTEM_ID = SRC.SOURCE_SYSTEM_ID'||CHR(10)||
    '                 AND :1 BETWEEN DEST.EFFECTIVE_START AND DEST.EFFECTIVE_END'||CHR(10)||
    '       WHERE '||UPPER(vOwner)||'.PKG_ETL_SIGNS.ISEQUAL(DEST.SIGN_VAL, SRC.SIGN_VAL) = 0)'||CHR(10)||
    ' ,s AS ('||CHR(10)||
    '  SELECT obj_gid'||CHR(10)||
    '         ,source_system_id'||CHR(10)||
    '         ,MIN(EFFECTIVE_START) AS VNEXTEFF'||CHR(10)||
    '         ,MIN(SIGN_VAL) KEEP(DENSE_RANK FIRST ORDER BY SIGN_NAME,EFFECTIVE_START) AS VNEXTVAL'||CHR(10)||
    '     FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' PARTITION('||UPPER(inSign)||')'||CHR(10)||
    '     WHERE EFFECTIVE_START > :1'||CHR(10)||
    '       AND (obj_gid,source_system_id) IN (SELECT SRC_OBJ_GID,SRC_SOURCE_SYSTEM_ID FROM ch)'||CHR(10)||
    '   GROUP BY obj_gid,source_system_id)'||CHR(10)||
    ' ,p AS ('||CHR(10)||
    '   SELECT obj_gid'||CHR(10)||
    '         ,source_system_id'||CHR(10)||
    '         ,MAX(EFFECTIVE_END) AS VPREVEFF'||CHR(10)||
    '         ,MAX(SIGN_VAL) KEEP(DENSE_RANK LAST ORDER BY SIGN_NAME,EFFECTIVE_START) AS VPREVVAL'||CHR(10)||
    '     FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' PARTITION('||UPPER(inSign)||')'||CHR(10)||
    '     WHERE EFFECTIVE_END < :1'||CHR(10)||
    '       AND (obj_gid,source_system_id) IN (SELECT SRC_OBJ_GID,SRC_SOURCE_SYSTEM_ID FROM CH WHERE D_SIGN_NAME IS NULL)'||CHR(10)||
    '   GROUP BY obj_gid,source_system_id)'||CHR(10)||
    'SELECT'||CHR(10)||
    '   CH.SRC_EFFECTIVE_START,'||CHR(10)||
    '   CH.SRC_EFFECTIVE_END,'||CHR(10)||
    '   CH.SRC_OBJ_GID,'||CHR(10)||
    '   CH.SRC_SOURCE_SYSTEM_ID,'||CHR(10)||
    '   CH.SRC_SIGN_NAME,'||CHR(10)||
    '   CH.SRC_SIGN_VAL,'||CHR(10)||
    '   CH.D_SIGN_NAME,'||CHR(10)||
    '   CH.D_EFFECTIVE_START,'||CHR(10)||
    '   CH.D_SIGN_VAL,'||CHR(10)||
    '   p.VPREVEFF,'||CHR(10)||
    '   p.VPREVVAL,'||CHR(10)||
    '   s.VNEXTEFF,'||CHR(10)||
    '   s.VNEXTVAL'||CHR(10)||
    '  FROM CH'||CHR(10)||
    '  LEFT JOIN S'||CHR(10)||
    '    ON S.OBJ_GID = CH.SRC_OBJ_GID'||CHR(10)||
    '       AND S.SOURCE_SYSTEM_ID = CH.SRC_SOURCE_SYSTEM_ID'||CHR(10)||
    '  LEFT JOIN P'||CHR(10)||
    '    ON P.OBJ_GID = CH.SRC_OBJ_GID'||CHR(10)||
    '       AND P.SOURCE_SYSTEM_ID = CH.SRC_SOURCE_SYSTEM_ID'||CHR(10)||
    ') LOOP';
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
    vBuff :=
    '  BEGIN'||CHR(10)||
    '    IF idx.src_effective_start = idx.d_effective_start THEN'||CHR(10)||
    '      vStr := ''DDel_1'';'||CHR(10)||
    '      DELETE FROM /*+ index(a) */ '||lower(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END)||' a'||CHR(10)||
    '        WHERE sign_name = UPPER(idx.src_sign_name)'||CHR(10)||
    '          AND obj_gid = idx.src_obj_gid'||CHR(10)||
    '          AND source_system_id = idx.src_source_system_id'||CHR(10)||
    '          AND idx.src_effective_start BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    ELSE'||CHR(10)||
    '      vStr := ''DUpd_1'';'||CHR(10)||
    '      UPDATE /*+ index(a) */ '||lower(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END)||' a'||CHR(10)||
    '        SET effective_end = idx.src_effective_start - 1'||CHR(10)||
    '        WHERE sign_name = UPPER(idx.src_sign_name)'||CHR(10)||
    '          AND obj_gid = idx.src_obj_gid'||CHR(10)||
    '          AND source_system_id = idx.src_source_system_id'||CHR(10)||
    '          AND idx.src_effective_start BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    END IF; '||CHR(10)||
        --
    '    IF idx.vNextEff < to_date(''31.12.5999'',''DD.MM.YYYY'') AND '||lower(vOwner)||'.pkg_etl_signs.isEqual(idx.src_sign_val,idx.vNextVal) = 1 THEN'||CHR(10)||
    '      vStr := ''DUpd_2'';'||CHR(10)||
    '      UPDATE /*+ index(a) */'||lower(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END)||' a SET effective_start = idx.src_effective_start'||CHR(10)||
    '        WHERE sign_name = UPPER(idx.src_sign_name)'||CHR(10)||
    '          AND obj_gid = idx.src_obj_gid'||CHR(10)||
    '          AND source_system_id = idx.src_source_system_id'||CHR(10)||
    '          AND idx.vNextEff BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    ELSIF idx.src_effective_start - idx.vPrevEff = 1  AND '||lower(vOwner)||'.pkg_etl_signs.isEqual(idx.src_sign_val,idx.vPrevVal) = 1 THEN'||CHR(10)||
    '      vStr := ''DUpd_4'';'||CHR(10)||
    '      UPDATE /*+ index(a) */'||lower(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END)||' a SET effective_end = NVL(idx.vNextEff - 1,idx.src_effective_end)'||CHR(10)||
    '        WHERE sign_name = UPPER(idx.src_sign_name)'||CHR(10)||
    '          AND obj_gid = idx.src_obj_gid'||CHR(10)||
    '          AND source_system_id = idx.src_source_system_id'||CHR(10)||
    '          AND idx.vPrevEff BETWEEN effective_start AND effective_end;'||CHR(10)||
    '    ELSE'||CHR(10)||
    '      IF idx.src_sign_val IS NOT NULL THEN'||CHR(10)||
    '        vStr := ''DIns_2'';'||CHR(10)||
    '        INSERT INTO '||lower(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END)||CHR(10)||
    '          (effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10)||
    '          VALUES (idx.src_effective_start'||CHR(10)||
    '                 ,NVL(idx.vNextEff - 1,idx.src_effective_end)'||CHR(10)||
    '                 ,idx.src_obj_gid'||CHR(10)||
    '                 ,idx.src_source_system_id'||CHR(10)||
    '                 ,UPPER(idx.src_sign_name)'||CHR(10)||
    '                 ,idx.src_sign_val);'||CHR(10)||
    '      END IF;  '||CHR(10)||
    '    END IF;'||CHR(10)||
    '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
    --'    IF NOT vLogged THEN'||CHR(10)||
    '      vStr := ''ERROR :: "'||UPPER(inSign)||'" - "''||to_char(idx.src_effective_start,''DD.MM.YYYY'')||''" - OBJ_SID = ''||idx.src_obj_gid*10+idx.src_source_system_id||'' :: ''||SQLERRM||Chr(10)||vStr;'||CHR(10)||
    --'      '||lower(vOwner)||'.pkg_etl_signs.pr_log_write('''||lower(vOwner)||'.pkg_etl_signs.tb_load_daily'',vStr);'||CHR(10)||
    --'      vLogged := TRUE;'||CHR(10)||
    --'    END IF;'||CHR(10)||
    '  END;'||CHR(10)||
    '  vCou := vCou + 1;'||CHR(10)||
    'END LOOP;'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN
      ':3 := vCou;' ELSE ':4 := vCou;'
    END||CHR(10)||
    'END;';
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
      IF inAnltCode IS NULL THEN
        EXECUTE IMMEDIATE vSQL USING IN inBegDate+days
               ,IN UPPER(inSign)
               ,OUT vCou;
      ELSE
        EXECUTE IMMEDIATE vSQL USING IN inBegDate+days
               ,IN UPPER(inSign)
               ,IN UPPER(inAnltCode)
               ,OUT vCou;
      END IF;
    --dbms_output.put_line(vSQL);
    COMMIT;
    vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - "'||to_char(inBegDate + days,'DD.MM.YYYY')||'" - '||vCou||' rows proccessed in table "'||lower(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END)||'"';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_daily',vMes);
    dbms_lob.freetemporary(vSQL);
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||UPPER(inSign)||'" - "'||to_char(inBegDate,'DD.MM.YYYY')||'" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_daily',vMes);
  vMes := dbms_lob.substr(vSQL,32700,1);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_daily',vMes);
END tb_load_daily;

PROCEDURE ptb_load_daily(inBegDate IN DATE,inEndDate IN DATE,inSign VARCHAR2,inAnltCode IN VARCHAR2)
  IS
    vDays INTEGER;
    vMes VARCHAR2(32700);
    vBuff VARCHAR2(32700);
    vCou INTEGER := 0;
    vFctTable VARCHAR2(256);
    vFctATable VARCHAR2(256);
    vSPCode VARCHAR2(256);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  EXECUTE IMMEDIATE 'alter session set "_FIX_CONTROL" = "11814428:0"';
  vDays := inEndDate - inBegDate;
  -- Получение наименования таблицы для загрузки
  BEGIN
    SELECT UPPER(vOwner||'.'||e.fct_table_name) AS fct_table_name
          ,lower(vOwner)||'.'||ae.fct_table_name AS fct_a_table_name
          ,p.sp_code
      INTO vFctTable,vFctATable,vSPCode
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  FOR days IN 0..vDays LOOP
    vBuff :=
    'DECLARE'||CHR(10)||
    '  vCou INTEGER := 0;'||CHR(10)||
    'BEGIN'||CHR(10)||
    'FOR rw IN ('||CHR(10)||
    '   SELECT  :1 as as_of_date,obj_gid,source_system_id,sign_name,sign_val'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN
    '       FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign(:2,:1))'||CHR(10)
    ELSE
    '       FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign_anlt(:2,:1,:3,'||CASE WHEN UPPER(inSign) = UPPER(inAnltCode) THEN '1' ELSE '0' END||'))'||CHR(10)
    END||
    'WHERE sign_val IS NOT NULL'||CHR(10)||
    ') LOOP'||CHR(10)||
    '  INSERT INTO '||CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END||' subpartition('||vSPCode||'_'||to_char(inBegDate+days,'YYYYMMDD')||') (as_of_date,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10)||
    '    VALUES(rw.as_of_date,rw.obj_gid,rw.source_system_id,rw.sign_name,rw.sign_val);'||CHR(10)||
    '  vCou := vCou + 1;'||CHR(10)||
    'END LOOP;'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN ':3 := vCou;' ELSE ':4 := vCou;' END||CHR(10)||
    'END;';
    IF inAnltCode IS NULL THEN
      EXECUTE IMMEDIATE vBuff USING IN inBegDate+days
             ,IN UPPER(inSign)
             ,OUT vCou;
    ELSE
      EXECUTE IMMEDIATE vBuff USING IN inBegDate+days
             ,IN UPPER(inSign)
             ,IN UPPER(inAnltCode)
             ,OUT vCou;
    END IF;
    COMMIT;
    vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - "'||to_char(inBegDate + days,'DD.MM.YYYY')||'" - '||vCou||' rows inserted into table "'||lower(CASE WHEN inAnltCode IS NULL THEN vFCTTable ELSE vFCTATable END)||'"';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.ptb_load_daily',vMes);
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||UPPER(inSign)||'" - '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.ptb_load_daily',vMes);
END ptb_load_daily;

PROCEDURE load_sign(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inPrepareSegments NUMBER)
  IS
    vDays INTEGER;
    vMes VARCHAR2(2000);
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vHistFlg NUMBER;
    vCond NUMBER;
    vBuff VARCHAR2(32700);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vDays := inEndDate - inBegDate;
  vMes := 'START :: "'||inSign||'" "'||to_char(inBegDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.load_sign" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign',vMes);
  BEGIN
    SELECT p.hist_flg,GetConditionResult(p.condition) AS vCond
      INTO vHistFlg,vCond
      FROM tb_signs_pool p
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||UPPER(inSign)||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  IF vCond = 1 THEN
    FOR idx IN 0..vDays
    LOOP
      IF inPrepareSegments = 1 THEN
        -- Подготовка субпартиций
        vTIBegin := SYSDATE;
        vMes := CheckSubpartition(inBegDate+idx,inBegDate+idx,UPPER(inSign),inAnltCode);
        -- Сохранение времени  подготовки в таблицу статистики расчетов
        vEndTime := SYSDATE;
        pr_stat_write(inSign,inAnltCode,(vEndTime - vTIBegin)*24*60*60,'PREPARE');
      END IF;
      -- Вставка данных в таблицу
      vTIBegin := SYSDATE;
      IF vHistFlg = 0 THEN -- Для "FCT" показателей
        vBuff :=
        'BEGIN'||CHR(10)||
        lower(vOwner)||'.pkg_etl_signs.ptb_load_daily(:1,:2,:3,:4);'||CHR(10)||
        'END;';
        EXECUTE IMMEDIATE vBuff USING IN inBegDate+idx,IN inBegDate+idx,IN UPPER(inSign),IN inAnltCode;
      ELSE -- Для "HIST" показателей
        vBuff :=
        'BEGIN'||CHR(10)||
           lower(vOwner)||'.pkg_etl_signs.tb_load_daily(:1,:2,:3,:4);'||CHR(10)||
        'END;';
        EXECUTE IMMEDIATE vBuff USING IN inBegDate+idx,IN inBegDate+idx,IN UPPER(inSign),IN inAnltCode;
      END IF;

      -- Сохранение времени расчета в таблицу статистики расчетов
      vEndTime := SYSDATE;
      pr_stat_write(inSign,inAnltCode,(vEndTime - vTIBegin)*24*60*60,'CALC');
      --Сжатие субпартиций
      vTIBegin := SYSDATE;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign',CompressSubpartition(inBegDate+idx,UPPER(inSign),inAnltCode));
      -- Сохранение времени сжатия в таблицу статистики расчетов
      vEndTime := SYSDATE;
      pr_stat_write(inSign,inAnltCode,(vEndTime - vTIBegin)*24*60*60,'COMPRESS');
    END LOOP;
  ELSE
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign','ERROR :: "'||inSign||'" - Не выполнено доп.условие запуска расчета показателя, расчет не может быть запущен');
  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inSign||'" "'||to_char(inBegDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.load_sign" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: "'||UPPER(inSign)||'" - '||SQLERRM;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign',vMes);
    vMes := 'FINISH :: "'||inSign||'" "'||to_char(inBegDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.load_sign" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign',vMes);
END load_sign;

PROCEDURE load_new(inSQL IN CLOB,inJobName IN VARCHAR2 DEFAULT NULL,inCalcPoolId NUMBER DEFAULT NULL)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := NVL(inJobName,UPPER(vOwner)||'.'||'LOADJOB_'||tb_signs_job_id_seq.nextval);
    vCalcPoolId NUMBER := inCalcPoolId;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  MERGE INTO tb_signs_job dest
    USING (SELECT vJobName AS job_name,vBegTime AS start_time,SUBSTR(inSQL,1,4000) AS action_sql,vCalcPoolId AS calc_pool_id FROM dual) src
      ON (src.job_name = dest.job_name)
  WHEN NOT MATCHED THEN INSERT (job_name,start_time,action_sql,head_job_name,calc_pool_id) VALUES (src.job_name,src.start_time,src.action_sql,src.job_name,src.calc_pool_id)
  WHEN MATCHED THEN UPDATE SET dest.start_time = src.start_time,dest.action_sql = src.action_sql;
  COMMIT;

  EXECUTE IMMEDIATE 'ALTER SESSION SET nls_date_format = ''DD.MM.RRRR HH24:MI:SS''';
  ChainKiller(ChainStarter(ChainBuilder(inSQL),vJobName));

  vEndTime := SYSDATE;
  UPDATE tb_signs_job j SET j.elapsed_time = get_ti_as_hms(vEndTime - vBegTime), state = 'FINISHED', last_update = vEndTime
    WHERE job_name = vJobName AND state IS NULL;
  COMMIT;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(LOWER(vOwner)||'.pkg_etl_signs.load_new',SQLERRM);
END load_new;

PROCEDURE load(inBegDate IN DATE,inEndDate IN DATE)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
    vBuff VARCHAR2(32700);
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'LOADALLJOB_'||tb_signs_job_id_seq.nextval;
BEGIN
  vBuff :=
    q'[SELECT p.sign_name AS ID
          ,s.prev_sign_name AS parent_id
          ,']'||vOwner||q'[.pkg_etl_signs.'||CASE WHEN p.sign_sql IS NOT NULL THEN 'load_sign' ELSE 'mass_load' END AS unit
          ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||p.sign_name||'#!##!#1' AS params
          ,CASE WHEN (p.condition IS NULL OR pkg_etl_signs.GetConditionResult(p.condition) = 1) AND p.archive_flg = 0 THEN 0 ELSE 1 END AS skip
      FROM tb_signs_pool p
           LEFT JOIN tb_sign_2_sign s
            ON s.sign_name = p.sign_name]';
   load_new(vBuff,vJobName);
   --dbms_output.put_line(vBuff);
END load;

PROCEDURE mass_load(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inPrepareSegments NUMBER)
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vTIBegin DATE;
    vHistFlg NUMBER;
    vMassSQL CLOB;
    vMassDDL CLOB;
    --
    vHistTable VARCHAR2(256);
    vFctTable VARCHAR2(256);
    vTmpTable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vFctATable VARCHAR2(256);
    vTmpATable VARCHAR2(256);
    vSPCode VARCHAR2(30);
    vBuff VARCHAR2(32700);
    vMAsk VARCHAR2(30);
    --
    vRowCount INTEGER := 0;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_ctr_signs.mass_load" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_ctr_signs.mass_load',vMes);

  EXECUTE IMMEDIATE 'alter session set "_FIX_CONTROL" = "11814428:0"';

  BEGIN
    SELECT p.hist_flg,p.mass_sql,p.sp_code
          ,UPPER(vOwner||'.'||e.hist_table_name) AS hist_table_name
          ,UPPER(vOwner||'.'||e.fct_table_name) AS fct_table_name
          ,UPPER(vOwner||'.'||e.tmp_table_name) AS tmp_table_name
          ,UPPER(vOwner||'.'||ae.fct_table_name) AS fct_a_table_name
          ,UPPER(vOwner||'.'||ae.hist_table_name) AS hist_a_table_name
          ,UPPER(vOwner||'.'||ae.tmp_table_name) AS tmp_a_table_name
      INTO vHistFlg,vMassSQL,vSPCode,vHistTable,vFctTable,vTmpTable,vFctATable,vHistATable,vTmpATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||UPPER(inSign)||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  -- Установка архивного флага в таблице показателей (чтобы не было пересечения с ежедневной
  -- загрузкой. Ежедневка смотрит на этот флаг и если 1, то не расчитывает показатель)
  vBuff :=
  'BEGIN'||CHR(10)||
  '  UPDATE '||lower(vOwner)||'.tb_signs_pool SET archive_flg = 1 WHERE sign_name = '''||UPPER(inSign)||''';'||CHR(10)||
  '  COMMIT;'||CHR(10)||
  'END;';
  BEGIN
    EXECUTE IMMEDIATE vBuff;
  EXCEPTION WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20000,'ERROR :: UPD_1');
  END;

 -- Загрузка данных
 IF inPrepareSegments = 1 AND vMassSQL IS NOT NULL AND vHistFlg = 1 AND inAnltCode IS NULL THEN
   -- Если в "HIST" показателе заполнено поле MASS_SQL, то используем его для быстрой заливки

   -- Подготовка субпартиций в промежуточной таблице
   vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' DROP PARTITION '||UPPER(inSign);
   BEGIN
     EXECUTE IMMEDIATE vBuff;
   EXCEPTION WHEN OTHERS THEN
     NULL;
   END;

   vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' ADD PARTITION '||UPPER(inSign)||' VALUES('''||UPPER(inSign)||''') NOLOGGING STORAGE(INITIAL 64K NEXT 4M) (SUBPARTITION '||vSPCode||'_NEW VALUES LESS THAN (MAXVALUE))';
   EXECUTE IMMEDIATE vBuff;
   -- Окончание подготовки субпартиций в промежуточной таблице

   -- Вставка данных в промежуточную таблицу
   vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - вставка данных во временную таблицу --------';
   pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);

   vTIBegin := SYSDATE;
   dbms_lob.createtemporary(vMassDDL,FALSE);
   vBuff :=
   'BEGIN'||CHR(10)||
   '  INSERT /*+ APPEND */ INTO '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||CHR(10)||
   '   (effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10);
   dbms_lob.writeappend(vMassDDL,LENGTH(vBuff),vBuff);

   vMassDDL := vMassDDL||vMassSQL||';'||CHR(10);

   vBuff :=
   ' :1 := SQL%ROWCOUNT;'||CHR(10)||
   'COMMIT;'||CHR(10)||'END;';
   dbms_lob.writeappend(vMassDDL,LENGTH(vBuff),vBuff);

   BEGIN
     EXECUTE IMMEDIATE vMassDDL USING OUT vRowCount;
     --dbms_output.put_line(vMassDDL);
     vEndTime := SYSDATE;
     vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - '||vRowCount||' rows inserted into "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" in '||get_ti_as_hms(vEndTime - vTIBegin);
     pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);
   EXCEPTION WHEN OTHERS THEN
     vEndTime := SYSDATE;
     vMes := 'ERROR :: "'||UPPER(inSign)||'" not inserted into "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" in '||get_ti_as_hms(vEndTime - vTIBegin)||' with errors :: '||SQLERRM||CHR(10)||'------'||CHR(10)||dbms_lob.substr(vMassDDL,3000);
     pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);
   END;

   vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание вставки данных во временную таблицу. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
   pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);

   -- Склеивание в целевую таблицу
   sign_gluing(UPPER(inSign),UPPER(inAnltCode),'011');

  ELSE
    IF vHistFlg = 0 THEN -- для "FCT" показателей
      vTIBegin := SYSDATE;
      vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - загрузка данных --------';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);

      vMes := CheckSubpartition(inBegDate,inEndDate,UPPER(inSign),UPPER(inAnltCode));
      -- Сохранение времени  подготовки в таблицу статистики расчетов
      /*vEndTime := SYSDATE;
      INSERT INTO tb_signs_calc_stat (sign_name,anlt_code,action,sec)
        VALUES(inSign,inAnltCode,'PREPARE',ROUND((vEndTime - vTIBegin)*24*60*60/(inEndDate - inBegDate),1));*/

      --mass_load_parallel_by_date_pe(inBegDate,inEndDate,lower(vOwner)||'.pkg_etl_signs.load_sign','VARCHAR2 '||UPPER(inSign)||'::VARCHAR2 '||inAnltCode);
      mass_load_parallel_by_month(inBegDate,inEndDate,lower(vOwner)||'.pkg_etl_signs.load_sign','VARCHAR2 '||UPPER(inSign)||'::VARCHAR2 '||UPPER(inAnltCode)||'::NUMBER 0');

      vEndTime := SYSDATE;
      vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание загрузки данных. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);
    ELSE -- для "HIST" показателей
      vMask := '11'||'0'||'100';
      tb_load_mass(inBegDate,inEndDate,UPPER(inSign),inAnltCode,vMask);
    END IF;
  END IF;
  -- Возврат архивного флага в исходную
  vBuff :=
  'BEGIN'||CHR(10)||
  '  UPDATE tb_signs_pool SET archive_flg = 0 WHERE sign_name = '''||UPPER(inSign)||''';'||CHR(10)||
  '  COMMIT;'||CHR(10)||
  'END;';
  EXECUTE IMMEDIATE vBuff;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);
EXCEPTION WHEN OTHERS THEN
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load" :: '||SQLERRM||Chr(10)||vBuff;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.mass_load" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.mass_load',vMes);
END mass_load;

PROCEDURE sign_gluing(inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inMask IN VARCHAR2 DEFAULT '111')
 IS
   vBegTime DATE := SYSDATE;
   vEndTime DATE;
   vTIBegin DATE;
   vMes VARCHAR2(32700);
   vSPCode VARCHAR2(256);
   vHistTable VARCHAR2(256);
   vTmpTable VARCHAR2(256);
   vHistFlg NUMBER;
   vHistATable VARCHAR2(256);
   vTmpATable VARCHAR2(256);
   vBuff VARCHAR2(32700);
   vCou INTEGER := 0;
   vMask VARCHAR2(256) := NVL(inMask,'111');
   vTmpStage BOOLEAN := SUBSTR(vMask,1,1) = '1';
   vTargetStage BOOLEAN := SUBSTR(vMask,2,1) = '1';
   vTargetTruncate BOOLEAN := SUBSTR(vMask,3,1) = '1';
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||inSign||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.sign_gluing" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
  -- Получение метаданных
  BEGIN
    SELECT p.sp_code
          ,UPPER(vOwner||'.'||e.tmp_table_name) AS tmp_table_name
          ,UPPER(vOwner||'.'||e.hist_table_name) AS hist_table_name
          ,p.hist_flg
          ,UPPER(vOwner||'.'||ae.tmp_table_name) AS tmp_a_table_name
          ,UPPER(vOwner||'.'||ae.hist_table_name) AS hist_a_table_name
      INTO vSPCode
          ,vTmpTable
          ,vHistTable
          ,vHistFlg
          ,vTmpATable
          ,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND SYSDATE BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  IF vTmpStage THEN
    vTIBegin := SYSDATE;
    vMes := 'CONTINUE :: ------ Вставка '||UPPER(inSign)||' во временную таблицу ------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);

    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' TRUNCATE PARTITION '||UPPER(inSign);
    BEGIN
      EXECUTE IMMEDIATE vBuff;
      --dbms_output.put_line(vBuff);

      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" - Partition '||UPPER(inSign)||' truncated';
    EXCEPTION WHEN OTHERS THEN
      vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' ADD PARTITION '||UPPER(inSign)||' VALUES('''||UPPER(inSign)||''') STORAGE (INITIAL 64K NEXT 4M) NOLOGGING';
      BEGIN
        EXECUTE IMMEDIATE vBuff;
        vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" - Partition '||UPPER(inSign)||' added';
      EXCEPTION WHEN OTHERS THEN
       vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" - Partition '||UPPER(inSign)||' not proccessed :: '||SQLERRM;
      END;
    END;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);

    vBuff :=
    'BEGIN'||CHR(10)||
    '  INSERT /*+ APPEND */ INTO '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' (effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10)||
    '    SELECT effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val'||CHR(10)||
    '      FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' WHERE sign_name = :1;'||CHR(10)||
    '  :2 := SQL%ROWCOUNT;'||CHR(10)||
    '  COMMIT;'||CHR(10)||
    'END;';
    BEGIN
      EXECUTE IMMEDIATE vBuff USING IN UPPER(inSign),OUT vCou;
      --dbms_output.put_line(vBuff);

      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - '||vCou||' rows inserted into table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" in '||get_ti_as_hms(vEndTime - vTIBegin);
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
    EXCEPTION WHEN OTHERS THEN
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" - "'||UPPER(inSign)||'" not inserted :: '||SQLERRM;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
    END;

    vMes := 'CONTINUE :: ------ Окончание вставки '||UPPER(inSign)||' во временную таблицу. Время выполнения '||get_ti_as_hms(vEndTime - vTIBegin)||' ------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
  END IF;
  -------
  IF vTargetStage THEN
    vTIBegin := SYSDATE;
    vMes := 'CONTINUE :: ------ Склеивание '||UPPER(inSign)||' в целевую таблицу ------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);

    IF vTargetTruncate THEN
      vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' TRUNCATE PARTITION '||UPPER(inSign);
      BEGIN
        EXECUTE IMMEDIATE vBuff;
        --dbms_output.put_line(vBuff);

        vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' truncated';
      EXCEPTION WHEN OTHERS THEN
        vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' not truncated :: '||SQLERRM;
      END;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
    END IF;

    vBuff :=
    'BEGIN'||CHR(10)||
    '  INSERT INTO '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' (effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10)||
    '    SELECT MIN(effective_start) AS effective_start'||CHR(10)||
    '          ,effective_end    '||CHR(10)||
    '          ,obj_gid'||CHR(10)||
    '          ,source_system_id'||CHR(10)||
    '          ,sign_name'||CHR(10)||
    '          ,sign_val '||CHR(10)||
    '      FROM ('||CHR(10)||
    '        SELECT effective_start'||CHR(10)||
    '              ,NVL2(NVL2(LEAD(next_start) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start)'||CHR(10)||
    '                        ,LEAD(effective_start) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start) - 1'||CHR(10)||
    '                        ,LEAD(effective_end) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start))'||CHR(10)||
    '                   ,CASE WHEN next_start - effective_end = 1 THEN'||CHR(10)||
    '                      CASE WHEN '||lower(vOwner)||'.pkg_etl_signs.isEqual(LEAD(sign_val) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start), sign_val) = 1'||CHR(10)||
    '                             THEN LEAD(effective_end) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start)'||CHR(10)||
    '                        ELSE LEAD(effective_start) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start) - 1'||CHR(10)||
    '                      END'||CHR(10)||
    '                      ELSE effective_end'||CHR(10)||
    '                    END'||CHR(10)||
    '                   ,effective_end'||CHR(10)||
    '                   ) AS effective_end'||CHR(10)||
    '              ,obj_gid'||CHR(10)||
    '              ,source_system_id'||CHR(10)||
    '              ,sign_name'||CHR(10)||
    '              ,sign_val'||CHR(10)||
    '          FROM (SELECT /*+ no_index(s) */'||CHR(10)||
    '                       obj_gid'||CHR(10)||
    '                      ,source_system_id'||CHR(10)||
    '                      ,effective_start'||CHR(10)||
    '                      ,effective_end'||CHR(10)||
    '                      ,LEAD(effective_start) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start) AS next_start'||CHR(10)||
    '                      ,sign_name'||CHR(10)||
    '                      ,sign_val'||CHR(10)||
    '                      ,CASE WHEN '||lower(vOwner)||'.pkg_etl_signs.isEqual(LAG(sign_val) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start), sign_val) = 0'||CHR(10)||
    '                                 OR effective_start - LAG(effective_end) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start) > 1'||CHR(10)||
    '                                 OR LEAD(effective_start) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start) - effective_end > 1'||CHR(10)||
    '                                 OR NVL(LEAD(effective_start) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start),to_date(''31.12.5999'',''DD.MM.YYYY'')) - effective_end > 1'||CHR(10)||
    '                                 OR effective_start - NVL(LAG(effective_end) OVER (PARTITION BY obj_gid,source_system_id ORDER BY effective_start),to_date(''01.01.0001'',''DD.MM.YYYY'')) > 1'||CHR(10)||
    '                                 OR effective_end = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
    '                              THEN 1'||CHR(10)||
    '                       ELSE 0'||CHR(10)||
    '                       END AS flg'||CHR(10)||
    '                  FROM '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' s'||CHR(10)||
    '                  WHERE sign_name = :1'||CHR(10)||
    '          ) WHERE flg = 1'||CHR(10)||
    '    ) WHERE effective_end IS NOT NULL AND sign_val IS NOT NULL'||CHR(10)||
    '  GROUP BY obj_gid'||CHR(10)||
    '          ,source_system_id'||CHR(10)||
    '          ,effective_end'||CHR(10)||
    '          ,sign_name'||CHR(10)||
    '          ,sign_val;'||CHR(10)||
    '  :2 := SQL%ROWCOUNT;'||CHR(10)||
    '  COMMIT;'||CHR(10)||
    ' END;';
    BEGIN
      EXECUTE IMMEDIATE vBuff USING IN UPPER(inSign),OUT vCou;
      --dbms_output.put_line(vBuff);

      -- Сохранение времени расчета в таблицу статистики расчетов
      /*
      INSERT INTO tb_signs_calc_stat (sign_name,anlt_code,action,sec)
        VALUES(inSign,inAnltCode,'GLUING',(vEndTime - vTIBegin)*24*60*60);*/

      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - '||vCou||' rows inserted into table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" in '||get_ti_as_hms(vEndTime - vTIBegin);
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
    EXCEPTION WHEN OTHERS THEN
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - "'||UPPER(inSign)||'" not inserted :: '||SQLERRM;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
    END;

    -- Удаление временной партиции
    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' DROP PARTITION '||UPPER(inSign);
    BEGIN
      EXECUTE IMMEDIATE vBuff;
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" - Partition '||UPPER(inSign)||' dropped';
    EXCEPTION WHEN OTHERS THEN
      vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||'" - Partition '||UPPER(inSign)||' not dropped :: '||SQLERRM;
    END;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);

    vMes := 'CONTINUE :: ------ Окончание склеивания '||UPPER(inSign)||' в целевую таблицу. Время выполнения: '||get_ti_as_hms(vEndTime - vTIBegin)||'------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);

    HistTableService(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,'111',inSign);

  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inSign||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.sign_gluing" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.sign_gluing',vMes);
EXCEPTION WHEN OTHERS THEN
  vEndTime := SYSDATE;
  vMes := 'ERROR :: Procedure "'||lower(vOwner)||'.pkg_etl_ctr_signs.sign_gluing" :: '||SQLERRM||Chr(10)||vBuff;
  pr_log_write(lower(vOwner)||'.pkg_etl_ctr_signs.sign_gluing',vMes);
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_ctr_signs.sign_gluing" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  pr_log_write(lower(vOwner)||'.pkg_etl_ctr_signs.sign_gluing',vMes);
END sign_gluing;

PROCEDURE tmp_load_prev(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2)
  IS
    vDays INTEGER;
    vMes VARCHAR2(4000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    --
    vTmpTable VARCHAR2(256);
    vTmpATable VARCHAR2(256);
    vCou INTEGER := 0;
    vBuff VARCHAR2(32700);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vDays := inEndDate - inBegDate;
  BEGIN
    SELECT UPPER(vOwner||'.'||e.tmp_table_name) AS tmp_table_name
          ,UPPER(vOwner||'.'||ae.tmp_table_name) AS tmp_a_table_name
      INTO vTmpTable,vTmpATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||UPPER(inSign)||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  FOR idx IN 0..vDays
  LOOP
    vMes := 'CONTINUE :: "'||to_char(inBegDate+idx,'DD.MM.YYYY')||'" - "'||UPPER(inSign)||'" - loading started';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tmp_load_prev',vMes);

    vBuff :=
    'BEGIN'||CHR(10)||
    '  INSERT INTO '||lower(CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END)||' (effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10)||
    '     SELECT :1,last_day(:1),obj_gid,source_system_id,sign_name,sign_val'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN
    '       FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign(:2,:1)) WHERE sign_val IS NOT NULL;'||CHR(10)
    ELSE
    '       FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign_anlt(:2,:1,:3,'||CASE WHEN UPPER(inSign) = UPPER(inAnltCode) THEN '1' ELSE '0' END||')) WHERE sign_val IS NOT NULL;'||CHR(10)
    END||
    CASE WHEN inAnltCode IS NULL THEN ':3 := SQL%ROWCOUNT;' ELSE ':4 := SQL%ROWCOUNT;' END||CHR(10)||
    'COMMIT;'||CHR(10)||
    'END;';

    BEGIN
      IF inAnltCode IS NULL THEN
        EXECUTE IMMEDIATE vBuff USING IN inBegDate+idx
               ,IN UPPER(inSign)
               ,OUT vCou;
      ELSE
        EXECUTE IMMEDIATE vBuff USING IN inBegDate+idx
               ,IN UPPER(inSign)
               ,IN UPPER(inAnltCode)
               ,OUT vCou;
      END IF;
      --dbms_output.put_line(vBuff);
    EXCEPTION WHEN OTHERS THEN
      vMes := 'ERROR :: "'||to_char(inBegDate+idx,'DD.MM.YYYY')||'" :: '||SQLERRM||Chr(10);
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.tmp_load_prev',vMes);
    END;

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDate+idx,'DD.MM.YYYY')||'" - "'||UPPER(inSign)||'" '||vCou||' rows inserted into table "'||lower(CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END)||'" in '||get_ti_as_hms(vEndTime - vBegTime);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tmp_load_prev',vMes);
  END LOOP;
END tmp_load_prev;

PROCEDURE tmp_load_daily(inBegDate IN DATE,inEndDate IN DATE,inSign VARCHAR2,inAnltCode IN VARCHAR2)
  IS
    vDays INTEGER;
    vMes VARCHAR2(32700);
    vEndTime DATE;
    vTIBegin DATE;
    --
    vTmpTable VARCHAR2(256);
    vTmpATable VARCHAR2(256);
    vBuff VARCHAR2(32700);
    vSQL CLOB;
    vCou INTEGER := 0;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vDays := inEndDate - inBegDate;
  -- Получение наименования таблицы для загрузки
  BEGIN
    SELECT UPPER(vOwner||'.'||e.tmp_table_name) AS tmp_table_name
          ,UPPER(vOwner||'.'||ae.tmp_table_name) AS tmp_a_table_name
      INTO vTmpTable,vTmpATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  FOR days IN 0..vDays LOOP
    vTIBegin := SYSDATE;
    dbms_lob.createtemporary(vSQL,FALSE);
    vBuff :=
    'DECLARE'||CHR(10)||
    '  vStr VARCHAR2(4000);'||CHR(10)||
    '  vCou INTEGER := 0;'||CHR(10)||
    '  vLogged BOOLEAN := FALSE;'||CHR(10)||
    'BEGIN'||CHR(10)||
    'EXECUTE IMMEDIATE ''ALTER SESSION SET nls_date_format = ''''DD.MM.RRRR HH24:MI:SS'''''';'||CHR(10)||
    'FOR idx IN ('||CHR(10)||
    '  SELECT /*+ LEADING(SRC) NO_INDEX(DEST)*/'||CHR(10)||
    '         :1 AS SRC_EFFECTIVE_START,'||CHR(10)||
    '         last_day(:1) AS SRC_EFFECTIVE_END,'||CHR(10)||
    '         SRC.OBJ_GID AS SRC_OBJ_GID,'||CHR(10)||
    '         SRC.SOURCE_SYSTEM_ID AS SRC_SOURCE_SYSTEM_ID,'||CHR(10)||
    '         SRC.SIGN_NAME AS SRC_SIGN_NAME,'||CHR(10)||
    '         SRC.SIGN_VAL AS SRC_SIGN_VAL,'||CHR(10)||
    '         DEST.SIGN_NAME AS D_SIGN_NAME,'||CHR(10)||
    '         DEST.EFFECTIVE_START AS D_EFFECTIVE_START,'||CHR(10)||
    '         DEST.SIGN_VAL AS D_SIGN_VAL'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN
    '     FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign(:2,:1)) src'||CHR(10)
    ELSE
    '     FROM TABLE('||lower(vOwner)||'.pkg_etl_signs.get_sign_anlt(:2,:1,:3,'||CASE WHEN UPPER(inSign) = UPPER(inAnltCode) THEN '1' ELSE '0' END||')) src'||CHR(10)
    END||
    '          LEFT JOIN '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' DEST'||CHR(10)||
    '            ON DEST.SIGN_NAME = :2'||CHR(10)||
    '               AND last_day(:1) = DEST.EFFECTIVE_END'||CHR(10)||
    '               AND DEST.OBJ_GID = SRC.OBJ_GID'||CHR(10)||
    '               AND DEST.SOURCE_SYSTEM_ID = SRC.SOURCE_SYSTEM_ID'||CHR(10)||
    '     WHERE '||UPPER(vOwner)||'.PKG_ETL_SIGNS.ISEQUAL(DEST.SIGN_VAL, SRC.SIGN_VAL) = 0'||CHR(10)||
    ') LOOP';
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
    vBuff :=
    '  BEGIN'||CHR(10)||
    '      vStr := ''Upd|''||idx.src_sign_name;'||CHR(10)||
    '      UPDATE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||CHR(10)||
    '        SET effective_end = idx.src_effective_start - 1'||CHR(10)||
    '        WHERE sign_name = UPPER(idx.src_sign_name)'||CHR(10)||
    '          AND effective_end = idx.src_effective_end'||CHR(10)||
    '          AND obj_gid = idx.src_obj_gid'||CHR(10)||
    '          AND source_system_id = idx.src_source_system_id;'||CHR(10)||
    '      IF idx.src_sign_val IS NOT NULL THEN'||CHR(10)||
    '        vStr := ''Ins|''||idx.src_sign_name;'||CHR(10)||
    '        INSERT INTO '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' (effective_start,effective_end,obj_gid,source_system_id,sign_name,sign_val)'||CHR(10)||
    '          VALUES (idx.src_effective_start'||CHR(10)||
    '                 ,idx.src_effective_end'||CHR(10)||
    '                 ,idx.src_obj_gid'||CHR(10)||
    '                 ,idx.src_source_system_id'||CHR(10)||
    '                 ,UPPER(idx.src_sign_name)'||CHR(10)||
    '                 ,idx.src_sign_val);'||CHR(10)||
    '      END IF;'||CHR(10)||
    '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
    '    IF NOT vLogged THEN'||CHR(10)||
    '      vStr := ''ERROR :: "'||UPPER(inSign)||'" - "''||to_char(idx.src_effective_start,''DD.MM.YYYY'')||''" - OBJ_SID = ''||idx.src_obj_gid*10+idx.src_source_system_id||'' :: ''||SQLERRM||Chr(10)||vStr;'||CHR(10)||
    '      '||lower(vOwner)||'.pkg_etl_signs.pr_log_write('''||lower(vOwner)||'.pkg_etl_signs.tmp_load_daily'',vStr);'||CHR(10)||
    '      vLogged := TRUE;'||CHR(10)||
    '    END IF;'||CHR(10)||
    '  END;'||CHR(10)||
    '  vCou := vCou + 1;'||CHR(10)||
    'END LOOP;'||CHR(10)||
    CASE WHEN inAnltCode IS NULL THEN ':3 := vCou;' ELSE ':4 := vCou;' END||CHR(10)||
    'COMMIT;'||CHR(10)||
    'END;';
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
    IF inAnltCode IS NULL THEN
      EXECUTE IMMEDIATE vSQL USING IN inBegDate+days
             ,IN UPPER(inSign)
             ,OUT vCou;
    ELSE
      EXECUTE IMMEDIATE vSQL USING IN inBegDate+days
             ,IN UPPER(inSign)
             ,IN UPPER(inAnltCode)
             ,OUT vCou;
    END IF;
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - "'||to_char(inBegDate + days,'DD.MM.YYYY')||'" - '||vCou||' rows proccessed in table "'||lower(CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END)||'" in '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tmp_load_daily',vMes);
    dbms_lob.freetemporary(vSQL);
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||UPPER(inSign)||'" - "'||to_char(inBegDate,'DD.MM.YYYY')||'" :: '||SQLERRM||Chr(10);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tmp_load_daily',vMes);
END tmp_load_daily;

PROCEDURE tb_upd_eff_end(inSign IN VARCHAR2,inAnltCode IN VARCHAR2,inDate IN DATE DEFAULT NULL)
  IS
    vMes VARCHAR2(32700);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    --
    vHistTable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vBuff VARCHAR2(32700);
    vCou INTEGER := 0;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||UPPER(inSign)||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.load_sign',vMes);
  -- Получение наименования таблицы для апдейта
  BEGIN
    SELECT UPPER(vOwner||'.'||e.hist_table_name) AS hist_table_name
          ,UPPER(vOwner||'.'||ae.hist_table_name) AS hist_a_table_name
      INTO vHistTable,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND SYSDATE BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;
  vBuff :=
  'DECLARE'||CHR(10)||
  '  vCou INTEGER := 0;'||CHR(10)||
  'BEGIN'||CHR(10)||
  '  FOR idx IN ('||CHR(10)||
  CASE WHEN inDate IS NULL THEN
    '    SELECT sign_name,obj_gid,source_system_id,MAX(effective_end) AS effective_end'||CHR(10)||
    '      FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||CHR(10)||
    '      WHERE sign_name = :1'||CHR(10)||
    '    GROUP BY sign_name,obj_gid,source_system_id'||CHR(10)||
    '    HAVING MAX(effective_end) != to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)
  ELSE
    'WITH'||CHR(10)||
    '  a AS ('||CHR(10)||
    '    SELECT /*+ no_index(c)*/'||CHR(10)||
    '           obj_gid,source_system_id'||CHR(10)||
    '      FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' c'||CHR(10)||
    '      WHERE sign_name = :1'||CHR(10)||
    '        AND effective_end = to_date(:2,''DD.MM.RRRR'')'||CHR(10)||
    '    MINUS'||CHR(10)||
    '    SELECT obj_gid,source_system_id'||CHR(10)||
    '      FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||CHR(10)||
    '      WHERE sign_name = :1'||CHR(10)||
    '        AND effective_start > to_date(:2,''DD.MM.RRRR''))'||CHR(10)||
    'SELECT /*+ no_index(s) */'||CHR(10)||
    '       sign_name,obj_gid,source_system_id,effective_end'||CHR(10)||
    '  FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' s'||CHR(10)||
    '  WHERE sign_name = :1'||CHR(10)||
    '    AND effective_end = to_date(:2,''DD.MM.RRRR'')'||CHR(10)||
    '    AND (obj_gid,source_system_id) IN (SELECT obj_gid,source_system_id FROM a)'||CHR(10)

  END||
  '  ) LOOP'||CHR(10)||
  '    UPDATE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||CHR(10)||
  '      SET effective_end = to_date(''31.12.5999'',''DD.MM.YYYY'')'||CHR(10)||
  '      WHERE sign_name = idx.sign_name'||CHR(10)||
  '        AND obj_gid = idx.obj_gid'||CHR(10)||
  '        AND source_system_id = idx.source_system_id'||CHR(10)||
  '        AND effective_end = idx.effective_end;'||CHR(10)||
  '    vCou := vCou + 1;'||CHR(10)||
  '  END LOOP;'||CHR(10)||
  '  COMMIT;'||CHR(10)||
  CASE WHEN inDate IS NOT NULL THEN '  :3 := vCou;' ELSE '  :2 := vCou;' END||CHR(10)||
  'END;';

  IF inDate/*inAnltCode*/ IS NULL THEN
    EXECUTE IMMEDIATE vBuff USING IN UPPER(inSign),OUT vCou;
  ELSE
    EXECUTE IMMEDIATE vBuff USING IN UPPER(inSign),IN to_char(inDate,'DD.MM.RRRR'),OUT vCou;
  END IF;

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" - EFFECTIVE_END -> "31.12.5999" - '||vCou||' rows proccessed in table "'||lower(vHistTable)||'" in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end',vMes);
  vMes := 'FINISH :: "'||inSign||'" - EFFECTIVE_END -> "31.12.5999" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end',vMes);
EXCEPTION WHEN OTHERS THEN
  vEndTime := SYSDATE;
  vMes := 'ERROR :: "'||UPPER(inSign)||'"  - EFFECTIVE_END -> "31.12.5999" :: '||SQLERRM||Chr(10)||vBuff;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end',vMes);
  vMes := 'FINISH :: "'||inSign||'" - EFFECTIVE_END -> "31.12.5999" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_upd_eff_end',vMes);
END tb_upd_eff_end;

PROCEDURE tb_load_mass(inBegDate IN DATE,inEndDate IN DATE,inSign IN VARCHAR2,inAnltCode IN VARCHAR2
  ,inMask IN VARCHAR2 DEFAULT '111111')
  IS
    vMes VARCHAR2(4000);
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    --
    vCou INTEGER;
    vSPCode VARCHAR2(30);
    vTmpTable VARCHAR2(256);
    vHistTable VARCHAR2(256);
    vTmpATable VARCHAR2(256);
    vHistATable VARCHAR2(256);
    vIdx VARCHAR2(256);
    vBuff VARCHAR2(32700);
    vPrev BOOLEAN := SUBSTR(inMask,1,1) = '1';
    vDaily BOOLEAN := SUBSTR(inMask,2,1) = '1';
    vTruncateTarget BOOLEAN := SUBSTR(inMask,3,1) = '1';
    vLoadTarget BOOLEAN := SUBSTR(inMask,4,1) = '1';
    vCompress BOOLEAN := SUBSTR(inMask,5,1) = '1';
    vStats BOOLEAN := SUBSTR(inMask,6,1) = '1';
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.tb_load_mass" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

  -- Получение метаданных
  BEGIN
    SELECT p.sp_code
          ,UPPER(vOwner||'.'||e.tmp_table_name) AS tmp_table_name
          ,UPPER(vOwner||'.'||e.hist_table_name) AS hist_table_name
          ,UPPER(vOwner||'.'||ae.tmp_table_name) AS tmp_a_table_name
          ,UPPER(vOwner||'.'||ae.hist_table_name) AS hist_a_table_name
      INTO vSPCode
          ,vTmpTable
          ,vHistTable
          ,vTmpATable
          ,vHistATable
      FROM tb_signs_pool p
           INNER JOIN tb_entity e
             ON e.id = p.entity_id
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = p.sign_name
                AND s2a.anlt_code = UPPER(inAnltCode)
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inEndDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity ae
             ON ae.id = a.entity_id
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  -- Подготовка субпартиций в промежуточной таблице
  IF vPrev THEN
    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' DROP PARTITION '||UPPER(inSign);
    BEGIN
      EXECUTE IMMEDIATE vBuff;
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;

    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' ADD PARTITION '||UPPER(inSign)||' VALUES('''||UPPER(inSign)||''') STORAGE(INITIAL 64K NEXT 4M) NOLOGGING (SUBPARTITION '||vSPCode||'_OLD VALUES LESS THAN (to_date('''||to_char(TRUNC(inBegDate,'MM'),'DD.MM.YYYY')||''',''DD.MM.YYYY'')))';
    EXECUTE IMMEDIATE vBuff;

    FOR dt IN (
      SELECT TRUNC(dt,'MM') AS dt FROM (
      SELECT TRUNC(inEndDate,'MM') - ROWNUM + 1 AS dt FROM dual CONNECT BY ROWNUM <= TRUNC(inEndDate,'MM') - TRUNC(inBegDate,'MM') + 1
      ) GROUP BY TRUNC(dt,'MM') ORDER BY 1
    ) LOOP
      vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' MODIFY PARTITION '||UPPER(inSign)||' ADD SUBPARTITION '||vSPCode||'_'||to_char(dt.dt,'YYYYMM')||' VALUES LESS THAN (to_date('''||to_char(last_day(dt.dt)+1,'DD.MM.YYYY')||''',''DD.MM.YYYY''))';
      EXECUTE IMMEDIATE vBuff;
    END LOOP;
    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vTmpTable ELSE vTmpATable END||' MODIFY PARTITION '||UPPER(inSign)||' ADD SUBPARTITION '||vSPCode||'_NEW VALUES LESS THAN (MAXVALUE)';
    EXECUTE IMMEDIATE vBuff;

    vTIBegin := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - загрузка первых чисел месяца в промежуточную таблицу --------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    -- Вставка данных в промежуточную таблицу за первые числа каждого месяца
    /*mass_load_parallel_by_year(TRUNC(inBegDate,'DD'),inEndDate
      ,lower(vOwner)||'.pkg_etl_signs.tmp_load_prev'
      ,'VARCHAR2 '||UPPER(inSign),FALSE,'01',inHeadJobName);*/
    mass_load_parallel_by_ydate_pe(TRUNC(inBegDate,'DD'),inEndDate
      ,lower(vOwner)||'.pkg_etl_signs.tmp_load_prev'
      ,'VARCHAR2 '||UPPER(inSign)||'::VARCHAR2 '||inAnltCode,FALSE,'01'/*,inHeadJobName*/);

    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание загрузки первых чисел месяца в промежуточную таблицу. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
  END IF;

  IF vDaily THEN
    vTIBegin := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - прогрузка всех чисел месяца в промежуточную таблицу (распараллеливание по месяцам) --------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    FOR idx IN 2..31
      LOOP
        -- Прогрузка всех чисел месяца в промежуточную таблицу (распараллеливание по месяцам)
        /*mass_load_parallel_by_year(TRUNC(inBegDate,'DD'),inEndDate
          ,lower(vOwner)||'.pkg_etl_signs.tmp_load_daily'
          ,'VARCHAR2 '||UPPER(inSign),FALSE,to_char(idx,'00'),inHeadJobName);*/
        mass_load_parallel_by_ydate_pe(TRUNC(inBegDate,'DD'),inEndDate
          ,lower(vOwner)||'.pkg_etl_signs.tmp_load_daily'
          ,'VARCHAR2 '||UPPER(inSign)||'::VARCHAR2 '||inAnltCode,FALSE,to_char(idx,'00')/*,inHeadJobName*/);
      END LOOP;

    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание прогрузки всех чисел месяца в промежуточную таблицу. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
  END IF;


  vTIBegin := SYSDATE;
  vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - Подготовка существующих данных в целевой таблице --------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

  IF vTruncateTarget THEN
    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' TRUNCATE PARTITION '||UPPER(inSign);
    BEGIN
      EXECUTE IMMEDIATE vBuff;
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' truncated';
    EXCEPTION WHEN OTHERS THEN
      vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' not truncated :: '||SQLERRM;
    END;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
  ELSE
    IF vLoadTarget THEN
      -- Установка effective_end у записей, соответствующих дате начала периода
      vBuff :=
      'BEGIN'||CHR(10)||
      '  UPDATE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' SET effective_end = to_date('''||to_char(inBegDate - 1,'DD.MM.YYYY')||''',''DD.MM.YYYY'')'||CHR(10)||
      '    WHERE sign_name = '''||UPPER(inSign)||''''||CHR(10)||
      '      AND to_date('''||to_char(inBegDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') BETWEEN effective_start AND effective_end'||CHR(10)||
      '      AND effective_start < to_date('''||to_char(inBegDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'');'||CHR(10)||
      '  :1 := SQL%ROWCOUNT;'||CHR(10)||
      '  COMMIT;'||CHR(10)||
      'END;';
      EXECUTE IMMEDIATE vBuff USING OUT vCou;
      vMes := 'SUCCESSFULLY :: ------- "'||UPPER(inSign)||'" - "effective_end" - '||vCou||' rows updated in table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'"';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
      -- Установка effective_start у записей, соответствующих дате окончания периода
      vBuff :=
      'BEGIN'||CHR(10)||
      '  UPDATE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' SET effective_start = to_date('''||to_char(last_day(inEndDate) + 1,'DD.MM.YYYY')||''',''DD.MM.YYYY'')'||CHR(10)||
      '    WHERE sign_name = '''||UPPER(inSign)||''''||CHR(10)||
      '      AND to_date('''||to_char(last_day(inEndDate),'DD.MM.YYYY')||''',''DD.MM.YYYY'') BETWEEN effective_start AND effective_end'||CHR(10)||
      '      AND effective_end > to_date('''||to_char(inEndDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'');'||CHR(10)||
      '  :1 := SQL%ROWCOUNT;'||CHR(10)||
      '  COMMIT;'||CHR(10)||
      'END;';
      EXECUTE IMMEDIATE vBuff USING OUT vCou;
      vMes := 'SUCCESSFULLY :: ------- "'||UPPER(inSign)||'" - "effective_start" - '||vCou||' rows updated in table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'"';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
      -- Удаление записей, с effective_start больше или равно даты начала периода
      vBuff :=
      'BEGIN'||CHR(10)||
      'DELETE FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||CHR(10)||
      '  WHERE sign_name = '''||UPPER(inSign)||''''||CHR(10)||
      '    AND effective_start BETWEEN to_date('''||to_char(inBegDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') AND to_date('''||to_char(last_day(inEndDate),'DD.MM.YYYY')||''',''DD.MM.YYYY'');'||CHR(10)||
      '  :1 := SQL%ROWCOUNT;'||CHR(10)||
      '  COMMIT;'||CHR(10)||
      'END;';
      EXECUTE IMMEDIATE vBuff USING OUT vCou;
      vMes := 'SUCCESSFULLY :: ------- "'||UPPER(inSign)||'" - '||vCou||' rows deleted from table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'"';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
      -- Удаление записей, с effective_start больше или равно текущей даты (такие получаются когда считаем всё, по вчерашний день)
      vBuff :=
      'BEGIN'||CHR(10)||
      'DELETE FROM '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||CHR(10)||
      '  WHERE sign_name = '''||UPPER(inSign)||''''||CHR(10)||
      '    AND effective_start >= to_date('''||to_char(trunc(SYSDATE,'DD'),'DD.MM.YYYY')||''',''DD.MM.YYYY'');'||CHR(10)||
      '  :1 := SQL%ROWCOUNT;'||CHR(10)||
      '  COMMIT;'||CHR(10)||
      'END;';
      EXECUTE IMMEDIATE vBuff USING OUT vCou;
      vMes := 'SUCCESSFULLY :: ------- "'||UPPER(inSign)||'" - Technical Fictitious Future - '||vCou||' rows deleted from table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'"';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    END IF;
  END IF;

  vEndTime := SYSDATE;
  vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание подготовки существующих данных в целевой таблице. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

  IF vLoadTarget THEN
    vTIBegin := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - загрузка данных в целевую таблицу --------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    vTIBegin := SYSDATE;
    sign_gluing(UPPER(inSign),UPPER(inAnltCode),'010');

    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание загрузки данных в целевую таблицу. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    -- Проставляем effective_end = 31.12.5999 на последних записях
    -- !!!ТОЛЬКО ЕСЛИ ДАТА ОКОНЧАНИЯ НЕ РАНЕЕ ВЧЕРАШНЕЙ ИНАЧЕ БУДЕТ ОШИБКА Unique constraint!!!
    IF last_day(inEndDate) >= TRUNC(SYSDATE - 1,'DD') THEN
       vMes := 'CONTINUE :: -------- "'||UPPER(inSign)||'" - EFFECTIVE_END -> "31.12.5999" апдейт последних записей ---------';
       pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

       vTIBegin := SYSDATE;
       tb_upd_eff_end(UPPER(inSign),UPPER(inAnltCode),last_day(inEndDate));

     ELSE
       vMes := 'SUCCESSFULLY :: ------- "'||UPPER(inSign)||'" Update of column EFFECTIVE_END on date "31.12.5999" not required';
       pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
     END IF;

     vEndTime := SYSDATE;
     vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - EFFECTIVE_END -> "31.12.5999" окончание апдейта последних записей. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
     pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
  END IF;

  IF vCompress THEN
    -- Сжатие данных в целевой таблице
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - сжатие данных в целевой таблице --------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    vTIBegin := SYSDATE;
    vBuff := 'ALTER TABLE '||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||' MOVE PARTITION '||UPPER(inSign)||' COMPRESS';
    BEGIN
      EXECUTE IMMEDIATE vBuff;
      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' compressed in '||get_ti_as_hms(vEndTime - vTIBegin);
    EXCEPTION WHEN OTHERS THEN
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' not compressed :: '||SQLERRM||Chr(10)||'------'||Chr(10)||'Execution time: '||get_ti_as_hms(vEndTime - vTIBegin);
    END;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание сжатия данных в целевой таблице. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    -- Перестроение индексов в целевой таблице
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - перестроение индексов в целевой таблице --------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    -- Получение наименования индекса
    SELECT index_name INTO vIdx FROM all_indexes
      WHERE owner = UPPER(vOwner) AND table_name = UPPER(SUBSTR(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,INSTR(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,'.',1,1) + 1,LENGTH(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END) - INSTR(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,'.',1,1)))
        AND uniqueness = 'UNIQUE'
        AND index_name LIKE 'UIX%';

    vTIBegin := SYSDATE;
    vBuff := 'ALTER INDEX '||lower(vOwner||'.'||vIdx)||' REBUILD PARTITION '||UPPER(inSign);
    BEGIN
      EXECUTE IMMEDIATE vBuff;
      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: Index "'||lower(vOwner||'.'||vIdx)||'" - Partition '||UPPER(inSign)||' rebuilded in '||get_ti_as_hms(vEndTime - vTIBegin);
    EXCEPTION WHEN OTHERS THEN
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Index "'||lower(vOwner||'.'||vIdx)||'" - Partition '||UPPER(inSign)||' not rebuilded :: '||SQLERRM||Chr(10)||'------'||Chr(10)||'Execution time: '||get_ti_as_hms(vEndTime - vTIBegin);
    END;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание перестроения индексов в целевой таблице. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
  END IF;

  IF vStats THEN
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - сбор статистики по целевой таблице --------';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    vTIBegin := SYSDATE;
    vBuff := 'BEGIN dbms_stats.gather_table_stats('''||UPPER(vOwner)||''','''||UPPER(SUBSTR(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,INSTR(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,'.',1,1) + 1,LENGTH(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END) - INSTR(CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END,'.',1,1)))||''','''||UPPER(inSign)||''',20); END;';
    BEGIN
      EXECUTE IMMEDIATE vBuff;
      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' Statistic gathered in '||get_ti_as_hms(vEndTime - vTIBegin);
    EXCEPTION WHEN OTHERS THEN
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Table "'||CASE WHEN inAnltCode IS NULL THEN vHistTable ELSE vHistATable END||'" - Partition '||UPPER(inSign)||' Statistic not gathered :: '||SQLERRM||Chr(10)||'------'||Chr(10)||'Execution time: '||get_ti_as_hms(vEndTime - vTIBegin);
    END;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);

    vEndTime := SYSDATE;
    vMes := 'CONTINUE :: ------- "'||UPPER(inSign)||'" - окончание сбора статистики по целевой таблице. Время выполнения - '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inSign||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.tb_load_mass" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' successfully';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: '||SQLERRM;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
    vMes := 'FINISH :: "'||inSign||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.tb_load_mass" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.tb_load_mass',vMes);
END tb_load_mass;

PROCEDURE SignExtProcessing(inSign IN VARCHAR2,inDate IN DATE)
  IS
    vStmt CLOB;
    vRes VARCHAR2(32700);
    --
    vMes VARCHAR2(32700);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||UPPER(inSign)||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.SignExtProcessing" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.SignExtProcessing',vMes);

  -- Получение ext_plsql
  BEGIN
    SELECT ext_plsql
      INTO vStmt
      FROM tb_signs_pool p
      WHERE p.sign_name = UPPER(inSign);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Показатель "'||inSign||'" не найден в таблице '||lower(vOwner)||'.tb_signs_pool');
  END;

  EXECUTE IMMEDIATE 'ALTER SESSION SET nls_date_format = ''DD.MM.RRRR HH24:MI:SS''';
  -- Обработка
  EXECUTE IMMEDIATE vStmt USING IN UPPER(inSign),IN inDate,OUT vRes;

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: "'||UPPER(inSign)||'" extended processing :: '||vRes;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.SignExtProcessing',vMes);
  vMes := 'FINISH :: "'||UPPER(inSign)||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.SignExtProcessing" finished successfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.SignExtProcessing',vMes);
EXCEPTION WHEN OTHERS THEN
  vEndTime := SYSDATE;
  vMes := 'ERROR :: "'||UPPER(inSign)||'" extended processing :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.SignExtProcessing',vMes);
  vMes := 'FINISH :: "'||UPPER(inSign)||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.SignExtProcessing" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.SignExtProcessing',vMes);
END;


FUNCTION get_empty_sign_id RETURN NUMBER
  IS
    vRes NUMBER;
BEGIN
  SELECT MAX(ID) + 1 INTO vRes FROM tb_signs_pool;

  WITH
    digit AS (
     SELECT LEVEL AS ID FROM dual CONNECT BY ROWNUM <= vRes
    )
  SELECT MIN(d_id) AS ID INTO vRes
    FROM (SELECT digit.id AS d_id,p.id AS p_id FROM digit LEFT JOIN tb_signs_pool p ON p.id = digit.id)
    WHERE p_id IS NULL;
  RETURN vRes;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN vRes;
  WHEN OTHERS THEN
    RETURN -1;
END get_empty_sign_id;

FUNCTION DropSignPartitions(inSign IN VARCHAR2) RETURN VARCHAR2
  IS
    vOut VARCHAR2(4000);
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vOut := '------------';
  FOR idx IN (
    WITH
      fct AS (
        SELECT UPPER(fct_table_name) AS table_name
          FROM tb_signs_pool p
               INNER JOIN tb_entity e ON e.id = p.entity_id
          WHERE p.sign_name = UPPER(inSign)
            AND p.hist_flg = 0
        UNION
        SELECT UPPER(e.fct_table_name)
          FROM tb_signs_pool p
               INNER JOIN tb_sign_2_anlt s2a ON s2a.sign_name = p.sign_name
               INNER JOIN tb_signs_anlt a
                 ON a.anlt_code = s2a.anlt_code
                    AND SYSDATE BETWEEN a.effective_start AND a.effective_end
               INNER JOIN tb_entity e
                 ON e.id = a.entity_id
          WHERE p.sign_name = UPPER(inSign)
            AND p.hist_flg = 0
      )
     ,hist AS (
        SELECT UPPER(e.hist_table_name) AS table_name
          FROM tb_signs_pool p
               INNER JOIN tb_entity e ON e.id = p.entity_id
          WHERE p.sign_name = UPPER(inSign)
            AND p.hist_flg = 1
        UNION
        SELECT UPPER(e.tmp_table_name)
          FROM tb_signs_pool p
               INNER JOIN tb_entity e ON e.id = p.entity_id
          WHERE p.sign_name = UPPER(inSign)
            AND p.hist_flg = 1
        UNION
        SELECT UPPER(e.hist_table_name)
          FROM tb_signs_pool p
               INNER JOIN tb_sign_2_anlt s2a ON s2a.sign_name = p.sign_name
               INNER JOIN tb_signs_anlt a
                 ON a.anlt_code = s2a.anlt_code
                    AND SYSDATE BETWEEN a.effective_start AND a.effective_end
               INNER JOIN tb_entity e
                 ON e.id = a.entity_id
          WHERE p.sign_name = UPPER(inSign)
            AND p.hist_flg = 1
        UNION
        SELECT UPPER(e.tmp_table_name)
          FROM tb_signs_pool p
               INNER JOIN tb_sign_2_anlt s2a ON s2a.sign_name = p.sign_name
               INNER JOIN tb_signs_anlt a
                 ON a.anlt_code = s2a.anlt_code
                    AND SYSDATE BETWEEN a.effective_start AND a.effective_end
               INNER JOIN tb_entity e
                 ON e.id = a.entity_id
          WHERE p.sign_name = UPPER(inSign)
            AND p.hist_flg = 1
      )

    SELECT fct.table_name,prt.partition_name
      FROM fct
           INNER JOIN all_tab_partitions prt
             ON prt.table_owner = UPPER(vOwner)
                AND prt.table_name = fct.table_name
                AND prt.partition_name = UPPER(inSign)
    UNION
    SELECT hist.table_name,prt.partition_name
      FROM hist
           INNER JOIN all_tab_partitions prt
             ON prt.table_owner = UPPER(vOwner)
                AND prt.table_name = hist.table_name
                AND prt.partition_name = UPPER(inSign)
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||lower(vOwner||'.'||idx.table_name)||' DROP PARTITION '||UPPER(inSign);
      vOut := vOut||CHR(10)||'SUCCESSFULLY :: Table "'||lower(vOwner||'.'||idx.table_name)||'" - Partition "'||UPPER(inSign)||'" dropped';
      --dbms_output.put_line(idx.table_name||'|'||idx.partition_name);
    EXCEPTION WHEN OTHERS THEN
      vOut := vOut||CHR(10)||'ERROR :: Table "'||lower(vOwner||'.'||idx.table_name)||'" - Partition "'||UPPER(inSign)||'" not dropped :: '||SQLERRM;
    END;
  END LOOP;
  RETURN vOut;
END DropSignPartitions;

PROCEDURE drop_sign(inSign IN VARCHAR2,outRes OUT VARCHAR2)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Удаление партиции
  outRes := DropSignPartitions(UPPER(inSign));

  -- Удаление привязки к аналитикам
  BEGIN
    DELETE FROM tb_sign_2_anlt WHERE sign_name = UPPER(inSign);
    outRes := outRes||CHR(10)||'------------'||CHR(10)||'SUCCESSFULLY :: "'||UPPER(inSign)||'" - Удалено '||SQL%ROWCOUNT||' привязок к аналитикам';
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||CHR(10)||'------------'||CHR(10)||'ERROR :: "'||UPPER(inSign)||'" - не возможно удалить привязки к аналитикам :: '||SQLERRM;
    RAISE_APPLICATION_ERROR(-20000,outRes);
  END;

  -- Удаление привязки к группе
  BEGIN
    DELETE FROM tb_signs_2_group WHERE sign_name = UPPER(inSign);
    outRes := outRes||CHR(10)||'SUCCESSFULLY :: "'||UPPER(inSign)||'" - Удалено '||SQL%ROWCOUNT||' привязок к группам';
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||CHR(10)||'ERROR :: "'||UPPER(inSign)||'" - не возможно удалить привязки к группам :: '||SQLERRM;
    RAISE_APPLICATION_ERROR(-20000,outRes);
  END;
  -- Удаление зависимости от других показателей
  BEGIN
    DELETE FROM tb_sign_2_sign WHERE sign_name = UPPER(inSign) OR prev_sign_name = UPPER(inSign);
    outRes := outRes||CHR(10)||'SUCCESSFULLY :: "'||UPPER(inSign)||'" - Удалено '||SQL%ROWCOUNT||' зависимостей от других показателей';
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||CHR(10)||'ERROR :: "'||UPPER(inSign)||'" - не возможно удалить зависимости от других показателей :: '||SQLERRM;
    RAISE_APPLICATION_ERROR(-20000,outRes);
  END;

  -- Удаление из списка показателей
  BEGIN
    DELETE FROM tb_signs_pool WHERE sign_name = UPPER(inSign);
    outRes := outRes||CHR(10)||'------------'||CHR(10)||'SUCCESSFULLY :: "'||UPPER(inSign)||'" - Показатель удален из списка показателей';
  EXCEPTION WHEN OTHERS THEN
    outRes := outRes||CHR(10)||'------------'||CHR(10)||'ERROR :: "'||UPPER(inSign)||'" - не возможно удалить показатель в таблице "'||lower(vOwner)||'.tb_signs_pool" :: '||SQLERRM;
  END;
EXCEPTION WHEN OTHERS THEN
  outRes := outRes||CHR(10)||'------------'||CHR(10)||'ERROR :: "'||UPPER(inSign)||'" - '||SQLERRM;
END drop_sign;

FUNCTION GetTreeList(inSQL IN CLOB) RETURN TTabTree PIPELINED
  IS
    rec TRecTree;
      cur INTEGER;       -- хранит идентификатор (ID) курсора
      ret INTEGER;       -- хранит возвращаемое по вызову значение
BEGIN
  cur := dbms_sql.open_cursor;
  dbms_sql.parse(cur, inSQL, dbms_sql.native);
  dbms_sql.define_column(cur,1,rec.Id,4000);
  dbms_sql.define_column(cur,2,rec.ParentId,4000);
  ret := dbms_sql.execute(cur);
  LOOP
    EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
    dbms_sql.column_value(cur,1,rec.Id);
    dbms_sql.column_value(cur,2,rec.ParentId);
    PIPE ROW(rec);
  END LOOP;
  dbms_sql.close_cursor(cur);
END;

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
    dbms_sql.define_column(cur,5,rec.skip);

    ret := dbms_sql.execute(cur);

    LOOP
      EXIT WHEN dbms_sql.fetch_rows(cur) = 0;
      dbms_sql.column_value(cur,1,rec.id);
      dbms_sql.column_value(cur,2,rec.parent_id);
      dbms_sql.column_value(cur,3,rec.unit);
      dbms_sql.column_value(cur,4,rec.params);
      dbms_sql.column_value(cur,5,rec.skip);
      PIPE ROW(rec);
    END LOOP;
    dbms_sql.close_cursor(cur);
END GetChainList;

FUNCTION GetTreeSQL(inFullSQL IN CLOB
                   ,inStartSQL IN CLOB
                   ,inIncludeChilds IN INTEGER DEFAULT 0)
  RETURN CLOB
  IS
    vRes CLOB;
    vBuff VARCHAR2(32700);
    vCou INTEGER :=0;
    vStartSQL CLOB := inStartSQL;
BEGIN
  IF inStartSQL IS NULL THEN vStartSQL := inFullSQL; END IF;

  dbms_lob.createtemporary(vRes,FALSE);

  IF inIncludeChilds = 0 AND inStartSQL IS NOT NULL THEN
    FOR idx IN (
      WITH
        f AS (SELECT * FROM TABLE(GetTreeList(inFullSQL)))
       ,s AS (SELECT * FROM TABLE(GetTreeList(vStartSQL)))
       SELECT DISTINCT s.id,f.parentid
         FROM s INNER JOIN f ON f.id = s.id
         WHERE NVL(f.parentid,s.id) IN (SELECT ID FROM s)
    ) LOOP
      vBuff := CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.id||''' AS id,'||CASE WHEN idx.parentid IS NOT NULL THEN ''''||idx.parentid||'''' ELSE 'NULL' END||' AS PARENT_ID FROM dual';
      dbms_lob.writeappend(vRes,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;
  ELSIF inIncludeChilds = 1  AND inStartSQL IS NOT NULL THEN
    FOR idx IN (
    WITH
      f AS (SELECT * FROM TABLE(GetTreeList(inFullSQL)))
     ,s AS (SELECT * FROM TABLE(GetTreeList(vStartSQL)))
     ,c AS (
        SELECT ID,parentid FROM s
        UNION ALL
        SELECT ID,parentid FROM (
          SELECT ID,parentid FROM f
          MINUS
          SELECT ID,parentid FROM s)
      )
      SELECT DISTINCT ID,parentid FROM (
        SELECT ID,parentid
          FROM c CONNECT BY PRIOR ID = parentid START WITH id IN (SELECT ID FROM s)
      ) WHERE parentid IS NULL OR parentid IN (SELECT ID FROM s)
    ) LOOP
      vBuff := CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.id||''' AS id,'||CASE WHEN idx.parentid IS NOT NULL THEN ''''||idx.parentid||'''' ELSE 'NULL' END||' AS PARENT_ID FROM dual';
      dbms_lob.writeappend(vRes,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;
  ELSE
    FOR idx IN (
      WITH
        f AS (SELECT * FROM TABLE(GetTreeList(inFullSQL)))
       SELECT DISTINCT f.id,f.parentid
         FROM f
    ) LOOP
      vBuff := CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.id||''' AS id,'||CASE WHEN idx.parentid IS NOT NULL THEN ''''||idx.parentid||'''' ELSE 'NULL' END||' AS PARENT_ID FROM dual';
      dbms_lob.writeappend(vRes,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;
  END IF;
  RETURN vRes;
END GetTreeSQL;

FUNCTION ChainBuilder(/*inID VARCHAR2,*/inSQL CLOB) RETURN VARCHAR2
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vID VARCHAR2(30) := to_char(tb_signs_job_id_seq.nextval);
    vChainName VARCHAR2(256) := vOwner||'.CHAIN_'||vID;--inID;
    vBuff VARCHAR2(32700);
    vPrg CLOB;
    vArg CLOB;
    vStp CLOB;
    vRul CLOB;
    vAct CLOB;
    ErrAct VARCHAR2(256);
    ErrComm VARCHAR2(256);
    PrgCou INTEGER := 0;
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
     IF PrgCou <=1 THEN ErrAct := idx.action; ErrComm := idx.comm; END IF;
     PrgCou := PrgCou + 1;
      vBuff :=
      '  sys.dbms_scheduler.create_program(program_name        => '''||idx.prg_name||''','||CHR(10)||
      '                                    program_type        => ''STORED_PROCEDURE'','||CHR(10)||
      '                                    program_action      => '''||idx.action||''','||CHR(10)||
      '                                    number_of_arguments => '||idx.arg_cou||','||CHR(10)||
      '                                    enabled             => false,'||CHR(10)||
      '                                    comments            => '''||idx.comm||''');'||CHR(10);
      dbms_lob.writeappend(vPrg,length(vBuff),vBuff);
  END LOOP;
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
          ,skip
      FROM TABLE(GetChainList(inSQL)) p
  ) LOOP
    vBuff :=
    '  sys.dbms_scheduler.define_chain_step(chain_name   => '''||vChainName||''','||CHR(10)||
    '                                       step_name    => '''||idx.stp_name||''','||CHR(10)||
    '                                       program_name => '''||idx.prg_name||''');'||CHR(10);
    dbms_lob.writeappend(vStp,length(vBuff),vBuff);

    IF idx.skip = 1 THEN
      vBuff :=
      'dbms_scheduler.alter_chain(chain_name  =>  '''||vChainName||''','||CHR(10)||
      'step_name   =>  '''||idx.stp_name||''','||CHR(10)||
      'attribute   =>  ''SKIP'','||CHR(10)||
      'value       =>  TRUE);'||CHR(10);
      dbms_lob.writeappend(vStp,length(vBuff),vBuff);
    END IF;
  END LOOP;
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
  END LOOP;
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
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.ChainBuilder','SUCCESSFULLY :: Chain '||vChainName||' - Action '||ErrAct||' - Comments '||ErrComm||' builded');

  RETURN vChainName;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.ChainBuilder','ERROR :: '||SQLERRM);
  RETURN vChainName;
END ChainBuilder;

FUNCTION ChainStarter(inChainName IN VARCHAR2,inHeadJobName IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vRes VARCHAR2(4000);
    vJobName VARCHAR2(256) := NVL(inHeadJobName,vOwner||'.CHAINJOB_'||to_char(SYSDATE,'RRRRMMDDHH24MISS'));
BEGIN
  vRes := inChainName;
  sys.dbms_scheduler.run_chain(inChainName,'STP_START',vJobName);
  RETURN vRes;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.ChainStarter','ERROR :: '||SQLERRM);
  RETURN vRes;
END ChainStarter;

PROCEDURE ChainKiller(inChainName VARCHAR2)
  IS
  vRunChCou INTEGER := 1;
  curPrg SYS_REFCURSOR;
  vPrgName VARCHAR2(256);
  vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Ожидание пока отработает цепь
  LOOP
    SELECT COUNT(1) INTO vRunChCou
      FROM all_scheduler_running_chains
      WHERE lower(owner)||'.'||lower(chain_name) = LOWER(inChainName)
        AND completed = 'FALSE';
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
  BEGIN
    sys.dbms_scheduler.drop_chain(LOWER(inChainName),TRUE);
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- Удаление программ
  LOOP
    FETCH curPrg INTO vPrgName;
    EXIT WHEN curPrg%NOTFOUND;
    BEGIN
      sys.dbms_scheduler.drop_program(vPrgName,TRUE);
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;

  CLOSE curPrg;
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.ChainKiller','ERROR :: '||SQLERRM);
END ChainKiller;

PROCEDURE calc(inBegDate IN DATE,inEndDate IN DATE)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'AUTOCALC_'||tb_signs_job_id_seq.nextval;
    vBuff VARCHAR2(4000);
BEGIN
  vBuff :=
    'SELECT p.id,c2c.parent_id,p.e_unit AS unit'||CHR(10)||
    '      ,REPLACE(REPLACE(p.params,'':INBEGDATE'','''||to_char(inBegDate,'DD.MM.YYYY')||'''),'':INENDDATE'','''||to_char(inEndDate,'DD.MM.YYYY')||''') AS params'||CHR(10)||
    '      ,CASE WHEN p.archive_flag = 0 AND '||vOwner||'.pkg_etl_signs.GetConditionResult(p.condition) = 1 THEN 0 ELSE 1 END AS skip'||CHR(10)||
    ' FROM tb_calc_pool p'||CHR(10)||
    '       LEFT JOIN tb_calc_2_calc c2c'||CHR(10)||
    '         ON c2c.id = p.id /*AND c2c.parent_id IN (SELECT id FROM tb_calc_pool WHERE archive_flag = 0)*/'||CHR(10)||
    '  /*WHERE p.archive_flag = 0*/'||CHR(10);

    load_new(vBuff,vJobName);
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.calc',SQLERRM);
END calc;

PROCEDURE CalcSignsByGroup(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vBuff VARCHAR2(32700);
    vUnit VARCHAR2(256) := lower(vOwner)||'.pkg_etl_signs.'||CASE WHEN ABS(MONTHS_BETWEEN(inEndDate,inBegDate)) <= 1 THEN 'load_sign' ELSE 'mass_load' END;
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vBuff :=
  q'[
  SELECT s2g.sign_name AS id
        ,s2s.prev_sign_name AS parent_id
        ,']'||vUnit||q'[' AS unit
        ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||s2g.sign_name||'#!##!#1' AS params
        ,CASE WHEN p.condition IS NULL OR pkg_etl_signs.GetConditionResult(p.condition) = 1 THEN 0 ELSE 1 END AS skip
    FROM tb_signs_2_group s2g
         LEFT JOIN tb_signs_pool p ON p.sign_name = s2g.sign_name
         LEFT JOIN tb_sign_2_sign s2s
           ON s2s.sign_name = s2g.sign_name
              AND EXISTS (SELECT NULL FROM tb_signs_pool WHERE sign_name = s2s.prev_sign_name AND archive_flg = 0)
              AND s2s.prev_sign_name IN (SELECT g1.sign_name
                                           FROM tb_signs_2_group g1
                                           WHERE g1.group_id = ]'||inGroupID||q'[)
    WHERE s2g.group_id = ]'||inGroupID||q'[
      AND EXISTS (SELECT NULL FROM tb_signs_pool WHERE sign_name = s2g.sign_name AND archive_flg = 0)
  ORDER BY s2g.sign_name
  ]';

  load_new(vBuff,inJobName);
  --dbms_output.put_line(vBuff);
END CalcSignsByGroup;


PROCEDURE CalcSignsByStar(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vBuff VARCHAR2(32700);
    vUnit VARCHAR2(256) := lower(vOwner)||'.pkg_etl_signs.'||CASE WHEN ABS(MONTHS_BETWEEN(inEndDate,inBegDate)) <= 1 THEN 'load_sign' ELSE 'mass_load' END;
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vBuff :=
  q'[
  SELECT s2g.sign_name AS ID
        ,s2s.prev_sign_name AS parent_id
        ,']'||vUnit||q'[' AS unit
        ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||s2g.sign_name||'#!##!#1' AS params
        ,CASE WHEN p.condition IS NULL OR pkg_etl_signs.GetConditionResult(p.condition) = 1 THEN 0 ELSE 1 END AS skip
    FROM tb_signs_2_group s2g
         LEFT JOIN tb_signs_pool p ON p.sign_name = s2g.sign_name
         LEFT JOIN tb_sign_2_sign s2s
           ON s2s.sign_name = s2g.sign_name
              AND EXISTS (SELECT NULL FROM tb_signs_pool WHERE sign_name = s2s.prev_sign_name AND archive_flg = 0)
              AND s2s.prev_sign_name IN (SELECT sg.sign_name
                                           FROM tb_signs_group g1
                                                LEFT JOIN tb_signs_2_group sg
                                                  ON sg.group_id = g1.group_id
                                           WHERE LEVEL <= 2
                                           CONNECT BY PRIOR g1.group_id = g1.parent_group_id
                                           START WITH g1.group_id = ]'||inGroupID||q'[)
    WHERE s2g.group_id IN (SELECT group_id FROM tb_signs_group WHERE LEVEL <= 2 CONNECT BY PRIOR group_id = parent_group_id START WITH group_id = ]'||inGroupID||q'[)
      AND EXISTS (SELECT NULL FROM tb_signs_pool WHERE sign_name = s2g.sign_name AND archive_flg = 0)
  ORDER BY s2g.sign_name
  ]';

  load_new(vBuff,inJobName);
  --dbms_output.put_line(vBuff);
END CalcSignsByStar;

PROCEDURE CalcAnltByGroup(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vBuff VARCHAR2(32700);
    vUnit VARCHAR2(256) := lower(vOwner)||'.pkg_etl_signs.'||CASE WHEN ABS(MONTHS_BETWEEN(inEndDate,inBegDate)) <= 1 THEN 'load_sign' ELSE 'mass_load' END;
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vBuff :=
  q'[
    SELECT s2g.sign_name||'|'||s2a.anlt_code AS id
          ,NULL AS parent_id
          ,']'||vUnit||q'[' AS unit
          ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||s2g.sign_name||'#!#'||s2a.anlt_code||'#!#1' AS params
          ,0 AS skip
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
                AND p.archive_flg = 0
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2g.sign_name = s2a.sign_name
                AND EXISTS (SELECT NULL FROM tb_anlt_2_group a2g WHERE a2g.anlt_code = s2a.anlt_code AND a2g.group_id = ]'||inGroupID||')
      WHERE s2g.group_id = '||inGroupID||'
        AND s2a.anlt_code IS NOT NULL';
  load_new(vBuff,inJobName);
  --dbms_output.put_line(vBuff);
END CalcAnltByGroup;

PROCEDURE CalcAnltByStar(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inJobName VARCHAR2)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vBuff VARCHAR2(32700);
    vUnit VARCHAR2(256) := lower(vOwner)||'.pkg_etl_signs.'||CASE WHEN ABS(MONTHS_BETWEEN(inEndDate,inBegDate)) <= 1 THEN 'load_sign' ELSE 'mass_load' END;
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vBuff :=
  q'[
  SELECT s2g.sign_name||'|'||s2a.anlt_code AS ID
        ,NULL AS parent_id
        ,']'||vUnit||q'[' AS unit
        ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||s2g.sign_name||'#!#'||s2a.anlt_code||'#!#1' AS params
        ,0 AS skip
    FROM tb_signs_2_group s2g
         LEFT JOIN tb_sign_2_anlt s2a
           ON s2g.sign_name = s2a.sign_name
              AND EXISTS (SELECT NULL FROM tb_anlt_2_group a2g
                            WHERE a2g.anlt_code = s2a.anlt_code
                              AND a2g.group_id = (SELECT group_id FROM tb_signs_group WHERE LEVEL = 3 CONNECT BY PRIOR group_id = parent_group_id START WITH group_id = ]'||inGroupID||q'[))
    WHERE s2g.group_id = (SELECT group_id FROM tb_signs_group WHERE LEVEL = 3 CONNECT BY PRIOR group_id = parent_group_id START WITH group_id = ]'||inGroupID||q'[)
      AND EXISTS (SELECT NULL FROM tb_signs_pool WHERE sign_name = s2g.sign_name AND archive_flg = 0)
  ORDER BY s2g.sign_name
  ]';
  load_new(vBuff,inJobName);
  --dbms_output.put_line(vBuff);
END CalcAnltByStar;

/******************************** ИМПОРТ - ЭКСПОРТ **************************************/
FUNCTION AnltSpecImpGetCondition(inSignName VARCHAR2,inIds VARCHAR2 DEFAULT NULL,inProduct IN NUMBER DEFAULT 0) RETURN CLOB
  IS
    vCond CLOB;
    vBuff VARCHAR2(32700);
    vCou INTEGER := 0;
BEGIN
  dbms_lob.createtemporary(vCond,TRUE);
  FOR idx IN (
    SELECT rul.rule_id
      FROM skb_ecc_new.ecc_rule rul
      WHERE skb_ecc_new.getdim(rul.dim_key,CASE WHEN inProduct = 0 THEN 'D38328296CBF147E5A0794D9AF4FB1F59DFFACBD' ELSE '597074F6BDD5CDBFCBBA37523F1D0C4D72BB0B23' END) = inSignName
        AND (inIds IS NULL OR inIds IS NOT NULL AND rul.rule_id IN (SELECT str FROM TABLE(parse_str(inIds,','))))
  ) LOOP
    IF vCou = 0 THEN
      vBuff := REPLACE(REPLACE(dbms_lob.substr(skb_ecc_new.rule_pkg.getSqlCondition(idx.rule_id,'N')),'t.','anlt.'),'T.','anlt.');
      ELSE vBuff := CHR(10)||' OR '||CHR(10)||REPLACE(REPLACE(dbms_lob.substr(skb_ecc_new.rule_pkg.getSqlCondition(idx.rule_id,'N')),'t.','anlt.'),'T.','anlt.');
    END IF;
    dbms_lob.writeappend(vCond,LENGTH(vBuff),vBuff);
    vCou := vCou + 1;
  END LOOP;
  RETURN vCond;
EXCEPTION WHEN OTHERS THEN
  RETURN 'ERROR :: '||inSignName||' :: '||SQLERRM;
END AnltSpecImpGetCondition;

PROCEDURE AnltSpecImport(inDate IN DATE,inAnltCode IN VARCHAR2)
  IS
    vAnltID NUMBER;
    vMes VARCHAR2(4000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.AnltSpecImport" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.AnltSpecImport',vMes);

  FOR idx IN (
    SELECT str AS AnltCode FROM TABLE(parse_str(inAnltCode,','))
  ) LOOP
    BEGIN
      -- ИД аналитики
      SELECT id
        INTO vAnltID
        FROM tb_signs_anlt
        WHERE anlt_code = UPPER(idx.AnltCode) AND inDate BETWEEN effective_start AND effective_end;

      MERGE INTO tb_signs_anlt_spec dest
        USING (SELECT vAnltID AS anlt_id,val,parent_val,name,condition
                 FROM TABLE(get_anlt_spec_imp(inDate,UPPER(idx.AnltCode)))
              ) src ON (dest.anlt_id = src.anlt_id AND dest.anlt_spec_val = src.val)
        WHEN NOT MATCHED THEN
          INSERT (dest.id,dest.anlt_id,dest.anlt_spec_val,dest.parent_val,dest.anlt_spec_name,dest.condition)
            VALUES (tb_signs_anlt_spec_id_seq.nextval,src.anlt_id,src.val,src.parent_val,src.name,src.condition)
        WHEN MATCHED THEN
          UPDATE SET dest.parent_val = src.parent_val
                    ,dest.anlt_spec_name = src.name
                    ,dest.condition = src.condition
            WHERE (isEqual(dest.parent_val,src.parent_val) = 0 OR
                   isEqual(dest.anlt_spec_name,src.name) = 0 OR
                   isEqual(dest.condition,src.condition) = 0)
                   AND dbms_lob.substr(src.condition,1,30) != '1 = 0'
                   AND dest.block_import = 0;

      vMes := 'SUCCESSFULLY :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Аналитика "'||UPPER(idx.AnltCode)||'"  - '||SQL%ROWCOUNT||' rows merged into table "'||vOwner||'.tb_signs_anlt_spec"';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.AnltSpecImport',vMes);
      COMMIT;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      vMes := 'ERROR :: "'||UPPER(idx.AnltCode)||'"  - Аналитика не найдена в таблице "'||lower(vOwner)||'.tb_signs_anlt"';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.AnltSpecImport',vMes);
    END;
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.AnltSpecImport" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.AnltSpecImport',vMes);
EXCEPTION WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: "'||UPPER(inAnltCode)||'"  - '||SQLERRM;
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.AnltSpecImport',vMes);
    vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.AnltSpecImport" finished in '||get_ti_as_hms(vEndTime - vBegTime)||' with errors';
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.AnltSpecImport',vMes);
END AnltSpecImport;

/********************* ЗВЕЗДЫ И ВСЁ ЧТО С НИМИ СВЯЗАНО **********************************/
FUNCTION  GetAnltLineSQL(inSQL IN CLOB,inIDName IN VARCHAR2
  ,inPIDName IN VARCHAR2,inName IN VARCHAR2,inValue IN VARCHAR2) RETURN CLOB
  IS
    vMaxLev INTEGER;
    vBuff VARCHAR2(32700);
    vWith CLOB;
    vSQL CLOB;
    vSel VARCHAR2(32700);
    vSelNames VARCHAR2(32700);
    vSelIDs VARCHAR2(32700);
    vSelValues VARCHAR2(32700);
BEGIN
  vBuff :=
  'DECLARE'||CHR(10)||
  '  vMaxLev INTEGER;'||CHR(10)||
  'BEGIN'||CHR(10)||
  'SELECT MAX(LEVEL) INTO vMaxLev FROM ('||inSQL||') CONNECT BY PRIOR '||inIDName||' = '||inPIDName||CHR(10)||
  'START WITH '||inPIDName||' IS NULL;'||CHR(10)||
  ':1 := vMaxLev;'||CHR(10)||
  'END;';

  EXECUTE IMMEDIATE vBuff USING OUT vMaxLev;
  --dbms_output.put_line(vBuff);

  FOR idx IN 1..vMaxLev LOOP
    vBuff :=
    'DECLARE'||CHR(10)||
    '  vId VARCHAR2(32700);'||CHR(10)||
    '  vName VARCHAR2(32700);'||CHR(10)||
    '  vValue VARCHAR2(32700);'||CHR(10)||
    'BEGIN'||CHR(10)||
    '  SELECT id'||idx||',lev_name'||idx||',lev_value'||idx||CHR(10)||
    '    INTO vId,vName,vValue'||CHR(10)||
    '    FROM ('||CHR(10)||
    '      SELECT '||inIDName||' AS id,'||inPIDName||' AS parent_id,'||inName||' AS lev_name,'||inValue||' AS lev_value,LEVEL AS lev'||CHR(10)||
    '        ,SUBSTR(sys_connect_by_path(''lev''||to_char(abs(LEVEL - '||idx||') + 1)||''.id'','',''),2,LENGTH(sys_connect_by_path(''lev''||to_char(abs(LEVEL - '||idx||') + 1)||''.id'','','')) - 1) AS id'||idx||CHR(10)||
    '        ,SUBSTR(sys_connect_by_path(''lev''||to_char(abs(LEVEL - '||idx||') + 1)||''.lev_name'','',''),2,LENGTH(sys_connect_by_path(''lev''||to_char(abs(LEVEL - '||idx||') + 1)||''.lev_name'','','')) - 1) AS lev_name'||idx||CHR(10)||
    '        ,SUBSTR(sys_connect_by_path(''lev''||to_char(abs(LEVEL - '||idx||') + 1)||''.lev_value'','',''),2,LENGTH(sys_connect_by_path(''lev''||to_char(abs(LEVEL - '||idx||') + 1)||''.lev_value'','','')) - 1) AS lev_value'||idx||CHR(10)||
    '        FROM ('||inSQL||')'||CHR(10)||
    '      CONNECT BY PRIOR '||inIDName||' = '||inPIDName||CHR(10)||
    '      START WITH '||inPIDName||' IS NULL'||CHR(10)||
    '  ) WHERE lev = '||idx||'  GROUP BY id'||idx||',lev_name'||idx||',lev_value'||idx||';'||CHR(10)||
    '  :1 := vId;'||CHR(10)||
    '  :2 := vName;'||CHR(10)||
    '  :3 := vValue;'||CHR(10)||
    'END;'||CHR(10);

    EXECUTE IMMEDIATE vBuff USING OUT vSelIDs,OUT vSelNames,OUT vSelValues;
    --dbms_output.put_line(vBuff);

    IF idx = 1 THEN
      vSel := 'lev'||idx||'.id AS id'||idx||',lev'||idx||'.lev_name AS name'||idx||',lev'||idx||'.lev_value AS value'||idx||CHR(10);
    ELSE
      vSel := vSel||',COALESCE('||vSelIDs||') AS id'||idx||',COALESCE('||vSelNames||') AS name'||idx||',COALESCE('||vSelValues||') AS value'||idx||CHR(10);
    END IF;
  END LOOP;

  dbms_lob.createtemporary(vWith,FALSE);
  dbms_lob.createtemporary(vSQL,FALSE);

  vBuff := 'WITH'||CHR(10);
  dbms_lob.writeappend(vWith,LENGTH(vBuff),vBuff);

  FOR idx IN 1..vMaxLev LOOP
    vBuff :=
    '  '||CASE WHEN idx > 1 THEN ',' ELSE NULL END||'lev'||idx||' AS ('||CHR(10)||
    '  SELECT id,parent_id,lev_name,lev_value,lev'||CHR(10)||
    '    FROM ('||CHR(10)||
    '      SELECT '||inIDName||' AS id,'||inPIDName||' AS parent_id,'||inName||' AS lev_name,'||inValue||' AS lev_value, LEVEL AS lev'||CHR(10)||
    '        FROM ('||inSQL||')'||CHR(10)||
    '      CONNECT BY PRIOR '||inIDName||' = '||inPIDName||CHR(10)||
    '      START WITH '||inPIDName||' IS NULL'||CHR(10)||
    '  ) WHERE lev BETWEEN '||idx||' - 1 AND '||idx||CHR(10)||
    ')'||CHR(10);
    dbms_lob.writeappend(vWith,LENGTH(vBuff),vBuff);

    IF idx > 1 THEN
      vBuff := '       LEFT JOIN lev'||idx||' ON lev'||idx||'.lev = '||idx||' AND lev'||idx||'.parent_id = lev'||to_char(idx - 1)||'.id OR'||CHR(10)||
               '                                 lev'||idx||'.lev = '||idx||' - 1 AND lev'||idx||'.id = lev'||to_char(idx - 1)||'.id'||CHR(10);
    ELSE
      vBuff := CHR(10)||'  FROM lev1'||CHR(10);
    END IF;
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
  END LOOP;

  RETURN vWith||'SELECT '||vSel||vSQL;
END GetAnltLineSQL;


PROCEDURE StarPrepareDim(inDate IN DATE,inGroupID IN NUMBER,inEntityID IN NUMBER)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    -- список наименований полей через запятую (для использования при построении динамического SQL)
    vFieldsForCreate VARCHAR2(32700);
    --
    vDDL CLOB;

    vBuff VARCHAR2(32700);
    vStarDimTable VARCHAR2(256) := vOwner||'.dim_'||inGroupID||'#'||inEntityID; -- наименование таблицы фактов в звезде
    vGroupName VARCHAR2(4000);   -- наименование группы показателей
    vEntityName VARCHAR2(4000);  -- нименование сущности
    vTabCou INTEGER;

    vMes VARCHAR2(4000);
    vTIBegin DATE;
    vENdTime DATE;
BEGIN
  -- Получение наименования группы
  SELECT group_name INTO vGroupName FROM tb_signs_group WHERE group_id = inGroupID;
  -- Получение наименования сущности
  SELECT entity_name INTO vEntityName FROM tb_entity WHERE id = inEntityID;

  /*******************************************************************/
  vTIBegin := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - начало подготовки таблицы -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareDim',vMes);

  /*******************************************************************/

  -- Формирование строковых переменных со списком полей через запятую
  vFieldsForCreate := NULL;
  FOR idx IN (
    SELECT DISTINCT
           NVL(s2g.sgn_alias,p.sign_name) AS sign_name
          ,p.data_type
          ,LISTAGG(p.sign_descr,'; ') WITHIN GROUP (ORDER BY p.id) OVER (PARTITION BY NVL(s2g.sgn_alias,p.sign_name)) AS sign_descr
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
                AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                    START WITH id = inEntityID)
      WHERE s2g.group_id = inGroupID
  ) LOOP
        vFieldsForCreate := vFieldsForCreate||','||idx.sign_name||' '||
        CASE WHEN idx.data_type = 'Число' THEN 'NUMBER'
             WHEN idx.data_type = 'Дата' THEN 'DATE'
          ELSE 'VARCHAR2(4000)'
        END;
  END LOOP;

  dbms_lob.createtemporary(vDDL,FALSE);

  vBuff :=
  'DECLARE'||CHR(10)||
  '  vBuff VARCHAR2(32700);'||CHR(10)||
  'BEGIN'||CHR(10);
  dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);

  -- Проверка на существование таблицы измерения для звезды
  SELECT COUNT(1) INTO vTabCou FROM dba_all_tables
    WHERE owner = UPPER(vOwner) AND table_name = 'DIM_'||inGroupID||'#'||inEntityID;

  -- ЕСЛИ ТАБЛИЦА ОТСУТСТВУЕТ, ТО СОЗДАЕМ
  IF vTabCou = 0 THEN
    vBuff :=
    '  EXECUTE IMMEDIATE ''CREATE TABLE '||vStarDimTable||CHR(10)||
    '   (as_of_date DATE,obj_sid NUMBER'||vFieldsForCreate||')'||CHR(10)||
    '   PARTITION BY LIST (as_of_date) '||CHR(10)||
    '   (PARTITION P'||to_char(inDate,'RRRRMMDD')||' VALUES(to_date('''''||to_char(inDate,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')) STORAGE (INITIAL 64K NEXT 4M)) NOLOGGING'';'||CHR(10)||CHR(10);
    dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);

    -- Комментарии для колонок таблицы
    vBuff := '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||vStarDimTable||'.as_of_date IS ''''Отчетная дата'''' '';'||CHR(10);
    dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);
    vBuff := '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||vStarDimTable||'.obj_sid IS ''''Ид объекта (уникально в переделах одной даты). Используется для связки с фактами (по ключевым полям фактов).'''' '';'||CHR(10);
    dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);
    FOR idx IN (
      SELECT DISTINCT
             NVL(s2g.sgn_alias,p.sign_name) AS sign_name
            ,p.data_type
            ,LISTAGG(p.sign_descr,'; ') WITHIN GROUP (ORDER BY p.id) OVER (PARTITION BY NVL(s2g.sgn_alias,p.sign_name)) AS sign_descr
        FROM tb_signs_2_group s2g
             INNER JOIN tb_signs_pool p
               ON p.sign_name = s2g.sign_name
                  AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                      START WITH id = inEntityID)
        WHERE s2g.group_id = inGroupID
    ) LOOP
      vBuff := '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||vStarDimTable||'.'||LOWER(idx.sign_name)||' IS '''''||REPLACE(idx.sign_descr,'''','''''')||''''' '';'||CHR(10);
      dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);
    END LOOP;
    -- Вешаем комментарий на таблицу
    vBuff :=
    '  EXECUTE IMMEDIATE ''COMMENT ON TABLE '||vStarDimTable||' IS ''''Измерение: Группа - "'||vGroupName||'"; Сущность - "'||vEntityName||'"'''' '';'||CHR(10)||
    '  vBuff := ''SUCCESSFULLY :: Table "'||vStarDimTable||'" created''||CHR(10);'||CHR(10);
    dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);

 -- ЕСЛИ ТАБЛИЦА УЖЕ СУЩЕСТВУЕТ
  ELSE
    -- Если партиция отсутствует - добавляем
    vBuff :=
    '  BEGIN'||CHR(10)||
    '    EXECUTE IMMEDIATE ''ALTER TABLE '||vStarDimTable||' ADD PARTITION P'||to_char(inDate,'RRRRMMDD')||' VALUES (to_date('''''||to_char(inDate,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')) STORAGE (INITIAL 64K NEXT 4M) NOLOGGING'';'||CHR(10)||
    '    vBuff := ''SUCCESSFULLY :: Table "'||vStarDimTable||'" - Partition P'||to_char(inDate,'RRRRMMDD')||' added''||CHR(10);'||CHR(10)||
    '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
    '    NULL;'||CHR(10)||
    '  END;'||CHR(10);
    dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);

    -- Т.к., к моменту текущего разворачивания, ключевые колонки (как количество так и наименование), могут измениться
    -- то необходимо добавить недостающие (если таковые найдутся)
    -- !!!Пока что предполагается, что количество может только увеличиться!!!
    FOR idx IN (
      SELECT DISTINCT
             NVL(s2g.sgn_alias,p.sign_name) AS sign_name
            ,CASE WHEN p.data_type = 'Число' THEN 'NUMBER'
                  WHEN p.data_type = 'Дата' THEN 'DATE'
               ELSE 'VARCHAR2(4000)'
             END AS data_type
            ,LISTAGG(p.sign_descr,'; ') WITHIN GROUP (ORDER BY p.id) OVER (PARTITION BY NVL(s2g.sgn_alias,p.sign_name)) AS sign_descr
        FROM tb_signs_2_group s2g
             INNER JOIN tb_signs_pool p
               ON p.sign_name = s2g.sign_name
                  AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                      START WITH id = inEntityID)
        WHERE s2g.group_id = inGroupID
      MINUS
      SELECT c.column_name
            ,c.data_type
            ,cmnt.comments
        FROM all_tab_columns c
             INNER JOIN all_col_comments cmnt
               ON cmnt.owner = c.owner
                  AND cmnt.table_name = c.table_name
                  AND cmnt.column_name = c.column_name
        WHERE c.owner = UPPER(vOwner)
          AND c.table_name = UPPER(SUBSTR(vStarDimTable,INSTR(vStarDimTable,'.',1) + 1,LENGTH(vStarDimTable) - INSTR(vStarDimTable,'.',1)))
          AND NOT(c.column_name IN ('AS_OF_DATE'))
    ) LOOP
      vBuff :=
      '  BEGIN'||CHR(10)||
      -- Добавление колонки
      '    EXECUTE IMMEDIATE ''ALTER TABLE '||vStarDimTable||' ADD '||idx.sign_name||' '||idx.data_type||' '';'||CHR(10)||
      -- Добавление комментария
      '    EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||vStarDimTable||'.'||LOWER(idx.sign_name)||' IS '''''||REPLACE(idx.sign_descr,'''','''''')||''''' '';'||CHR(10)||
      '    vBuff := vBuff||''SUCCESSFULLY :: Column "'||vStarDimTable||'.'||lower(idx.sign_name)||'" added''||CHR(10);'||CHR(10)||
      '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
      '    NULL;'||CHR(10)||
      '  END;'||CHR(10);
      dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);
    END LOOP;
  END IF;

  -- Финальный END
  vBuff :=
  '  :1 := vBuff;'||CHR(10)||
  'END;'||CHR(10);
  dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);

  EXECUTE IMMEDIATE vDDL USING OUT vMes;
  --dbms_output.put_line(vDDL);
  IF vMes IS NULL THEN
    vMes := 'SUCCESSFULLY :: Table "'||vStarDimTable||'" - подготовка не требуется';
  END IF;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareDim',vMes);

  vEndTime := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - окончание подготовки таблицы. Время выполнения: '||get_ti_as_hms(vEndTime - vTIBegin)||' -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareDim',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarPrepareDim" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareDim',vMes);
END StarPrepareDim;

PROCEDURE StarPrepareFct(inDate IN DATE,inGroupID IN NUMBER)
  IS
    vResBuff VARCHAR2(500);
    --
    vBuff VARCHAR2(32700);
    vCreateDDL CLOB;
    vAddPartDDL CLOB;
    vAddSubPartDDL CLOB;
    vFields VARCHAR2(32700);
    vCreateFields VARCHAR2(32700);
    vAnltCodes VARCHAR2(32700);
    vPartCou INTEGER := 0;
    vGroupName VARCHAR2(4000);

    vMes VARCHAR2(4000);
    vTIBegin DATE;
    vENdTime DATE;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  -- Получение наименования группы
  SELECT group_name INTO vGroupName FROM tb_signs_group WHERE group_id = inGroupID;

  vTIBegin := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - начало подготовки таблицы -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareFct',vMes);

  -- Получение и сохранение в строки ключевых колонок
  SELECT LISTAGG(anlt_alias,',') WITHIN GROUP (ORDER BY anlt_alias) AS Fields
        ,LISTAGG(anlt_alias||CASE WHEN data_type = 'Число' THEN ' NUMBER'
                      WHEN data_type = 'Дата' THEN ' DATE'
                 ELSE ' VARCHAR2(4000)' END
                 ,',') WITHIN GROUP (ORDER BY anlt_alias) AS CreateFields
        ,LISTAGG(anlt_alias||CASE WHEN data_type = 'Число' THEN ' NUMBER'
                      WHEN data_type = 'Дата' THEN ' DATE'
                 ELSE ' VARCHAR2(4000)' END||';'||anlt_alias_descr
                 ,',') WITHIN GROUP (ORDER BY anlt_alias) AS anlt_alias_descr
    INTO vFields,vCreateFields,vAnltCodes
    FROM (
      SELECT a.anlt_alias
            ,a.data_type
            ,MAX(a.anlt_alias_descr) AS anlt_alias_descr
        FROM tb_signs_2_group s2g
             INNER JOIN tb_signs_group g
               ON g.parent_group_id = s2g.group_id
             INNER JOIN tb_sign_2_anlt s2a
               ON s2a.sign_name = s2g.sign_name
                  AND EXISTS (SELECT NULL FROM tb_anlt_2_group WHERE anlt_code = s2a.anlt_code AND group_id = g.group_id)
             INNER JOIN tb_signs_anlt a
               ON a.anlt_code = s2a.anlt_code
                  AND inDate BETWEEN a.effective_start AND a.effective_end
        WHERE s2g.group_id = inGroupID
      GROUP BY a.anlt_alias,a.data_type
    );

  /*********************** Формирование и выполнение CreateDDL *****************************/

  dbms_lob.createtemporary(vCreateDDL,FALSE);

  vBuff :=
  'BEGIN'||CHR(10);
  dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);

  -- Формирование добавления вновь появившихся ключевых колонок. Если ошибка, то таблица не существует.
  -- Оборачиваем блок добавления EXCEPTION'ом на такой случай
  FOR alt IN (
   SELECT '  BEGIN'||CHR(10)||
          '    EXECUTE IMMEDIATE ''ALTER TABLE '||LOWER(vOwner)||'.fct_'||inGroupID||' ADD '||SUBSTR(b.str,1,INSTR(b.str,';',1,1)-1)||''';'||CHR(10)||
          '    EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.'||LOWER(SUBSTR(b.str,1,INSTR(b.str,' ',1,1)-1))||' IS '''''||a.anlt_alias_descr||''''' '';'||CHR(10)||
          '  EXCEPTION WHEN OTHERS THEN'||CHR(10)||
          '    NULL;'||CHR(10)||
          '  END;'||CHR(10) AS alt_ddl
     FROM TABLE(parse_str(vAnltCodes,',')) b
          LEFT JOIN tb_signs_anlt a
            ON a.anlt_code = SUBSTR(b.str,INSTR(b.str,';',1,1) + 1,LENGTH(b.str))
               AND inDate BETWEEN a.effective_start AND a.effective_end
  ) LOOP
    vBuff := alt.alt_ddl;
    dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);
  END LOOP;

  -- Создание таблицы
  vBuff :=
  '  EXECUTE IMMEDIATE'||CHR(10)||
  '  ''CREATE TABLE '||LOWER(vOwner)||'.fct_'||inGroupID||CHR(10)||
  '    (as_of_date DATE'||CHR(10)||
  '    ,obj_gid NUMBER'||CHR(10)||
  '    ,source_system_id NUMBER'||CHR(10)||
  '    ,sign_name VARCHAR2(256)'||CHR(10)||
  '    ,sgn_alias VARCHAR2(256)'||CHR(10)||
  '    ,sign_val VARCHAR2(4000),'||CHR(10)||vCreateFields||')'||CHR(10)||
  '  PARTITION BY LIST (as_of_date)'||CHR(10)||
  '  SUBPARTITION BY LIST (sgn_alias) ('||CHR(10)||
  '  PARTITION P'||to_char(inDate,'RRRRMMDD')||' VALUES(to_date('''''||to_char(inDate,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')) STORAGE(INITIAL 64K NEXT 4M) NOLOGGING ('||CHR(10);
  dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);

  FOR idx IN (
    SELECT DISTINCT
           NVL(s2g.sgn_alias,s2g.sign_name) AS sign_name
          ,'SP'||ora_hash(NVL(s2g.sgn_alias,s2g.sign_name)) AS sp_code
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
      WHERE s2g.group_id = inGroupID
  ) LOOP
     vBuff :=
     '   '||CASE WHEN vPartCou > 0 THEN ',' END||'SUBPARTITION '||idx.sp_code||'_'||to_char(inDate,'RRRRMMDD')||' VALUES('''''||idx.sign_name||''''')'||CHR(10);
     dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);
     vPartCou := vPartCou + 1;
  END LOOP;

  vBuff := '  )) NOLOGGING''; '||CHR(10)||CHR(10);
  dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);

  -- Добавление комментариев на колонки
  vBuff :=
  '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.as_of_date IS ''''Отчетная дата'''' '';'||CHR(10)||
  '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.obj_gid IS ''''ИД объекта (зависит от сущности, например на договорах CONTRACT_GID и т.д.)'''' '';'||CHR(10)||
  '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.source_system_id IS ''''ИД системы - источника'''' '';'||CHR(10)||
  '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.sign_name IS ''''Наименование показателя'''' '';'||CHR(10)||
  '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.sgn_alias IS ''''Альяс показателя'''' '';'||CHR(10)||
  '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.sign_val IS ''''Значение показателя'''' '';'||CHR(10);
  dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);

  FOR idx IN (
    SELECT DISTINCT
           a.anlt_alias
          ,MAX(a.anlt_alias_descr) KEEP (dense_rank LAST ORDER BY a.effective_start) AS col_descr
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_group g
             ON g.parent_group_id = s2g.group_id
           INNER JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = s2g.sign_name
                AND EXISTS (SELECT NULL FROM tb_anlt_2_group WHERE anlt_code = s2a.anlt_code AND group_id = g.group_id)
           INNER JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inDate BETWEEN a.effective_start AND a.effective_end
      WHERE s2g.group_id = inGroupID
    GROUP BY a.anlt_alias
  ) LOOP
    vBuff := '  EXECUTE IMMEDIATE ''COMMENT ON COLUMN '||LOWER(vOwner)||'.fct_'||inGroupID||'.'||LOWER(idx.anlt_alias)||' IS '''''||idx.col_descr||''''' '';'||CHR(10);
    dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);
  END LOOP;

  -- Добавление комментария на таблицу
  vBuff := '  EXECUTE IMMEDIATE ''COMMENT ON TABLE '||LOWER(vOwner)||'.fct_'||inGroupID||' IS '''''||vGroupNAme||''''' '';'||CHR(10);
  dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);

  -- Логирование и обработка ошибок
  vBuff :=
  '  :1 := ''SUCCESSFULLY :: Table "'||LOWER(vOwner)||'.fct_'||inGroupID||'" created'';'||CHR(10)||
  'EXCEPTION WHEN OTHERS THEN'||CHR(10)||
  '  :1 := NULL;'||CHR(10)||
  'END;';
  dbms_lob.writeappend(vCreateDDL,LENGTH(vBuff),vBuff);

  EXECUTE IMMEDIATE vCreateDDL USING OUT vResBuff;
  --dbms_output.put_line(vCreateDDL);

  IF vResBuff IS NOT NULL THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareFct',vResBuff);
  END IF;

  /*********************** Формирование и выполнение AddPartDDL *****************************/
  dbms_lob.createtemporary(vAddPartDDL,FALSE);

  vBuff :=
  'BEGIN'||CHR(10)||
  '  EXECUTE IMMEDIATE ''ALTER TABLE '||LOWER(vOwner)||'.fct_'||inGroupID||' ADD PARTITION P'||to_char(inDate,'RRRRMMDD')||' VALUES(to_date('''''||to_char(inDate,'DD.MM.YYYY')||''''',''''DD.MM.YYYY'''')) STORAGE(INITIAL 64K NEXT 4M) NOLOGGING ('||CHR(10);
  dbms_lob.writeappend(vAddPartDDL,LENGTH(vBuff),vBuff);

  vPartCou := 0;
  FOR idx IN (
    SELECT DISTINCT
           NVL(s2g.sgn_alias,s2g.sign_name) AS sign_name
          ,'SP'||ora_hash(NVL(s2g.sgn_alias,s2g.sign_name)) AS sp_code
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
      WHERE s2g.group_id = inGroupID
  ) LOOP
     vBuff :=
     '   '||CASE WHEN vPartCou > 0 THEN ',' END||'SUBPARTITION '||idx.sp_code||'_'||to_char(inDate,'RRRRMMDD')||' VALUES('''''||idx.sign_name||''''')'||CHR(10);
     dbms_lob.writeappend(vAddPartDDL,LENGTH(vBuff),vBuff);
     vPartCou := vPartCou + 1;
  END LOOP;

  vBuff :=
  ')'';'||CHR(10)||
  '  :1 := ''SUCCESSFULLY :: Table "'||LOWER(vOwner)||'.fct_'||inGroupID||'" - Partition P'||to_char(inDate,'RRRRMMDD')||' added'';'||CHR(10)||
  'EXCEPTION WHEN OTHERS THEN'||CHR(10)||
  '  :1 := NULL;'||CHR(10)||
  'END;';
  dbms_lob.writeappend(vAddPartDDL,LENGTH(vBuff),vBuff);

  EXECUTE IMMEDIATE vAddPartDDL USING OUT vResBuff;
  --dbms_output.put_line(vAddPartDDL);

  IF vResBuff IS NOT NULL THEN
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareFct',vResBuff);
  END IF;

  /*********************** Формирование и выполнение AddSubPartDDL *****************************/

  dbms_lob.createtemporary(vAddSubPartDDL,FALSE);

  vBuff :=
  'DECLARE'||CHR(10)||
  '  vCou INTEGER := 0;'||CHR(10)||
  'BEGIN'||CHR(10);
  dbms_lob.writeappend(vAddSubPartDDL,LENGTH(vBuff),vBuff);

  FOR idx IN (
    SELECT DISTINCT
           NVL(s2g.sgn_alias,s2g.sign_name) AS sign_name
          ,'SP'||ora_hash(NVL(s2g.sgn_alias,s2g.sign_name)) AS sp_code
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
      WHERE s2g.group_id = inGroupID
  ) LOOP
     vBuff :=
     'BEGIN'||CHR(10)||
     '  EXECUTE IMMEDIATE ''ALTER TABLE '||LOWER(vOwner)||'.fct_'||inGroupID||' MODIFY PARTITION P'||to_char(inDate,'RRRRMMDD')||CHR(10)||
     '    ADD SUBPARTITION '||idx.sp_code||'_'||to_char(inDate,'RRRRMMDD')||' VALUES('''''||idx.sign_name||''''') '';'||CHR(10)||
     '  vCou := vCou + 1;'||CHR(10)||
     'EXCEPTION WHEN OTHERS THEN'||CHR(10)||
     '  NULL;'||CHR(10)||
     'END;'||CHR(10);
     dbms_lob.writeappend(vAddSubPartDDL,LENGTH(vBuff),vBuff);
  END LOOP;

  vBuff :=
  '  :1 := ''SUCCESSFULLY :: Table "'||LOWER(vOwner)||'.fct_'||inGroupID||'" - ''||vCou||'' SubPartitions added'';'||CHR(10)||
  'EXCEPTION WHEN OTHERS THEN'||CHR(10)||
  '  :1 := NULL;'||CHR(10)||
  'END;'||CHR(10);
  dbms_lob.writeappend(vAddSubPartDDL,LENGTH(vBuff),vBuff);

  EXECUTE IMMEDIATE vAddSubPartDDL USING OUT vResBuff;
  --dbms_output.put_line(vAddSubPartDDL);

  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareFct',vResBuff);

  vEndTime := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - окончание подготовки таблицы. Время выполнения: '||get_ti_as_hms(vEndTime - vTIBegin)||' -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareFct',vMes);
EXCEPTION WHEN OTHERS THEN
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepareFct','ERROR :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||' :: '||SQLERRM);
END StarPrepareFct;

PROCEDURE StarFctOnDate(inDate IN DATE,inGroupID IN NUMBER,inEntityID IN NUMBER)
  IS
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(4000);
    -- список наименований полей через запятую (для использования при построении динамического SQL)
    vOtherFields VARCHAR2(4000);
    vAnltFieldsPref VARCHAR2(4000);
    vAnltFields VARCHAR2(4000);
    vAnltJoins VARCHAR2(4000);
    --
    vDML CLOB;

    vBuff VARCHAR2(32700);
    vHistTable VARCHAR2(256);    -- наименование таблицы хранения периодами
    vFctTable VARCHAR2(256);     -- наименование таблицы хранения по датам
    vGroupName VARCHAR2(4000);   -- наименование группы показателей
    vEntityName VARCHAR2(4000);  -- нименование сущности
    vRowCou INTEGER := 0;
    vAnltCou INTEGER := 0;
    vAlsCou INTEGER := 0;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarFctOnDate" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);
  -- Сохранение наименований сущности и её таблиц хранения в переменные
  BEGIN
    SELECT vOwner||'.'||fct_table_name AS FctTable
          ,vOwner||'.'||hist_table_name AS HistTable
          ,entity_name
      INTO vFctTable,vHistTable/*,vFctView*/,vEntityName
      FROM tb_entity
      WHERE ID = inEntityID;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Описание сущности ID = '||inEntityID||' не найдено в таблице '||vOwner||'.tb_entity');
  END;

  -- Сохранение наименования группы в переменную
  BEGIN
    SELECT group_name
      INTO vGroupName
      FROM tb_signs_group
      WHERE group_id = inGroupID;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Описание группы ID = '||inGroupID||' не найдено в таблице '||vOwner||'.tb_signs_group');
  END;

  vTIBegin := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - вставка данных -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);

  -- Формирование строковых переменных со списком полей через запятую
  FOR idx IN (
    SELECT p.sign_name
          ,p.data_type
          ,p.sign_descr
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
                AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                    START WITH id = inEntityID)
      WHERE s2g.group_id = inGroupID
  ) LOOP
      vOtherFields := vOtherFields||CHR(10)||','''||idx.sign_name||'''';
  END LOOP;
  vOtherFields := SUBSTR(vOtherFields,3,LENGTH(vOtherFields) - 2);

  -- Формирование строк с полями и джойнов для аналитик
  SELECT LISTAGG(anlt_alias||'.'||'sign_val AS '||anlt_alias,',') WITHIN GROUP (ORDER BY anlt_alias) AS FieldsPref
        ,LISTAGG(anlt_alias,',') WITHIN GROUP (ORDER BY anlt_alias) AS Fields
        ,LISTAGG(' LEFT JOIN '||anlt_alias||CHR(10)||
                 '   ON '||anlt_alias||'.'||'sign_name = fct.sign_name'||CHR(10)||
                 '      AND '||anlt_alias||'.'||'obj_gid = fct.obj_gid'||CHR(10)||
                 '      AND '||anlt_alias||'.'||'source_system_id = fct.source_system_id',CHR(10)
                ) WITHIN GROUP (ORDER BY anlt_alias) AS joins
    INTO vAnltFieldsPref,vAnltFields,vAnltJoins
    FROM (
      SELECT a.anlt_alias
        FROM tb_signs_2_group s2g
             INNER JOIN tb_signs_pool p
               ON p.sign_name = s2g.sign_name
                  AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                      START WITH id = inEntityID)
             LEFT JOIN tb_sign_2_anlt s2a
               ON s2a.sign_name = s2g.sign_name
                  AND EXISTS (SELECT NULL
                                FROM tb_anlt_2_group
                                WHERE anlt_code = s2a.anlt_code
                                  AND group_id IN (SELECT group_id FROM tb_signs_group
                                                   CONNECT BY PRIOR group_id = parent_group_id
                                                   START WITH group_id = inGroupID)
                             )
             LEFT JOIN tb_signs_anlt a
               ON a.anlt_code = s2a.anlt_code
                  AND inDate BETWEEN a.effective_start AND a.effective_end
        WHERE s2g.group_id = inGroupID
      GROUP BY a.anlt_alias
  );

  dbms_lob.createtemporary(vDML,FALSE);
  vBuff :=
  'BEGIN'||CHR(10)||
  'EXECUTE IMMEDIATE ''ALTER SESSION SET nls_numeric_characters = '''', '''''';'||CHR(10)||
  'EXECUTE IMMEDIATE ''ALTER SESSION SET nls_date_format = ''''DD.MM.YYYY HH24:MI:SS'''''';'||CHR(10)||
  'INSERT INTO '||lower(vOwner)||'.fct_'||inGroupID||'(as_of_date,obj_gid,source_system_id,sign_name,sgn_alias,sign_val,'||vAnltFields||')'||CHR(10)||
  'WITH'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  -- Формирование подзапросов для аналитик
  FOR als IN (
    SELECT a.anlt_alias
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
                AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                    START WITH id = inEntityID)
           LEFT JOIN tb_sign_2_anlt s2a
             ON s2a.sign_name = s2g.sign_name
                AND EXISTS (SELECT NULL
                              FROM tb_anlt_2_group
                              WHERE anlt_code = s2a.anlt_code
                                AND group_id IN (SELECT group_id FROM tb_signs_group
                                                 CONNECT BY PRIOR group_id = parent_group_id
                                                 START WITH group_id = inGroupID)
                           )
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = s2a.anlt_code
                AND inDate BETWEEN a.effective_start AND a.effective_end
      WHERE s2g.group_id = inGroupID
    GROUP BY a.anlt_alias
  ) LOOP
    vBuff := CASE WHEN vAlsCou > 0 THEN ',' END||als.anlt_alias||' AS ('||CHR(10);
    dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
    vAnltCou := 0;
    FOR idx IN (
      SELECT LISTAGG(''''||p.sign_name||'''',',') WITHIN GROUP (ORDER BY s2g.sign_name) AS sign_name
            ,s2a.anlt_code
            ,lower(vOwner)||'.'||e.fct_table_name AS a_fct_table
            ,lower(vOwner)||'.'||e.hist_table_name AS a_hist_table
            ,a.anlt_alias
        FROM tb_signs_2_group s2g
             INNER JOIN tb_signs_pool p
               ON p.sign_name = s2g.sign_name
                  AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                      START WITH id = inEntityID)
             LEFT JOIN tb_sign_2_anlt s2a
               ON s2a.sign_name = s2g.sign_name
                  AND EXISTS (SELECT NULL
                                FROM tb_anlt_2_group
                                WHERE anlt_code = s2a.anlt_code
                                  AND group_id IN (SELECT group_id FROM tb_signs_group
                                                   CONNECT BY PRIOR group_id = parent_group_id
                                                   START WITH group_id = inGroupID)
                             )
             LEFT JOIN tb_signs_anlt a
               ON a.anlt_code = s2a.anlt_code
                  AND inDate BETWEEN a.effective_start AND a.effective_end
             LEFT JOIN tb_entity e
               ON e.id = a.entity_id
        WHERE s2g.group_id = inGroupID
          AND a.anlt_alias = als.anlt_alias
      GROUP BY a.anlt_alias,s2a.anlt_code,e.fct_table_name,e.hist_table_name
      HAVING s2a.anlt_code IS NOT NULL
    ) LOOP
      vBuff :=
      CASE WHEN vAnltCou > 0 THEN '  UNION ALL'||CHR(10) END||
      '  SELECT sign_name,obj_gid,source_system_id,sign_val'||CHR(10)||
      '    FROM '||idx.a_fct_table||CHR(10)||
      '    WHERE sign_name IN ('||idx.sign_name||')'||CHR(10)||
      '      AND as_of_date = to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'')'||CHR(10)||
      '  UNION ALL'||CHR(10)||
      '  SELECT /*+ no_index(v) */ v.sign_name,v.obj_gid,v.source_system_id,v.sign_val'||CHR(10)||
      '    FROM '||idx.a_hist_table||' v'||CHR(10)||
      '    WHERE v.sign_name IN ('||idx.sign_name||')'||CHR(10)||
      '      AND to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') BETWEEN v.effective_start AND v.effective_end'||CHR(10);
      dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
      vAnltCou := vAnltCou + 1;
    END LOOP;

    vBuff := ')'||CHR(10);
    dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
    vAlsCou := vAlsCou + 1;
  END LOOP;
  -- Окончание формирования подзапросов для аналитик

  vBuff :=
  ',fct AS ('||CHR(10)||
  'SELECT to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') AS as_of_date,fct.obj_gid,fct.source_system_id,fct.sign_name,CASE WHEN fct.sign_val = ''0,'' THEN null ELSE fct.sign_val END AS sign_val'||CHR(10)||
  '  FROM '||vHistTable||' fct'||CHR(10)||
  '  WHERE fct.sign_name IN ('||vOtherFields||')'||CHR(10)||
  '    AND to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') BETWEEN fct.effective_start AND fct.effective_end'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  vBuff :=
  'UNION ALL'||CHR(10)||
  'SELECT to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') AS as_of_date,fct.obj_gid,fct.source_system_id,fct.sign_name,CASE WHEN fct.sign_val = ''0,'' THEN null ELSE fct.sign_val END AS sign_val'||CHR(10)||
  '  FROM '||vFctTable||' fct'||CHR(10)||
  '  WHERE fct.sign_name IN ('||vOtherFields||')'||CHR(10)||
  '    AND fct.as_of_date = to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY''))'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  -- Подзапрос альясов не ключевых показателей
  vBuff :=
  ',als AS ('||CHR(10)||
  '   SELECT /*+ no_index(s2g) */ s2g.sign_name,NVL(s2g.sgn_alias,s2g.sign_name) AS sgn_alias FROM tb_signs_2_group s2g WHERE s2g.group_id = '||inGroupID||' AND s2g.sign_name IN ('||vOtherFields||')'||CHR(10)||
  ')'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);
  -- Окончание подзапроса альясов не ключевых показателей

  vBuff :=
  'SELECT fct.as_of_date,fct.obj_gid,fct.source_system_id,fct.sign_name,als.sgn_alias AS sign_name,fct.sign_val,'||vAnltFieldsPref||CHR(10)||
  '  FROM fct '||CHR(10)||vAnltJoins||CHR(10)||' LEFT JOIN als ON als.sign_name = fct.sign_name'||CHR(10)||
  '  WHERE fct.sign_val IS NOT NULL;'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  vBuff :=
  ':1 := SQL%ROWCOUNT;'||CHR(10)||
  'COMMIT;'||CHR(10)||
  'END;'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  EXECUTE IMMEDIATE vDML USING OUT vRowCou;
  --dbms_output.put_line(vDML);

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - '||vRowCou||' rows inserted into table '||lower(vOwner)||'.fct_'||inGroupID||' in '||get_ti_as_hms(vEndTime - vTIBegin);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);

  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - окончание вставки данных. Время выполнения: '||get_ti_as_hms(vEndTime - vTIBegin)||' -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarFctOnDate" finished successfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarFctOnDate" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarFctOnDate" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarFctOnDate',vMes);
END StarFctOnDate;

PROCEDURE StarDimOnDate(inDate IN DATE,inGroupID IN NUMBER,inEntityID IN NUMBER)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(4000);
    -- список наименований полей через запятую (для использования при построении динамического SQL)
    vKeyFieldsForIns VARCHAR2(32700);
    vKeyFieldsForSel VARCHAR2(32700);
    vKeyFields VARCHAR2(32700);
    vKeyFieldsWithAlias VARCHAR2(32700);

    vDML CLOB;
    vRestrictSQL CLOB;

    vBuff VARCHAR2(32700);
    vHistTable VARCHAR2(256);    -- наименование таблицы хранения периодами
    vFctTable VARCHAR2(256);     -- наименование таблицы хранения по датам
    vFctView VARCHAR2(256);
    vStarDimTable VARCHAR2(256) := vOwner||'.dim_'||inGroupID||'#'||inEntityID; -- наименование таблицы фактов в звезде
    vGroupName VARCHAR2(4000);   -- наименование группы показателей
    vEntityName VARCHAR2(4000);  -- нименование сущности
    vTabCou INTEGER := 0;
    vRowCou INTEGER := 0;
BEGIN
  vMes := 'START :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDimOnDate" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);
  -- Сохранение наименований сущности и её таблиц хранения в переменные
  BEGIN
    SELECT vOwner||'.'||fct_table_name AS FctTable
          ,vOwner||'.'||hist_table_name AS HistTable
          ,vOwner||'.v_'||hist_table_name AS FctView
          ,entity_name
      INTO vFctTable,vHistTable,vFctView,vEntityName
      FROM tb_entity
      WHERE ID = inEntityID;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Описание сущности ID = '||inEntityID||' не найдено в таблице '||vOwner||'.tb_entity');
  END;

  -- Сохранение наименования группы в переменную
  BEGIN
    SELECT group_name
      INTO vGroupName
      FROM tb_signs_group
      WHERE group_id = inGroupID;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Описание группы ID = '||inGroupID||' не найдено в таблице '||vOwner||'.tb_signs_group');
  END;

  vTIBegin := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - вставка данных -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);

  vKeyFieldsForIns := NULL;
  vKeyFieldsForSel := NULL;
  vKeyFields := NULL;
  vKeyFieldsWithAlias := NULL;

  -- Формирование строковых переменных со списком полей через запятую
  FOR idx IN (
    SELECT p.sign_name
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
                AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                    START WITH id = inEntityID)
      WHERE s2g.group_id = inGroupID
  ) LOOP
      vKeyFields := vKeyFields||CHR(10)||','''||idx.sign_name||'''';
      vKeyFieldsWithAlias := vKeyFieldsWithAlias||CHR(10)||','''||idx.sign_name||''' AS '||idx.sign_name;
  END LOOP;

  FOR idx IN (
    SELECT DISTINCT
           NVL(s2g.sgn_alias,p.sign_name) AS sign_name
          ,NVL2(s2g.sgn_alias,'COALESCE('||LISTAGG(p.sign_name,',') WITHIN GROUP (ORDER BY p.id) OVER (PARTITION BY NVL(s2g.sgn_alias,p.sign_name))||',NULL) AS '||s2g.sgn_alias,p.sign_name) AS coal_sign_name
      FROM tb_signs_2_group s2g
           INNER JOIN tb_signs_pool p
             ON p.sign_name = s2g.sign_name
                AND p.entity_id IN (SELECT id FROM tb_entity CONNECT BY PRIOR id = parent_id
                                    START WITH id = inEntityID)
      WHERE s2g.group_id = inGroupID
  ) LOOP
      vKeyFieldsForIns := vKeyFieldsForIns||CHR(10)||','||lower(idx.sign_name);
      vKeyFieldsForSel := vKeyFieldsForSel||CHR(10)||','||lower(idx.coal_sign_name);
  END LOOP;

  vKeyFieldsForIns := SUBSTR(vKeyFieldsForIns,3,LENGTH(vKeyFieldsForIns) - 2);
  vKeyFieldsForSel := SUBSTR(vKeyFieldsForSel,3,LENGTH(vKeyFieldsForSel) - 2);
  vKeyFields := SUBSTR(vKeyFields,3,LENGTH(vKeyFields) - 2);
  vKeyFieldsWithAlias := SUBSTR(vKeyFieldsWithAlias,3,LENGTH(vKeyFieldsWithAlias) - 2);

  dbms_lob.createtemporary(vDML,FALSE);
  vBuff :=
  'BEGIN'||CHR(10)||
  'EXECUTE IMMEDIATE ''ALTER SESSION SET nls_numeric_characters = '''', '''''';'||CHR(10)||
  'EXECUTE IMMEDIATE ''ALTER SESSION SET nls_date_format = ''''DD.MM.YYYY HH24:MI:SS'''''';'||CHR(10)||
  'INSERT INTO '||vStarDimTable||'(as_of_date,obj_sid'||CHR(10)||','||vKeyFieldsForIns||')'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  -- Формирование блока ограничения (WITH...) для запроса вставки данных
  vBuff :=
  'WITH '||CHR(10)||'  fct_keys AS ('||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  dbms_lob.createtemporary(vRestrictSQL,FALSE);
  vBuff := 'SELECT sign_val AS obj_sid FROM ('||CHR(10);
  dbms_lob.writeappend(vRestrictSQL,LENGTH(vBuff),vBuff);

  FOR idx IN (
    SELECT LISTAGG(''''||g1.sign_name||'''',',') WITHIN GROUP (ORDER BY g1.sign_name) AS parts
          ,gr.anlt_alias
          ,CASE WHEN p.hist_flg = 0 THEN gr.fct_table_name ELSE gr.hist_table_name END AS table_name
          ,p.hist_flg
      FROM (
    SELECT g.group_id,g.parent_group_id,a2g.anlt_code,a.anlt_alias,e.entity_name
          ,e.fct_table_name
          ,e.hist_table_name
          ,(SELECT ID FROM tb_entity WHERE parent_id IS NULL CONNECT BY PRIOR parent_id = ID START WITH ID = a.entity_id) AS e_id
      FROM tb_signs_group g
           LEFT JOIN tb_anlt_2_group a2g
             ON a2g.group_id = g.group_id
           LEFT JOIN tb_signs_anlt a
             ON a.anlt_code = a2g.anlt_code
                AND inDate BETWEEN a.effective_start AND a.effective_end
           LEFT JOIN tb_entity e
             ON e.id = a.entity_id
    CONNECT BY PRIOR g.group_id = g.parent_group_id
    START WITH g.group_id = inGroupID
    ) gr LEFT JOIN tb_signs_2_group g1
           ON g1.group_id = gr.parent_group_id
              AND EXISTS (SELECT NULL FROM tb_sign_2_anlt WHERE sign_name = g1.sign_name AND anlt_code = gr.anlt_code)
         LEFT JOIN tb_signs_pool p
           ON p.sign_name = g1.sign_name
    WHERE gr.e_id = inEntityID
    GROUP BY gr.anlt_alias,p.hist_flg,CASE WHEN p.hist_flg = 0 THEN gr.fct_table_name ELSE gr.hist_table_name END
  ) LOOP
    vBuff :=
    CASE WHEN vTabCou > 0 THEN 'UNION ALL'||CHR(10) END||
    'SELECT /*+ no_index(v) */ v.sign_val FROM '||LOWER(vOwner)||'.'||idx.table_name||' v'||CHR(10)||
    '  WHERE v.sign_name IN ('||idx.parts||') AND '||
    CASE WHEN idx.hist_flg = 0 THEN 'v.as_of_date = to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'')'
    ELSE 'to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') BETWEEN v.effective_start and v.effective_end' END||CHR(10);
    dbms_lob.writeappend(vRestrictSQL,LENGTH(vBuff),vBuff);
    vTabCou := vTabCou + 1;
  END LOOP;

  vBuff := ') GROUP BY sign_val)'||CHR(10);
  dbms_lob.writeappend(vRestrictSQL,LENGTH(vBuff),vBuff);

  vBuff :=
  'SELECT /*+ parallel(2)*/ to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') AS as_of_date,obj_gid*10+source_system_id as obj_sid'||CHR(10)||','||vKeyFieldsForSel||' FROM ('||CHR(10)||
  '      SELECT /*+ no_index(s) */ s.obj_gid,s.source_system_id,s.sign_name,s.sign_val'||CHR(10)||
  '        FROM '||vHistTable||' s'||CHR(10)||
  '             INNER JOIN fct_keys ON fct_keys.obj_sid = s.obj_gid*10+s.source_system_id'||CHR(10)||
  '        WHERE s.sign_name IN ('||vKeyFields||')'||CHR(10)||
  '          AND to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') BETWEEN s.effective_start AND s.effective_end'||CHR(10)||
  '      UNION ALL'||CHR(10)||
  '      SELECT s.obj_gid,s.source_system_id,s.sign_name,s.sign_val'||CHR(10)||
  '        FROM '||vFctTable||' s'||CHR(10)||
  '             INNER JOIN fct_keys ON fct_keys.obj_sid = s.obj_gid*10+s.source_system_id'||CHR(10)||
  '        WHERE sign_name IN ('||vKeyFields||')'||CHR(10)||
  '          AND s.as_of_date = to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'')'||CHR(10)||
  '    ) PIVOT (MAX(sign_val) FOR sign_name IN ('||vKeyFieldsWithAlias||'));'||CHR(10);

  dbms_lob.writeappend(vDML,dbms_lob.getlength(vRestrictSQL),vRestrictSQL);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  vBuff :=
  ':1 := SQL%ROWCOUNT;'||CHR(10)||
  'COMMIT;'||CHR(10)||
  'END;'||CHR(10);
  dbms_lob.writeappend(vDML,LENGTH(vBuff),vBuff);

  EXECUTE IMMEDIATE vDML USING OUT vRowCou;
  --dbms_output.put_line(vDML);

  vEndTime := SYSDATE;
  vMes := 'SUCESSFULLY :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - '||vRowCou||' rows inserted into table '||vStarDimTable||' in '||get_ti_as_hms(vEndTime - vTIBegin);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);

  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Сущность: "'||vEntityName||'" - окончание вставки данных. Время выполнения: '||get_ti_as_hms(vEndTime - vTIBegin)||' -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDimOnDate" finished successfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDimOnDate" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDimOnDate" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDimOnDate',vMes);
END StarDimOnDate;

PROCEDURE StarAnltOnDate(inDate IN DATE,inGroupID IN NUMBER,inAnltAlias IN VARCHAR2)
  IS
    vSQL CLOB;
    vGroupName VARCHAR2(4000);
    vAnltName VARCHAR2(4000);
    vAnltSpecID VARCHAR2(4000);
    --
    vMes VARCHAR2(32700);
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vCou1 INTEGER;
    vCou2 INTEGER;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);
  -- Сохранение наименования группы в переменную
  BEGIN
    SELECT group_name
      INTO vGroupName
      FROM tb_signs_group
      WHERE group_id = inGroupID;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Описание группы ID = '||inGroupID||' не найдено в таблице '||vOwner||'.tb_signs_group');
  END;

  -- Сохранение наименования аналитики в переменную
  BEGIN
SELECT LISTAGG(a.anlt_code,',') WITHIN GROUP (ORDER BY a.id) AS AnltCode
          ,LISTAGG(a.id,',') WITHIN GROUP (ORDER BY a.id) AS AnltSpecID
      INTO vAnltName,vAnltSpecID
      FROM tb_signs_anlt a
      WHERE a.anlt_alias = inAnltAlias
        AND inDate BETWEEN a.effective_start AND a.effective_end -- 28,46
        AND a.anlt_code IN (SELECT a2g.anlt_code
                              FROM tb_signs_group g
                                   LEFT JOIN tb_anlt_2_group a2g ON a2g.group_id = g.group_id
                              WHERE LEVEL = 3
                            CONNECT BY PRIOR g.group_id = g.parent_group_id
                            START WITH g.group_id = inGroupID);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20000,'Описание аналитиики ANLT_ALIAS = '||inAnltAlias||' за дату "'||to_char(inDate,'DD.MM.YYYY')||'" не найдено в таблице '||vOwner||'.tb_signs_anlt');
  END;

  vTIBegin := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Аналитика: "'||vAnltName||'" - начало подготовки таблицы -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);

  vSQL := 'SELECT anlt_spec_val AS id,parent_val AS parent_id,anlt_spec_name AS name,anlt_spec_val AS val
       FROM '||lower(vOwner)||'.tb_signs_anlt_spec
     WHERE anlt_id IN ('||vAnltSpecID||')';

  vSQL := GetAnltLineSQL(vSQL,'id','parent_id','name','val');
  BEGIN
      EXECUTE IMMEDIATE
      'BEGIN'||CHR(10)||
      'DELETE FROM '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||' WHERE as_of_date = to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'');'||CHR(10)||
      '  :1 := SQL%ROWCOUNT;'||CHR(10)||
      'INSERT INTO '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||CHR(10)||
      'WITH'||CHR(10)||
      '  dt AS ('||CHR(10)||
      '    SELECT to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') AS as_of_date FROM dual'||CHR(10)||
      '  )'||CHR(10)||
      '  SELECT * FROM dt CROSS JOIN ('||vSQL||');'||CHR(10)||
      '  :2 := SQL%ROWCOUNT;'||CHR(10)||
      '  COMMIT;'||CHR(10)||
      'END;'
      USING OUT vCou1,OUT vCou2;

      vMes := 'SUCCESSFULLY :: '||vCou1||' rows deleted from table '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);

      vMes := 'SUCCESSFULLY :: '||vCou2||' rows inserted into table '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);
  EXCEPTION WHEN OTHERS THEN
    BEGIN
      vSQL := 'SELECT anlt_spec_val AS id,parent_val AS parent_id,anlt_spec_name AS name,anlt_spec_val AS val
           FROM '||lower(vOwner)||'.tb_signs_anlt_spec
         WHERE anlt_id IN ('||vAnltSpecID||')';

      vSQL := GetAnltLineSQL(vSQL,'id','parent_id','name','val');
      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'CREATE TABLE '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||' AS '||CHR(10)||
      'WITH'||CHR(10)||
      '  dt AS ('||CHR(10)||
      '    SELECT to_date('''||to_char(inDate,'DD.MM.YYYY')||''',''DD.MM.YYYY'') AS as_of_date FROM dual'||CHR(10)||
      '  )'||CHR(10)||
      '  SELECT * FROM dt CROSS JOIN ('||vSQL||')'
      --)
      ;

      vMes := 'SUCCESSFULLY :: Table '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||' created';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);

      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'ALTER TABLE '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||' NOLOGGING'
      --)
      ;
      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'ALTER TABLE '||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||' COMPRESS'
      --)
      ;
      EXECUTE IMMEDIATE
      --dbms_output.put_line(
      'CREATE BITMAP INDEX '||LOWER(vOwner)||'.bidx_anltline_'||inGroupID||'#'||inAnltAlias||' ON'||CHR(10)||
        LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||' (as_of_date) NOLOGGING'
      --)
      ;

      vMes := 'SUCCESSFULLY :: Index '||LOWER(vOwner)||'.idx_anltline_'||inGroupID||'#'||inAnltAlias||' created';
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);

    EXCEPTION WHEN OTHERS THEN
      vMes := 'ERROR :: Не удалось создать таблицу "'||LOWER(vOwner)||'.anltline_'||inGroupID||'#'||inAnltAlias||'"'||CHR(10)||
              '--------------------------------------'||CHR(10)||SQLERRM;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);
    END;
  END;
  dbms_lob.freetemporary(vSQL);

  vEndTime := SYSDATE;
  vMes := 'CONTINUE :: ------------ "'||to_char(inDate,'DD.MM.YYYY')||'" - Группа: "'||vGroupName||'" - Аналитика: "'||vAnltName||'" - окончание подготовки таблицы. Время выполнения: '||get_ti_as_hms(vEndTime - vTIBegin)||' -----------';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate" finished successfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.YYYY')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarAnltOnDate',vMes);
END StarAnltOnDate;

PROCEDURE StarPrepare(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'PREPAREJOB_'||tb_signs_job_id_seq.nextval;
    vBuff VARCHAR2(32700);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(4000);
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarPrepare" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepare',vMes);

  vBuff :=
  q'[WITH
      dt AS (
        SELECT to_date(']'||vEndDate||q'[','DD.MM.YYYY') - LEVEL + 1 AS as_of_date
          FROM dual CONNECT BY LEVEL <= to_date(']'||vEndDate||q'[','DD.MM.YYYY') - to_date(']'||vBegDate||q'[','DD.MM.YYYY') + 1
        ORDER BY 1)
     ,a AS (
        SELECT group_id||'|'||head_entity_id AS ID
              ,group_id
              ,head_entity_id
          FROM (
            SELECT DISTINCT
                   g.group_id
                  ,CASE WHEN LEVEL = 1 THEN
                           (SELECT ID FROM tb_entity WHERE parent_id IS NULL
                            CONNECT BY ID = PRIOR parent_id START WITH ID = p.entity_id)
                         ELSE NULL END AS head_entity_id
              FROM tb_signs_group g
                   LEFT JOIN tb_signs_2_group s2g
                     ON s2g.group_id = g.group_id
                   LEFT JOIN tb_signs_pool p
                     ON p.sign_name = s2g.sign_name
                    WHERE s2g.sign_name IS NOT NULL AND LEVEL <= 2
            CONNECT BY PRIOR g.group_id = g.parent_group_id
            START WITH g.group_id = ]'||inGroupID||q'[))
      SELECT DISTINCT
             a.id||'|'||to_char(dt.as_of_date,'RRRRMMDD') AS ID
            ,NULL AS parent_id
            ,CASE WHEN a.head_entity_id IS NOT NULL THEN ']'||LOWER(vOwner)||q'[.pkg_etl_signs.StarPrepareDim' ELSE ']'||LOWER(vOwner)||q'[.pkg_etl_signs.StarPrepareFct' END AS unit
            ,to_char(dt.as_of_date,'DD.MM.YYYY')||'#!#'||a.group_id||CASE WHEN a.head_entity_id IS NOT NULL THEN '#!#'||a.head_entity_id END as params
            ,0 AS skip
        FROM dt CROSS JOIN a]';
  load_new(vBuff,vJobName);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarPrepare" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepare',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarPrepare" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepare',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarPrepare" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarPrepare',vMes);
END StarPrepare;

PROCEDURE StarClear(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'CLEARJOB_'||tb_signs_job_id_seq.nextval;
    vBuff VARCHAR2(32700);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(4000);
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarClear" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarClear',vMes);

  EXECUTE IMMEDIATE 'alter session set "_FIX_CONTROL" = "11814428:0"';

  vBuff :=
    q'[WITH
      dt AS (
        SELECT to_date(']'||vEndDate||q'[','DD.MM.YYYY') - LEVEL + 1 AS as_of_date
          FROM dual CONNECT BY LEVEL <= to_date(']'||vEndDate||q'[','DD.MM.YYYY') - to_date(']'||vBegDate||q'[','DD.MM.YYYY') + 1
        ORDER BY 1)
     ,a AS (
        SELECT DISTINCT
               to_char(g.group_id) AS ID
              ,NULL AS parent_id
              ,CASE WHEN LEVEL = 1 THEN
                 (SELECT ID FROM tb_entity WHERE parent_id IS NULL
                  CONNECT BY ID = PRIOR parent_id START WITH ID = p.entity_id)
               ELSE NULL END AS head_entity_id
              ,']'||LOWER(vOwner)||q'[.pkg_etl_signs.MyExecute' AS unit
              ,CASE WHEN LEVEL = 1 THEN 'dim' ELSE 'fct' END AS StarPart
          FROM tb_signs_group g
               LEFT JOIN tb_signs_2_group s2g
                 ON s2g.group_id = g.group_id
               LEFT JOIN tb_signs_pool p
                 ON p.sign_name = s2g.sign_name
          WHERE s2g.sign_name IS NOT NULL AND LEVEL <= 2
        CONNECT BY PRIOR g.group_id = g.parent_group_id
        START WITH g.group_id = ]'||inGroupID||q'[)
      SELECT a.id||'_'||a.head_entity_id||'_P'||to_char(dt.as_of_date,'RRRRMMDD') AS ID
            ,NULL AS parent_id
            ,a.unit
            ,'ALTER TABLE ]'||LOWER(vOwner)||q'[.'||CASE WHEN a.head_entity_id IS NULL THEN 'fct_' ELSE 'dim_' END||a.id||CASE WHEN a.head_entity_id IS NULL THEN NULL ELSE '#'||a.head_entity_id END||CHR(10)||
            '   TRUNCATE PARTITION P'||to_char(dt.as_of_date,'RRRRMMDD') AS params
            ,0 AS skip
        FROM dt CROSS JOIN a
        WHERE EXISTS (SELECT NULL FROM all_tables WHERE owner = ']'||UPPER(vOwner)||q'[' AND table_name = UPPER(a.StarPart||'_'||a.id||CASE WHEN a.StarPart = 'fct' THEN NULL ELSE '#'||a.head_entity_id END))]';

  load_new(vBuff,vJobName);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarClear" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarClear',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarClear" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarClear',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarClear" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarClear',vMes);
END StarClear;

PROCEDURE StarExpand(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER,inMask VARCHAR2 DEFAULT '00',inCalcPoolId NUMBER DEFAULT NULL)
  /************************************
   Описание маски (0 - не выполнять, 1 - выполнять):
   1-й символ - предварительный пересчет всех показателей по кубу
   2-й символ - предварительный пересчет всех аналитик по кубу
  ************************************/
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'EXPANDJOB_'||tb_signs_job_id_seq.nextval;
    vBuff VARCHAR2(32700);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(400);
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
    --
    vDoSign BOOLEAN := SUBSTR(inMask,1,1) = '1';
    vDoAnlt BOOLEAN := SUBSTR(inMask,2,1) = '1';
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarExpand" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarExpand',vMes);

  -- Если требуется предварительный пересчет показателей
  IF vDoSign THEN CalcSignsByStar(inBegDate,inEndDate,inGroupID,REPLACE(vJobName,'EXPANDJOB','SIGNSBYSTARJOB')); END IF;

  -- Если требуется предварительный пересчет аналитик
  IF vDoAnlt THEN CalcAnltByStar(inBegDate,inEndDate,inGroupID,REPLACE(vJobName,'EXPANDJOB','ANLTBYSTARJOB')); END IF;

  -- Подготовка
  StarPrepare(inBegDate,inEndDate,inGroupID);

  -- Очистка
  StarClear(inBegDate,inEndDate,inGroupID);

  -- Загрузка
  vBuff :=
    q'[WITH
      dt AS (
        SELECT to_date(']'||vEndDate||q'[','DD.MM.YYYY') - LEVEL + 1 AS as_of_date
          FROM dual CONNECT BY LEVEL <= to_date(']'||vEndDate||q'[','DD.MM.YYYY') - to_date(']'||vBegDate||q'[','DD.MM.YYYY') + 1
        ORDER BY 1)
     ,a AS (
        SELECT DISTINCT
               to_char(g.group_id) AS ID
              ,NULL AS parent_id
              ,(SELECT ID FROM tb_entity WHERE parent_id IS NULL
                CONNECT BY ID = PRIOR parent_id START WITH ID = p.entity_id) AS head_entity_id
              ,CASE WHEN LEVEL = 1 THEN ']'||LOWER(vOwner)||q'[.pkg_etl_signs.StarDimOnDate' ELSE ']'||LOWER(vOwner)||q'[.pkg_etl_signs.StarFctOnDate' END AS unit
              ,CASE WHEN LEVEL = 1 THEN 'dim' ELSE 'fct' END AS StarPart
          FROM tb_signs_group g
               LEFT JOIN tb_signs_2_group s2g
                 ON s2g.group_id = g.group_id
               LEFT JOIN tb_signs_pool p
                 ON p.sign_name = s2g.sign_name
          WHERE s2g.sign_name IS NOT NULL AND LEVEL <= 2
        CONNECT BY PRIOR g.group_id = g.parent_group_id
        START WITH g.group_id = ]'||inGroupID||q'[)
     ,b AS (
        SELECT DISTINCT
               dt.as_of_date
              ,a.anlt_alias
          FROM tb_signs_group g CROSS JOIN dt
               LEFT JOIN tb_anlt_2_group a2g
                 ON a2g.group_id = g.group_id
               LEFT JOIN tb_signs_anlt a
                 ON a.anlt_code = a2g.anlt_code
                    AND dt.as_of_date BETWEEN a.effective_start AND a.effective_end
          WHERE LEVEL = 3 AND EXISTS (SELECT NULL FROM tb_signs_anlt_spec WHERE anlt_id = a.id)
        CONNECT BY PRIOR g.group_id = g.parent_group_id
        START WITH g.group_id = ]'||inGroupID||q'[)
      -- Факты и ПИДАРЫ (ПИДАР - Простое Измерение Для Агрегирования Результатов)
      SELECT DISTINCT
             to_char(dt.as_of_date,'DD.MM.YYYY')||']'||LOWER(vOwner)||q'[.'||a.StarPart||'_'||a.id||'#'||a.head_entity_id AS ID
            ,NULL AS parent_id
            ,a.unit
            ,to_char(dt.as_of_date,'DD.MM.YYYY')||'#!#'||a.id||'#!#'||a.head_entity_id AS params
            ,0 AS skip
        FROM dt CROSS JOIN a
      -- СУКИ (СУКА - Сквозная Унифицированная Комплексная Аналитика)
      UNION ALL
      SELECT DISTINCT
             to_char(b.as_of_date,'DD.MM.YYYY')||']'||LOWER(vOwner)||q'[.anltline_]'||inGroupID||q'[#'||b.anlt_alias AS ID
            ,NULL AS parent_id
            ,']'||LOWER(vOwner)||q'[.pkg_etl_signs.StarAnltOnDate'
            ,to_char(b.as_of_date,'DD.MM.YYYY')||'#!#]'||inGroupID||q'[#!#'||b.anlt_alias AS params
            ,0 AS skip
        FROM b]';

  load_new(vBuff,vJobName,inCalcPoolId);

  -- Сжатие
  StarCompress(inBegDate,inEndDate,inGroupID);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarExpand" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarExpand',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarExpand" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarExpand',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarExpand" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarExpand',vMes);
END StarExpand;

PROCEDURE StarCompress(inBegDate IN DATE,inEndDate IN DATE,inGroupID IN NUMBER)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'COMPRESSJOB_'||tb_signs_job_id_seq.nextval;
    vBuff VARCHAR2(32700);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(4000);
    vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
    vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
BEGIN
  vMes := 'START :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarCompress" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarCompress',vMes);

  vBuff :=
    q'[WITH
      dt AS (
        SELECT to_date(']'||vEndDate||q'[','DD.MM.YYYY') - LEVEL + 1 AS as_of_date
          FROM dual CONNECT BY LEVEL <= to_date(']'||vEndDate||q'[','DD.MM.YYYY') - to_date(']'||vBegDate||q'[','DD.MM.YYYY') + 1
        ORDER BY 1)
     ,a AS (
        SELECT DISTINCT
               to_char(g.group_id) AS ID
              ,NULL AS parent_id
              ,CASE WHEN LEVEL = 1 THEN
                 (SELECT ID FROM tb_entity WHERE parent_id IS NULL
                  CONNECT BY ID = PRIOR parent_id START WITH ID = p.entity_id)
               ELSE NULL END AS head_entity_id
              ,']'||LOWER(vOwner)||q'[.pkg_etl_signs.MyExecute' AS unit
              ,CASE WHEN LEVEL = 1 THEN 'dim' ELSE 'fct' END AS StarPart
              ,'SP'||ora_hash(NVL(s2g.sgn_alias,s2g.sign_name)) AS sp_code
          FROM tb_signs_group g
               LEFT JOIN tb_signs_2_group s2g
                 ON s2g.group_id = g.group_id
               LEFT JOIN tb_signs_pool p
                 ON p.sign_name = s2g.sign_name
          WHERE s2g.sign_name IS NOT NULL AND LEVEL <= 2
        CONNECT BY PRIOR g.group_id = g.parent_group_id
        START WITH g.group_id = ]'||inGroupID||q'[)
      SELECT DISTINCT a.id||'_'||a.head_entity_id||'_P'||to_char(dt.as_of_date,'RRRRMMDD')||CASE WHEN a.head_entity_id IS NULL THEN '_'||a.sp_code END AS ID
            ,NULL AS parent_id
            ,a.unit
            ,'ALTER TABLE ]'||LOWER(vOwner)||q'[.'||CASE WHEN a.head_entity_id IS NULL THEN 'fct_' ELSE 'dim_' END||a.id||CASE WHEN a.head_entity_id IS NULL THEN NULL ELSE '#'||a.head_entity_id END||CHR(10)||
            '   MOVE '||CASE WHEN a.head_entity_id IS NULL THEN 'SUBPARTITION '||a.sp_code||'_'||to_char(dt.as_of_date,'RRRRMMDD') ELSE 'PARTITION P'||to_char(dt.as_of_date,'RRRRMMDD') END||' COMPRESS' AS params
            ,0 AS skip
        FROM dt CROSS JOIN a]';

  load_new(vBuff,vJobName);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarCompress" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarCompress',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarCompress" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarCompress',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarCompress" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarCompress',vMes);
END StarCompress;

PROCEDURE StarDropOldParts(inDate IN DATE,inGroupID IN NUMBER)
  IS
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
    vJobName VARCHAR2(256) := UPPER(vOwner)||'.'||'DROPPARTSJOB_'||tb_signs_job_id_seq.nextval;
    vCou INTEGER := 0;
    vBuff VARCHAR2(32700);
    vDDL CLOB;
    --
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vMes VARCHAR2(4000);
BEGIN
  vMes := 'START :: "'||to_char(inDate,'DD.MM.RRRR')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDropOldParts" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDropOldParts',vMes);

  dbms_lob.createtemporary(vDDL,FALSE);
  FOR idx IN (
    WITH
      g AS (
        SELECT group_id
              ,LEVEL AS lev
              ,MIN(group_id) KEEP (dense_rank FIRST ORDER BY LEVEL) OVER () AS head_group_id
              ,strg_period
              ,strg_period_type
          FROM tb_signs_group
        CONNECT BY PRIOR group_id = parent_group_id
        START WITH group_id = (SELECT MAX(group_id) KEEP (dense_rank LAST ORDER BY LEVEL) AS group_id
                                 FROM tb_signs_group
                               CONNECT BY PRIOR parent_group_id = group_id
                               START WITH group_id = inGroupID)
      )
    SELECT LOWER(vOwner)||'.'||CASE lev WHEN 1 THEN 'dim_' WHEN 2 THEN 'fct_' ELSE 'anltline_' END||group_id||
             CASE WHEN lev != 2 THEN '#'||entity_id END AS table_name
          ,CASE WHEN strg_period_type = 'D' THEN TRUNC(inDate,'DD') - strg_period
             ELSE add_months(TRUNC(inDate,'DD'),-strg_period) END AS dt
          ,lev
      FROM (
        SELECT DISTINCT
               CASE WHEN g.lev IN (1,2) THEN g.group_id ELSE g.head_group_id END AS group_id
              ,CASE WHEN g.lev = 1 THEN to_char((SELECT MAX(ID) KEEP (dense_rank LAST ORDER BY LEVEL) FROM tb_entity CONNECT BY PRIOR parent_id = ID START WITH ID = p.entity_id))
                    WHEN g.lev = 2 THEN NULL
               ELSE a.anlt_alias END AS entity_id
              ,g.lev
              ,g.strg_period
              ,g.strg_period_type
          FROM g
               LEFT JOIN tb_signs_2_group s2g
                 ON g.lev = 1 AND s2g.group_id = g.group_id
               LEFT JOIN tb_Signs_pool p
                 ON p.sign_name = s2g.sign_name
               LEFT JOIN tb_anlt_2_group a2g
                 ON g.lev = 3 AND a2g.group_id = g.group_id
               LEFT JOIN tb_signs_anlt a
                 ON a.anlt_code = a2g.anlt_code
                    AND inDate BETWEEN a.effective_start AND a.effective_end
                    AND EXISTS (SELECT NULL FROM tb_signs_anlt_spec WHERE anlt_id = a.id)
          WHERE (g.lev IN (1,2) OR a.anlt_alias IS NOT NULL) AND strg_period IS NOT NULL
        ORDER BY lev DESC
    )
  ) LOOP
    IF idx.lev = 3 THEN
      vBuff := CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.table_name||''' AS id,NULL AS parent_id,'''||LOWER(vOwner)||'.pkg_etl_signs.MyExecute'||''' AS unit,q''['||'DELETE FROM '||idx.table_name||' WHERE as_of_date <= to_date('''''||to_char(idx.dt,'DD.MM.RRRR')||''''',''''DD.MM.RRRR'''')]'' as params,0 AS skip FROM dual';
      dbms_lob.writeappend(vDDL,length(vBuff),vBuff);
      vCou := vCou + 1;
    ELSE
      FOR p IN (
            SELECT UPPER(idx.table_name)||'|'||partition_name AS ID
                  ,NULL AS parent_id
                  ,LOWER(vOwner)||'.pkg_etl_signs.MyExecute' AS unit
                  ,'ALTER TABLE '||idx.table_name||' DROP PARTITION '||partition_name AS params
                  ,to_date(SUBSTR(partition_name,-8),'YYYYMMDD') AS p_dt
                  ,idx.dt AS i_dt
            FROM all_tab_partitions
            WHERE lower(table_owner||'.'||table_name) = LOWER(idx.table_name)
      ) LOOP
        IF p.p_dt <= p.i_dt THEN
          vBuff := CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||p.id||''' AS id,NULL AS parent_id,'''||p.unit||''' AS unit,'''||p.params||''' AS params,0 AS skip FROM dual';
          dbms_lob.writeappend(vDDL,length(vBuff),vBuff);
        END IF;
      END LOOP;
    END IF;
    vCou := vCou + 1;
  END LOOP;
  IF dbms_lob.getlength(vDDL) > 1
    THEN load_new(vDDL,vJobName);
         --dbms_output.put_line(vDDL);
    ELSE pr_log_write(lower(vOwner)||'.pkg_Etl_signs.StarDropOldParts','INFORMATION :: "'||to_char(inDate,'DD.MM.RRRR')||'" - Для звезды с номером группы '||inGroupID||' не обнаружено сегментов старше периода хранения');
  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.RRRR')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDropOldParts" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDropOldParts',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||to_char(inDate,'DD.MM.RRRR')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDropOldParts" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDropOldParts',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||to_char(inDate,'DD.MM.RRRR')||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.StarDropOldParts" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.StarDropOldParts',vMes);
END StarDropOldParts;

/****************************************************************************************/

PROCEDURE HistTableService(inTableName IN VARCHAR2,inMask IN VARCHAR2,inSign IN VARCHAR2 DEFAULT NULL)
  IS
    vDDL CLOB;
    vIDX CLOB;
    vStats CLOB;
    vBuff VARCHAR2(32700);
    vCou INTEGER := 0;
    vJobName VARCHAR2(256);
    vCompress BOOLEAN := SUBSTR(inMask,1,1) = '1';
    vRebuildIdx BOOLEAN := SUBSTR(inMask,2,1) = '1';
    vGatherStats BOOLEAN := SUBSTR(inMask,3,1) = '1';
    --
    vMes VARCHAR2(32700);
    vTIBegin DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vOwner VARCHAR2(4000) := GetVarValue('vOwner');
BEGIN
  vMes := 'START :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.HistTableService" started.';
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);

  -- Если необходим сбор статистики
  IF vGatherStats THEN
    vTIBegin := SYSDATE;
    vJobName := UPPER(vOwner)||'.SERVICEGATHERSTATSJOB_'||tb_signs_job_id_seq.nextval;
    vCou := 0;

    dbms_lob.createtemporary(vStats,FALSE);
    FOR idx IN (
      SELECT p.table_owner||'.'||p.table_name AS table_name
            ,p.partition_name AS partition_name
        FROM all_tab_partitions p
        WHERE p.table_owner = UPPER(vOwner)
          AND p.table_name = UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))
          AND (UPPER(inSign) IS NULL OR
               UPPER(inSign) IS NOT NULL AND p.partition_name IN (SELECT str FROM TABLE(parse_str(UPPER(inSign),',')))
              )
    ) LOOP
      vBuff :=
      CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.table_name||'|'||idx.partition_name||''' AS id'||CHR(10)||
      '      ,NULL AS parent_id'||CHR(10)||
      '      ,'''||LOWER(vOwner)||'.pkg_etl_signs.MyExecute'' AS unit'||CHR(10)||
      '      ,q''[BEGIN dbms_stats.gather_table_stats(ownname => '''''||UPPER(vOwner)||''''', tabname => '''''||SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1)||''''', partname => '''''||idx.partition_name||''''', degree => 2, granularity => ''''PARTITION''''); END;]'' AS params'||CHR(10)||
      '      ,0 AS skip'||CHR(10)||
      '  FROM dual';
      dbms_lob.writeappend(vStats,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;

    load_new(vStats,vJobName);
    --dbms_output.put_line(vStats);

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: Table "'||inTableName||'" - stats gathered in '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);

  END IF;

  -- Если необходимо сжатие
  IF vCompress THEN
    vTIBegin := SYSDATE;
    vJobName := UPPER(vOwner)||'.SERVICECOMPRESSJOB_'||tb_signs_job_id_seq.nextval;
    -- После сжатия необходимо обязательное перестроение индексов,
    -- т.к. они становятся UNUSABLE
    -- Устанавливаем соответствующий флаг принудительно
    vRebuildIdx := TRUE;

    dbms_lob.createtemporary(vDDL,FALSE);
    vCou := 0;
    FOR idx IN (
      SELECT LOWER(p.table_owner||'.'||p.table_name) AS table_name
            ,LOWER(p.partition_name) AS partition_name
            ,LOWER(s.subpartition_name) AS subpartition_name
        FROM all_tab_partitions p
             LEFT JOIN all_tab_subpartitions s
               ON s.table_owner = p.table_owner
                  AND s.table_name = p.table_name
                  AND s.partition_name = p.partition_name
                  --AND s.num_rows > 0
        WHERE p.table_owner = UPPER(vOwner)
          AND p.table_name = UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))
          --AND p.num_rows > 0
          AND (UPPER(inSign) IS NULL OR
               UPPER(inSign) IS NOT NULL AND p.partition_name IN (SELECT str FROM TABLE(parse_str(UPPER(inSign),',')))
              )
    ) LOOP
      vBuff :=
      CASE WHEN vCou > 0 THEN CHR(10)||'UNION ALL'||CHR(10) END||'SELECT '''||idx.table_name||'|'||CASE WHEN idx.subpartition_name IS NULL THEN idx.partition_name ELSE idx.subpartition_name END||''' AS id'||CHR(10)||
      '      ,NULL AS parent_id'||CHR(10)||
      '      ,'''||LOWER(vOwner)||'.pkg_etl_signs.MyExecute'' AS unit'||CHR(10)||
      '      ,''ALTER TABLE '||idx.table_name||' MOVE'||CASE WHEN idx.subpartition_name IS NULL THEN ' PARTITION '||idx.partition_name ELSE ' SUBPARTITION '||idx.subpartition_name END||' COMPRESS'' AS params'||CHR(10)||
      '      ,0 AS skip'||CHR(10)||
      '  FROM dual';
      dbms_lob.writeappend(vDDL,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;

    --dbms_output.put_line(vDDL);
    load_new(vDDL,vJobName);

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: Table "'||inTableName||'" - '||vCou||' partitions compressed in '||get_ti_as_hms(vEndTime - vTIBegin);
    pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);

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
                  AND (UPPER(inSign) IS NULL OR
                       UPPER(inSign) IS NOT NULL AND ip.partition_name IN (SELECT str FROM TABLE(dm_skb.pkg_etl_signs.parse_str(UPPER(inSign),',')))
                      )
             LEFT JOIN all_ind_subpartitions sp
               ON sp.index_owner = ip.index_owner
                  AND sp.index_name = ip.index_name
                  AND sp.partition_name = ip.partition_name
        WHERE i.owner = UPPER(vOwner)
          AND i.table_name = UPPER(SUBSTR(inTableName,INSTR(inTableName,'.',1,1) + 1))
    ) LOOP
      vBuff := 'EXECUTE IMMEDIATE ''ALTER INDEX '||idx.index_name||' REBUILD'||CASE WHEN idx.subpartition_name IS NULL THEN ' PARTITION '||idx.partition_name ELSE ' SUBPARTITION '||idx.subpartition_name END||' PARALLEL 16''; '||CHR(10);
      dbms_lob.writeappend(vIDX,LENGTH(vBuff),vBuff);
      vCou := vCou + 1;
    END LOOP;
    vBuff := 'END;';
    dbms_lob.writeappend(vIDX,LENGTH(vBuff),vBuff);

    BEGIN
      EXECUTE IMMEDIATE vIDX;
      --dbms_output.put_line(vIDX);

      vEndTime := SYSDATE;
      vMes := 'SUCCESSFULLY :: Table "'||inTableName||'" - '||vCou||' partitions rebuilded in '||get_ti_as_hms(vEndTime - vTIBegin);
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);
    EXCEPTION WHEN OTHERS THEN
      vEndTime := SYSDATE;
      vMes := 'ERROR :: Table "'||inTableName||'" :: Rebuild of indexses finished in '||get_ti_as_hms(vEndTime - vTIBegin)||' with error:'||CHR(10)||SQLERRM;
      pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);
    END;
  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.HistTableService" finished sucessfully in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);

EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.HistTableService" :: '||SQLERRM;
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: "'||inTableName||'" - Procedure "'||lower(vOwner)||'.pkg_etl_signs.HistTableService" finished with errors in '||get_ti_as_hms(vEndTime - vBegTime);
  pr_log_write(lower(vOwner)||'.pkg_etl_signs.HistTableService',vMes);
END HistTableService;

FUNCTION GetVarCLOBValue(inVarName VARCHAR2) RETURN CLOB
  IS
    vType VARCHAR2(30);
    vVal CLOB := NULL;
    vRes CLOB := NULL;
    --
    errNotExists EXCEPTION;
BEGIN
  BEGIN
    SELECT var_type INTO vType FROM tb_variable_registry WHERE NAME = inVarName;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE errNotExists;
  END;

  SELECT val INTO vVal FROM tb_variable_registry WHERE NAME = inVarName;

  IF vType = 'Простая' THEN
    RETURN vVal;
  ELSE
    EXECUTE IMMEDIATE vVal USING OUT vRes;
    RETURN vRes;
  END IF;
EXCEPTION
  WHEN errNotExists THEN
    RETURN 'Переменная не найдена';
  WHEN OTHERS THEN
  RETURN SQLERRM;
END;

FUNCTION GetVarValue(inVarName VARCHAR2) RETURN VARCHAR2
IS
BEGIN
  RETURN dbms_lob.substr(pkg_etl_signs.GetVarCLOBValue(inVarName),32700,1);
END;

FUNCTION call_hist(inTable IN VARCHAR2, inID IN VARCHAR2,inAction VARCHAR2) RETURN VARCHAR2
  IS
  vStr VARCHAR2(32700);
  vRes VARCHAR2(4000);
BEGIN
  IF NOT(UPPER(inAction) IN ('ON','OFF')) THEN
    RAISE_APPLICATION_ERROR(-20000,'Неизвестное значение параметра inAction.'||CHR(10)||'Возможные значения параметра inAction: ON - включить; OFF - отключить');
  END IF;

  IF NOT CanHaveHistory(inTable) AND UPPER(inAction) = 'ON' THEN
    RAISE_APPLICATION_ERROR(-20001,'История не может быть включена для таблиц хранения, а так же для фактов и измерений куба');
  END IF;

  IF UPPER(inAction) = 'ON' THEN
    vStr := 'CREATE OR REPLACE TRIGGER '||SUBSTR(inTable,1,24)||'_h_trg';
    vStr := vStr||' AFTER INSERT OR UPDATE OR DELETE'||' ON '||inTable||Chr(10);
    vStr := vStr||'FOR EACH ROW'||Chr(10);
    vStr := vStr||'DECLARE'||Chr(10);
    vStr := vStr||'  vDML_Type VARCHAR2(1);'||Chr(10)||'  vTableID VARCHAR2(255);'||Chr(10);
    vStr := vStr||'BEGIN'||Chr(10);
    vStr := vStr||'  IF DELETING THEN'||Chr(10)||'    vDML_Type := ''D'';'||Chr(10)||'    vTableID := :Old.'||inID||';'||Chr(10)||
                  '  ELSIF INSERTING THEN'||Chr(10)||'    vDML_Type := ''I'';'||Chr(10)||'    vTableID := :New.'||inID||';'||Chr(10)||
                  '  ELSE'||Chr(10)||'    vDML_Type := ''U'';'||Chr(10)||'    vTableID := :Old.'||inID||';'||Chr(10)||
                  '  END IF;'||Chr(10);
    vStr := vStr||'  IF DELETING OR INSERTING THEN'||Chr(10);
    FOR col IN (SELECT column_name,data_type FROM dba_tab_columns
                 WHERE lower(owner||'.'||table_name) = lower(inTable) AND column_name != 'LASTUPDATE'
               )
    LOOP
      vStr := vStr||'    INSERT INTO tb_signs_history (table_name,col_name,dt,os_user,ip_addr,dml_type,old_val,new_val,table_id)'||Chr(10);
      vStr := vStr||'      VALUES('''||UPPER(inTable)||''','''||col.column_name||''',SYSDATE,sys_context(''userenv'',''OS_USER''),sys_context(''userenv'',''IP_ADDRESS''),vDML_Type,'||
        CASE WHEN col.data_type = 'NUMBER' THEN 'to_char(:Old.'||col.column_name||',''FM999999999999999D999999999'',''nls_numeric_characters='''', '''''')'
             WHEN col.data_type = 'DATE' THEN 'to_char(:Old.'||col.column_name||',''DD.MM.YYYY HH24:MI:SS'')'
        ELSE ':Old.'||col.column_name
        END||','||
        CASE WHEN col.data_type = 'NUMBER' THEN 'to_char(:New.'||col.column_name||',''FM999999999999999D999999999'',''nls_numeric_characters='''', '''''')'
             WHEN col.data_type = 'DATE' THEN 'to_char(:New.'||col.column_name||',''DD.MM.YYYY HH24:MI:SS'')'
        ELSE ':New.'||col.column_name
        END||',vTableID);'||Chr(10);
    END LOOP;
    vStr := vStr||'  ELSE'||Chr(10);
    FOR col IN (SELECT column_name,data_type FROM dba_tab_columns
                 WHERE lower(owner||'.'||table_name) = lower(inTable) AND column_name != 'LASTUPDATE'
               )
    LOOP
      vStr := vStr||'    IF :Old.'||col.column_name||' != :New.'||col.column_name||' OR'||Chr(10);
      vStr := vStr||'       :Old.'||col.column_name||' IS NULL AND :New.'||col.column_name||' IS NOT NULL OR'||Chr(10);
      vStr := vStr||'       :Old.'||col.column_name||' IS NOT NULL AND :New.'||col.column_name||' IS NULL'||Chr(10);
      vStr := vStr||'      THEN'||Chr(10);
      vStr := vStr||'        INSERT INTO tb_signs_history (table_name,col_name,dt,os_user,ip_addr,dml_type,old_val,new_val,table_id)'||Chr(10);
      vStr := vStr||'          VALUES('''||UPPER(inTable)||''','''||col.column_name||''',SYSDATE,sys_context(''userenv'',''OS_USER''),sys_context(''userenv'',''IP_ADDRESS''),vDML_Type,'||
        CASE WHEN col.data_type = 'NUMBER' THEN 'to_char(:Old.'||col.column_name||',''FM999999999999999D999999999'',''nls_numeric_characters='''', '''''')'
             WHEN col.data_type = 'DATE' THEN 'to_char(:Old.'||col.column_name||',''DD.MM.YYYY HH24:MI:SS'')'
        ELSE ':Old.'||col.column_name
        END||','||
        CASE WHEN col.data_type = 'NUMBER' THEN 'to_char(:New.'||col.column_name||',''FM999999999999999D999999999'',''nls_numeric_characters='''', '''''')'
             WHEN col.data_type = 'DATE' THEN 'to_char(:New.'||col.column_name||',''DD.MM.YYYY HH24:MI:SS'')'
        ELSE ':New.'||col.column_name
        END||',vTableID);'||Chr(10);
      vStr := vStr||'    END IF;'||Chr(10);
    END LOOP;
    vStr := vStr||'  END IF;'||Chr(10);
    --vStr := vStr||'EXCEPTION WHEN OTHERS THEN NULL;'||Chr(10);
    vStr := vStr||'END;';
    EXECUTE IMMEDIATE vStr;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE tb_signs_history ADD PARTITION '||UPPER(REPLACE(inTable,'.','#'))||' VALUES('''||UPPER(inTable)||''') STORAGE(INITIAL 64K NEXT 1M)';
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT ON tb_signs_history TO '||SUBSTR(inTable,1,INSTR(inTable,'.',1,1) - 1);
    vRes := 'SUCCESSFULLY :: История по таблице "'||inTable||'" успешно включена';
  ELSE
    vStr := 'DROP TRIGGER '||SUBSTR(inTable,1,24)||'_h_trg';
    EXECUTE IMMEDIATE vStr;
    BEGIN
      EXECUTE IMMEDIATE 'REVOKE SELECT,INSERT ON tb_signs_history FROM '||SUBSTR(inTable,1,INSTR(inTable,'.',1,1) - 1);
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
    vRes := 'SUCCESSFULLY :: История по таблице "'||inTable||'" успешно отключена';
  END IF;
  RETURN vRes;
EXCEPTION WHEN OTHERS THEN
  RETURN 'ERROR :: Не удалось включить/отключить историю по таблице "'||inTable||'" :: '||SQLERRM||CHR(10)||'---------------------'||CHR(10)||vStr;
END call_hist;

FUNCTION CanHaveHistory(inTable IN VARCHAR2) RETURN BOOLEAN
  IS
    vCou INTEGER := 0;
BEGIN
  WITH
    a AS (
      SELECT LOWER(pkg_etl_signs.GetVarValue('vOwner')||'.'||fct_table_name) AS table_name
        FROM tb_entity
      UNION ALL
      SELECT LOWER(pkg_etl_signs.GetVarValue('vOwner')||'.'||hist_table_name)
        FROM tb_entity
      UNION ALL
      SELECT LOWER(pkg_etl_signs.GetVarValue('vOwner')||'.'||tmp_table_name)
        FROM tb_entity
      UNION ALL
      SELECT LOWER(pkg_etl_signs.GetVarValue('vOwner')||'.'||'fct_'||group_id)
        FROM tb_signs_group
        WHERE parent_group_id IS NOT NULL
      UNION ALL
      SELECT LOWER(pkg_etl_signs.GetVarValue('vOwner')||'.'||'dim_'||g.group_id||'#'||e.id)
        FROM tb_signs_group g
             CROSS JOIN tb_entity e
        WHERE g.parent_group_id IS NULL
      UNION ALL
      SELECT LOWER(pkg_etl_signs.GetVarValue('vOwner')||'.'||'anltline_'||g.group_id||'#'||a.anlt_alias)
        FROM tb_signs_anlt a
             INNER JOIN tb_signs_group g ON g.parent_group_id IS NULL
        WHERE EXISTS (SELECT NULL FROM tb_signs_anlt_spec WHERE anlt_id = a.id)
    )
   ,b AS (
     SELECT LOWER(inTable) AS table_name FROM dual
    )
  SELECT COUNT(1) INTO vCou FROM a INNER JOIN b ON a.table_name = b.table_name;
  IF vCou > 0 THEN RETURN FALSE; ELSE RETURN TRUE; END IF;
END CanHaveHistory;

PROCEDURE SetFlag
  (inName IN VARCHAR2
  ,inDate IN DATE
  ,inVal IN VARCHAR2 DEFAULT NULL
  ,inAction NUMBER DEFAULT 1 -- 1 - UPSERT, 0 - DELETE
  )
  IS
    vMes VARCHAR2(4000);
    vOwner VARCHAR2(256) := getvarvalue('vOwner');
BEGIN
  IF inAction = 1 THEN
    MERGE INTO tb_flags_pool dest
      USING (SELECT inName AS NAME,inDate AS dt, inVal AS val FROM dual) src
         ON (dest.name = src.name AND dest.dt = src.dt)
      WHEN MATCHED THEN
        UPDATE SET dest.val = src.val
      WHEN NOT MATCHED THEN
        INSERT (dest.id,dest.name,dest.dt,dest.val)
          VALUES (tb_flags_pool_id_seq.nextval,src.name,src.dt,src.val);
  ELSE
    DELETE FROM tb_flags_pool WHERE dt = inDate AND NAME = inName;
  END IF;

  COMMIT;
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Procedure "'||vOwner||'.pkg_etl_signs.set_flag" :: '||SQLERRM;
  pr_log_write(vOwner||'.pkg_etl_signs.set_flag',vMes);
  COMMIT;
END SetFlag;

FUNCTION GetFlag(inFlagName IN VARCHAR2, inDate IN DATE) RETURN VARCHAR2
  IS
    vRes VARCHAR2(4000) := NULL;
BEGIN
  SELECT val INTO vRes FROM tb_flags_pool WHERE dt = inDate AND NAME = inFlagName;
  RETURN vRes;
EXCEPTION WHEN OTHERS THEN
  RETURN vRes;
END;

FUNCTION PDCA(inObj IN VARCHAR2, inAnalyzeContent IN NUMBER DEFAULT 0) RETURN VARCHAR2
IS
  --inObj VARCHAR2(256) := 'CRE.NBCH_REQUESTOR';
  vSQL CLOB;
  vBuff VARCHAR2(32700);
  vNumRow INTEGER := 0;
  vCols VARCHAR2(32700);
  vCur SYS_REFCURSOR;
  vCurVal VARCHAR2(32700);
  vAnalyzeContent NUMBER := inAnalyzeContent;
  --
  --vRes VARCHAR2(10);
  --
  errYesColumn EXCEPTION;
  errYesContent EXCEPTION;
BEGIN
  dbms_lob.createtemporary(vSQL,FALSE);
  vBuff := 'SELECT col_val FROM ('||CHR(10)||'SELECT '||CHR(10);
  dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
  vNumRow := 0;
  FOR idx IN (
    SELECT data_type
          ,column_name
          ,row_number() OVER (ORDER BY column_id) AS col_num
      FROM dba_tab_columns
      WHERE owner = SUBSTR(inObj,1,INSTR(inobj,'.',1,1)-1)
        AND table_name = SUBSTR(inObj,INSTR(inobj,'.',1,1)+1,LENGTH(inObj) - INSTR(inobj,'.',1,1))
        AND data_type IN ('NUMBER','VARCHAR2')
        AND NOT(column_name LIKE '%EMPLOYEE%')
        ORDER BY column_id
  ) LOOP

    IF pkg_etl_signs.GetConditionResult(REPLACE(dm_skb.pkg_etl_signs.GetVarValue('PDCA_ColNameContent'),':CONTENT:',''''||idx.column_name||'''')) = 1 THEN RAISE errYesColumn; END IF;

    vCols := vCols||CASE WHEN vNumRow = 0 THEN '' ELSE ',' END||'COL_'||idx.col_num;
    vBuff := CASE WHEN vNumRow = 0 THEN '        ' ELSE '       ,' END||CASE WHEN idx.data_type = 'NUMBER' THEN 'to_char(' END||inObj||'.'||idx.column_name||CASE WHEN idx.data_type = 'NUMBER' THEN ')' END||' AS '||'COL_'||idx.col_num||CHR(10);
    dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);
    vNumRow := vNumRow + 1;
  END LOOP;
  vBuff := '  FROM '||inObj||' WHERE rownum <= 1000'||CHR(10)||') UNPIVOT (col_val FOR col_name IN ('||vCols||'))';
  dbms_lob.writeappend(vSQL,LENGTH(vBuff),vBuff);

  IF vAnalyzeContent = 1 THEN
    OPEN vCur FOR vSQL;

    IF (vCur IS NOT NULL)
      THEN
          LOOP
              FETCH vCur INTO vCurVal;
              EXIT WHEN vCur%NOTFOUND;
              IF pkg_etl_signs.GetConditionResult(REPLACE(dm_skb.pkg_etl_signs.GetVarValue('PDCA_Content'),':CONTENT:','q''['||vCurVal||']''')) = 1 THEN RAISE errYesContent; END IF;
          END LOOP;
          CLOSE vCur;
    END IF;
  END IF;
  IF vAnalyzeContent = 1 THEN RETURN 'NO'; ELSE RETURN 'NO WITHOUT CONTENT ANALYZE'; END IF;
EXCEPTION
  WHEN errYesColumn THEN
    RETURN 'COLUMN';
  WHEN errYesContent THEN
    RETURN 'CONTENT';
    CLOSE vCur;
  WHEN OTHERS THEN
    RETURN 'ERROR';
END PDCA;

FUNCTION SQLasHTML(inSQL IN CLOB,inColNames IN VARCHAR2,inColAliases IN VARCHAR2,inStyle IN VARCHAR2 DEFAULT NULL,inShowLogo BOOLEAN DEFAULT FALSE,inTabHeader VARCHAR2 DEFAULT NULL) RETURN CLOB
IS
  vSQL CLOB;
  vOut CLOB;
  vBuff VARCHAR2(32700);
  vCur SYS_REFCURSOR;
  vKey NUMBER;
  vKeyName VARCHAR2(30);
  vKeyVal VARCHAR2(4000);
  vPrevRowNum NUMBER := 0;
  --
  errSqlIsNull EXCEPTION;
BEGIN
  IF inSQL IS NULL OR inColNames IS NULL OR inColAliases IS NULL THEN RAISE errSqlIsNull; END IF;
  vSQL := 'SELECT * FROM (SELECT row_number() OVER (ORDER BY null) AS rownum_key,'||REPLACE(inColNames,'#!#',',')||' FROM ('||inSQL||')) UNPIVOT INCLUDE NULLS (key_val FOR key_name IN ('||REPLACE(inColNames,'#!#',',')||'))';
  dbms_lob.createtemporary(vOut,FALSE);
  vBuff :=
  '<!DOCTYPE html>'||Chr(10)||'<html>'||Chr(10)||'<head>'||Chr(10)||pkg_etl_signs.GetVarValue('HTMLEncoding')||CHR(10)||CASE WHEN inStyle IS NULL THEN pkg_etl_signs.GetVarValue('HTMLTableStyle') ELSE inStyle END||Chr(10)||
  '</head>'||Chr(10)||'<body>'||Chr(10)||CASE WHEN inShowLogo THEN pkg_etl_signs.GetVarValue('HTMLLogo')||CHR(10) ELSE NULL END||
  CASE WHEN inTabHeader IS NOT NULL THEN '<br>'||inTabHeader||'<br>' ELSE NULL END||
  '<table>'||Chr(10);
  dbms_lob.writeappend(vOut,LENGTH(vBuff),vBuff);
  vBuff := '<tr><th>'||REPLACE(inColAliases,'#!#','</th><th>');
  dbms_lob.writeappend(vOut,LENGTH(vBuff),vBuff);

  OPEN vCur FOR vSQL;
  IF (vCur IS NOT NULL) THEN
    LOOP
      FETCH vCur INTO vKey,vKeyName,vKeyVal;
      EXIT WHEN vCur%NOTFOUND;
      vKeyVal := '<td>'||vKeyVal||'</td>';
      IF vPrevRowNum < vKey THEN vKeyVal := '</tr>'||CHR(10)||'<tr>'||vKeyVal; END IF;
      vBuff := vKeyVal;
      dbms_lob.writeappend(vOut,LENGTH(vBuff),vBuff);
      vPrevRowNum := vKey;
    END LOOP;
    CLOSE vCur;
  END IF;
  vBuff := '</tr>'||CHR(10)||'</body>'||CHR(10)||'</html>';
  dbms_lob.writeappend(vOut,LENGTH(vBuff),vBuff);
  RETURN vOut;
EXCEPTION
  WHEN errSqlIsNull THEN RETURN ('NULL');
  WHEN OTHERS THEN RETURN SQLERRM;
END SQLasHTML;


END pkg_etl_signs;
/
