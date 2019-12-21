object frmBaseMasterDetailNew: TfrmBaseMasterDetailNew
  Left = 611
  Top = 169
  Width = 524
  Height = 610
  Caption = 'frmBaseMasterDetailNew'
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
    Top = 200
    Width = 508
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  inline frMaster: TfrBase
    Left = 0
    Top = 0
    Width = 508
    Height = 200
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited dbGrid: TDBGridEh
      Width = 508
      Height = 175
      PopupMenu = pmnuMaster
    end
    inherited panTopFilter: TPanel
      Width = 508
      inherited edtSearch: TEdit
        Width = 493
      end
    end
  end
  inline frDetail: TfrPCEBase
    Left = 0
    Top = 203
    Width = 508
    Height = 368
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    inherited PageControl: TPageControl
      Width = 508
      Height = 368
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          Width = 500
          inherited frButtons: TfrButtons
            Width = 500
            inherited ControlBar1: TControlBar
              Width = 500
            end
          end
        end
        inherited frList: TfrBase
          Width = 500
          Height = 334
          inherited dbGrid: TDBGridEh
            Width = 500
            Height = 309
            PopupMenu = pmnuDetail
          end
          inherited panTopFilter: TPanel
            Width = 500
            inherited edtSearch: TEdit
              Width = 485
            end
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 152
    Top = 64
  end
  object pmnuDetail: TPopupMenu
    Left = 160
    Top = 320
  end
end
