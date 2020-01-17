object frmBaseMainForm: TfrmBaseMainForm
  Left = 516
  Top = 172
  Width = 660
  Height = 518
  Caption = 'frmBaseMainForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 300
    Top = 0
    Width = 4
    Height = 479
  end
  object panList: TPanel
    Left = 0
    Top = 0
    Width = 300
    Height = 479
    Align = alLeft
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inline frTree: TfrBaseSQLTree
      Left = 0
      Top = 0
      Width = 300
      Height = 479
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      inherited tvSQLTree: TTreeView
        Width = 300
        Height = 479
        OnChange = frTreetvSQLTreeChange
      end
    end
  end
  object panBody: TPanel
    Left = 304
    Top = 0
    Width = 340
    Height = 479
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
  end
  object Session: TOraSession
    ThreadSafety = False
    Options.DateFormat = 'DD.MM.RRRR HH24:MI:SS'
    Left = 80
    Top = 8
  end
end
