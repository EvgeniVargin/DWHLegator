object frmViewerNew: TfrmViewerNew
  Left = 629
  Top = 130
  Width = 543
  Height = 563
  Caption = 'frmViewerNew'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  inline frMaster: TfrBase
    Left = 0
    Top = 0
    Width = 535
    Height = 536
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited dbGrid: TDBGridEh
      Width = 535
      Height = 511
      PopupMenu = pmnuMaster
    end
    inherited panTopFilter: TPanel
      Width = 535
      inherited edtSearch: TEdit
        Width = 512
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    Left = 96
    Top = 32
  end
  object pmnuMaster: TPopupMenu
    Left = 144
    Top = 32
  end
end
