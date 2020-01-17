object frmUploads: TfrmUploads
  Left = 597
  Top = 174
  Width = 905
  Height = 706
  Caption = #1042#1099#1075#1088#1091#1079#1082#1072' '#1088#1077#1079#1091#1083#1100#1090#1072#1090#1086#1074' '#1079#1072#1087#1088#1086#1089#1086#1074
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object pcUploads: TPageControl
    Left = 0
    Top = 0
    Width = 889
    Height = 667
    ActivePage = tshSQL
    Align = alClient
    TabOrder = 0
    object tshSQL: TTabSheet
      Caption = 'SQL'
      object panButtons: TPanel
        Left = 0
        Top = 612
        Width = 881
        Height = 27
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 0
        object Button1: TButton
          Left = 0
          Top = 1
          Width = 75
          Height = 25
          Caption = #1042#1099#1087#1086#1083#1085#1080#1090#1100
          TabOrder = 0
          OnClick = Button1Click
        end
      end
      object memSQL: TMemo
        Left = 0
        Top = 0
        Width = 881
        Height = 612
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
      end
    end
    object tshResult: TTabSheet
      Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090
      ImageIndex = 1
      inline frResult: TfrBase
        Left = 0
        Top = 0
        Width = 881
        Height = 639
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        inherited dbGrid: TDBGridEh
          Width = 881
          Height = 614
          DataSource = dsUploads
          Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgMultiSelect]
        end
        inherited panTopFilter: TPanel
          Width = 881
          inherited edtSearch: TEdit
            Width = 858
          end
        end
      end
    end
  end
  object qryUploads: TOraQuery
    SQL.Strings = (
      'select '
      'request_id,'
      'response,'
      'CREATE_TSTMP,'
      'CLIENT_ID,'
      'SCORE_TYPE'
      'from tddw.requests_result_cre'
      'where'
      
        'REQUEST_ID in ('#39'2811866'#39', '#39'2817216'#39', '#39'2817525'#39', '#39'2819949'#39', '#39'2821' +
        '499'#39', '#39'2822223'#39', '#39'2824526'#39', '#39'2824785'#39', '#39'2827104'#39', '#39'2827786'#39', '#39'28' +
        '27992'#39', '#39'2828120'#39', '#39'2831459'#39', '#39'2832811'#39', '#39'2836862'#39', '#39'2843068'#39', '#39 +
        '2845208'#39', '#39'2845989'#39', '#39'2847052'#39', '#39'2850503'#39', '#39'2853692'#39', '#39'2854037'#39',' +
        ' '#39'2854245'#39', '#39'2857301'#39', '#39'2858470'#39', '#39'2863804'#39', '#39'2871800'#39', '#39'2886059' +
        #39', '#39'2886498'#39', '#39'2887009'#39', '#39'2889977'#39', '#39'2892336'#39', '#39'2892877'#39', '#39'28933' +
        '74'#39', '#39'2895630'#39', '#39'2896034'#39', '#39'2896070'#39', '#39'2896446'#39', '#39'2896821'#39', '#39'289' +
        '7076'#39', '#39'2898397'#39', '#39'2898930'#39', '#39'2908190'#39', '#39'2918972'#39', '#39'2922719'#39', '#39'2' +
        '924418'#39', '#39'2925691'#39', '#39'2942340'#39', '#39'2950225'#39', '#39'2964427'#39', '#39'2966380'#39', ' +
        #39'2967590'#39', '#39'2968411'#39', '#39'2974821'#39', '#39'2981258'#39')'
      '-- '#1101#1090#1086' '#1089#1087#1080#1089#1086#1082' ID '#1079#1072#1103#1074#1086#1082', '#1087#1086' '#1082#1086#1090#1086#1088#1099#1084' '#1085#1072#1076#1086' '#1085#1072#1081#1090#1080' '#1080#1085#1092#1091
      'and'
      'SCORE_TYPE = '#39'CRONOS'#39)
    Left = 8
    Top = 32
  end
  object dsUploads: TOraDataSource
    DataSet = qryUploads
    Left = 40
    Top = 32
  end
end
