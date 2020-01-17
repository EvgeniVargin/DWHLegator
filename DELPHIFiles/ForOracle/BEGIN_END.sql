BEGIN
  --dm_skb.pkg_etl_signs.ChainKiller('dm_skb.chain_59969');  -- пример ручной очистки аварийно-остановленных чейнов (остановлены посредством убийства сессий)
  --dm_skb.starexpand_dps(to_date('29.04.2019','DD.MM.RRRR'),to_date('29.04.2019','DD.MM.RRRR'),NULL); -- пример запуска ежедневного расчета кубов ФинДеп
  --dwh.pkg_normalize_ref_table.load_dwh('dwh.ref_account','dwh.ref_account_new',NULL,NULL,'10'); -- пример запуска полной перезагрузки колонки/списка колонок справочника в таблицу ...NEW
  --dwh.pkg_normalize_ref_table.reload_dwh('dwh.ref_account','dwh.ref_account_new','SUMMARY_ACCOUNT_SID,ACCOUNT_SID,CLOSE_ACCOUNT_DATE::WITHNULLS,COUNTERAGENT_ACCNT_NUM,CLIENT_SID,ABS_DEPARTMENT_SID,ACTIVE_FLG,ACCOUNT_SNAME,ACCOUNT_NAME,CLOSE_DATE,OPEN_DATE,ACCOUNT_NUMBER,STATUS,REASON_OF_CLOSE,OPENED_EMPLOYEE_GID,CLOSED_EMPLOYEE_GID,CLIENT_R_SID'); -- пример запуска дозагрузки отсутствующих GID в таблицу ...NEW
  --dwh.pkg_normalize_ref_table.HistTableService('dwh.ref_employees_for_dm','111'); -- пример запуска обслуживания (сбор статистики, сжатие и перестроение индекса) таблицы ...NEW
  --dm_skb.pkg_etl_signs.HistTableService('dm_skb.tb_ctr_signs_new','111','CTR_CLOSE_FACT_DATE'); -- пример запуска обслуживания (сбор статистики, сжатие и перестроение индекса) таблицы хранения периодами показателя
  --dm_skb.pkg_etl_signs.load(to_date('12.04.2019','DD.MM.RRRR'),to_date('14.04.2019','DD.MM.RRRR')); -- пример запуска расчета всех показателей
  --dm_skb.pkg_etl_signs.Calc(to_date('19.02.2019','DD.MM.RRRR'),to_date('19.02.2019','DD.MM.RRRR')); -- пример запуска AUTOCALC
  --dm_clant.mass_load_parallel_by_month(to_date('08.12.2018','DD.MM.RRRR'),to_date('09.12.2018','DD.MM.RRRR'),'dm_clant.pkg_etl.tb_cards_stock'); -- пример запуска расчета остатков по витрине CARDS_STATE за период
  --dm_clant.pkg_etl.calc_emp_oper_activity_period(to_date('26.12.2018','DD.MM.RRRR')); -- пример запуска пересчета нагрузки операционных работников
  --dm_clant.mass_load_parallel_by_month(to_date('08.12.2018','DD.MM.RRRR'),to_date('09.12.2018','DD.MM.RRRR'),'dm_clant.pkg_etl.ptb_entry_fact'); -- пример запуска расчета по витрине ENTRY_FACT за период
END;
  
