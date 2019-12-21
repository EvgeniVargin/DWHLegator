SELECT partition_name,
      SUM(bytes/1024/1024) AS bytes
  FROM dba_segments
  WHERE owner = 'DM_SKB' AND segment_name = 'YAI_TB_CTR_SIGNS_SPD'
    --AND partition_name LIKE 'SP0019%'
GROUP BY ROLLUP(partition_name)--,subpartition_name
ORDER BY 2 DESC,1

SELECT segment_name,partition_name
      ,SUM(bytes/1024/1024) AS bytes
  FROM dba_segments s
  WHERE owner = 'DM_SKB' AND segment_name IN --('UIX_2149873'/*'PK_REF_CONTRACT','REF_CONTRACT_INX2','REF_CONTRACT_INX3','UK_REF_CONTRACT'*/) --AND partition_name != 'POTHERS'
                                          ('FCT_9')
    --AND partition_name = 'SUM_ALL_PRC_TO_MAIN' 
GROUP BY segment_name,ROLLUP(partition_name)
--HAVING SUM(bytes/1024/1024) > 1000
ORDER BY bytes DESC

SELECT COUNT(*) FROM all_tab_subpartitions WHERE table_owner = 'DM_SKB' AND table_name = 'PTB_CTR_SIGNS' AND partition_name = 'MAX_CNT_DAY_OVERDUE_CLIENT'

--SELECT index_name,status FROM all_indexes WHERE owner = 'DM_SKB' AND index_name = 'IDX_TB_CTR_SIGNS_U001'
SELECT * FROM all_indexes WHERE owner = 'TDDW' AND table_name = 'CREDS_FOR_SCORING_TDDW'--index_name = 'UIX_3996585'

SELECT *--index_owner,index_name,partition_name,subpartition_name,status 
  FROM all_ind_subpartitions WHERE index_owner = 'DWH' AND status = 'UNUSABLE'

SELECT *--index_owner,index_name,partition_name,subpartition_name,status 
  FROM all_ind_partitions WHERE index_owner = 'DM_SKB' AND status = 'UNUSABLE' 

SELECT COUNT(*)
  FROM dba_tab_partitions
  WHERE table_owner = 'DM_CLANT' AND table_name = 'PTB_CREDS_IN_WORK'-- AND partition_name = 'REG_REGION'


