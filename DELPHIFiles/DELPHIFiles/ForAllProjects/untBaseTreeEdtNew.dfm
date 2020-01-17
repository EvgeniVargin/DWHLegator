object frmBaseTreeEdtNew: TfrmBaseTreeEdtNew
  Left = 582
  Top = 168
  Width = 573
  Height = 563
  Caption = 'frmBaseTreeEdtNew'
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
  inline frMaster: TfrPCSQLTree
    Left = 0
    Top = 0
    Width = 557
    Height = 524
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited pcTree: TPageControl
      Width = 557
      Height = 524
      inherited tshTree: TTabSheet
        inherited frButtons: TfrButtons
          Width = 549
          inherited ImageList: TImageList
            Left = 72
          end
        end
        inherited frTree: TfrBaseSQLTree
          Width = 549
          Height = 483
          inherited tvSQLTree: TTreeView
            Width = 549
            Height = 483
            PopupMenu = pmnuMaster
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 48
    Top = 120
  end
end
