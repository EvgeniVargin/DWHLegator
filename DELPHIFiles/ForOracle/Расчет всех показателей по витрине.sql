DECLARE
  inBegDate DATE := to_date('30.04.2017','DD.MM.YYYY');
  inEndDate DATE := to_date('30.04.2017','DD.MM.YYYY');
  vBegDate VARCHAR2(30) := to_char(inBegDate,'DD.MM.YYYY');
  vEndDate VARCHAR2(30) := to_char(inEndDate,'DD.MM.YYYY');
  inGroupID INTEGER := 5;
  vOwner VARCHAR2(30) := 'DM_SKB';
  vBuff VARCHAR2(32700) :=
  q'[
  SELECT p.sign_name AS id
        ,s2s.prev_sign_name AS parent_id
          ,']'||lower(vOwner)||q'[.pkg_etl_signs.load_sign' AS unit
          ,']'||vBegDate||'#!#'||vEndDate||q'[#!#'||p.sign_name||'#!#' AS params
    FROM dm_skb.tb_signs_pool p
         INNER JOIN dm_skb.tb_signs_2_group s2g
           ON s2g.sign_name = p.sign_name
              AND s2g.group_id = ]'||inGroupID||q'[
         LEFT JOIN dm_skb.tb_sign_2_sign s2s
           ON s2s.sign_name = p.sign_name  
              AND EXISTS (SELECT NULL FROM dm_skb.tb_signs_pool WHERE sign_name = s2s.prev_sign_name AND p.archive_flg = 0)
    WHERE p.archive_flg = 0
  ]';

BEGIN
  dm_skb.pkg_etl_signs.load_new(vBuff);
  --dbms_output.put_line(vBuff);
END;
