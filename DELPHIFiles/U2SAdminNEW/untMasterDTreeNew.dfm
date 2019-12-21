object frmMasterDTreeNew: TfrmMasterDTreeNew
  Left = 671
  Top = 143
  Width = 617
  Height = 563
  Caption = 'frmMasterDTreeNew'
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
    Width = 601
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  inline frMaster: TfrPCEBase
    Left = 0
    Top = 0
    Width = 601
    Height = 300
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited PageControl: TPageControl
      Width = 601
      Height = 300
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          Width = 593
          inherited frButtons: TfrButtons
            Width = 593
            inherited ControlBar1: TControlBar
              Width = 593
            end
          end
        end
        inherited frList: TfrBase
          Width = 593
          Height = 266
          inherited dbGrid: TDBGridEh
            Width = 593
            Height = 241
            Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
            PopupMenu = pmnuMaster
          end
          inherited panTopFilter: TPanel
            Width = 593
            inherited edtSearch: TEdit
              Width = 578
            end
          end
        end
      end
    end
  end
  inline frDetail: TfrPCSQLTree
    Left = 0
    Top = 303
    Width = 601
    Height = 221
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    inherited pcTree: TPageControl
      Width = 601
      Height = 221
      inherited tshTree: TTabSheet
        inherited frButtons: TfrButtons
          Width = 593
        end
        inherited frTree: TfrBaseSQLTree
          Width = 593
          Height = 180
          inherited tvSQLTree: TTreeView
            Width = 593
            Height = 180
            PopupMenu = pmnuDetail
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 144
    Top = 104
  end
  object pmnuDetail: TPopupMenu
    Left = 112
    Top = 376
  end
end
