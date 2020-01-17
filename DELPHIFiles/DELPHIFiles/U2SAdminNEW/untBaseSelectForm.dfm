object frmSelect: TfrmSelect
  Left = 463
  Top = 226
  Width = 300
  Height = 300
  Caption = 'frmSelect'
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
  inline frSelect: TfrBase
    Left = 0
    Top = 0
    Width = 292
    Height = 273
    Align = alClient
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    inherited dbGrid: TDBGridEh
      Width = 292
      Height = 248
      Color = clWindow
      ParentColor = False
      OnDblClick = frSelectdbGridDblClick
    end
    inherited panTopFilter: TPanel
      Width = 292
      ParentColor = False
      inherited edtSearch: TEdit
        Width = 269
        Color = clWindow
        ParentColor = False
      end
    end
  end
end
