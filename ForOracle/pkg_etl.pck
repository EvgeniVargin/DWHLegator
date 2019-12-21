CREATE OR REPLACE PACKAGE DM_CLANT.pkg_etl
  IS
----------------------------------- ИЗМЕРЕНИЯ -----------------------------------------------
PROCEDURE tb_contract_clant_merge;
PROCEDURE tb_ref_contract_clant_all;
PROCEDURE tb_ref_contract_clant;
PROCEDURE tb_dwh_employees;
PROCEDURE tb_dwh_product_clant;
PROCEDURE tb_dwh_abs_dep_clant;
PROCEDURE mv_ref_contract_top_up;
PROCEDURE mv_ref_emp_oper_activity_cols;
PROCEDURE mv_department_line;
PROCEDURE tb_hist_users;
-- промежуточные для последующих заливок
PROCEDURE tb_contract_for_update;
PROCEDURE tb_client_for_update;
PROCEDURE tb_cl_contracts_all;
PROCEDURE tb_cl_contracts;                           
PROCEDURE tb_cl_credits_all;
PROCEDURE tb_account_to_credit_all;
PROCEDURE contr_2_prod_closed (inBegDate IN DATE, inEndDate IN DATE);
PROCEDURE contr_2_prod_opened;
PROCEDURE ptb_pre_limits_cl_clm (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE ptb_pre_limits_cl (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE tb_fpd_spd_tpd_all;
PROCEDURE tb_fpd_spd_tpd_prev;
PROCEDURE tb_fpd_spd_tpd;
PROCEDURE tb_fpd_spd_tpd_update (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE ptb_fpd_spd_tpd_def (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE tb_client_not_load;
--------------------------- ОЧИСТКА УСТАРЕВШИХ ДАННЫХ  --------------------------------------
PROCEDURE tables_clearing;
------------------------------------- ФАКТЫ -------------------------------------------------
PROCEDURE ptb_abb_fact (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE ptb_pre_limits_creds (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE ptb_pre_limits_cl_fact (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE ptb_pre_limits_nvpv (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE ptb_entry_fact (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE tb_emp_oper_activity 
  (inBegDt IN DATE, inEndDt IN DATE, inPartID IN NUMBER DEFAULT NULL);
PROCEDURE calc_emp_oper_activity_period(inBegDate IN DATE);
PROCEDURE tb_cards_state (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE tb_fpd_spd_tpd_fifo (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE tb_fpd_spd_tpd_fact;
PROCEDURE tb_cards_stock (inBegDt IN DATE, inEndDt IN DATE);
PROCEDURE bl_vki_set_date;
---------------------------------------- DWH слой --------------------------------------------
PROCEDURE ref_contract_new(inColumnName IN VARCHAR2);
PROCEDURE ref_abs_department_new(inColumnName IN VARCHAR2);
PROCEDURE ref_contract_spec_new(inColumnName IN VARCHAR2);
PROCEDURE ref_client_new(inColumnName IN VARCHAR2);
PROCEDURE ref_client_address_new(inColumnName IN VARCHAR2);
PROCEDURE ref_account_new(inColumnName IN VARCHAR2);
PROCEDURE ref_card_new(inColumnName IN VARCHAR2);
PROCEDURE ref_crd_claim_new(inColumnName IN VARCHAR2);

END pkg_etl;
/
CREATE OR REPLACE PACKAGE BODY DM_CLANT.pkg_etl
  IS
--------------------------------------- ИЗМЕРЕНИЯ --------------------------------------------------------
PROCEDURE tb_contract_clant_merge
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_contract_clant_merge" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_clant_merge',vMes);
  
  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_contract_clant_merge';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_contract_clant_merge" truncated';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_clant_merge',vMes);
  
  vTIBegin := SYSDATE;
  INSERT /*+ APPEND */ INTO dm_clant.tb_contract_clant_merge
     (categories_id,contract_sid,date_actual,client_type_id,client_gid,client_sid,contract_gid,source_system_id,contract_no,product_group
     ,contract_type,open_date,close_date,close_fact_date,crt_closed_reason,principal,principal_in_rur,cur_id
     ,employee_sid,br_name,br_code,open_abs_department_name,open_abs_department_code,abs_department_name
     ,abs_department_code,interest_rate_open_date,interest_rate,effective_rate,product_group_sid,contract_type_sid
     ,open_abs_department_sid,abs_department_sid,created_by_employee_sid,loan_quality_cod,product_dm1_code
     ,contract_type_sid2,effective_end,delflag
     ,comments,status,tag_access,name_access,prolong_count,open_reason_code
     ,open_reason_name,next_contract_type,next_ctr_type_name,crd_claim_gid,created_by_emp_name,instrument_id
     ,bank_name,cl_tax_system
     )
    SELECT categories_id,contract_sid,date_actual,client_type_id,client_gid,client_sid,contract_gid,source_system_id,contract_no,product_group
          ,contract_type,open_date,close_date,close_fact_date,crt_closed_reason,principal,principal_in_rur,cur_id
          ,employee_sid,br_name,br_code,open_abs_department_name,open_abs_department_code,abs_department_name
          ,abs_department_code,interest_rate_open_date,interest_rate,effective_rate,product_group_sid,contract_type_sid
          ,open_abs_department_sid,abs_department_sid,created_by_employee_sid,loan_quality_cod,product_dm1_code
          ,contract_type_sid2,effective_end,delflag
          ,comments,status,tag_access,name_access,prolong_count,open_reason_code
          ,open_reason_name,next_contract_type,next_ctr_type_name,crd_claim_gid,created_by_emp_name,instrument_id
          ,bank_name,cl_tax_system
      FROM dm_clant.v_contract_all_new
  ;

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_contract_clant_merge" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_clant_merge',vMes);
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_contract_clant_merge in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_clant_merge',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_contract_clant_merge" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_clant_merge',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_contract_clant_merge" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_clant_merge',vMes);
END tb_contract_clant_merge; 

PROCEDURE tb_ref_contract_clant_all
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_ref_contract_clant_all" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant_all',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_ref_contract_clant';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_ref_contract_clant" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant_all',vMes);
  
  INSERT /*+ APPEND */ INTO dm_clant.tb_ref_contract_clant
     (categories_id,contract_sid,date_actual,client_type_id,client_gid,client_sid,contract_gid,source_system_id,contract_no,product_group
     ,contract_type,open_date,close_date,close_fact_date,crt_closed_reason,principal,principal_in_rur,cur_id
     ,employee_sid,br_name,br_code,open_abs_department_name,open_abs_department_code,abs_department_name
     ,abs_department_code,interest_rate_open_date,interest_rate,effective_rate,product_group_sid,contract_type_sid
     ,open_abs_department_sid,abs_department_sid,created_by_employee_sid,loan_quality_cod,product_dm1_code
     ,contract_type_sid2,effective_end,delflag
     ,comments,status,tag_access,name_access,prolong_count,open_reason_code
     ,open_reason_name,next_contract_type,next_ctr_type_name,crd_claim_gid,created_by_emp_name,instrument_id
     ,bank_name,cl_tax_system
     )
    SELECT categories_id,contract_sid,date_actual,client_type_id,client_gid,client_sid,contract_gid,source_system_id,contract_no,product_group
          ,contract_type,open_date,close_date,close_fact_date,crt_closed_reason,principal,principal_in_rur,cur_id
          ,employee_sid,br_name,br_code,open_abs_department_name,open_abs_department_code,abs_department_name
          ,abs_department_code,interest_rate_open_date,interest_rate,effective_rate,product_group_sid,contract_type_sid
          ,open_abs_department_sid,abs_department_sid,created_by_employee_sid,loan_quality_cod,product_dm1_code
          ,contract_type_sid2,effective_end,delflag
          ,comments,status,tag_access,name_access,prolong_count,open_reason_code
          ,open_reason_name,next_contract_type,next_ctr_type_name,crd_claim_gid,created_by_emp_name,instrument_id
          ,bank_name,cl_tax_system
      FROM dm_clant.tb_contract_clant_merge;
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_ref_contract_clant".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant_all',vMes);

  dm_skb.dm_showcase_set_date('ALL_CONTRACTS',1,TRUNC(SYSDATE - 1,'DD'));

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_ref_contract_clant_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant_all',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_ref_contract_clant" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant_all',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_ref_contract_clant_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant_all',vMes);
END tb_ref_contract_clant_all;

PROCEDURE tb_ref_contract_clant
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
    vCou INTEGER := 0;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_ref_contract_clant" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant',vMes);
  
  -- Проверяем количество обновляемых догорворов. Если > 1000000,
  -- делаем полную перезагрузку, иначе MERGE
  SELECT COUNT(1) INTO vCou FROM dm_clant.tb_contract_for_update;
  
  --IF vCou > 1000000 THEN dm_clant.pkg_etl.tb_ref_contract_clant_all;
  --ELSE
    vTIBegin := SYSDATE;
    MERGE INTO dm_clant.tb_ref_contract_clant dest
      USING dm_clant.v_contract_all_for_update src
         ON (dest.contract_sid = src.contract_sid)
      WHEN MATCHED THEN
        UPDATE SET dest.categories_id = src.categories_id
                  ,dest.date_actual = src.date_actual
                  ,dest.client_type_id = src.client_type_id
                  ,dest.client_gid = src.client_gid
                  ,dest.client_sid = src.client_sid
                  ,dest.contract_gid = src.contract_gid
                  ,dest.source_system_id = src.source_system_id
                  ,dest.contract_no = src.contract_no
                  ,dest.product_group = src.product_group
                  ,dest.contract_type = src.contract_type
                  ,dest.contract_type_sid = src.contract_type_sid
                  ,dest.product_group_sid = src.product_group_sid
                  ,dest.open_date = src.open_date
                  ,dest.close_date = src.close_date
                  ,dest.close_fact_date = src.close_fact_date
                  ,dest.crt_closed_reason = src.crt_closed_reason
                  ,dest.principal = src.principal
                  ,dest.principal_in_rur = src.principal_in_rur
                  ,dest.cur_id = src.cur_id
                  ,dest.employee_sid = src.employee_sid
                  ,dest.br_name = src.br_name
                  ,dest.br_code = src.br_code
                  ,dest.open_abs_department_name = src.open_abs_department_name
                  ,dest.open_abs_department_code = src.open_abs_department_code
                  ,dest.open_abs_department_sid = src.open_abs_department_sid
                  ,dest.abs_department_name = src.abs_department_name
                  ,dest.abs_department_code = src.abs_department_code
                  ,dest.abs_department_sid = src.abs_department_sid
                  ,dest.interest_rate = src.interest_rate
                  ,dest.effective_rate = src.effective_rate
                  ,dest.interest_rate_open_date = src.interest_rate_open_date
                  ,dest.created_by_employee_sid = src.created_by_employee_sid
                  ,dest.loan_quality_cod = src.loan_quality_cod
                  ,dest.product_dm1_code = src.product_dm1_code
                  ,dest.contract_type_sid2 = src.contract_type_sid2
                  ,dest.effective_end = src.effective_end
                  ,dest.delflag = src.delflag
                  ,dest.comments = src.comments
                  ,dest.status = src.status
                  ,dest.tag_access = src.tag_access
                  ,dest.name_access = src.name_access
                  ,dest.prolong_count = src.prolong_count
                  ,dest.open_reason_code = src.open_reason_code
                  ,dest.open_reason_name = src.open_reason_name
                  ,dest.next_contract_type = src.next_contract_type
                  ,dest.next_ctr_type_name = src.next_ctr_type_name
                  ,dest.crd_claim_gid = src.crd_claim_gid
                  ,dest.created_by_emp_name = src.created_by_emp_name
      DELETE WHERE dest.delflag = 1           
      WHEN NOT MATCHED THEN
        INSERT    (dest.categories_id
                  ,dest.contract_sid
                  ,dest.date_actual
                  ,dest.client_type_id
                  ,dest.client_gid
                  ,dest.client_sid
                  ,dest.contract_gid
                  ,dest.source_system_id
                  ,dest.contract_no
                  ,dest.product_group
                  ,dest.contract_type
                  ,dest.contract_type_sid
                  ,dest.product_group_sid
                  ,dest.open_date
                  ,dest.close_date
                  ,dest.close_fact_date
                  ,dest.crt_closed_reason
                  ,dest.principal
                  ,dest.principal_in_rur
                  ,dest.cur_id
                  ,dest.employee_sid
                  ,dest.br_name
                  ,dest.br_code
                  ,dest.open_abs_department_name
                  ,dest.open_abs_department_code
                  ,dest.open_abs_department_sid
                  ,dest.abs_department_name
                  ,dest.abs_department_code
                  ,dest.abs_department_sid
                  ,dest.interest_rate
                  ,dest.effective_rate
                  ,dest.interest_rate_open_date
                  ,dest.created_by_employee_sid
                  ,dest.loan_quality_cod
                  ,dest.product_dm1_code
                  ,dest.contract_type_sid2
                  ,dest.effective_end
                  ,dest.delflag
                  ,dest.comments
                  ,dest.status
                  ,dest.tag_access
                  ,dest.name_access
                  ,dest.prolong_count
                  ,dest.open_reason_code
                  ,dest.open_reason_name
                  ,dest.next_contract_type
                  ,dest.next_ctr_type_name
                  ,dest.crd_claim_gid
                  ,dest.created_by_emp_name
                  )
        
        VALUES
                (src.categories_id
                ,src.contract_sid
                ,src.date_actual
                ,src.client_type_id
                ,src.client_gid
                ,src.client_sid
                ,src.contract_gid
                ,src.source_system_id
                ,src.contract_no
                ,src.product_group
                ,src.contract_type
                ,src.contract_type_sid
                ,src.product_group_sid
                ,src.open_date
                ,src.close_date
                ,src.close_fact_date
                ,src.crt_closed_reason
                ,src.principal
                ,src.principal_in_rur
                ,src.cur_id
                ,src.employee_sid
                ,src.br_name
                ,src.br_code
                ,src.open_abs_department_name
                ,src.open_abs_department_code
                ,src.open_abs_department_sid
                ,src.abs_department_name
                ,src.abs_department_code
                ,src.abs_department_sid
                ,src.interest_rate
                ,src.effective_rate
                ,src.interest_rate_open_date
                ,src.created_by_employee_sid
                ,src.loan_quality_cod
                ,src.product_dm1_code
                ,src.contract_type_sid2
                ,src.effective_end
                ,src.delflag
                ,src.comments
                ,src.status
                ,src.tag_access
                ,src.name_access
                ,src.prolong_count
                ,src.open_reason_code
                ,src.open_reason_name
                ,src.next_contract_type
                ,src.next_ctr_type_name
                ,src.crd_claim_gid
                ,src.created_by_emp_name
                )
       WHERE src.delflag = 0
    ;          

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_ref_contract_clant" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant',vMes);
  --END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_ref_contract_clant in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_ref_contract_clant" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_ref_contract_clant" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_ref_contract_clant',vMes);
END tb_ref_contract_clant;     

PROCEDURE tb_dwh_employees
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_dwh_employees" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_employees',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_dwh_employees';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_dwh_employees" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_employees',vMes);
  
  INSERT /*+ APPEND */ INTO dm_clant.tb_dwh_employees 
    (sid_lv0,gid_lv0,name_lv0,code_lv0,start_date_lv0,end_date_lv0,sid_lv1,gid_lv1
    ,name_lv1,login_lv1,start_date_lv1,end_date_lv1,position,tab_num,source_system_id,dep_name_path,direction_name)
  SELECT sid_lv0,gid_lv0,name_lv0,code_lv0,start_date_lv0,end_date_lv0,sid_lv1,gid_lv1
        ,name_lv1,login_lv1,start_date_lv1,end_date_lv1,position,tab_num,source_system_id,dep_name_path,direction_name
    FROM dm_clant.v_dwh_employees;
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_dwh_employees".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_employees',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_dwh_employees" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_employees',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_dwh_employees" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_employees',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_dwh_employees" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_employees',vMes);
END tb_dwh_employees;  

PROCEDURE tb_dwh_product_clant
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_dwh_product_clant" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);

  -- Целищев А.
  -- ожидаем готовности IBSO (для dm_clant.v_dwh_product_clant)
    declare
    msgfl number := 1;
    cnt number;
    begin  
    loop
      begin
        execute immediate 'select count(1) from dual@ibso_rez' into cnt;
      exception
        when others then begin cnt:=0; end;
      end;
      exit when cnt>0;
      if msgfl = 1 then
        msgfl := 0;
        vMes := 'Waiting for wake up IBSO_REZ in procedure "dm_clant.pkg_etl.tb_dwh_product_clant".';
        dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);        
      end if;
       stage.mysleep(60);
    end loop;
    end;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_dwh_product_clant';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_dwh_product_clant" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);
  
  INSERT /*+ APPEND */ INTO dm_clant.tb_dwh_product_clant
   (sid_lv0,name_lv0,start_date_lv0,end_date_lv0,sid_lv1,name_lv1,start_date_lv1,end_date_lv1,sid2_lv1) 
  SELECT sid_lv0,name_lv0,start_date_lv0,end_date_lv0,sid_lv1,name_lv1,start_date_lv1,end_date_lv1,sid2_lv1
  FROM dm_clant.v_dwh_product_clant;
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_dwh_product_clant".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_dwh_product_clant" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_dwh_product_clant" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_dwh_product_clant" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_product_clant',vMes);
END tb_dwh_product_clant;  

PROCEDURE tb_dwh_abs_dep_clant
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_dwh_abs_dep_clant" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_abs_dep_clant',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_dwh_abs_dep_clant';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_dwh_abs_dep_clant" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_abs_dep_clant',vMes);
  
  INSERT /*+ APPEND */ INTO dm_clant.tb_dwh_abs_dep_clant
   (sid_lv0,name_lv0,code_lv0,start_date_lv0,end_date_lv0,sid_lv1,name_lv1,code_lv1
   ,start_date_lv1,end_date_lv1,source_system_id,bank_name,city,direction_name)
  SELECT sid_lv0,name_lv0,code_lv0,start_date_lv0,end_date_lv0,sid_lv1,name_lv1,code_lv1
        ,start_date_lv1,end_date_lv1,source_system_id,bank_name,city,direction_name
  FROM dm_clant.v_dwh_abs_dep_clant;
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_dwh_abs_dep_clant".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_abs_dep_clant',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_dwh_abs_dep_clant" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_abs_dep_clant',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_dwh_abs_dep_clant" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_abs_dep_clant',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_dwh_abs_dep_clant" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_dwh_abs_dep_clant',vMes);
END tb_dwh_abs_dep_clant;

PROCEDURE mv_ref_contract_top_up
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.mv_ref_contract_top_up" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_contract_top_up',vMes);
  
  dbms_mview.refresh('dm_clant.mv_ref_contract_top_up');
  
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: MView "dm_clant.mv_ref_contract_top_up" refreshed in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime);
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_contract_top_up',vMes);

  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.mv_ref_contract_top_up" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_contract_top_up',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: MView "dm_clant.mv_ref_contract_top_up" refresh failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_contract_top_up',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.mv_ref_contract_top_up" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_contract_top_up',vMes);
END mv_ref_contract_top_up;

PROCEDURE mv_ref_emp_oper_activity_cols
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols',vMes);
  
  dbms_mview.refresh('dm_clant.mv_ref_emp_oper_activity_cols');
  
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: MView "dm_clant.mv_ref_emp_oper_activity_cols" refreshed in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime);
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols',vMes);

  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: MView "dm_clant.mv_ref_emp_oper_activity_cols" refresh failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols',vMes);
END mv_ref_emp_oper_activity_cols;

-- Справочник точек продаж
PROCEDURE mv_department_line
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.mv_department_line" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_department_line',vMes);

  dbms_mview.refresh('dm_clant.mv_department_line');
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.mv_department_line" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_department_line',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: MView "dm_clant.mv_department_line" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_department_line',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.mv_department_line" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.mv_department_line',vMes);
END mv_department_line;

PROCEDURE tb_hist_users
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_hist_users" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_hist_users',vMes);

  MERGE INTO dm_clant.tb_hist_users dest
    USING (SELECT DISTINCT os_user,ip_addr FROM dm_clant.tb_hist WHERE dt BETWEEN TRUNC(SYSDATE-2,'DD') AND SYSDATE) src
     ON (src.os_user = dest.os_user AND src.ip_addr = dest.ip_addr)
    WHEN NOT MATCHED THEN INSERT (dest.os_user,dest.ip_addr) VALUES (src.os_user,src.ip_addr);
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_hist_users" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_hist_users',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: MView "dm_clant.tb_hist_users" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_hist_users',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_hist_users" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_hist_users',vMes);
END tb_hist_users;

-- промежуточные для последующих заливок
PROCEDURE tb_contract_for_update
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_contract_for_update" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_for_update',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_contract_for_update';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_contract_for_update" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_for_update',vMes);
  
  INSERT /*+ APPEND */ 
    INTO dm_clant.tb_contract_for_update (contract_sid)
      SELECT /*+ parallel(3) */
             DISTINCT
             contract_sid
        FROM
      (
      SELECT contract_sid
        FROM dwh.ref_contract c
             LEFT JOIN dwh.ref_contract_type ct 
                       ON ct.contract_type_gid = (c.contract_type_sid - c.source_system_id)/10
                          AND ct.source_system_id = c.source_system_id 
             LEFT JOIN dwh.ref_product_group pg 
                       ON pg.product_group_gid = (ct.product_group_sid - ct.source_system_id)/10
                          AND pg.source_system_id = ct.source_system_id
        WHERE ((c.start_date >= TRUNC(SYSDATE)- 2  AND c.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
                OR
                c.effective_end >= TRUNC(SYSDATE)- 2 AND c.effective_end != to_date('31.12.5999', 'dd.mm.yyyy') AND c.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
                ) 
               OR 
               ct.start_date >= TRUNC(SYSDATE)- 2 AND ct.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
               OR 
               pg.start_date >= TRUNC(SYSDATE)- 2 AND pg.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
              )
      UNION ALL
      SELECT contract_sid
        FROM dwh.ref_contract_spec csp
        WHERE start_date >= TRUNC(SYSDATE)- 2 AND end_date = to_date('31.12.5999', 'dd.mm.yyyy')
      UNION ALL
      SELECT contract_sid 
        FROM dwh.ref_contract
        WHERE client_sid IN (SELECT client_sid FROM dwh.ref_client WHERE start_date >= TRUNC(SYSDATE)- 2 AND end_date = to_date('31.12.5999', 'dd.mm.yyyy'))
      UNION ALL
      SELECT contract_sid
        FROM dwh.ref_contract
        WHERE abs_department_sid IN (SELECT abs_department_sid 
                                       FROM dwh.ref_abs_department ad
                                            LEFT JOIN dwh.ref_branch b
                                                      ON b.br_gid = (ad.branch_sid - ad.source_system_id)/10
                                                         AND b.source_system_id = ad.source_system_id
                                       WHERE ad.start_date >= TRUNC(SYSDATE)- 2 AND ad.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
                                             OR b.start_date >= TRUNC(SYSDATE)- 2 AND b.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
                                                                       
                                    )
      UNION ALL
      SELECT contract_sid
        FROM dwh.ref_contract
        WHERE abs_department_sid IN (SELECT serv_department_sid 
                                       FROM dwh.ref_contract_spec csp
                                            INNER JOIN dwh.ref_abs_department ad 
                                                       ON ad.abs_department_id = csp.serv_department_sid
                                                          AND ad.start_date >= TRUNC(SYSDATE)- 2 AND ad.end_date = to_date('31.12.5999', 'dd.mm.yyyy')
                                                           
                                    ) 
      UNION ALL
      SELECT DISTINCT 
             contract_sid
        FROM dwh.ref_contract
        WHERE client_sid IN (SELECT DISTINCT 
                                    obj_sid AS client_sid
                               FROM dwh.ref_add_param_values apv
                               WHERE apv.obj_type_gid = 8
                                 AND apv.end_date = to_date('31.12.5999','DD.MM.YYYY')
                                 AND apv.start_date BETWEEN TRUNC(SYSDATE-2,'DD') AND SYSDATE
                            )
      )
      ;  
      
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_contract_for_update".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_for_update',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_contract_for_update" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_for_update',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_contract_for_update" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_for_update',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_contract_for_update" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_contract_for_update',vMes);
END tb_contract_for_update;

PROCEDURE tb_client_for_update
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_client_for_update" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_for_update',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_client_for_update';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_client_for_update" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_for_update',vMes);
  
  INSERT /*+ APPEND */ 
    INTO dm_clant.tb_client_for_update (client_sid)
      SELECT DISTINCT 
             client_sid 
        FROM (SELECT /*+ parallel(3)*/
                      client_sid
                 FROM dwh.ref_client
                 WHERE  end_date = to_Date('31.12.5999','DD.MM.YYYY') AND effective_end = to_Date('31.12.5999','DD.MM.YYYY')
                   AND start_date BETWEEN TRUNC(SYSDATE-2) AND SYSDATE
               UNION ALL
               SELECT obj_sid AS client_sid
                 FROM dwh.ref_add_param_values apv
                 WHERE apv.obj_type_gid = 8
                   AND apv.end_date = to_date('31.12.5999','DD.MM.YYYY')
                   AND apv.start_date BETWEEN TRUNC(SYSDATE-2,'DD') AND SYSDATE
               UNION ALL
               SELECT /*+ parallel(3)*/
                      client_sid AS client_sid
                 FROM dwh.ref_client_phones
                 WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
                   AND start_date BETWEEN TRUNC(SYSDATE-2,'DD') AND SYSDATE
               UNION ALL
               SELECT /*+ parallel(3)*/
                      client_sid AS client_sid
                 FROM dwh.ref_client_address
                 WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
                   AND start_date BETWEEN TRUNC(SYSDATE-2,'DD') AND SYSDATE
             )
      ;  
      
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_client_for_update".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_for_update',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_client_for_update" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_for_update',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_client_for_update" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_for_update',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_client_for_update" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_for_update',vMes);
END tb_client_for_update; 
    
PROCEDURE tb_cl_contracts_all
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_cl_contracts_all" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts_all',vMes);
  
  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_cl_contracts';

  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_cl_contracts" truncated';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts_all',vMes);

  INSERT /*+ APPEND*/ INTO dm_clant.tb_cl_contracts
    (categories_id,contract_sid,date_actual,client_sid,contract_gid,source_system_id,contract_no,open_date,
     close_date,close_fact_date,crt_closed_reason,principal,created_by_employee_sid,contract_type_sid,
     employee_sid,effective_start,effective_end,end_date,abs_department_sid,cur_id,loan_quality_cod,
     open_abs_department_sid,delflag,status,comments,org_sid,org_agreement_sid,fst_open_date
    ,principal_eqv,dsa_employee_sid,instrument_id,tag_access_sid
    ,name_access,prolong_count,open_reason_code,open_reason_name,next_contract_type
    ,next_ctr_type_name,crd_claim_sid

    )
  WITH
    o_d AS
      ( 
        SELECT /*+ parallel(3) */
               c.contract_sid
              ,MAX(c.contract_id) KEEP (dense_rank LAST ORDER BY c.effective_start) AS contract_id
              ,MIN(c.abs_department_sid) KEEP (dense_rank FIRST ORDER BY c.effective_start) AS open_abs_department_sid
          FROM dwh.ref_contract c
               --LEFT JOIN dm_clant.v_client_not_load cnl
                -- ON cnl.client_sid = c.client_sid
          WHERE c.end_date = TO_DATE ('31.12.5999', 'dd.mm.yyyy')
            AND (c.categories_id IS NULL 
                 OR 
                 c.categories_id IS NOT NULL 
                   AND NOT(c.categories_id IN (SELECT categories_id FROM dm_clant.v_categories_not_load)))
            --AND NOT(c.client_sid IN (SELECT client_sid FROM dm_clant.v_client_not_load))
            --AND cnl.client_sid IS NULL
        GROUP BY c.contract_sid
      ),
    ol AS (
      SELECT /*+ materialize */
             mbid_sid
            ,MAX(owner_sid) KEEP (dense_rank LAST ORDER BY effective_start) AS owner_sid
        FROM dwh.ref_objects_links
        WHERE end_Date = to_date('31.12.5999','DD.MM.YYYY')
          AND SYSDATE BETWEEN effective_start AND effective_end
          AND (linktype_sid - source_system_id)/10 = 100028
          AND mbid_type = 101
          GROUP BY mbid_sid 
    )
     
    SELECT c.categories_id,
           c.contract_sid,
           TRUNC (SYSDATE) AS date_actual,
           c.client_sid,
           c.contract_gid,
           c.source_system_id,
           c.contract_no,
           c.open_date,
           c.close_date,
           c.close_fact_date,
           NVL(c.crt_closed_reason,c.notes_close) AS crt_closed_reason,
           c.principal,
           c.created_by_employee_sid,
           c.contract_type_sid,
           c.created_by_employee_sid AS employee_sid,
           c.effective_start,
           c.effective_end,
           c.end_date,
           c.abs_department_sid,
           c.cur_id,
           c.loan_quality_cod,
           o_d.open_abs_department_sid,
           /*CASE WHEN clnl.client_sid IS NULL AND cat.categories_id IS NULL
             THEN 0 ELSE 1  
           END*/ 0 AS DelFlag,
           c.status,
           c.comments,
           c.org_sid,
           c.org_agreement_sid,
           c.fst_open_date,
           c.principal*NVL(cr.rate_of_exchange,1) AS principal_eqv,
           --NVL(ol.mbid_sid,ol1.owner_sid) AS dsa_employee_sid
           ol.owner_sid AS dsa_employee_sid,
           c.instrument_id,
           c.tag_access_sid
          ,ca.name_access
          ,c.prolong_count
          ,c.crt_open_reason AS open_reason_code
          ,cst.description AS open_reason_name
          ,c.next_contract_type
          ,nct.contract_type_name AS next_ctr_type_name
          ,c.crd_claim_sid
      FROM o_d
           INNER JOIN dwh.ref_contract c
             ON c.contract_id = o_d.contract_id
           LEFT JOIN dwh.fct_cur_rate cr
             ON cr.cur_rate_date = c.fst_open_date
                AND cr.cur_id = c.cur_id
                AND cr.end_date = to_date('31.12.5999','DD.MM.YYYY')
           LEFT JOIN ol
             ON ol.mbid_sid = c.contract_sid
           LEFT JOIN dwh.ref_contract_access ca
             ON ca.gid_access = (c.tag_access_sid - c.source_system_id)/10
                AND ca.source_system_id = c.source_system_id
                AND ca.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN ca.effective_start AND ca.effective_end
           LEFT JOIN dwh.ref_constants cst
             ON cst.constant_gid = (c.crt_open_reason - c.source_system_id)/10
                AND cst.source_system_id = c.source_system_id
                AND cst.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN cst.effective_start AND cst.effective_end
                AND cst.type_gid = 113
           LEFT JOIN dwh.ref_contract_type nct
             ON nct.contract_type_gid = (c.contract_type_sid - c.source_system_id)/10
                AND nct.source_system_id = c.source_system_id
                AND nct.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN nct.effective_start AND nct.effective_end
  ;
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_cl_contracts".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts_all',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cl_contracts_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts_all',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_cl_contracts" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts_all',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_cl_contracts_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts_all',vMes);
END tb_cl_contracts_all; 

PROCEDURE tb_cl_contracts
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vCou INTEGER := 0;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_cl_contracts" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts',vMes);
  
  -- Проверяем объем обновляемых договоров. Если > 1000000 то делаем полную загрузку
  -- вместо MERGE
  SELECT COUNT(1) INTO vCou FROM dm_clant.tb_contract_for_update;
  
  IF vCou > 100000 
    THEN 
      tb_cl_contracts_all; 
  ELSE
    MERGE INTO dm_clant.tb_cl_contracts dest
    USING
    ( WITH
        o_d AS
          ( 
            SELECT c.contract_sid
                  ,MAX(c.contract_id) KEEP (dense_rank LAST ORDER BY c.effective_start) AS contract_id
                  ,MIN(c.abs_department_sid) KEEP (dense_rank FIRST ORDER BY c.effective_start) AS open_abs_department_sid
             FROM  dwh.ref_contract c
             WHERE c.end_date = TO_DATE ('31.12.5999', 'dd.mm.yyyy')
               AND c.contract_sid IN (SELECT contract_sid FROM dm_clant.tb_contract_for_update) 
            GROUP BY c.contract_sid
          ),
    
        ol AS (
          SELECT /*+ materialize */
                 mbid_sid
                ,MAX(owner_sid) KEEP (dense_rank LAST ORDER BY effective_start) AS owner_sid
            FROM dwh.ref_objects_links
            WHERE end_Date = to_date('31.12.5999','DD.MM.YYYY')
              AND SYSDATE BETWEEN effective_start AND effective_end
              AND (linktype_sid - source_system_id)/10 = 100028
              AND mbid_type = 101
              GROUP BY mbid_sid 
        )
    /*SELECT categories_id,contract_sid,date_actual,client_sid,contract_gid,source_system_id,contract_no,open_date,
           close_date,close_fact_date,crt_closed_reason,principal,created_by_employee_sid,contract_type_sid,
           employee_sid,effective_start,effective_end,end_date,abs_department_sid,cur_id,loan_quality_cod,delflag,
           open_abs_department_sid
      FROM (*/
    SELECT c.categories_id,
           c.contract_sid,
           TRUNC (SYSDATE) AS date_actual,
           c.client_sid,
           c.contract_gid,
           c.source_system_id,
           c.contract_no,
           c.open_date,
           c.close_date,
           c.close_fact_date,
           c.crt_closed_reason,
           c.principal,
           c.created_by_employee_sid,
           c.contract_type_sid,
           c.created_by_employee_sid AS employee_sid,
           c.effective_start,
           c.effective_end,
           c.end_date,
           c.abs_department_sid,
           c.cur_id,
           c.loan_quality_cod,
           --MAX (c.effective_end) OVER (PARTITION BY c.contract_sid) AS m_effective_end,
           CASE WHEN clnl.client_sid IS NULL AND cat.categories_id IS NULL
             THEN 0 ELSE 1  
           END AS  DelFlag,
           o_d.open_abs_department_sid,
           c.status,
           c.comments,
           c.org_sid,
           c.org_agreement_sid,
           c.fst_open_date,
           c.principal*NVL(cr.rate_of_exchange,1) AS principal_eqv,
           --NVL(ol.mbid_sid,ol1.owner_sid) AS dsa_employee_sid
           ol.owner_sid AS dsa_employee_sid,
           c.instrument_id,
           c.tag_access_sid
          ,ca.name_access
          ,c.prolong_count
          ,c.crt_open_reason AS open_reason_code
          ,cst.description AS open_reason_name
          ,c.next_contract_type
          ,nct.contract_type_name AS next_ctr_type_name
          ,c.crd_claim_sid
      FROM o_d
           INNER JOIN dwh.ref_contract c
             ON c.contract_id = o_d.contract_id
           LEFT JOIN dm_clant.v_categories_not_load cat
             ON cat.categories_id = c.categories_id
           LEFT JOIN dm_clant.v_client_not_load clnl
             ON clnl.client_sid = c.client_sid
           LEFT JOIN dwh.fct_cur_rate cr
             ON cr.cur_rate_date = c.fst_open_date
                AND cr.cur_id = c.cur_id
                AND cr.end_date = to_date('31.12.5999','DD.MM.YYYY')
           LEFT JOIN ol
             ON ol.owner_sid = c.contract_sid
           LEFT JOIN dwh.ref_contract_access ca
             ON ca.gid_access = (c.tag_access_sid - c.source_system_id)/10
                AND ca.source_system_id = c.source_system_id
                AND ca.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN ca.effective_start AND ca.effective_end
           LEFT JOIN dwh.ref_constants cst
             ON cst.constant_gid = (c.crt_open_reason - c.source_system_id)/10
                AND cst.source_system_id = c.source_system_id
                AND cst.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN cst.effective_start AND cst.effective_end
                AND cst.type_gid = 113
           LEFT JOIN dwh.ref_contract_type nct
             ON nct.contract_type_gid = (c.contract_type_sid - c.source_system_id)/10
                AND nct.source_system_id = c.source_system_id
                AND nct.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN nct.effective_start AND nct.effective_end
    ) src ON (dest.contract_sid = src.contract_sid)
    WHEN NOT MATCHED THEN
      INSERT (dest.categories_id,dest.contract_sid,dest.date_actual,dest.client_sid,dest.contract_gid
             ,dest.source_system_id,dest.contract_no,dest.open_date,dest.close_date,dest.close_fact_date
             ,dest.crt_closed_reason,dest.principal,dest.created_by_employee_sid,dest.contract_type_sid
             ,dest.employee_sid,dest.effective_start,dest.effective_end,dest.end_date,dest.abs_department_sid
             ,dest.cur_id,dest.loan_quality_cod,dest.open_abs_department_sid,dest.delflag
             ,dest.status,dest.comments,dest.org_sid,dest.org_agreement_sid,dest.fst_open_date
             ,dest.principal_eqv,dest.dsa_employee_sid,dest.instrument_id,dest.tag_access_sid
             ,dest.name_access
             ,dest.prolong_count
             ,dest.open_reason_code
             ,dest.open_reason_name
             ,dest.next_contract_type
             ,dest.next_ctr_type_name
             ,dest.crd_claim_sid
             )
      VALUES (src.categories_id,src.contract_sid,src.date_actual,src.client_sid,src.contract_gid,src.source_system_id
             ,src.contract_no,open_date,src.close_date,src.close_fact_date,src.crt_closed_reason,src.principal
             ,src.created_by_employee_sid,src.contract_type_sid,src.employee_sid,src.effective_start,src.effective_end
             ,src.end_date,src.abs_department_sid,src.cur_id,src.loan_quality_cod,src.open_abs_department_sid
             ,src.delflag,src.status,src.comments,src.org_sid,src.org_agreement_sid,src.fst_open_date
             ,src.principal_eqv,src.dsa_employee_sid,src.instrument_id,src.tag_access_sid
             ,src.name_access
             ,src.prolong_count
             ,src.open_reason_code
             ,src.open_reason_name
             ,src.next_contract_type
             ,src.next_ctr_type_name
             ,src.crd_claim_sid
             )
      WHERE src.delflag = 0       
    WHEN MATCHED THEN
      UPDATE SET dest.categories_id = src.categories_id
                --,dest.contract_sid  = src.contract_sid
                ,dest.date_actual = src.date_actual
                ,dest.client_sid = src.client_sid
                ,dest.contract_gid = src.contract_gid
                ,dest.source_system_id = src.source_system_id
                ,dest.contract_no = src.contract_no
                ,dest.open_date = src.open_date
                ,dest.close_date = src.close_date
                ,dest.close_fact_date = src.close_fact_date
                ,dest.crt_closed_reason = src.crt_closed_reason
                ,dest.principal = src.principal
                ,dest.created_by_employee_sid = src.created_by_employee_sid
                ,dest.contract_type_sid = src.contract_type_sid
                ,dest.employee_sid = src.employee_sid
                ,dest.effective_start = src.effective_start
                ,dest.effective_end = src.effective_end
                ,dest.end_date = src.end_date
                ,dest.abs_department_sid = src.abs_department_sid
                ,dest.cur_id = src.cur_id
                ,dest.loan_quality_cod = src.loan_quality_cod
                ,dest.open_abs_department_sid = src.open_abs_department_sid
                ,dest.delflag = src.delflag
                ,dest.status = src.status
                ,dest.comments = src.comments
                ,dest.org_sid = src.org_sid
                ,dest.org_agreement_sid = src.org_agreement_sid
                ,dest.fst_open_date = src.fst_open_date
                ,dest.principal_eqv = src.principal_eqv
                ,dest.dsa_employee_sid = src.dsa_employee_sid
                ,dest.instrument_id = src.instrument_id
                ,dest.tag_access_sid = src.tag_access_sid
                ,dest.name_access = src.name_access
                ,dest.prolong_count = src.prolong_count
                ,dest.open_reason_code = src.open_reason_code
                ,dest.open_reason_name = src.open_reason_name
                ,dest.next_contract_type = src.next_contract_type
                ,dest.next_ctr_type_name = src.next_ctr_type_name
                ,dest.crd_claim_sid = src.crd_claim_sid
      DELETE WHERE dest.delflag = 1
    ;
    
    vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_cl_contracts".';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts',vMes);
  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cl_contracts" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_cl_contracts" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_cl_contracts" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_contracts',vMes);
END tb_cl_contracts;                                 

PROCEDURE tb_cl_credits_all
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_cl_credits_all" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_credits_all',vMes);
  
  -- Все кредиты
  MERGE INTO dm_clant.tb_cl_credits dest
    USING (
       SELECT contract_sid,contract_gid,source_system_id FROM (
          SELECT ac.contract_sid
                ,TRUNC(ac.contract_sid/10) AS contract_gid
                ,ac.source_system_id
            FROM dwh.ref_account_to_contract ac
            WHERE ac.end_date = to_date('31.12.5999','DD.MM.YYYY')
              AND TRUNC(ac.link_type_sid/10) in (2, 3, 4, 5, 14, 23, 24, 1576, 1577, 992)
          UNION ALL
          SELECT contract_gid*10+source_system_id
                ,contract_gid
                ,source_system_id
            FROM dwh.ref_contract_new
            WHERE column_name = 'INSTRUMENT_ID'
              AND end_date = to_date('31.12.5999','DD.MM.YYYY')
              AND val_num = 1
       ) GROUP BY contract_sid,contract_gid,source_system_id
    ) src ON (dest.contract_sid = src.contract_sid)
    WHEN NOT MATCHED THEN
      INSERT (dest.contract_sid,dest.contract_gid,dest.source_system_id)
        VALUES(src.contract_sid,src.contract_gid,src.source_system_id);
        
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_cl_credits".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_credits_all',vMes);

  -- Закрытые кредиты (все даты закрытия, т.к. их может быть на одном договоре несколько)
  MERGE INTO dm_skb.tb_cl_credits_closed dest
    USING (
      SELECT c.contract_gid
            ,c.source_system_id
            ,c.contract_gid*10+c.source_system_id AS contract_sid
            ,MAX(c.val_date) KEEP (dense_rank LAST ORDER BY c.effective_start) AS close_fact_date
            ,TRUNC(MAX(cl.val_num) KEEP (dense_rank LAST ORDER BY c.effective_start)/10) AS client_gid
            ,MAX(cl.val_num) KEEP (dense_rank LAST ORDER BY c.effective_start) AS client_sid
            ,MAX(a.val_num) KEEP (dense_rank LAST ORDER BY c.effective_start) AS abs_department_sid
        FROM dwh.ref_contract_new c
             INNER JOIN dm_clant.tb_cl_credits cr
               ON cr.contract_gid = c.contract_gid
                  AND cr.source_system_id = c.source_system_id
             INNER JOIN dwh.ref_contract_new cl
               ON cl.column_name = 'CLIENT_SID'
                  AND cl.end_date = to_date('31.12.5999','DD.MM.YYYY')
                  AND cl.contract_gid = c.contract_gid
                  AND cl.source_system_id = c.source_system_id
                  AND c.val_date BETWEEN cl.effective_start AND cl.effective_end
             INNER JOIN dwh.ref_contract_new a
               ON a.column_name = 'ABS_DEPARTMENT_SID'
                  AND a.end_date = to_date('31.12.5999','DD.MM.YYYY')
                  AND a.contract_gid = c.contract_gid
                  AND a.source_system_id = c.source_system_id
                  AND c.val_date BETWEEN a.effective_start AND a.effective_end
        WHERE c.column_name = 'CLOSE_FACT_DATE'
          AND c.end_date = to_date('31.12.5999','DD.MM.YYYY')
          AND c.val_date IS NOT NULL   
      GROUP BY c.contract_gid,c.source_system_id,c.val_date
    ) src ON (dest.contract_gid = src.contract_gid AND dest.source_system_id = src.source_system_id AND dest.close_fact_date = src.close_fact_date)
    WHEN MATCHED THEN
      UPDATE SET dest.contract_sid = src.contract_sid
                ,dest.client_gid = src.client_gid
                ,dest.client_sid = src.client_sid
                ,dest.abs_department_sid = src.abs_department_sid
        WHERE dwh.pkg_normalize_ref_table.isEqual(dest.contract_sid,src.contract_sid) = 0 OR
              dwh.pkg_normalize_ref_table.isEqual(dest.client_gid,src.client_gid) = 0 OR
              dwh.pkg_normalize_ref_table.isEqual(dest.client_sid,src.client_sid) = 0 OR
              dwh.pkg_normalize_ref_table.isEqual(dest.abs_department_sid,src.abs_department_sid) = 0
    WHEN NOT MATCHED THEN
      INSERT (dest.contract_gid,dest.source_system_id,dest.contract_sid,dest.close_fact_date
             ,dest.client_gid,dest.client_sid,dest.abs_department_sid)
        VALUES (src.contract_gid,src.source_system_id,src.contract_sid,src.close_fact_date
               ,src.client_gid,src.client_sid,src.abs_department_sid);
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_skb.tb_cl_credits_closed".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_credits_all',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cl_credits_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_credits_all',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_cl_credits" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_credits_all',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_cl_credits_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cl_credits_all',vMes);
END tb_cl_credits_all;

PROCEDURE tb_account_to_credit_all
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_account_to_credit_all" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_account_to_credit_all',vMes);

  MERGE INTO dm_skb.tb_account_to_credit dest
  USING (
    WITH
      b AS (
        SELECT /*+ no_index(ctr) no_index(a2c) */
               a2c.account_sid,
               a2c.contract_sid,
               a2c.source_system_id,
               a2c.link_type_sid
          FROM dm_clant.tb_cl_credits ctr
               INNER JOIN dwh.ref_account_to_contract a2c
                  ON a2c.end_date = to_date('31.12.5999', 'DD.MM.YYYY')
                     AND a2c.contract_sid = ctr.contract_sid
                     AND SYSDATE BETWEEN a2c.effective_start AND a2c.effective_end
        UNION ALL
        SELECT /*+ no_index(ctr) no_index(a2c) */
               a2c.account_sid,
               a2c.contract_sid,
               a2c.source_system_id,
               a2c.link_type_sid
          FROM dm_clant.tb_cl_credits ctr
               INNER JOIN dwh.ref_account_to_contract2 a2c
                  ON a2c.end_date = to_date('31.12.5999', 'DD.MM.YYYY')
                     AND a2c.contract_sid = ctr.contract_sid
                     AND SYSDATE BETWEEN a2c.effective_start AND a2c.effective_end
      )
     ,a AS
       (SELECT account_gid,
               source_system_id,
               val_str AS account_number,
               SUBSTR(TRIM(val_str),1,5) AS bal_account_id
          FROM dwh.ref_account_new a
         WHERE a.column_name = 'ACCOUNT_NUMBER'
           AND end_date = to_date('31.12.5999', 'DD.MM.YYYY')
           AND SYSDATE BETWEEN a.effective_start AND a.effective_end
           AND NOT (val_str LIKE ('%*%'))
        )
      SELECT b.account_sid,b.contract_sid,b.source_system_id,b.link_type_sid,a.account_number,a.bal_account_id
        FROM b INNER JOIN a ON a.account_gid = TRUNC(b.account_sid/10) AND a.source_system_id = b.source_system_id
  ) src ON (src.account_sid = dest.account_sid AND src.contract_sid = dest.contract_sid AND src.link_type_sid = dest.link_type_sid)
  WHEN MATCHED THEN
    UPDATE SET dest.account_number = src.account_number
              ,dest.bal_account_id = src.bal_account_id
      WHERE dwh.pkg_normalize_ref_table.isequal(dest.account_number,src.account_number) = 0
            OR dwh.pkg_normalize_ref_table.isequal(dest.bal_account_id,src.bal_account_id) = 0
  WHEN NOT MATCHED THEN
    INSERT (dest.account_sid,dest.contract_sid,dest.source_system_id,dest.link_type_sid,dest.account_number,dest.bal_account_id)          
      VALUES (src.account_sid,src.contract_sid,src.source_system_id,src.link_type_sid,src.account_number,src.bal_account_id);

  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_skb.tb_account_to_credit"';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_account_to_credit_all',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_account_to_credit_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_account_to_credit_all',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_account_to_credit_all" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_account_to_credit_all',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_rep_aggr.tb_account_to_credit_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_account_to_credit_all',vMes);
END tb_account_to_credit_all;

PROCEDURE contr_2_prod_closed
  (inBegDate IN DATE, inEndDate IN DATE)
  IS  
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
    vTIBegin DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.contr_2_prod_closed" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_closed',vMes);
  
  FOR idx IN 0..inEndDate-inBegDate
  LOOP
    vTIBegin := SYSDATE;
    MERGE
    INTO dm_clant.tb_ref_contract_2_product dest 
    USING (
      SELECT /*+ leading(dm) */
                    dm.contract_sid,
                    inBegDate + idx AS close_fact_date,
                    SUBSTR(MAX(dm.dim_key),2,6) AS p_id
               FROM SKB_ECC.ECC_DM_1 dm
                    INNER JOIN dwh.ref_contract_new ctr
                      ON ctr.column_name = 'CLOSE_FACT_DATE'
                         AND ctr.end_date = to_date('31.12.5999','DD.MM.YYYY')
                         AND ctr.contract_gid = TRUNC(dm.contract_sid/10)
                         AND ctr.source_system_id = MOD(dm.contract_sid,10)
                         AND inBegDate + idx BETWEEN ctr.effective_start AND ctr.effective_end
                         AND ctr.val_date = inBegDate + idx
              WHERE dm.as_of_date = inBegDate + idx
                AND DIM_KEY IN (SUBSTR(DIM_KEY, 1, 10) || 'AMOUNT_EQV>2')
              GROUP BY CONTRACT_SID
    ) src ON (dest.contract_sid = src.contract_sid)
    WHEN MATCHED THEN
      UPDATE SET dest.close_fact_date = src.close_fact_date,
                 dest.p_id = src.p_id
                --,dest.stock_value = src.stock_value
    WHEN NOT MATCHED THEN
      INSERT (dest.contract_sid,dest.close_fact_date,dest.p_id--,dest.stock_value
      )
        VALUES (src.contract_sid,src.close_fact_date,src.p_id--,src.stock_value
        );

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDate+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_ref_contract_2_product" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_closed',vMes);
  END LOOP;
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.contr_2_prod_closed" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_closed',vMes);
EXCEPTION
  WHEN OTHERS THEN                                        
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Procedure "dm_clant.pkg_etl.contr_2_prod_closed" :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_closed',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.contr_2_prod_closed" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_closed',vMes);
END contr_2_prod_closed;

PROCEDURE contr_2_prod_opened
  IS  
    vMes VARCHAR2(2000);
    vMaxDM1dt DATE;
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.contr_2_prod_opened" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_opened',vMes);
  
  -- Получаем максимальную дату загруженных данных
  SELECT to_date(SUBSTR(MAX(partition_name),2,LENGTH(MAX(partition_name))-1),'YYYYMMDD') INTO vMaxDM1dt
    FROM sys.dba_segments
    WHERE owner = 'SKB_ECC' AND segment_name = 'ECC_DM_1' 
      AND segment_type = 'TABLE PARTITION';  

  MERGE INTO dm_clant.tb_ref_contract_2_product dest
    USING (
      SELECT /*+ leading(dm) */
                    dm.contract_sid,
                    to_date('31.12.5999','DD.MM.YYYY') AS close_fact_date,
                    SUBSTR(MAX(dm.dim_key),2,6) AS p_id
               FROM SKB_ECC.ECC_DM_1 dm
                    INNER JOIN dwh.ref_contract_new ctr
                      ON ctr.column_name = 'CLOSE_FACT_DATE'
                         AND ctr.end_date = to_date('31.12.5999','DD.MM.YYYY')
                         AND ctr.contract_gid = TRUNC(dm.contract_sid/10)
                         AND ctr.source_system_id = MOD(dm.contract_sid,10)
                         AND vMaxDM1dt BETWEEN ctr.effective_start AND ctr.effective_end
                         AND ctr.val_date IS NULL
              WHERE dm.as_of_date = vMaxDM1dt
                AND DIM_KEY IN (SUBSTR(DIM_KEY, 1, 10) || 'AMOUNT_EQV>2')
              GROUP BY CONTRACT_SID





    /*SELECT contract_sid, to_date('31.12.5999','DD.MM.YYYY') AS close_fact_date
          ,skb_ecc.get_dim(MAX(dim_key),1) p_id
      FROM  skb_ecc.ecc_dm_1
      WHERE as_of_date = vMaxDM1dt
        AND contract_sid IN  (SELECT contract_sid
                                FROM dwh.ref_contract c
                                WHERE end_date = TO_DATE ('31.12.5999', 'dd.mm.yyyy')
                                  AND effective_end = TO_DATE ('31.12.5999', 'dd.mm.yyyy')
                                  AND close_fact_date IS NULL
                           )
        AND dim_key IN (SUBSTR(dim_key,1,10)||'AMOUNT_EQV>2')
    GROUP BY contract_sid*/
    
    ) src ON (src.contract_sid = dest.contract_sid)
    WHEN MATCHED THEN
      UPDATE SET dest.close_fact_date = src.close_fact_date,
                 dest.p_id = src.p_id--,dest.stock_value = src.stock_value
    WHEN NOT MATCHED THEN
      INSERT (dest.contract_sid,dest.close_fact_date,dest.p_id--,dest.stock_value
      )
        VALUES (src.contract_sid,src.close_fact_date,src.p_id--,src.stock_value
        );
  
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_ref_contract_2_product" in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime);
  dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_opened',vMes);

  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.contr_2_prod_opened" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_opened',vMes);
EXCEPTION
  WHEN OTHERS THEN                                        
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Procedure "dm_clant.pkg_etl.contr_2_prod_opened" :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_opened',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.contr_2_prod_opened" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.contr_2_prod_opened',vMes);
END contr_2_prod_opened;

PROCEDURE ptb_pre_limits_cl_clm (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_pre_limits_cl_clm" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_pre_limits_cl_clm truncate partition P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_cl_clm" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_pre_limits_cl_clm
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_cl_clm" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);

    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.ptb_pre_limits_cl_clm
      (as_of_date,client_sid,date_create,income_db,income_contr,income
      ,income_notnull,have_spouse,dependent_count,claim_status_sid,income_2ndfl)
    SELECT as_of_date,client_sid,date_create,income_db,income_contr,income
          ,income_notnull,have_spouse,dependent_count,claim_status_sid,income_2ndfl
      FROM TABLE(dm_clant.pkg_etl_gets.get_pre_limits_cl_clm(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_pre_limits_cl_clm" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_cl_clm MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_cl_clm" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_pre_limits_cl_clm" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_cl_clm" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_clm',vMes);
END ptb_pre_limits_cl_clm; 

PROCEDURE ptb_pre_limits_cl (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_pre_limits_cl" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_cl TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_cl" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_pre_limits_cl
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_cl" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);

    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.ptb_pre_limits_cl
      (as_of_date,client_sid,income_cl,have_spouse,have_spouse_job,dependent_count
      ,nvpv_date,nvpv_income,nvpv_limit,personal_offer_sum,ndfl2_gived)
    SELECT as_of_date,client_sid,income_cl,have_spouse,have_spouse_job,dependent_count
          ,nvpv_date,nvpv_income,nvpv_limit,personal_offer_sum,ndfl2_gived
      FROM TABLE(dm_clant.pkg_etl_gets.get_pre_limits_cl(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_pre_limits_cl_clm" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_cl MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_cl" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_pre_limits_cl" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_cl" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl',vMes);
END ptb_pre_limits_cl; 

PROCEDURE tb_fpd_spd_tpd_all
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.tb_fpd_spd_tpd_all" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_all',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_fpd_spd_tpd';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_fpd_spd_tpd" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_all',vMes);

  vTIBegin := SYSDATE;
  INSERT /*+ APPEND */ INTO dm_clant.tb_fpd_spd_tpd dest 
    (contract_sid,lifo_dt,payment_number,lifo_value,rk_flg,lifo_value_cfd
    ,close_fact_date,benefit_cou)
    WITH
      ctr_rk AS (
        SELECT /*+ materialize */
               ctr_old.contract_sid AS contract_sid
          FROM (SELECT obj_gid,add_param_value,source_system_id
                  FROM dwh.ref_add_param_values apv312
                  WHERE apv312.obj_type_gid = 190 /*заявка*/
                    AND apv312.add_param_gid = 277
                    AND apv312.rec_number = 0
                    AND apv312.parent_rec_number = 0
                    AND apv312.end_date = to_date('31.12.5999','DD.MM.YYYY')
                    AND SYSDATE BETWEEN apv312.effective_start AND apv312.effective_end
               ) ctr_nums_rk
               LEFT JOIN dm_clant.tb_cl_contracts ctr_old
                 ON ctr_old.source_system_id = ctr_nums_rk.source_system_id
                    AND ctr_old.contract_no = ctr_nums_rk.add_param_value       
               LEFT JOIN dwh.ref_crd_claim clm
                 ON clm.crd_claim_gid = ctr_nums_rk.obj_gid
                    AND clm.source_system_id = ctr_nums_rk.source_system_id
                    AND clm.end_date = to_date('31.12.5999','DD.MM.YYYY')
                    AND SYSDATE BETWEEN clm.effective_start AND clm.effective_end
               LEFT JOIN dm_clant.tb_cl_contracts ctr_new
                 ON ctr_new.contract_sid = clm.contract_sid
          WHERE (ctr_new.contract_type_sid-ctr_new.source_system_id)/10 IN (1290,1291)
      )
    SELECT a.contract_sid 
          ,a.lifo_dt
          ,MAX(pr.payment_number) AS payment_number
          ,0 lifo_value
          ,NVL2(ctr_rk.contract_sid,1,0) AS rk_flg
          ,0 lifo_value_cfd
          ,a.close_fact_date
          --,a.principal
          ,NVL(pr.benefit_cou,0) AS benefit_cou
      FROM (SELECT DISTINCT
                   l.contract_gid*10+l.source_system_id AS contract_sid
                  ,l.delinquency_date AS lifo_dt
                  ,ctr.close_fact_date
                  --,ctr.principal*NVL(cr.rate_of_exchange,1) AS principal
              FROM dwh.ref_credit_exp_dates_days_lifo l
                   LEFT JOIN dm_clant.tb_cl_contracts ctr
                     ON ctr.contract_sid = l.contract_gid*10+l.source_system_id
                   /*LEFT JOIN dwh.fct_cur_rate cr
                     ON cr.cur_rate_date = ctr.fst_open_date
                        AND cr.cur_id = ctr.cur_id
                        AND cr.end_date = to_date('31.12.5999','DD.MM.YYYY')*/
            ) a
            INNER JOIN dm_clant.tb_fpd_spd_tpd_prev pr
              ON pr.contract_sid = a.contract_sid
                 AND pr.lifo_dt = a.lifo_dt
            /*INNER JOIN dwh.ref_plan_pays pp
              ON pp.contract_sid = a.contract_sid
                 AND pp.end_date = to_date('31.12.5999','DD.MM.YYYY')
                 AND pp.date_pays = a.lifo_dt
                 AND SYSDATE BETWEEN pp.effective_start AND pp.effective_end
                 AND payment_number IN (1,2,3)*/
            LEFT JOIN ctr_rk
              ON ctr_rk.contract_sid = a.contract_sid
            GROUP BY a.contract_sid 
                    ,a.lifo_dt
                    ,ctr_rk.contract_sid
                    ,a.close_fact_date
                    --,a.principal
                    ,pr.benefit_cou
  ;
    
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_fpd_spd_tpd" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_all',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_all',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_fpd_spd_tpd" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_all',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_all" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_all',vMes);
END tb_fpd_spd_tpd_all;

PROCEDURE tb_fpd_spd_tpd_prev
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.tb_fpd_spd_tpd_prev" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_prev',vMes);

  vTIBegin := SYSDATE;
  MERGE INTO dm_clant.tb_fpd_spd_tpd_prev dest USING
    (
      WITH 
        bf AS (
          SELECT /*+ materialize */
                 obj_sid AS contract_type_sid
                ,to_number(add_param_value) AS benefit_cou
            FROM dwh.ref_add_param_values apv
            WHERE apv.obj_type_gid = 170 /*Тип договора*/
              AND apv.add_param_gid = 129 /*Кол-во отложенных платежей*/
              AND apv.rec_number = 0
              AND apv.parent_rec_number = 0
              AND apv.end_date = to_date('31.12.5999','DD.MM.YYYY')
              AND SYSDATE BETWEEN apv.effective_start AND apv.effective_end
              AND apv.obj_sid > 0
        ),    
        d AS
          ( SELECT DISTINCT
                   (rcs.contract_gid*10+rcs.source_system_id) AS contract_sid
                              --,rcs.delinquency_date AS lifo_dt
                              ,least(COALESCE(rcs.delinquency_date, rcs.delinquency_interest_date),COALESCE(rcs.delinquency_interest_date, rcs.delinquency_date)) AS lifo_dt
                              ,ctr.contract_type_sid
                          FROM dwh.ref_credit_exp_dates_days_lifo rcs
                               LEFT JOIN dm_clant.tb_cl_contracts ctr
                                 ON ctr.contract_sid = rcs.contract_gid*10+rcs.source_system_id
                           WHERE (rcs.contract_gid*10+rcs.source_system_id) 
                                 IN ( SELECT c2p.contract_sid 
                                        FROM dm_clant.tb_ref_contract_2_product c2p
                                        WHERE c2p.p_id IN (SELECT id_lv4 
                                                             FROM dm_skb.mv_rep_product_dim
                                                             WHERE id_lv0 = 4919561 -- Иерархия статей управленческого учета
                                                               AND name_lv1 = 'Активы' 
                                                               AND name_lv2 IN ('Потребительское кредитование','Ипотечное кредитование')
                                                               AND NOT(name_lv4 IN ('Кредитная карта VISA','Овердрафт','Старый овердрафт'))
                                                          )
                                    )
                             AND NVL(ctr.fst_open_date,ctr.open_date) >= to_date('01.01.2014','DD.MM.YYYY')       
                             --AND rcs.delinquency_date IS NOT NULL
                             AND (rcs.delinquency_date IS NOT NULL or rcs.delinquency_interest_date IS NOT NULL)
                             AND rcs.delinquency_date >= TRUNC(SYSDATE-4,'DD')
                             --AND rcs.contract_gid*10+rcs.source_system_id = 106723612
          ) 
    SELECT 
    distinct 
    contract_sid,
    min(lifo_dt) over (partition by contract_sid, payment_number) lifo_dt,
    payment_number,
    date_pays,
    benefit_cou
    FROM (
    SELECT d.contract_sid
          ,d.lifo_dt
          ,MAX(pp.payment_number) - MAX(NVL(bf.benefit_cou,0)) - CASE WHEN pp.source_system_id IN (1,3) THEN 1 ELSE 0 END AS payment_number
          ,MAX(pp.date_pays) AS date_pays
          ,MAX(NVL(bf.benefit_cou,0)) AS benefit_cou
      FROM d
           LEFT JOIN bf 
             ON bf.contract_type_sid = d.contract_type_sid
           INNER JOIN dwh.ref_plan_pays pp
             ON pp.contract_sid = d.contract_sid
                AND pp.date_pays <= d.lifo_dt
                AND pp.end_date = to_date('31.12.5999','DD.MM.YYYY')
                AND SYSDATE BETWEEN pp.effective_start AND pp.effective_end
            GROUP BY d.contract_sid,d.lifo_dt,pp.source_system_id
         ) WHERE payment_number BETWEEN 1 AND 3
      ) src ON (dest.contract_sid = src.contract_sid AND dest.lifo_dt = src.lifo_dt)
    WHEN MATCHED THEN UPDATE SET dest.payment_number = src.payment_number
                                ,dest.date_pays = src.date_pays
                                ,dest.benefit_cou = src.benefit_cou
    WHEN NOT MATCHED THEN INSERT (dest.contract_sid,dest.lifo_dt,dest.payment_number,dest.date_pays,dest.benefit_cou)
                            VALUES (src.contract_sid,src.lifo_dt,src.payment_number,src.date_pays,src.benefit_cou);
      
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_fpd_spd_tpd_prev" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_prev',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_prev" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_prev',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_fpd_spd_tpd_prev" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_prev',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_prev" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_prev',vMes);
END tb_fpd_spd_tpd_prev;

PROCEDURE tb_fpd_spd_tpd
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.tb_fpd_spd_tpd" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd',vMes);

  vTIBegin := SYSDATE;
  MERGE INTO dm_clant.tb_fpd_spd_tpd dest
  USING ( WITH
            ctr_rk AS (
              SELECT /*+ materialize */
                     ctr_old.contract_sid AS contract_sid
                FROM (SELECT obj_gid,add_param_value,source_system_id
                        FROM dwh.ref_add_param_values apv312
                        WHERE apv312.obj_type_gid = 190 /*заявка*/
                          AND apv312.add_param_gid = 277
                          AND apv312.rec_number = 0
                          AND apv312.parent_rec_number = 0
                          AND apv312.end_date = to_date('31.12.5999','DD.MM.YYYY')
                          AND SYSDATE BETWEEN apv312.effective_start AND apv312.effective_end
                     ) ctr_nums_rk
                     LEFT JOIN dm_clant.tb_cl_contracts ctr_old
                       ON ctr_old.source_system_id = ctr_nums_rk.source_system_id
                          AND ctr_old.contract_no = ctr_nums_rk.add_param_value       
                     LEFT JOIN dwh.ref_crd_claim clm
                       ON clm.crd_claim_gid = ctr_nums_rk.obj_gid
                          AND clm.source_system_id = ctr_nums_rk.source_system_id
                          AND clm.end_date = to_date('31.12.5999','DD.MM.YYYY')
                          AND SYSDATE BETWEEN clm.effective_start AND clm.effective_end
                     LEFT JOIN dm_clant.tb_cl_contracts ctr_new
                       ON ctr_new.contract_sid = clm.contract_sid
                WHERE (ctr_new.contract_type_sid-ctr_new.source_system_id)/10 IN (1290,1291)
            )
          SELECT pr.contract_sid 
                ,pr.lifo_dt
                ,MAX(pr.payment_number) AS payment_number
                ,0 lifo_value
                ,NVL2(ctr_rk.contract_sid,1,0) AS rk_flg
                ,0 lifo_value_cfd
                ,ctr.close_fact_date
                ,NVL(pr.benefit_cou,0) AS benefit_cou
            FROM
          dm_clant.tb_fpd_spd_tpd_prev pr
          INNER JOIN dm_clant.tb_cl_contracts ctr
            ON ctr.contract_sid = pr.contract_sid
          LEFT JOIN ctr_rk
            ON ctr_rk.contract_sid = pr.contract_sid
          GROUP BY pr.contract_sid 
                  ,pr.lifo_dt
                  ,ctr_rk.contract_sid
                  ,ctr.close_fact_date
                  ,pr.benefit_cou
        ) src
  ON (dest.contract_sid = src.contract_sid AND dest.payment_number = src.payment_number)
  WHEN NOT MATCHED THEN
    INSERT (dest.contract_sid,dest.lifo_dt,dest.payment_number,dest.lifo_value
           ,dest.rk_flg,dest.benefit_cou,dest.close_fact_date)
      VALUES (src.contract_sid,src.lifo_dt,src.payment_number,src.lifo_value
             ,src.rk_flg,src.benefit_cou,src.close_fact_date)
  WHEN MATCHED THEN UPDATE SET dest.lifo_dt = src.lifo_dt
                              ,dest.rk_flg = src.rk_flg
                              ,dest.benefit_cou = src.benefit_cou
                              ,dest.close_fact_date = src.close_fact_date
                      WHERE NVL(dest.lifo_dt,to_date('31.12.5999','DD.MM.YYYY')) != NVL(src.lifo_dt,to_date('31.12.5999','DD.MM.YYYY')) OR
                            NVL(dest.rk_flg,0) != NVL(src.rk_flg,0) OR
                            NVL(dest.benefit_cou,0) != NVL(src.benefit_cou,0) OR
                            NVL(dest.close_fact_date,to_date('31.12.5999','DD.MM.YYYY')) != NVL(src.close_fact_date,to_date('31.12.5999','DD.MM.YYYY'))
  ;
    
  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows merged into table "dm_clant.tb_fpd_spd_tpd" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_fpd_spd_tpd" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd',vMes);
END tb_fpd_spd_tpd;

PROCEDURE tb_fpd_spd_tpd_update (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
    vCou INTEGER := 0;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.tb_fpd_spd_tpd_update" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_update',vMes);

  FOR idx IN 0..vDays
  LOOP

    vTIBegin := SYSDATE;
    FOR a IN (SELECT as_of_date,contract_sid,SUM(stock_value) AS stock_value
                FROM (
                  SELECT inBegDt+idx-1 AS as_of_date
                        ,f.obj_gid*10+f.source_system_id AS contract_sid
                        ,to_number(f.sign_val, 'FM999999999999999D999999999', 'nls_numeric_characters='', ''') AS stock_value
                    FROM dm_skb.ptb_ctr_signs_new f
                    WHERE f.as_of_date = inBegDt+idx-1
                      AND (obj_gid,source_system_id) IN (SELECT TRUNC(contract_sid/10),MOD(contract_sid,10)
                                              FROM dm_clant.tb_fpd_spd_tpd
                                              WHERE lifo_dt = inBegDt+idx
                                              --  AND rk_flg = 1
                                              -- SD 1312466 Целищев
                                              -- Это условие ранее было только для LIFO_VALUE_CFD
                                              -- а добавлено Евгением при переходе на новые таблицы показателей
                                          )
                      --AND dim_key IN (SUBSTR(dim_key,1,10)||'AMOUNT_EQV>2',SUBSTR(dim_key,1,10)||'OVERDUE_PRINCIPAL_EQV>2')
                      AND f.sign_name = 'AMOUNT_EQV'
                  UNION ALL
                  SELECT inBegDt+idx-1 AS as_of_date
                        ,obj_gid*10+source_system_id AS contract_sid
                        ,to_number(sign_val,'FM999999999999999D999999999','nls_numeric_characters='', ''')
                    FROM dm_skb.tb_ctr_signs_new
                    WHERE sign_name = 'OVERDUE_PRINCIPAL_EQV'
                      AND inBegDt+idx-1 BETWEEN effective_start AND effective_end
                      AND (obj_gid,source_system_id) IN (SELECT TRUNC(contract_sid/10),MOD(contract_sid,10)
                                              FROM dm_clant.tb_fpd_spd_tpd
                                              WHERE lifo_dt = inBegDt+idx
                                              --  AND rk_flg = 1
                                              -- SD 1312466 Целищев
                                              -- Это условие ранее было только для LIFO_VALUE_CFD
                                              -- а добавлено Евгением при переходе на новые таблицы показателей
                                          )
                ) GROUP BY as_of_date,contract_sid
             )
    LOOP
      UPDATE dm_clant.tb_fpd_spd_tpd SET lifo_value = a.stock_value
        WHERE contract_sid = a.contract_sid AND lifo_dt = a.as_of_date+1;
      vCou := vCou + 1;  
    END LOOP;

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: LIFO_VALUE "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||vCou||' rows updated in table "dm_clant.tb_fpd_spd_tpd" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_update',vMes);
    
    vTIBegin := SYSDATE;
    FOR a IN (SELECT as_of_date,contract_sid,SUM(stock_value) AS stock_value
                FROM (
                  SELECT inBegDt+idx-1 AS as_of_date
                        ,f.obj_gid*10+f.source_system_id AS contract_sid
                        ,to_number(f.sign_val, 'FM999999999999999D999999999', 'nls_numeric_characters='', ''') AS stock_value
                    FROM dm_skb.ptb_ctr_signs_new f
                    WHERE f.as_of_date = inBegDt+idx-1
                      AND (obj_gid,source_system_id) IN (SELECT TRUNC(contract_sid/10),MOD(contract_sid,10)
                                              FROM dm_clant.tb_fpd_spd_tpd
                                              WHERE close_fact_date = inBegDt+idx
                                                AND rk_flg = 1
                                          )
                      --AND dim_key IN (SUBSTR(dim_key,1,10)||'AMOUNT_EQV>2',SUBSTR(dim_key,1,10)||'OVERDUE_PRINCIPAL_EQV>2')
                      AND f.sign_name = 'AMOUNT_EQV'
                  UNION ALL
                  SELECT inBegDt+idx-1 AS as_of_date
                        ,obj_gid*10+source_system_id AS contract_sid
                        ,to_number(sign_val,'FM999999999999999D999999999','nls_numeric_characters='', ''')
                    FROM dm_skb.tb_ctr_signs_new
                    WHERE sign_name = 'OVERDUE_PRINCIPAL_EQV'
                      AND inBegDt+idx-1 BETWEEN effective_start AND effective_end
                      AND (obj_gid,source_system_id) IN (SELECT TRUNC(contract_sid/10),MOD(contract_sid,10)
                                              FROM dm_clant.tb_fpd_spd_tpd
                                              WHERE close_fact_date = inBegDt+idx
                                                AND rk_flg = 1
                                          )
                ) GROUP BY as_of_date,contract_sid                                       
             )
    LOOP
      UPDATE dm_clant.tb_fpd_spd_tpd SET lifo_value_cfd = a.stock_value
        WHERE contract_sid = a.contract_sid AND close_fact_date = a.as_of_date+1;
      vCou := vCou + 1;  
    END LOOP;

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: LIFO_VALUE_CFD "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||vCou||' rows updated in table "dm_clant.tb_fpd_spd_tpd" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_update',vMes);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_update" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_update',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_fpd_spd_tpd_update" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_update',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_update" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_update',vMes);
END tb_fpd_spd_tpd_update;

PROCEDURE ptb_fpd_spd_tpd_def (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_fpd_spd_tpd_def" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_fpd_spd_tpd_def TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_fpd_spd_tpd_def" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_fpd_spd_tpd_def
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_fpd_spd_tpd_def" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);


    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.ptb_fpd_spd_tpd_def
      (as_of_date,contract_sid,def_dlq_value)
    SELECT as_of_date,contract_sid,SUM(def_dlq_value) AS def_dlq_value
      FROM (
        SELECT inBegDt+idx AS as_of_date
              ,dm.obj_gid*10+dm.source_system_id AS contract_sid
              ,to_number(dm.sign_val, 'FM999999999999999D999999999', 'nls_numeric_characters='', ''') AS def_dlq_value
          FROM dm_skb.ptb_ctr_signs_new dm
          WHERE dm.as_of_date = inBegDt+idx - 1
            AND (dm.obj_gid,dm.source_system_id) IN (SELECT DISTINCT dd.contract_gid,dd.source_system_id
                                      FROM dwh.ref_credit_exp_dates_days dd
                                      WHERE inBegDt+idx BETWEEN dd.delinquency_date AND dd.delinquency_date + dd.days
                                        AND dd.days > 90  
                                   )
            AND dm.sign_name = 'AMOUNT_EQV'
        UNION ALL
        SELECT inBegDt+idx AS as_of_date
              ,obj_gid*10+source_system_id AS contract_sid
              ,to_number(sign_val,'FM999999999999999D999999999','nls_numeric_characters='', ''')
          FROM dm_skb.tb_ctr_signs_new
          WHERE sign_name = 'OVERDUE_PRINCIPAL_EQV'
            AND inBegDt+idx-1 BETWEEN effective_start AND effective_end
            AND (obj_gid,source_system_id) IN (SELECT DISTINCT dd.contract_gid,dd.source_system_id
                                      FROM dwh.ref_credit_exp_dates_days dd
                                      WHERE inBegDt+idx BETWEEN dd.delinquency_date AND dd.delinquency_date + dd.days
                                        AND dd.days > 90
                                )
      ) GROUP BY as_of_date,contract_sid;

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_fpd_spd_tpd_def" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_fpd_spd_tpd_def MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_fpd_spd_tpd_def" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_fpd_spd_tpd_def" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_fpd_spd_tpd_def" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_fpd_spd_tpd_def',vMes);
END ptb_fpd_spd_tpd_def;
--------------------------- ОЧИСТКА УСТАРЕВШИХ ДАННЫХ  --------------------------------------
PROCEDURE tables_clearing
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
    vSegType VARCHAR2(30);
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tables_clearing" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
  
  FOR idx IN (SELECT UPPER(tfc.owner) AS owner
                    ,UPPER(tfc.segment_name) AS segment_name
                    ,UPPER(tfc.date_field_name) AS date_field_name
                    ,tfc.older_than_days
                    ,tfc.older_than_months
                    ,UPPER(tfc.partitioning_type) AS partitioning_type
                FROM dm_clant.v_tables_for_clearing tfc
             )
  LOOP
    -- Если не партицированная таблица
    IF idx.partitioning_type = 'NO' 
      THEN
        vTIBegin := SYSDATE;
        EXECUTE IMMEDIATE 'DELETE FROM '||idx.owner||'.'||idx.segment_name||' WHERE '||idx.date_field_name||' < '||
           CASE WHEN idx.older_than_days IS NOT NULL THEN 'trunc(sysdate-1,''DD'') - '||idx.older_than_days
                WHEN idx.older_than_months IS NOT NULL THEN 'add_months('||'trunc(sysdate-1,''MM''),-'||idx.older_than_months||')'
           END;
        vEndTime := SYSDATE;
        vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows deleted from table "'||lower(idx.owner)||'.'||lower(idx.segment_name)||'" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
        dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
    -- Если таблица партицирована по дням  
    ELSIF idx.partitioning_type = 'PDAY' THEN  
      -- Определим, где лежат значения дней, в партициях, или субпартициях
      SELECT segment_type INTO vSegType FROM (
        SELECT 'PARTITION' AS segment_type
          FROM sys.dba_part_key_columns
          WHERE owner = idx.owner AND name = idx.segment_name AND object_type = 'TABLE'
            AND column_name = idx.date_field_name
        UNION ALL
        SELECT 'SUBPARTITION' AS segment_type
          FROM sys.dba_subpart_key_columns
          WHERE owner = idx.owner AND name = idx.segment_name AND object_type = 'TABLE'
            AND column_name = idx.date_field_name
      );
      IF vSegType = 'PARTITION' THEN
        FOR p IN (
          SELECT s.partition_name
                    FROM sys.dba_tab_partitions s
                    WHERE s.table_owner = idx.owner AND s.table_name = idx.segment_name
                      AND to_date(SUBSTR(partition_name,-8),'YYYYMMDD') < TRUNC(SYSDATE-1,'DD')-idx.older_than_days
        ) LOOP
          EXECUTE IMMEDIATE 'ALTER TABLE '||idx.owner||'.'||idx.segment_name||' DROP '||vSegType||' '||p.partition_name;
          vEndTime := SYSDATE;
          vMes := 'SUCCESSFULLY :: '||vSegType||' '||p.partition_name||' dropped from table "'||lower(idx.owner)||'.'||lower(idx.segment_name)||'"';
          dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
        END LOOP;
               
      END IF;  
          
      IF vSegType = 'SUBPARTITION' THEN
        FOR p IN (SELECT s.partition_name
                    FROM sys.dba_segments s
                    WHERE s.owner = idx.owner AND s.segment_name = idx.segment_name
                      AND to_date(SUBSTR(partition_name,-8),'YYYYMMDD') < TRUNC(SYSDATE-1,'DD')-idx.older_than_days
                 )
        LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE '||idx.owner||'.'||idx.segment_name||' DROP '||vSegType||' '||p.partition_name;
            vEndTime := SYSDATE;
            vMes := 'SUCCESSFULLY :: '||vSegType||' '||p.partition_name||' dropped from table "'||lower(idx.owner)||'.'||lower(idx.segment_name)||'"';
            dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
        END LOOP;
      END IF;  
    ELSE
      NULL;
    END IF;    
  END LOOP;
    
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tables_clearing" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Procedure "dm_clant.pkg_etl.tables_clearing" :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tables_clearing" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tables_clearing',vMes);
END tables_clearing;  
--------------------------------------- ФАКТЫ ------------------------------------------------------------
PROCEDURE ptb_abb_fact (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ptb_abb_fact" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_abb_fact truncate partition P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_abb_fact" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_abb_fact
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY''))  STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_abb_fact" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);

    vTIBegin := SYSDATE;
     INSERT INTO dm_clant.ptb_abb_fact
       (source_system_id,contract_sid,categories_id,client_sid,client_type_id,abs_department_sid,link_type_sid,contract_type_sid
       ,account_sid,bal_account_id,balance_date,balance_in,balance_in_rur,turn_debit,turn_debit_rur,turn_credit,turn_credit_rur
       ,balance,balance_rur,serv_department_sid,contract_type_sid2)
      SELECT  source_system_id,contract_sid,categories_id,client_sid,client_type_id,abs_department_sid,link_type_sid,contract_type_sid
             ,account_sid,bal_account_id,balance_date,balance_in,balance_in_rur,turn_debit,turn_debit_rur,turn_credit,turn_credit_rur
             ,balance,balance_rur,serv_department_sid,contract_type_sid2
         FROM --dm_clant.v_get_abb_fact WHERE balance_date = inBegDt+idx/*to_date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')*/;
              TABLE(dm_clant.pkg_etl_gets.get_abb_fact(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_abb_fact" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);

    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_abb_fact MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);
    
    dm_skb.dm_showcase_set_date('ABB',1,inBegDt+idx);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_abb_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_abb_fact" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_abb_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_abb_fact',vMes);
END ptb_abb_fact;

PROCEDURE ptb_pre_limits_creds (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_pre_limits_creds" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_creds TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_creds" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_pre_limits_creds
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_creds" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);

    vTIBegin := SYSDATE;
  INSERT INTO dm_clant.ptb_pre_limits_creds 
         (as_of_date,client_sid,uc_id,client_gid,source_system_id,system_name,claim_id
         ,contract_sid,contract_type_sid
         ,contract_no,open_date,gift_date,principal,close_date,close_fact_date
         ,unused_overdraft_limit,overdraft_limit_days,p_id,product_group_name,product_name
         ,contract_status,contract_state,delinq_date_lifo,delinq_date_fifo,current_delinq_lifo_days
         ,current_delinq_fifo_days,delinq_all_days,delinq_12_days,delinq_unbroken_days
         ,top_up,interest_rate,monthly_payment,sum_komiss_month,sum_main,sum_debt,sum_main_prc
         ,sum_debt_prc,sum_main_prc_outbal,sum_debt_prc_outbal,sum_debt_all,sum_debt_outstand
         ,sum_komiss,cnt_pays_od_on_debt,cnt_all_pays_od_on_debt,cnt_pays_prc_on_debt
         ,cnt_all_pays_prc_on_debt,abs_department_sid,abs_department_name,stock_by_open_office
         ,have_2ndfl_id,doc_2ndfl,confirmed_income,nvpv,have_refinance,overdraft_limit
         ,credit_sum_gift,sum_all_peny_to_main
         )
         SELECT as_of_date,client_sid,uc_id,client_gid,source_system_id,system_name,claim_id
               ,contract_sid,contract_type_sid
               ,contract_no,open_date,gift_date,principal,close_date,close_fact_date
               ,unused_overdraft_limit,overdraft_limit_days,p_id,product_group_name,product_name
               ,contract_status,contract_state,delinq_date_lifo,delinq_date_fifo,current_delinq_lifo_days
               ,current_delinq_fifo_days,delinq_all_days,delinq_12_days,delinq_unbroken_days
               ,top_up,interest_rate,monthly_payment,sum_komiss_month,sum_main,sum_debt,sum_main_prc
               ,sum_debt_prc,sum_main_prc_outbal,sum_debt_prc_outbal,sum_debt_all,sum_debt_outstand
               ,sum_komiss,cnt_pays_od_on_debt,cnt_all_pays_od_on_debt,cnt_pays_prc_on_debt
               ,cnt_all_pays_prc_on_debt,abs_department_sid,abs_department_name,stock_by_open_office
               ,have_2ndfl_id,doc_2ndfl,confirmed_income,nvpv,have_refinance,overdraft_limit
               ,credit_sum_gift,sum_all_peny_to_main 
            FROM TABLE(dm_clant.pkg_etl_gets.get_pre_limits_creds(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_pre_limits_creds" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_creds MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    EXECUTE IMMEDIATE 'ALTER INDEX dm_clant.idx_ptb_pre_limits_creds_001 REBUILD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' NOLOGGING';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);
    
    dm_skb.dm_showcase_set_date('PRE_LIMITS_CREDS',1,inBegDt+idx);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_creds" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_pre_limits_creds" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_creds" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_creds',vMes);
END ptb_pre_limits_creds;

PROCEDURE ptb_pre_limits_cl_fact (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_pre_limits_cl_fact" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_fact',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_cl_fact TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_cl_fact" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_pre_limits_cl_fact
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_cl_fact" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_fact',vMes);

    vTIBegin := SYSDATE;
    INSERT /*+ APPEND */ INTO dm_clant.ptb_pre_limits_cl_fact
      (as_of_date,client_sid,uc_id,client_gid,source_system_id,client_age,income_db
      ,income_contr,income_clm,income_notnull,income_cl,have_spouse,have_spouse_job
      ,dependent_count,nvpv_date,nvpv_income,nvpv_limit,personal_offer_sum,last_clm_date
      ,last_clm_status_sid,inner_credit_hist,stop_extreme,stop_extreme_reason,stop_signal
      ,stop_signal_reason,stop_nocredsubj,stop_nocredsubj_reason,stop_massregaddr
      ,stop_massregaddr_reason,stop_ufe,stop_ufe_reason,stop_comprodoc,stop_comprodoc_reason
      ,account_arrest,cl_in_stop,cl_salary,cl_employee,cl_persdata_endproc,cl_persdata_withdraw
      ,cl_credhist_access,ctr_state,income_2ndfl,ndfl2_gived)
    SELECT as_of_date,client_sid,uc_id,client_gid,source_system_id,client_age,income_db
          ,income_contr,income_clm,income_notnull,income_cl,have_spouse,have_spouse_job
          ,dependent_count,nvpv_date,nvpv_income,nvpv_limit,personal_offer_sum,last_clm_date
          ,last_clm_status_sid,inner_credit_hist,stop_extreme,stop_extreme_reason,stop_signal
          ,stop_signal_reason,stop_nocredsubj,stop_nocredsubj_reason,stop_massregaddr
          ,stop_massregaddr_reason,stop_ufe,stop_ufe_reason,stop_comprodoc,stop_comprodoc_reason
          ,account_arrest,cl_in_stop,cl_salary,cl_employee,cl_persdata_endproc,cl_persdata_withdraw
          ,cl_credhist_access,ctr_state,income_2ndfl,ndfl2_gived
      FROM TABLE(dm_clant.pkg_etl_gets.get_pre_limits_cl_fact(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_pre_limits_cl_fact" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_fact',vMes);
    
    dm_skb.dm_showcase_set_date('PRE_LIMITS_CL',1,inBegDt+idx);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_cl_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_fact',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_pre_limits_cl_fact" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_fact',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_cl_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_cl_fact',vMes);
END ptb_pre_limits_cl_fact;  

PROCEDURE ptb_pre_limits_nvpv (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_pre_limits_nvpv" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_nvpv TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_nvpv" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_pre_limits_nvpv
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_pre_limits_nvpv" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);

    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.ptb_pre_limits_nvpv
      (as_of_date,source_system_id,client_sid,uc_id,client_gid,cl_name,client_age,mobile_phone
      ,fact_address,delinq_all_days,general_ctr_status,open_ctr_count,open_date_fst_ctr
      ,open_date_lst_ctr,sum_debt_all,sum_unsecured,monthly_payment,kd1_product_name
      ,kd2_product_name,kd3_product_name,kd1_contract_sid,kd2_contract_sid,kd3_contract_sid
      ,kd1_interest_rate,kd2_interest_rate,kd3_interest_rate,kd1_sum_main,kd2_sum_main
      ,kd3_sum_main,proc_payment,sum_komiss_month,close_ctr_count,ovr_limit_more_50000_count
      ,overdraft_limit_days,open_date_lst_cls_ctr,close_date_lst_cls_ctr
      ,close_principal_lst_ctr,mid_salary,income_ctr,income_notnull,income_db,income_cl
      ,income_clm,have_spouse,have_spouse_job,dependent_count,nvpv_date,nvpv_income
      ,nvpv_limit,personal_offer_sum,lst_clm_date,lst_clm_status_sid,abs_department_sid
      ,abs_department_name,stock_by_open_office)
    SELECT as_of_date,source_system_id,client_sid,uc_id,client_gid,cl_name,client_age,mobile_phone
          ,fact_address,delinq_all_days,general_ctr_status,open_ctr_count,open_date_fst_ctr
          ,open_date_lst_ctr,sum_debt_all,sum_unsecured,monthly_payment,kd1_product_name
          ,kd2_product_name,kd3_product_name,kd1_contract_sid,kd2_contract_sid,kd3_contract_sid
          ,kd1_interest_rate,kd2_interest_rate,kd3_interest_rate,kd1_sum_main,kd2_sum_main
          ,kd3_sum_main,proc_payment,sum_komiss_month,close_ctr_count,ovr_limit_more_50000_count
          ,overdraft_limit_days,open_date_lst_cls_ctr,close_date_lst_cls_ctr
          ,close_principal_lst_ctr,mid_salary,income_ctr,income_notnull,income_db,income_cl
          ,income_clm,have_spouse,have_spouse_job,dependent_count,nvpv_date,nvpv_income
          ,nvpv_limit,personal_offer_sum,lst_clm_date,lst_clm_status_sid,abs_department_sid
          ,abs_department_name,stock_by_open_office
      FROM TABLE(dm_clant.pkg_etl_gets.get_pre_limits_nvpv(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_pre_limits_nvpv" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_pre_limits_nvpv MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);

    dm_skb.dm_showcase_set_date('PRE_LIMITS_NVPV',1,inBegDt+idx);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_nvpv" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_pre_limits_nvpv" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_pre_limits_nvpv" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_pre_limits_nvpv',vMes);
END ptb_pre_limits_nvpv; 

PROCEDURE ptb_entry_fact (inBegDt IN DATE, inEndDt IN DATE)
  IS 
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.ptb_entry_fact" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_entry_fact TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_entry_fact" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.ptb_entry_fact
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.ptb_entry_fact" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);

    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.ptb_entry_fact
      (as_of_date,source_system_id,cr_id,client_gid,contract_gid,contract_no
      ,pay_acc_no,receive_acc_no,cur_id,amount,amount_cred,entry_note
      ,operation_code,operation_name,abs_department_name,product_name)
    SELECT as_of_date,source_system_id,cr_id,client_gid,contract_gid,contract_no
          ,pay_acc_no,receive_acc_no,cur_id,amount,amount_cred,entry_note
          ,operation_code,operation_name,abs_department_name,product_name
      FROM TABLE(dm_clant.pkg_etl_gets.get_entry_fact(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.ptb_entry_fact" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.ptb_entry_fact MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_entry_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.ptb_entry_fact" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ptb_entry_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.ptb_entry_fact',vMes);
END ptb_entry_fact;

PROCEDURE tb_emp_oper_activity 
 (inBegDt IN DATE, inEndDt IN DATE, inPartID IN NUMBER DEFAULT NULL)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.tb_emp_oper_activity" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);

  FOR idx IN 0..vDays
  LOOP
    vTIBegin := SYSDATE;
    DELETE FROM dm_clant.tb_emp_oper_activity 
      WHERE part_id = NVL(inPartID,part_id) AND as_of_date = inBegDt+idx;
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows deleted from table "dm_clant.tb_emp_oper_activity" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);

    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.tb_emp_oper_activity
      (as_of_date,source_system_id,oper_dep_sid,emp_sid,col_id,cou,part_id,obj_gid,oper_code)
      SELECT as_of_date,source_system_id,oper_dep_sid,emp_sid,col_id,cou,part_id,obj_gid,oper_code
        FROM TABLE(dm_clant.pkg_etl_gets.get_emp_oper_activity_new(inBegDt+idx/*,inPartId*/));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_emp_oper_activity" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);

    vTIBegin := SYSDATE;
    INSERT INTO dm_clant.tb_emp_oper_activity
      (as_of_date,source_system_id,oper_dep_sid,emp_sid,col_id,cou,part_id,obj_gid,oper_code)
      SELECT as_of_date,source_system_id,oper_dep_sid,emp_sid,col_id,cou,part_id,obj_gid,oper_code
        FROM TABLE(dm_clant.pkg_etl_gets.get_emp_oper_activity(inBegDt+idx/*,inPartId*/));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_emp_oper_activity" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);
    
    vTIBegin := SYSDATE;
    FOR c IN (SELECT DISTINCT 
                   as_of_date,source_system_id,oper_dep_sid,emp_sid
                  ,SIGN(COUNT(1) OVER (PARTITION BY as_of_date,source_system_id,emp_sid))*8 AS h_cou
              FROM dm_clant.tb_emp_oper_activity
              WHERE as_of_date = inBegDt+idx
           ) 
    LOOP
      INSERT INTO dm_clant.tb_emp_oper_activity
        (as_of_date,source_system_id,oper_dep_sid,emp_sid,col_id,cou,part_id)
        VALUES (inBegDt+idx,c.source_system_id,c.oper_dep_sid,c.emp_sid
               ,'Часы',c.h_cou,0);
    END LOOP;

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_emp_oper_activity" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);

    --dm_skb.dm_showcase_set_date('EMP_OP_ACT',1,inBegDt+idx);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_emp_oper_activity" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_emp_oper_activity" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_emp_oper_activity" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_emp_oper_activity',vMes);
END tb_emp_oper_activity;

PROCEDURE calc_emp_oper_activity_period(inBegDate IN DATE)
  IS
    vBegDate DATE;
    vEndDate DATE;
    --
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.calc_emp_oper_activity_period" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.calc_emp_oper_activity_period',vMes);

  IF TRUNC(SYSDATE,'DD') - inBegDate <= 1 THEN
    vBegDate := add_months(TRUNC(SYSDATE,'MM'),-1);
    vEndDate := TRUNC(SYSDATE - 1, 'DD');
    dm_skb.mass_load_parallel_by_month(vBegDate,vEndDate,'dm_clant.pkg_etl.tb_emp_oper_activity');
    dm_clant.pkg_etl.mv_ref_emp_oper_activity_cols;
    dm_skb.dm_showcase_set_date('EMP_OP_ACT',1,vEndDate);
  END IF;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.calc_emp_oper_activity_period" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.calc_emp_oper_activity_period',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Procedure "dm_clant.pkg_etl.calc_emp_oper_activity_period" :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.calc_emp_oper_activity_period',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.calc_emp_oper_activity_period" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.calc_emp_oper_activity_period',vMes);
END calc_emp_oper_activity_period;

PROCEDURE tb_cards_state (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
    vCtrCou INTEGER := 0;
    --vStat VARCHAR2(256);
    --vDescr VARCHAR2(32700);
    --
    errCtrEmpty EXCEPTION;
BEGIN
  -- Если контракты не загрузились не запускаем процедуру
  SELECT COUNT(1) INTO vCtrCou FROM dm_clant.tb_cl_contracts;
  IF vCtrCou = 0 THEN RAISE errCtrEmpty; END IF;
  --
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dwh.pkg_etl.tb_cards_state" - "'||to_char(inBegDt,'DD.MM.RRRR')||'" started.';
  dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);

  FOR idx IN 0..vDays
  LOOP
    -- Очистка временной таблицы
    tmp_etl.truncate_my_any_table('tmp_tb_cards_state',vMes);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_state',vMes);

  -- Загрузка данных во временную таблицу
    vTIBegin := SYSDATE;
    INSERT /*+ APPEND */
      INTO tmp_etl.tmp_tb_cards_state
        (id,start_date,end_date,effective_start,effective_end
        ,source_system_id,client_sid,client_gid,card_gid,crd_start_date,crd_end_date
        ,crd_reg_date,crd_act_date,crd_add_flg,crd_main_flg,crd_add_count,crd_state,crd_block_flg
        ,crd_block_code,crd_block_name,crd_block_end_date,crd_block_owner_code,crd_block_owner_name
        ,crd_active_flg,crd_type_code,crd_type_name,crd_range_name,crd_dep_gid,crd_dep_sid,crd_dep_name
        ,crd_dir_name,ctr_interest_rate,ovr_interest_rate,crd_tariff,ctr_pkg_of_service,crd_pay_pass
        ,crd_of_good_flg,crd_sms_flg,crd_sms_full_flg,crd_sms_dt,crd_sms_light_flg,crd_sms_blck_flg
        ,crd_sms_grace,crd_org_agreement_sid,ctr_org_status,ctr_org_comments,ctr_org_name,ctr_org_tin
        ,ctr_org_open_date,ctr_apv_benefit,ctr_apv_ban,crd_contract_gid,product_id,ctr_status,ctr_comments
        ,ctr_open_date,ctr_close_date,ctr_close_fact_date,open_abs_department_sid,abs_department_sid
        ,gold,signature,student,virtuon,classic,icard,fk_ural,meed,DESIGN_CODE)     
      SELECT id,start_date,end_date,effective_start,effective_end
            ,source_system_id,client_sid,client_gid,card_gid,crd_start_date,crd_end_date
            ,crd_reg_date,crd_act_date,crd_add_flg,crd_main_flg,crd_add_count,crd_state,crd_block_flg
            ,crd_block_code,crd_block_name,crd_block_end_date,crd_block_owner_code,crd_block_owner_name
            ,crd_active_flg,crd_type_code,crd_type_name,crd_range_name,crd_dep_gid,crd_dep_sid,crd_dep_name
            ,crd_dir_name,ctr_interest_rate,ovr_interest_rate,crd_tariff,ctr_pkg_of_service,crd_pay_pass
            ,crd_of_good_flg,crd_sms_flg,crd_sms_full_flg,crd_sms_dt,crd_sms_light_flg,crd_sms_blck_flg
            ,crd_sms_grace,crd_org_agreement_sid,ctr_org_status,ctr_org_comments,ctr_org_name,ctr_org_tin
            ,ctr_org_open_date,ctr_apv_benefit,ctr_apv_ban,crd_contract_gid,product_id,ctr_status,ctr_comments
            ,ctr_open_date,ctr_close_date,ctr_close_fact_date,open_abs_department_sid,abs_department_sid
            ,gold,signature,student,virtuon,classic,icard,fk_ural,meed,DESIGN_CODE   
        FROM TABLE(dm_clant.pkg_etl_gets.get_cards_state(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "tmp_etl.tmp_tb_cards_state" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);

    -- Запуск обновления версий в целевой таблице
    dwh.pkg_normalize_ref_table.load_dwh_daily('tmp_etl.tmp_tb_cards_state','dwh.tb_cards_state_new',NULL,inBegDt+idx,'10');
    /*vTIBegin := SYSDATE;
    etl.p_load_dwh_m(schema_name_in => 'DM_CLANT',
                     table_name_in  => 'TB_CARDS_STATE',
                     status_out     => vStatus,
                     descr_out      => vMes,
                     in_date        => inBegDt+idx);

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" Table "dm_clant.tb_cards_state":'||vMes||' in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_state',vMes);*/
    dm_skb.dm_showcase_set_date('CARDS_STATE',1,inBegDt+idx);
  END LOOP;
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dwh.pkg_etl.tb_cards_state" - "'||to_char(inBegDt,'DD.MM.RRRR')||'" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);
EXCEPTION
  WHEN errCtrEmpty THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: В таблице "dm_clant.tb_cl_contracts" отсутствуют данные. Дальнейший расчет не возможен.';
    dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cards_state" - "'||to_char(inBegDt,'DD.MM.RRRR')||'" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "tmp_etl.tb_cards_state" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cards_state" - "'||to_char(inBegDt,'DD.MM.RRRR')||'" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dwh.pkg_etl.tb_cards_state',vMes);
END tb_cards_state;

PROCEDURE tb_fpd_spd_tpd_fifo (inBegDt IN DATE, inEndDt IN DATE)
  IS
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
    vStatus VARCHAR2(2000);
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);

  FOR idx IN 0..vDays
  LOOP
    -- Очистка временной таблицы
    tmp_etl.truncate_my_any_table('tmp_tb_fpd_spd_tpd_fifo',vMes);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);

  -- Загрузка данных во временную таблицу
    vTIBegin := SYSDATE;
    INSERT /*+ APPEND */
      INTO tmp_etl.tmp_tb_fpd_spd_tpd_fifo
        (id,start_date,end_date,effective_start,effective_end,
        contract_sid,fifo_dt,payment_number,date_pays,benefit_cou)
      SELECT id,start_date,end_date,effective_start,effective_end,
        contract_sid,fifo_dt,payment_number,date_pays,benefit_cou
        FROM TABLE(dm_clant.pkg_etl_gets.get_FpdSpdTpdFifo(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "tmp_etl.tmp_tb_fpd_spd_tpd_fifo" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);

    -- Запуск обновления версий в целевой таблице
    vTIBegin := SYSDATE;
    etl.p_load_dwh_m(schema_name_in => 'DM_CLANT',
                     table_name_in  => 'TB_FPD_SPD_TPD_FIFO',
                     status_out     => vStatus,
                     descr_out      => vMes,
                     in_date        => inBegDt+idx);
    
    
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" Table "dm_clant.tb_fpd_spd_tpd_fifo":'||vMes||' in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);
    
    -- Пожмем, хоть она и историческая. Говорят помогает :)
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.tb_fpd_spd_tpd_fifo MOVE PARTITION P59991231 COMPRESS';
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.tb_fpd_spd_tpd_fifo MOVE PARTITION POTHERS COMPRESS';
      
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITIONS P59991231;POTHERS compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);
    -- Оканчание ...пожмем, хоть она и историческая...
      
  END LOOP;
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "tmp_etl.tb_fpd_spd_tpd_fifo" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fifo',vMes);
END tb_fpd_spd_tpd_fifo;

PROCEDURE tb_fpd_spd_tpd_fact
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_fact" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fact',vMes);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_fpd_spd_tpd_fact_1';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_fpd_spd_tpd_fact_1" truncated.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fact',vMes);
  
  INSERT /*+ APPEND */ INTO dm_clant.tb_fpd_spd_tpd_fact_1 
    (contract_sid,source_system_id,fst_open_date,close_fact_date,abs_department_sid
    ,employee_sid,rk_flg
    ,dlq_interval,end_dt_m,end_dt_q,end_dt_s,end_dt_y/*,principal*/,benefit_cou
    ,fpd_dlq_value,spd_dlq_value,tpd_dlq_value,dlq_value_cfd
    ,fpd_lifo_dt,spd_lifo_dt,tpd_lifo_dt
    )
  SELECT contract_sid,source_system_id,fst_open_date,close_fact_date,abs_department_sid
        ,employee_sid,rk_flg
        ,dlq_interval,end_dt_m,end_dt_q,end_dt_s,end_dt_y/*,principal*/,benefit_cou
        ,fpd_dlq_value,spd_dlq_value,tpd_dlq_value,dlq_value_cfd
        ,fpd_lifo_dt,spd_lifo_dt,tpd_lifo_dt
  FROM dm_clant.v_tb_fpd_spd_tpd_fact_1;
  
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_fpd_spd_tpd_fact_1".';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fact',vMes);

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fact',vMes);
EXCEPTION WHEN OTHERS THEN
  vMes := 'ERROR :: Table "dm_clant.tb_fpd_spd_tpd_fact_1" aggregation failed :: '||SQLERRM;
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fact',vMes);
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_fpd_spd_tpd_fact" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_fpd_spd_tpd_fact',vMes);
END tb_fpd_spd_tpd_fact;
    
PROCEDURE tb_cards_stock (inBegDt IN DATE, inEndDt IN DATE)
  IS 
    vMes VARCHAR2(2000);
    vDays INTEGER;
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vDays := inEndDt - inBegDt;
  vMes := 'START :: Procedure "dm_clant.tb_cards_stock" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);

  FOR idx IN 0..vDays
  LOOP

    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.tb_cards_stock TRUNCATE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD');
      vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_cards_stock" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' truncated';
    EXCEPTION WHEN OTHERS THEN

      EXECUTE IMMEDIATE 'alter table dm_clant.tb_cards_stock
                            ADD PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' VALUES (to_Date('''||to_char(inBegDt+idx,'DD.MM.YYYY')||''',''DD.MM.YYYY'')) STORAGE(INITIAL 64K NEXT 1M) NOLOGGING';
      vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_cards_stock" altered. Partition P'||to_char(inBegDt+idx,'YYYYMMDD')||' added.';
    END;

    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);

    vTIBegin := SYSDATE;

    INSERT INTO dm_clant.tb_cards_stock
      (as_of_date,card_sid,card_gid,source_system_id,ovr_contract_sid,ovr_contract_gid
      ,stock,stock_eqv,ovr_stock,ovr_stock_eqv,ovr_unused,ovr_unused_eqv,balance_in_992,balance_in_rur_992,card_program)     /* andy 02.06.2017 rm23871*/
    SELECT as_of_date,card_sid,card_gid,source_system_id,ovr_contract_sid,ovr_contract_gid
          ,stock,stock_eqv,ovr_stock,ovr_stock_eqv,ovr_unused,ovr_unused_eqv,balance_in_992,balance_in_rur_992,card_program      /* andy 02.06.2017 rm23871*/
      FROM TABLE(dm_clant.pkg_etl_gets.get_cards_stock(inBegDt+idx));

    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: "'||to_char(inBegDt+idx,'DD.MM.YYYY')||'" '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_cards_stock" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);
    
    vTIBegin := SYSDATE;
    EXECUTE IMMEDIATE 'ALTER TABLE dm_clant.tb_cards_stock MOVE PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' COMPRESS';
    vEndTime := SYSDATE;
    vMes := 'SUCCESSFULLY :: PARTITION P'||to_char(inBegDt+idx,'YYYYMMDD')||' compressed in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin);
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);
  END LOOP;

  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cards_stock" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_cards_stock" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_cards_stock" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_cards_stock',vMes);
END tb_cards_stock;

PROCEDURE tb_client_not_load
  IS
    vMes VARCHAR2(2000);
    vBegTime DATE := SYSDATE;
    vTIBegin DATE := SYSDATE;
    vEndTime DATE;
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.tb_client_not_load" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_not_load',vMes);
  
  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_clant.tb_client_not_load';
  vMes := 'SUCCESSFULLY :: Table "dm_clant.tb_client_not_load" truncated';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_not_load',vMes);
  
  vTIBegin := SYSDATE;
  INSERT /*+ APPEND */ INTO dm_clant.tb_client_not_load (client_sid)
    SELECT client_sid FROM dm_clant.v_client_not_load
  ;

  vEndTime := SYSDATE;
  vMes := 'SUCCESSFULLY :: '||SQL%ROWCOUNT||' rows inserted into table "dm_clant.tb_client_not_load" in '||dm_skb.get_ti_as_hms(vEndTime - vTIBegin)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_not_load',vMes);
  
  vEndTime := SYSDATE;
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_client_not_load in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' successfully.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_not_load',vMes);
EXCEPTION
  WHEN OTHERS THEN
    vEndTime := SYSDATE;
    vMes := 'ERROR :: Table "dm_clant.tb_client_not_load" aggregation failed :: '||SQLERRM;
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_not_load',vMes);
    vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.tb_client_not_load" finished in '||dm_skb.get_ti_as_hms(vEndTime - vBegTime)||' with errors.';
    dm_skb.pr_log_write('dm_clant.pkg_etl.tb_client_not_load',vMes);
END tb_client_not_load; 

PROCEDURE bl_vki_set_date
  IS
   vDt DATE;
BEGIN
  SELECT MAX(reportdate) INTO vDt FROM tddw.bl_vki;
  dm_skb.dm_showcase_set_date('BL_VKI',1,vDt);
END;

PROCEDURE ref_contract_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,contract_gid 
      FROM dwh.ref_contract
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,contract_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_contract_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_contract_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_contract','dwh.ref_contract_new',inColumnName,vGidsSQL,'11');
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_contract','dwh.ref_contract_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_contract_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_contract_new',vMes);
END ref_contract_new;
  
PROCEDURE ref_abs_department_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,abs_department_gid 
      FROM dwh.ref_abs_department
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,abs_department_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_abs_department_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_abs_department_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_abs_department','dwh.ref_abs_department_new',inColumnName,vGidsSQL);
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_abs_department','dwh.ref_abs_department_new'
  --   ,inColumnName,'effective_start','WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_abs_department_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_abs_department_new',vMes);
END ref_abs_department_new;
  
PROCEDURE ref_contract_spec_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,contract_gid 
      FROM dwh.ref_contract_spec
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,contract_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_contract_spec_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_contract_spec_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_contract_spec','dwh.ref_contract_spec_new',inColumnName,vGidsSQL,'11');
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_contract_spec','dwh.ref_contract_spec_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_contract_spec_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_contract_spec_new',vMes);
END ref_contract_spec_new;
  
PROCEDURE ref_client_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,client_gid 
      FROM dwh.ref_client
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,client_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_client_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_client_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_client','dwh.ref_client_new',inColumnName,vGidsSQL);
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_client','dwh.ref_client_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_client_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_client_new',vMes);
END ref_client_new;
  
PROCEDURE ref_client_address_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT address_type,source_system_id,client_gid
      FROM dwh.ref_client_address
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY address_type,source_system_id,client_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_client_address_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_client_address_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_client_address','dwh.ref_client_address_new',inColumnName,vGidsSQL);
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_client_address','dwh.ref_client_address_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_client_address_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_client_address_new',vMes);
END ref_client_address_new;
  
PROCEDURE ref_account_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,account_gid 
      FROM dwh.ref_account
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,account_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_account_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_account_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_account','dwh.ref_account_new',inColumnName,vGidsSQL,'11');
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_account','dwh.ref_account_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_account_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_account_new',vMes);
END ref_account_new;

PROCEDURE ref_card_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,card_gid 
      FROM dwh.ref_card
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,card_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_card_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_card_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_card','dwh.ref_card_new',inColumnName,vGidsSQL);
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_card','dwh.ref_card_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_card_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_card_new',vMes);
END ref_card_new;

PROCEDURE ref_crd_claim_new(inColumnName IN VARCHAR2)
  IS
    vMes VARCHAR2(32700);
    --vStat VARCHAR2(32700);
    --vDescr VARCHAR2(32700);
    vGidsSQL CLOB :=
    q'[SELECT source_system_id,crd_claim_gid 
      FROM dwh.ref_crd_claim
      WHERE end_date = to_date('31.12.5999','DD.MM.YYYY')
        AND start_date BETWEEN TRUNC(SYSDATE - 4,'DD') AND SYSDATE
    GROUP BY source_system_id,crd_claim_gid]';
BEGIN
  vMes := 'START :: Procedure "dm_clant.pkg_etl.ref_crd_claim_new" started.';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_crd_claim_new',vMes);
  
  dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_crd_claim','dwh.ref_crd_claim_new',inColumnName,vGidsSQL,'11');
  --dwh.pkg_normalize_ref_table.load_dwh_daily('dwh.ref_crd_claim','dwh.ref_crd_claim_new',inColumnName,'effective_start'
  --  ,'WHERE end_date = to_date(''31.12.5999'',''DD.MM.YYYY'') AND start_date BETWEEN TRUNC(SYSDATE-2,''DD'') AND SYSDATE',vStat,vDescr);
  
  vMes := 'FINISH :: Procedure "dm_clant.pkg_etl.ref_crd_claim_new" finished successfully';
  dm_skb.pr_log_write('dm_clant.pkg_etl.ref_crd_claim_new',vMes);
END ref_crd_claim_new;

END pkg_etl;
/
