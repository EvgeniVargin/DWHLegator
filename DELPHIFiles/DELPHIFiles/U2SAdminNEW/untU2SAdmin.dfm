inherited frmU2SAdmin: TfrmU2SAdmin
  Left = 588
  Top = 120
  Width = 800
  Height = 688
  Caption = #1057#1080#1075#1080#1079#1084#1091#1085#1076
  OldCreateOrder = True
  WindowState = wsMaximized
  PixelsPerInch = 96
  TextHeight = 13
  inherited Splitter1: TSplitter
    Height = 649
  end
  inherited panList: TPanel
    Height = 649
    Font.Height = -13
    inherited frTree: TfrBaseSQLTree
      Height = 649
      inherited tvSQLTree: TTreeView
        Height = 649
      end
    end
  end
  inherited panBody: TPanel
    Width = 480
    Height = 649
    Color = clWindow
    object imgPict: TImage
      Left = 0
      Top = 0
      Width = 480
      Height = 649
      Align = alClient
      AutoSize = True
      Center = True
    end
  end
  inherited Session: TOraSession
    Options.Direct = True
    Username = 'stage'
    Server = '172.21.25.19:1521:ofsa'
    LoginPrompt = False
    EncryptedPassword = '8CFF8BFF9EFF98FF9AFF'
  end
  object tmrVers: TTimer
    Enabled = False
    Interval = 300000
    OnTimer = tmrVersTimer
    Left = 120
    Top = 8
  end
end
