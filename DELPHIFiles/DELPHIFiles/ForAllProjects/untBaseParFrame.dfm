object frBaseParFrame: TfrBaseParFrame
  Left = 0
  Top = 0
  Width = 614
  Height = 457
  TabOrder = 0
  object Splitter1: TSplitter
    Left = 177
    Top = 0
    Height = 457
  end
  inline frListParams: TfrBaseRepParams
    Left = 0
    Top = 0
    Width = 177
    Height = 457
    Align = alLeft
    TabOrder = 0
    inherited scrlBox: TScrollBox
      Width = 177
      Height = 425
    end
    inherited panBtn: TPanel
      Top = 425
      Width = 177
      inherited btnExRep: TButton
        Caption = #1057#1092#1086#1088#1084#1080#1088#1086#1074#1072#1090#1100
        OnClick = frListParamsbtnExRepClick
      end
    end
  end
  inline frList: TfrBase
    Left = 180
    Top = 0
    Width = 434
    Height = 457
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    inherited dbGrid: TDBGridEh
      Width = 434
      Height = 432
    end
    inherited panTopFilter: TPanel
      Width = 434
      inherited edtSearch: TEdit
        Width = 387
      end
    end
  end
end
