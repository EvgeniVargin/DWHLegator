object frmBaseUPrivs: TfrmBaseUPrivs
  Left = 524
  Top = 174
  Width = 596
  Height = 566
  Caption = #1056#1086#1083#1080' '#1080' '#1087#1088#1080#1074#1080#1083#1077#1075#1080#1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 200
    Width = 588
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  object panRoles: TPanel
    Left = 0
    Top = 0
    Width = 588
    Height = 200
    Align = alTop
    BevelOuter = bvNone
    Caption = 'panRoles'
    ParentColor = True
    TabOrder = 0
    inline frRoles: TfrBase
      Left = 0
      Top = 0
      Width = 588
      Height = 200
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      inherited dbGrid: TDBGridEh
        Width = 588
        Height = 175
        DataSource = dsRoles
        Columns = <
          item
            EditButtons = <>
            FieldName = 'NAME'
            Footers = <>
            Width = 250
          end
          item
            Checkboxes = True
            EditButtons = <>
            FieldName = 'GRANT'
            Footers = <>
            KeyList.Strings = (
              '1'
              '0')
            Width = 50
          end>
      end
      inherited panTopFilter: TPanel
        Width = 588
        inherited edtSearch: TEdit
          Width = 565
        end
      end
    end
  end
  object panButtons: TPanel
    Left = 0
    Top = 513
    Width = 588
    Height = 26
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    DesignSize = (
      588
      26)
    object bbCancel: TBitBtn
      Left = 496
      Top = 1
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1054#1090#1084#1077#1085#1072
      TabOrder = 0
      Kind = bkCancel
    end
    object bbSave: TBitBtn
      Left = 400
      Top = 1
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      TabOrder = 1
      OnClick = bbSaveClick
      Kind = bkOK
    end
  end
  object panPrivs: TPanel
    Left = 0
    Top = 203
    Width = 588
    Height = 310
    Align = alClient
    BevelOuter = bvNone
    Caption = 'panPrivs'
    ParentColor = True
    TabOrder = 2
    inline frPrivs: TfrBase
      Left = 0
      Top = 0
      Width = 588
      Height = 310
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      inherited dbGrid: TDBGridEh
        Width = 588
        Height = 285
        DataSource = dsPrivs
        Columns = <
          item
            EditButtons = <>
            FieldName = 'NAME'
            Footers = <>
            Width = 250
          end
          item
            Checkboxes = True
            EditButtons = <>
            FieldName = 'SELECT'
            Footers = <>
            KeyList.Strings = (
              '1'
              '0'
              '-1')
            Width = 50
          end
          item
            Checkboxes = True
            EditButtons = <>
            FieldName = 'INSERT'
            Footers = <>
            KeyList.Strings = (
              '1'
              '0'
              '-1')
            Width = 50
          end
          item
            Checkboxes = True
            EditButtons = <>
            FieldName = 'UPDATE'
            Footers = <>
            KeyList.Strings = (
              '1'
              '0'
              '-1')
            Width = 50
          end
          item
            Checkboxes = True
            EditButtons = <>
            FieldName = 'DELETE'
            Footers = <>
            KeyList.Strings = (
              '1'
              '0'
              '-1')
            Width = 50
          end
          item
            Checkboxes = True
            EditButtons = <>
            FieldName = 'EXECUTE'
            Footers = <>
            KeyList.Strings = (
              '1'
              '0'
              '-1')
          end>
      end
      inherited panTopFilter: TPanel
        Width = 588
        inherited edtSearch: TEdit
          Width = 565
        end
      end
    end
  end
  object qryRoles: TOraQuery
    SQL.Strings = (
      'SELECT DISTINCT'
      '       r.role AS NAME'
      '      ,NVL2(rp.GRANTEE,1,0) AS "GRANT"'
      '  FROM dba_roles r'
      '       CROSS JOIN (SELECT :inUserName AS username FROM dual) u'
      '       LEFT JOIN dba_role_privs rp'
      '         ON rp.GRANTEE = u.username AND rp.GRANTED_ROLE = r.ROLE'
      'ORDER BY NVL2(rp.GRANTEE,1,0) DESC,r.ROLE')
    FetchAll = True
    CachedUpdates = True
    BeforeOpen = qryRolesBeforeOpen
    AfterOpen = qryRolesAfterOpen
    Left = 24
    Top = 32
    ParamData = <
      item
        DataType = ftString
        Name = 'inUserName'
        ParamType = ptInput
      end>
    object qryRolesNAME: TStringField
      DisplayLabel = #1053#1072#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077' '#1088#1086#1083#1080':'
      FieldName = 'NAME'
      ReadOnly = True
      Required = True
      Size = 30
    end
    object qryRolesGRANT: TFloatField
      FieldName = 'GRANT'
    end
  end
  object dsRoles: TOraDataSource
    DataSet = qryRoles
    Left = 56
    Top = 32
  end
  object qryPrivs: TOraQuery
    SQL.Strings = (
      'SELECT NAME'
      
        '      ,DECODE(object_type,'#39'PACKAGE'#39',-1,'#39'PROCEDURE'#39',-1,'#39'FUNCTION'#39 +
        ',-1,NVL("'#39'SELECT'#39'",0)) AS "SELECT"'
      
        '      ,DECODE(object_type,'#39'VIEW'#39',-1,'#39'PACKAGE'#39',-1,'#39'PROCEDURE'#39',-1,' +
        #39'FUNCTION'#39',-1,NVL("'#39'INSERT'#39'",0)) AS "INSERT"'
      
        '      ,DECODE(object_type,'#39'VIEW'#39',-1,'#39'PACKAGE'#39',-1,'#39'PROCEDURE'#39',-1,' +
        #39'FUNCTION'#39',-1,NVL("'#39'UPDATE'#39'",0)) AS "UPDATE"'
      
        '      ,DECODE(object_type,'#39'VIEW'#39',-1,'#39'PACKAGE'#39',-1,'#39'PROCEDURE'#39',-1,' +
        #39'FUNCTION'#39',-1,NVL("'#39'DELETE'#39'",0)) AS "DELETE"'
      
        '      ,DECODE(object_type,'#39'VIEW'#39',-1,'#39'TABLE'#39',-1,NVL("'#39'EXECUTE'#39'",0' +
        ')) AS "EXECUTE"'
      '      ,object_type'
      'FROM (      '
      'SELECT * FROM'
      '('
      'SELECT DISTINCT'
      '                        ao.username AS user_name'
      '                       ,ao.owner'
      '                       ,ao.owner||'#39'.'#39'||ao.obj AS NAME'
      '                       ,NVL2(uo.user_name,1,0) AS ID'
      '                       ,uo.privilege AS priv'
      '                       ,ao.object_type'
      '                  FROM (SELECT owner'
      '                              ,object_name AS obj'
      '                              ,u.username'
      '                              ,ao.object_type'
      '                          FROM sys.all_objects ao'
      
        '                               CROSS JOIN (SELECT :inUserName AS' +
        ' username FROM dual) u'
      
        '                          WHERE object_type IN ('#39'TABLE'#39','#39'VIEW'#39','#39 +
        'PACKAGE'#39','#39'PROCEDURE'#39','#39'FUNCTION'#39')'
      
        '                            AND NOT(ao.owner IN ('#39'SYS'#39','#39'SYSMAN'#39',' +
        #39'SYSTEM'#39','#39'XDB'#39','#39'WMSYS'#39'))'
      '                            AND (:inOwner IS NULL OR'
      '                                 :inOwner IS NOT NULL AND'
      
        '                                 ao.owner IN (SELECT UPPER(regex' +
        'p_substr(:inOwner,'#39'[^,]+'#39', 1, LEVEL)) AS a'
      '                                               FROM dual'
      
        '                                             CONNECT BY instr(:i' +
        'nOwner, '#39','#39', 1, LEVEL - 1) > 0)'
      '                                )'
      '                       ) ao LEFT JOIN'
      '                       (SELECT grantee AS user_name'
      '                              ,owner'
      '                              ,table_name AS obj'
      '                              ,PRIVILEGE'
      '                          FROM sys.dba_tab_privs'
      '                          WHERE grantee = :inUserName'
      
        '                       ) uo ON uo.owner = ao.owner AND uo.obj = ' +
        'ao.obj AND uo.user_name = ao.username'
      
        ') PIVOT (SUM(ID) FOR priv IN ('#39'SELECT'#39','#39'INSERT'#39','#39'UPDATE'#39','#39'DELETE' +
        #39','#39'EXECUTE'#39'))'
      
        ') ORDER BY COALESCE("'#39'SELECT'#39'","'#39'INSERT'#39'","'#39'UPDATE'#39'","'#39'DELETE'#39'",' +
        '"'#39'EXECUTE'#39'") NULLS LAST,object_type DESC,NAME')
    FetchAll = True
    CachedUpdates = True
    BeforeOpen = qryPrivsBeforeOpen
    AfterOpen = qryPrivsAfterOpen
    Left = 24
    Top = 268
    ParamData = <
      item
        DataType = ftString
        Name = 'inUserName'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'inOwner'
        ParamType = ptInput
      end>
    object qryPrivsSELECT: TFloatField
      FieldName = 'SELECT'
    end
    object qryPrivsINSERT: TFloatField
      FieldName = 'INSERT'
    end
    object qryPrivsUPDATE: TFloatField
      FieldName = 'UPDATE'
    end
    object qryPrivsDELETE: TFloatField
      FieldName = 'DELETE'
    end
    object qryPrivsEXCUTE: TFloatField
      FieldName = 'EXECUTE'
    end
    object qryPrivsNAME: TStringField
      DisplayLabel = #1053#1072#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077' '#1086#1073#1098#1077#1082#1090#1072':'
      DisplayWidth = 150
      FieldName = 'NAME'
      ReadOnly = True
      Size = 61
    end
    object qryPrivsOBJECT_TYPE: TStringField
      FieldName = 'OBJECT_TYPE'
      Size = 19
    end
  end
  object dsPrivs: TOraDataSource
    DataSet = qryPrivs
    Left = 56
    Top = 268
  end
  object Scr: TOraScript
    Left = 24
    Top = 307
  end
end
