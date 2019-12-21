DECLARE
  inBegDate DATE := to_date('02.09.2017','DD.MM.YYYY');
  inEndDate DATE := to_date('02.09.2017','DD.MM.YYYY');
  vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
  vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
  inGroupID INTEGER := 6;
  vOwner VARCHAR2(30) := 'DM_SKB';
  vBuff VARCHAR2(32700) :=
  q'[
  SELECT s2g.sign_name||'|'||s2a.anlt_code AS ID
        ,NULL AS parent_id
        ,']'||lower(vOwner)||q'[.pkg_etl_signs.load_sign' AS unit
        ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||s2g.sign_name||'#!#'||s2a.anlt_code AS params
    FROM tb_signs_2_group s2g
         LEFT JOIN tb_sign_2_anlt s2a
           ON s2g.sign_name = s2a.sign_name
              AND EXISTS (SELECT NULL FROM tb_anlt_2_group a2g 
                            WHERE a2g.anlt_code = s2a.anlt_code
                              AND a2g.group_id = (SELECT group_id FROM tb_signs_group WHERE LEVEL = 3 CONNECT BY PRIOR group_id = parent_group_id START WITH group_id = ]'||inGroupID||q'[))
    WHERE s2g.group_id = (SELECT group_id FROM tb_signs_group WHERE LEVEL = 3 CONNECT BY PRIOR group_id = parent_group_id START WITH group_id = ]'||inGroupID||q'[)
  ORDER BY s2g.sign_name
  ]';
BEGIN
  --dm_skb.pkg_etl_signs.load_new(vBuff);
  dbms_output.put_line(vBuff);
END;
