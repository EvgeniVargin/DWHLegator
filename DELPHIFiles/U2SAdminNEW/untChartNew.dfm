object frmChartNew: TfrmChartNew
  Left = 678
  Top = 198
  Width = 722
  Height = 675
  Caption = 'frmChartNew'
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
  object Splitter1: TSplitter
    Left = 257
    Top = 0
    Height = 636
  end
  inline frMaster: TfrBaseChart
    Left = 260
    Top = 0
    Width = 446
    Height = 636
    Align = alClient
    TabOrder = 0
    inherited Chart: TDBChart
      Width = 446
      Height = 636
    end
  end
  inline frParams: TfrBaseRepParams
    Left = 0
    Top = 0
    Width = 257
    Height = 636
    Align = alLeft
    TabOrder = 1
    inherited scrlBox: TScrollBox
      Width = 257
      Height = 604
    end
    inherited panBtn: TPanel
      Top = 604
      Width = 257
      inherited btnExRep: TButton
        Width = 130
        Caption = #1054#1073#1085#1086#1074#1080#1090#1100' '#1076#1080#1072#1075#1088#1072#1084#1084#1091
        OnClick = frDetailbtnExRepClick
      end
    end
  end
  object tmrRefresh: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = tmrRefreshTimer
    Left = 288
    Top = 72
  end
end
