object frmLauncher: TfrmLauncher
  Left = 646
  Top = 207
  Width = 291
  Height = 128
  Caption = 'DWHLegator_launcher'
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
  object Ses: TOraSession
    Options.Direct = True
    Username = 'STAGE'
    Server = '172.21.25.19:1521:ofsa'
    Connected = True
    LoginPrompt = False
    Left = 8
    Top = 8
    EncryptedPassword = '8CFF8BFF9EFF98FF9AFF'
  end
end
