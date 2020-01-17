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
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 0
  end
  object panBtn: TPanel
    Left = 0
    Top = 376
    Width = 320
    Height = 32
    Align = alBottom
    BevelOuter = bvNone
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
    object chbToExcel: TCheckBox
      Left = 128
      Top = 8
      Width = 121
      Height = 17
      Alignment = taLeftJustify
      Caption = #1042#1099#1075#1088#1091#1079#1080#1090#1100' '#1074' Excel'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
  end
  object tmrRepParams: TTimer
    OnTimer = tmrRepParamsTimer
    Left = 8
    Top = 8
  end
end
