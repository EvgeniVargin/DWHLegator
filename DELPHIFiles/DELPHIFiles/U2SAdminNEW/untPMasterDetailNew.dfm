object frmPMasterDetailNew: TfrmPMasterDetailNew
  Left = 703
  Top = 210
  Width = 773
  Height = 675
  Caption = 'frmPMasterDetailNew'
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
    Top = 400
    Width = 757
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  inline frMaster: TfrBaseParFrame
    Left = 0
    Top = 0
    Width = 757
    Height = 400
    Align = alTop
    TabOrder = 0
    inherited Splitter1: TSplitter
      Height = 400
    end
    inherited frListParams: TfrBaseRepParams
      Height = 400
      inherited scrlBox: TScrollBox
        Height = 368
      end
      inherited panBtn: TPanel
        Top = 368
      end
    end
    inherited frList: TfrBase
      Width = 577
      Height = 400
      inherited dbGrid: TDBGridEh
        Width = 577
        Height = 375
        PopupMenu = pmnuMaster
      end
      inherited panTopFilter: TPanel
        Width = 577
        inherited edtSearch: TEdit
          Width = 530
        end
      end
    end
  end
  inline frDetail: TfrPCEBase
    Left = 0
    Top = 403
    Width = 757
    Height = 233
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    inherited PageControl: TPageControl
      Width = 757
      Height = 233
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          Width = 749
          inherited frButtons: TfrButtons
            Width = 749
            inherited ControlBar1: TControlBar
              Width = 749
            end
          end
        end
        inherited frList: TfrBase
          Width = 749
          Height = 199
          inherited dbGrid: TDBGridEh
            Width = 749
            Height = 174
          end
          inherited panTopFilter: TPanel
            Width = 749
            inherited edtSearch: TEdit
              Width = 702
            end
          end
        end
      end
    end
  end
  object pmnuMaster: TPopupMenu
    Left = 296
    Top = 48
  end
end
