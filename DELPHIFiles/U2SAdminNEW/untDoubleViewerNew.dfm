object frmDoubleViewerNew: TfrmDoubleViewerNew
  Left = 613
  Top = 176
  Width = 579
  Height = 563
  Caption = 'frmDoubleViewerNew'
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
    Left = 0
    Top = 300
    Width = 563
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  inline frMaster: TfrBase
    Left = 0
    Top = 0
    Width = 563
    Height = 300
    Align = alTop
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    inherited dbGrid: TDBGridEh
      Width = 563
      PopupMenu = pmnuMaster
    end
    inherited panTopFilter: TPanel
      Width = 563
      inherited edtSearch: TEdit
        Width = 548
      end
    end
  end
  inline frDetail: TfrBase
    Left = 0
    Top = 303
    Width = 563
    Height = 221
    Align = alClient
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    inherited dbGrid: TDBGridEh
      Width = 563
      Height = 196
      PopupMenu = pmnuDetail
    end
    inherited panTopFilter: TPanel
      Width = 563
      inherited edtSearch: TEdit
        Width = 548
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 136
    Top = 40
  end
  object pmnuDetail: TPopupMenu
    Left = 144
    Top = 376
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = Timer1Timer
    Left = 184
    Top = 40
  end
end
