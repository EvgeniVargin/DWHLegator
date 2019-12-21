object frBaseEdtChLB: TfrBaseEdtChLB
  Left = 0
  Top = 0
  Width = 376
  Height = 483
  TabOrder = 0
  object panButtons: TPanel
    Left = 0
    Top = 456
    Width = 376
    Height = 27
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      376
      27)
    object bbCancel: TBitBtn
      Left = 280
      Top = 0
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1054#1090#1084#1077#1085#1072
      TabOrder = 0
      Kind = bkCancel
    end
    object bbSave: TBitBtn
      Left = 184
      Top = 0
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      TabOrder = 1
      Kind = bkOK
    end
  end
  object panClient: TPanel
    Left = 0
    Top = 0
    Width = 376
    Height = 456
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    inline frList: TfrBaseChLB
      Left = 0
      Top = 0
      Width = 376
      Height = 456
      Align = alClient
      TabOrder = 0
      inherited chlbList: TCheckListBox
        Width = 376
        Height = 456
      end
    end
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 16
    Top = 80
  end
end
