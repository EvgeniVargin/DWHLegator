object frmMasterDetailCommentEditor: TfrmMasterDetailCommentEditor
  Left = 717
  Top = 221
  Width = 851
  Height = 675
  Caption = 'frmMasterDetailCommentEditor'
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
    Top = 345
    Width = 835
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  object Splitter2: TSplitter
    Left = 0
    Top = 508
    Width = 835
    Height = 3
    Cursor = crVSplit
    Align = alBottom
  end
  inline frMaster: TfrPCEBase
    Left = 0
    Top = 0
    Width = 835
    Height = 345
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    inherited PageControl: TPageControl
      Width = 835
      Height = 345
      inherited tshList: TTabSheet
        inherited panButtons: TPanel
          Width = 827
          inherited frButtons: TfrButtons
            Width = 827
            inherited ControlBar1: TControlBar
              Width = 827
            end
          end
        end
        inherited frList: TfrBase
          Width = 827
          Height = 311
          inherited dbGrid: TDBGridEh
            Width = 827
            Height = 286
          end
          inherited panTopFilter: TPanel
            Width = 827
            inherited edtSearch: TEdit
              Width = 780
            end
          end
        end
      end
    end
  end
  object panRichButtons: TPanel
    Left = 0
    Top = 600
    Width = 835
    Height = 36
    Align = alBottom
    TabOrder = 1
    DesignSize = (
      835
      36)
    object bbRichCancel: TBitBtn
      Left = 740
      Top = 4
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1054#1090#1084#1077#1085#1072
      TabOrder = 0
      OnClick = bbRichCancelClick
      Glyph.Data = {
        DE010000424DDE01000000000000760000002800000024000000120000000100
        0400000000006801000000000000000000001000000000000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        333333333333333333333333000033338833333333333333333F333333333333
        0000333911833333983333333388F333333F3333000033391118333911833333
        38F38F333F88F33300003339111183911118333338F338F3F8338F3300003333
        911118111118333338F3338F833338F3000033333911111111833333338F3338
        3333F8330000333333911111183333333338F333333F83330000333333311111
        8333333333338F3333383333000033333339111183333333333338F333833333
        00003333339111118333333333333833338F3333000033333911181118333333
        33338333338F333300003333911183911183333333383338F338F33300003333
        9118333911183333338F33838F338F33000033333913333391113333338FF833
        38F338F300003333333333333919333333388333338FFF830000333333333333
        3333333333333333333888330000333333333333333333333333333333333333
        0000}
      NumGlyphs = 2
    end
    object bbRichSave: TBitBtn
      Left = 648
      Top = 4
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      Default = True
      TabOrder = 1
      OnClick = bbRichSaveClick
      Glyph.Data = {
        DE010000424DDE01000000000000760000002800000024000000120000000100
        0400000000006801000000000000000000001000000000000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        3333333333333333333333330000333333333333333333333333F33333333333
        00003333344333333333333333388F3333333333000033334224333333333333
        338338F3333333330000333422224333333333333833338F3333333300003342
        222224333333333383333338F3333333000034222A22224333333338F338F333
        8F33333300003222A3A2224333333338F3838F338F33333300003A2A333A2224
        33333338F83338F338F33333000033A33333A222433333338333338F338F3333
        0000333333333A222433333333333338F338F33300003333333333A222433333
        333333338F338F33000033333333333A222433333333333338F338F300003333
        33333333A222433333333333338F338F00003333333333333A22433333333333
        3338F38F000033333333333333A223333333333333338F830000333333333333
        333A333333333333333338330000333333333333333333333333333333333333
        0000}
      NumGlyphs = 2
    end
  end
  object memComment: TDBMemo
    Left = 0
    Top = 348
    Width = 835
    Height = 160
    Align = alClient
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    ReadOnly = True
    TabOrder = 2
  end
  object memCommentAdd: TMemo
    Left = 0
    Top = 511
    Width = 835
    Height = 89
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object tmrRichButtons: TTimer
    Interval = 500
    OnTimer = tmrRichButtonsTimer
    Left = 616
    Top = 600
  end
  object pmnuMaster: TPopupMenu
    Left = 208
    Top = 80
  end
end
