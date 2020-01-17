object frmReportResultNew: TfrmReportResultNew
  Left = 693
  Top = 154
  Width = 697
  Height = 563
  Caption = 'frmReportResultNew'
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
  inline frMaster: TfrBase
    Left = 0
    Top = 0
    Width = 681
    Height = 524
    Align = alClient
    Color = clWindow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    inherited dbGrid: TDBGridEh
      Width = 681
      Height = 499
      FooterColor = clWindow
    end
    inherited panTopFilter: TPanel
      Width = 681
      inherited edtSearch: TEdit
        Width = 666
      end
    end
  end
  object tmrReportResult: TTimer
    Enabled = False
    OnTimer = tmrReportResultTimer
    Left = 112
    Top = 64
  end
end
