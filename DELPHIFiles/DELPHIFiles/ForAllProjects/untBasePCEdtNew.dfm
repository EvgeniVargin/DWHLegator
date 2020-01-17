object frmBasePCEdtNew: TfrmBasePCEdtNew
  Left = 725
  Top = 161
  Width = 533
  Height = 563
  Caption = 'frmBasePCEdtNew'
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
  inline frMaster: TfrPCEBase
    Left = 0
    Top = 0
    Width = 517
    Height = 524
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited PageControl: TPageControl
      Width = 517
      Height = 524
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          Width = 509
          inherited frButtons: TfrButtons
            Width = 509
            inherited ControlBar1: TControlBar
              Width = 509
            end
            inherited ImageList: TImageList
              Left = 56
            end
            inherited DImageList: TImageList
              Left = 24
            end
          end
        end
        inherited frList: TfrBase
          Width = 509
          Height = 490
          inherited dbGrid: TDBGridEh
            Width = 509
            Height = 465
            PopupMenu = pmnuMaster
          end
          inherited panTopFilter: TPanel
            Width = 509
            DesignSize = (
              509
              25)
            inherited edtSearch: TEdit
              Width = 494
            end
          end
        end
      end
      inherited tshForm: TTabSheet
        inherited panDown: TPanel
          Top = 491
          Width = 509
          DesignSize = (
            439
            25)
          inherited bbCancel: TBitBtn
            Left = 349
          end
          inherited bbSave: TBitBtn
            Left = 259
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 168
    Top = 72
  end
end
