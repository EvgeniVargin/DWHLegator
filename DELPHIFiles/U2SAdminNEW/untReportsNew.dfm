object frmReportsNew: TfrmReportsNew
  Left = 717
  Top = 167
  Width = 652
  Height = 563
  Caption = 'frmReportsNew'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 250
    Top = 0
    Height = 524
  end
  inline frMaster: TfrBase
    Left = 253
    Top = 0
    Width = 383
    Height = 524
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited dbGrid: TDBGridEh
      Width = 383
      Height = 499
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      PopupMenu = pmnuMaster
    end
    inherited panTopFilter: TPanel
      Width = 383
      inherited edtSearch: TEdit
        Width = 368
      end
    end
  end
  inline frDetail: TfrBaseRepParams
    Left = 0
    Top = 0
    Width = 250
    Height = 524
    Align = alLeft
    Color = clBtnFace
    ParentColor = False
    TabOrder = 1
    inherited scrlBox: TScrollBox
      Width = 250
      Height = 492
    end
    inherited panBtn: TPanel
      Top = 492
      Width = 250
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 112
    Top = 32
  end
end
