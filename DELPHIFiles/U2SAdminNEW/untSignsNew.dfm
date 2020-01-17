inherited frmSignsNew: TfrmSignsNew
  Left = 585
  Top = 140
  Caption = 'frmSignsNew'
  OldCreateOrder = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  inherited frMaster: TfrPCEBase
    inherited PageControl: TPageControl
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          inherited frButtons: TfrButtons
            inherited ControlBar1: TControlBar
              inherited ToolBar: TToolBar
                inherited btnDel: TToolButton
                  OnClick = frButtonsbtnDelClick
                end
              end
            end
          end
        end
        inherited frList: TfrBase
          inherited dbGrid: TDBGridEh
            PopupMenu = pmnuMaster
          end
        end
      end
    end
  end
  object qrySigns: TOraQuery
    KeyFields = 'ID'
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      
        'SELECT ID,sign_name,data_type,sign_descr,hist_flg,archive_flg,si' +
        'gn_sql,mass_sql,ext_plsql,condition,entity_id,sp_code'
      '  FROM dm_skb.tb_signs_pool'
      'ORDER BY entity_id,hist_flg,sign_name')
    BeforePost = qrySignsBeforePost
    Left = 20
    Top = 110
    object qrySignsSIGN_NAME: TStringField
      DisplayLabel = #1053#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077':'
      DisplayWidth = 250
      FieldName = 'SIGN_NAME'
      Size = 255
    end
    object qrySignsDataType: TStringField
      DisplayLabel = #1058#1080#1087':'
      DisplayWidth = 100
      FieldKind = fkLookup
      FieldName = 'DataType'
      LookupDataSet = qryDataType
      LookupKeyFields = 'ID'
      LookupResultField = 'NAME'
      KeyFields = 'DATA_TYPE'
      Size = 30
      Lookup = True
    end
    object qrySignsSIGN_DESCR: TStringField
      DisplayLabel = #1054#1087#1080#1089#1072#1085#1080#1077':'
      DisplayWidth = 300
      FieldName = 'SIGN_DESCR'
      Size = 255
    end
    object qrySignsEntityName: TStringField
      DisplayLabel = #1057#1091#1097#1085#1086#1089#1090#1100':'
      DisplayWidth = 100
      FieldKind = fkLookup
      FieldName = 'EntityName'
      LookupDataSet = qryEntity
      LookupKeyFields = 'ID'
      LookupResultField = 'ENTITY_NAME'
      KeyFields = 'ENTITY_ID'
      Size = 256
      Lookup = True
    end
    object qrySignsHIST_FLG: TIntegerField
      DisplayLabel = #1055#1077#1088#1080#1086#1076#1072#1084#1080':'
      DisplayWidth = 100
      FieldName = 'HIST_FLG'
    end
    object qrySignsARCHIVE_FLG: TFloatField
      DisplayLabel = #1040#1088#1093#1080#1074#1085#1099#1081':'
      DisplayWidth = 100
      FieldName = 'ARCHIVE_FLG'
    end
    object qrySignsSIGN_SQL: TMemoField
      DisplayLabel = #1058#1077#1082#1089#1090' '#1079#1072#1087#1088#1086#1089#1072':'
      DisplayWidth = 400
      FieldName = 'SIGN_SQL'
      Visible = False
      BlobType = ftOraClob
    end
    object qrySignsMASS_SQL: TMemoField
      DisplayLabel = 'SQL '#1076#1083#1103' '#1084#1072#1089#1089#1086#1074#1086#1081' '#1079#1072#1083#1080#1074#1082#1080':'
      DisplayWidth = 400
      FieldName = 'MASS_SQL'
      Visible = False
      BlobType = ftOraClob
    end
    object qrySignsFINAL_PLSQL: TMemoField
      DisplayLabel = 'PL/SQL '#1076#1083#1103' '#1076#1086#1087#1086#1083#1085#1080#1090#1077#1083#1100#1085#1086#1081' '#1086#1073#1088#1072#1073#1086#1090#1082#1080':'
      DisplayWidth = 400
      FieldName = 'EXT_PLSQL'
      Visible = False
      BlobType = ftOraClob
    end
    object qrySignsCONDITION: TMemoField
      DisplayLabel = #1044#1086#1087'. '#1091#1089#1083#1086#1074#1080#1103' '#1079#1072#1087#1091#1089#1082#1072' '#1088#1072#1089#1095#1077#1090#1072':'
      DisplayWidth = 400
      FieldName = 'CONDITION'
      Visible = False
      BlobType = ftOraClob
    end
    object qrySignsID: TFloatField
      DisplayLabel = #1048#1076':'
      DisplayWidth = 30
      FieldName = 'ID'
      Visible = False
    end
    object qrySignsSP_CODE: TStringField
      DisplayLabel = #1050#1086#1076' '#1087#1072#1088#1090#1080#1094#1080#1080':'
      DisplayWidth = 80
      FieldName = 'SP_CODE'
      Visible = False
      Size = 30
    end
    object qrySignsENTITY_ID: TFloatField
      FieldName = 'ENTITY_ID'
      Visible = False
    end
    object qrySignsDATA_TYPE: TStringField
      DisplayWidth = 50
      FieldName = 'DATA_TYPE'
      Visible = False
      Size = 255
    end
  end
  object dsSigns: TOraDataSource
    DataSet = qrySigns
    Left = 52
    Top = 110
  end
  object spGetId: TOraStoredProc
    StoredProcName = 'dm_skb.pkg_etl_signs.get_empty_sign_id'
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      'begin'
      '  :RESULT := dm_skb.pkg_etl_signs.get_empty_sign_id;'
      'end;')
    Left = 92
    Top = 110
    ParamData = <
      item
        DataType = ftFloat
        Name = 'RESULT'
        ParamType = ptOutput
        IsResult = True
      end>
    CommandStoredProcName = 'dm_skb.pkg_etl_signs.get_empty_sign_id'
  end
  object spDropSign: TOraStoredProc
    StoredProcName = 'dm_skb.pkg_etl_signs.drop_sign'
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      'begin'
      '  dm_skb.pkg_etl_signs.drop_sign(:INSIGN, :OUTRES);'
      'end;')
    Left = 124
    Top = 110
    ParamData = <
      item
        DataType = ftString
        Name = 'INSIGN'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'OUTRES'
        ParamType = ptOutput
      end>
    CommandStoredProcName = 'dm_skb.pkg_etl_signs.drop_sign'
  end
  object qryDataType: TOraQuery
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      'SELECT '#39#1063#1080#1089#1083#1086#39' AS id,'#39#1063#1080#1089#1083#1086#39' AS name FROM dual'
      'UNION ALL'
      'SELECT '#39#1057#1090#1088#1086#1082#1072#39','#39#1057#1090#1088#1086#1082#1072#39' FROM dual'
      'UNION ALL'
      'SELECT '#39#1044#1072#1090#1072#39','#39#1044#1072#1090#1072#39' FROM dual')
    Left = 20
    Top = 142
    object qryDataTypeID: TStringField
      FieldName = 'ID'
      Visible = False
      Size = 6
    end
    object qryDataTypeNAME: TStringField
      DisplayLabel = #1053#1072#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077':'
      DisplayWidth = 100
      FieldName = 'NAME'
      Size = 6
    end
  end
  object qryEntity: TOraQuery
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      'SELECT id,entity_name FROM dm_Skb.tb_entity ORDER BY id')
    Left = 20
    Top = 174
  end
  object sqlCheckOldPart: TOraSQL
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      'DECLARE'
      '  vCou INTEGER;'
      '  outHaveOldPart INTEGER;'
      '  vTableName VARCHAR2(256);'
      '  vHistFlg NUMBER;'
      '  vFctTable VARCHAR2(256);'
      '  vHistTable VARCHAR2(256);'
      'BEGIN'
      
        '  SELECT hist_flg,UPPER(e.fct_table_name),UPPER(e.hist_table_nam' +
        'e)'
      '    INTO vHistFlg,vFctTable,vHistTable'
      '    FROM tb_signs_pool p'
      '         INNER JOIN tb_entity e ON e.id = p.entity_id'
      '    WHERE UPPER(sign_name) = UPPER(:inPartName);'
      ''
      '  IF vHistFlg = 0 THEN'
      '    SELECT COUNT(1) INTO vCou'
      '      FROM all_tab_partitions'
      
        '      WHERE table_owner = UPPER(pkg_etl_signs.GetVarValue('#39'vOwne' +
        'r'#39')) AND table_name = vFctTable AND partition_name = UPPER(:inPa' +
        'rtName);'
      '  ELSE'
      '    SELECT COUNT(1) INTO vCou'
      '      FROM all_tab_partitions'
      
        '      WHERE table_owner = UPPER(pkg_etl_signs.GetVarValue('#39'vOwne' +
        'r'#39')) AND table_name = vHistTable AND partition_name = UPPER(:inP' +
        'artName);'
      '  END IF;'
      '  :outHaveOldPart := SIGN(vCou);'
      'EXCEPTION WHEN NO_DATA_FOUND THEN'
      '  :outHaveOldPart := 0;'
      'END;')
    Left = 20
    Top = 238
    ParamData = <
      item
        DataType = ftString
        Name = 'inPartName'
        ParamType = ptInput
      end
      item
        DataType = ftInteger
        Name = 'outHaveOldPart'
        ParamType = ptOutput
      end>
  end
  object sqlDelOldPart: TOraSQL
    Session = frmU2SAdmin.Session
    SQL.Strings = (
      'DECLARE'
      '  vTableName VARCHAR2(256);'
      '  vHistFlg NUMBER;'
      '  vFctTable VARCHAR2(256);'
      '  vHistTable VARCHAR2(256);'
      'BEGIN'
      
        '  SELECT hist_flg,UPPER(e.fct_table_name),UPPER(e.hist_table_nam' +
        'e)'
      '    INTO vHistFlg,vFctTable,vHistTable'
      '    FROM dm_skb.tb_signs_pool p'
      '         INNER JOIN dm_skb.tb_entity e ON e.id = p.entity_id'
      '    WHERE UPPER(sign_name) = UPPER(:inPartName);'
      ''
      '  IF vHistFlg = 0 THEN'
      
        '    EXECUTE IMMEDIATE '#39'ALTER TABLE '#39'||LOWER(pkg_etl_signs.GetVar' +
        'Value('#39'vOwner'#39'))||'#39'.'#39'||vFctTable||'#39' DROP PARTITION '#39'||UPPER(:inP' +
        'artName);'
      
        '    :OldTable := UPPER(pkg_etl_signs.GetVarValue('#39'vOwner'#39')||'#39'.'#39'|' +
        '|vFctTable);'
      
        '    :NewTable := UPPER(pkg_etl_signs.GetVarValue('#39'vOwner'#39')||'#39'.'#39'|' +
        '|vHistTable);'
      '  ELSE'
      
        '    EXECUTE IMMEDIATE '#39'ALTER TABLE '#39'||LOWER(pkg_etl_signs.GetVar' +
        'Value('#39'vOwner'#39'))||'#39'.'#39'||vHistTable||'#39' DROP PARTITION '#39'||UPPER(:in' +
        'PartName);'
      
        '    :OldTable := UPPER(pkg_etl_signs.GetVarValue('#39'vOwner'#39')||'#39'.'#39'|' +
        '|vHistTable);'
      
        '    :NewTable := UPPER(pkg_etl_signs.GetVarValue('#39'vOwner'#39')||'#39'.'#39'|' +
        '|vFctTable);'
      '  END IF;'
      'EXCEPTION WHEN NO_DATA_FOUND THEN'
      '  :OldTable := '#39'<'#1053#1045' '#1053#1040#1049#1044#1045#1053#1040'>'#39';'
      '  :NewTable := '#39'<'#1053#1045' '#1053#1040#1049#1044#1045#1053#1040'>'#39';'
      'END;')
    Left = 52
    Top = 238
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'inPartName'
      end
      item
        DataType = ftString
        Name = 'OldTable'
        ParamType = ptOutput
      end
      item
        DataType = ftString
        Name = 'NewTable'
        ParamType = ptOutput
      end>
  end
end
