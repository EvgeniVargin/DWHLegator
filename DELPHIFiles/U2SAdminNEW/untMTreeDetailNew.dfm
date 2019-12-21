object frmMTreeDetailNew: TfrmMTreeDetailNew
  Left = 644
  Top = 186
  Width = 600
  Height = 510
  Caption = 'frmMTreeDetailNew'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 16
  object Splitter1: TSplitter
    Left = 0
    Top = 168
    Width = 584
    Height = 3
    Cursor = crVSplit
    Align = alBottom
  end
  inline frMaster: TfrBaseSQLTree
    Left = 0
    Top = 0
    Width = 584
    Height = 168
    Align = alClient
    TabOrder = 0
    inherited tvSQLTree: TTreeView
      Width = 584
      Height = 168
      PopupMenu = pmnuMaster
    end
  end
  inline frDetail: TfrPCEBase
    Left = 0
    Top = 171
    Width = 584
    Height = 300
    Align = alBottom
    Color = clWindow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    inherited PageControl: TPageControl
      Width = 584
      Height = 300
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          Width = 576
          inherited frButtons: TfrButtons
            Width = 576
            inherited ControlBar1: TControlBar
              Width = 576
            end
          end
        end
        inherited frList: TfrBase
          Width = 576
          Height = 266
          inherited dbGrid: TDBGridEh
            Width = 576
            Height = 241
            FooterColor = clWindow
            PopupMenu = pmnuDetail
          end
          inherited panTopFilter: TPanel
            Width = 576
            inherited edtSearch: TEdit
              Width = 561
            end
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 208
    Top = 72
  end
  object pmnuDetail: TPopupMenu
    Left = 216
    Top = 312
  end
end
