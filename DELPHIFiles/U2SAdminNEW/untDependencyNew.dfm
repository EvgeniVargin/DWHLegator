object frmDependencyNew: TfrmDependencyNew
  Left = 639
  Top = 158
  Width = 699
  Height = 563
  Caption = 'frmDependencyNew'
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
    Left = 360
    Top = 0
    Height = 524
    Align = alRight
  end
  inline frTree: TfrBaseSQLTree
    Left = 363
    Top = 0
    Width = 320
    Height = 524
    Align = alRight
    TabOrder = 0
    inherited tvSQLTree: TTreeView
      Width = 320
      Height = 524
      PopupMenu = pmnuTree
    end
  end
  object panClient: TPanel
    Left = 0
    Top = 0
    Width = 360
    Height = 524
    Align = alClient
    Caption = 'panClient'
    TabOrder = 1
    object Splitter2: TSplitter
      Left = 1
      Top = 320
      Width = 358
      Height = 3
      Cursor = crVSplit
      Align = alBottom
    end
    inline frMaster: TfrBase
      Left = 1
      Top = 1
      Width = 358
      Height = 319
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
        Width = 358
        Height = 294
        FooterColor = clWindow
        PopupMenu = pmnuMaster
      end
      inherited panTopFilter: TPanel
        Width = 358
        inherited edtSearch: TEdit
          Width = 343
        end
      end
    end
    inline frDetail: TfrPCEBase
      Left = 1
      Top = 323
      Width = 358
      Height = 200
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
        Width = 358
        Height = 200
        inherited tshList: TTabSheet
          inherited panButtons: TPanel
            Width = 350
            inherited frButtons: TfrButtons
              Width = 350
              inherited ControlBar1: TControlBar
                Width = 350
              end
            end
          end
          inherited frList: TfrBase
            Width = 350
            Height = 166
            inherited dbGrid: TDBGridEh
              Width = 350
              Height = 141
              FooterColor = clWindow
              PopupMenu = pmnuDetail
            end
            inherited panTopFilter: TPanel
              Width = 350
              inherited edtSearch: TEdit
                Width = 335
              end
            end
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 136
    Top = 56
  end
  object pmnuDetail: TPopupMenu
    Left = 136
    Top = 344
  end
  object pmnuTree: TPopupMenu
    Left = 472
    Top = 56
  end
end
