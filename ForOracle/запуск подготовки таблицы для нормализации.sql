DECLARE
  vOut VARCHAR2(32700);
BEGIN
  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_client','SOURCE_SYSTEM_ID,CLIENT_GID','CLIENT_ID','dwh.ref_client_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_client','SOURCE_SYSTEM_ID,CLIENT_GID',vOut);
  dbms_output.put_line(vOut);

  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_contract_spec','SOURCE_SYSTEM_ID,CONTRACT_GID','CONTRACT_SPEC_ID','dwh.ref_contract_spec_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_contract_spec','SOURCE_SYSTEM_ID,CONTRACT_GID',vOut);
  dbms_output.put_line(vOut);
  
  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_contract','SOURCE_SYSTEM_ID,CONTRACT_GID','CONTRACT_ID','dwh.ref_contract_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_contract','SOURCE_SYSTEM_ID,CONTRACT_GID',vOut);
  dbms_output.put_line(vOut);
  
  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_card','SOURCE_SYSTEM_ID,CARD_GID','CARD_ID','dwh.ref_card_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_card','SOURCE_SYSTEM_ID,CARD_GID',vOut);
  dbms_output.put_line(vOut);
  
  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_abs_department','SOURCE_SYSTEM_ID,ABS_DEPARTMENT_GID','ABS_DEPARTMENT_ID,HASH_VALUE','dwh.ref_abs_department_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_abs_department','SOURCE_SYSTEM_ID,ABS_DEPARTMENT_GID',vOut);
  dbms_output.put_line(vOut);
  
  
  
  --dwh.pkg_normalize_ref_table.prepare_table('tmp_etl.tmp_tb_cards_state','SOURCE_SYSTEM_ID,CARD_GID','ID','dm_clant.tb_cards_state_new',vOut,FALSE);
  --dbms_output.put_line(vOut);
  --dwh.pkg_normalize_ref_table.prepare_tools('tmp_etl.tmp_tb_cards_state','SOURCE_SYSTEM_ID,CARD_GID',vOut);
  --dbms_output.put_line(vOut);

  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_client_address','SOURCE_SYSTEM_ID,CLIENT_GID,ADDRESS_TYPE','CLIENT_ID','dwh.ref_client_address_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_client_address','SOURCE_SYSTEM_ID,CLIENT_GID,ADDRESS_TYPE',vOut);
  dbms_output.put_line(vOut);
  
  
  
  --dwh.pkg_normalize_ref_table.prepare_table('tmp_etl.tmp_ref_employees_for_dm','SOURCE_SYSTEM_ID,EMPLOYEE_GID','EMPLOYEE_ID','dwh.ref_employees_for_dm',vOut);
  --dbms_output.put_line(vOut);
  --dwh.pkg_normalize_ref_table.prepare_tools('tmp_etl.tmp_ref_employees_for_dm','SOURCE_SYSTEM_ID,EMPLOYEE_GID',vOut);
  --dbms_output.put_line(vOut);
  
  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_account','SOURCE_SYSTEM_ID,ACCOUNT_GID','ACCOUNT_ID','dwh.ref_account_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_account','SOURCE_SYSTEM_ID,ACCOUNT_GID',vOut);
  dbms_output.put_line(vOut);
  
  --dwh.pkg_normalize_ref_table.prepare_table('dwh.ref_crd_claim','SOURCE_SYSTEM_ID,CRD_CLAIM_GID','CRD_CLAIM_ID','dwh.ref_crd_claim_new',vOut);
  --dbms_output.put_line(vOut);
  dwh.pkg_normalize_ref_table.prepare_tools('dwh.ref_crd_claim','SOURCE_SYSTEM_ID,CRD_CLAIM_GID',vOut);
  dbms_output.put_line(vOut);

END;
