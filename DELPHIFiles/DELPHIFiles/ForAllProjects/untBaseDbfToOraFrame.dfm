object frDbfToOra: TfrDbfToOra
  Left = 0
  Top = 0
  Width = 562
  Height = 499
  TabOrder = 0
  object statMain: TStatusBar
    Left = 0
    Top = 480
    Width = 562
    Height = 19
    Panels = <
      item
        Width = 110
      end
      item
        Width = 110
      end
      item
        Width = 110
      end
      item
        Width = 110
      end
      item
        Width = 110
      end
      item
        Width = 110
      end>
  end
  object lbLog: TListBox
    Left = 0
    Top = 0
    Width = 562
    Height = 423
    Align = alClient
    ItemHeight = 13
    ParentColor = True
    TabOrder = 1
  end
  object panPB: TPanel
    Left = 0
    Top = 423
    Width = 562
    Height = 57
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      562
      57)
    object labPB: TLabel
      Left = 8
      Top = 4
      Width = 123
      Height = 16
      Caption = #1053#1072#1095#1072#1083#1086' '#1086#1073#1088#1072#1073#1086#1090#1082#1080
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object pbFile: TProgressBar
      Left = 0
      Top = 25
      Width = 562
      Height = 16
      Align = alBottom
      TabOrder = 0
    end
    object pbAll: TProgressBar
      Left = 0
      Top = 41
      Width = 562
      Height = 16
      Align = alBottom
      TabOrder = 1
    end
    object btnStop: TButton
      Left = 486
      Top = 0
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'btnStop'
      Enabled = False
      TabOrder = 2
      OnClick = btnStopClick
    end
    object btnStart: TButton
      Left = 410
      Top = 0
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'btnStart'
      TabOrder = 3
      OnClick = btnStartClick
    end
  end
  object odOpn: TOpenDialog
    Left = 8
    Top = 376
  end
  object hdsMain: THalcyonDataSet
    AutoFlush = False
    Exclusive = False
    LargeIntegerAs = asLargeInt
    LockProtocol = Default
    TranslateASCII = True
    UseDeleted = False
    UserID = 0
    Left = 40
    Top = 376
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 72
    Top = 376
  end
end
