object frBaseRepParams: TfrBaseRepParams
  Left = 0
  Top = 0
  Width = 320
  Height = 408
  TabOrder = 0
  object scrlBox: TScrollBox
    Left = 0
    Top = 0
    Width = 320
    Height = 376
    Align = alTop
    BorderStyle = bsNone
    TabOrder = 0
  end
  object panBtn: TPanel
    Left = 0
    Top = 376
    Width = 320
    Height = 32
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object btnExRep: TButton
      Left = 4
      Top = 4
      Width = 120
      Height = 25
      Caption = #1057#1092#1086#1088#1084#1080#1088#1086#1074#1072#1090#1100' '#1086#1090#1095#1077#1090
      TabOrder = 0
      OnClick = btnExRepClick
    end
  end
end
