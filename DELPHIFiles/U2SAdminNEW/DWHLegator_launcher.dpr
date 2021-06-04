program DWHLegator_launcher;

uses
  Forms,
  Ora,
  OdacVcl,
  DB,
  SysUtils,
  Dialogs,
  Windows,
  untUtility in '..\ForAllProjects\untUtility.pas',
  untRegistry in 'untRegistry.pas',
  untUploads in 'untUploads.pas' {frmUploads};

{$R *.res}

var  Ses :TOraSession;
     ConDlg :TConnectDialog;
     VersID :integer;
     VersNum,Enhancements :string;
     FindedNewVers :boolean;

begin
  Application.Initialize;
  RUserRead;
  Ses := TOraSession.Create(Application);
  with Ses do begin
    Options.Direct := true;
    Server := '172.21.25.19:1521:ofsa';
    Username := GetUserName;
    Password := GetUserPass;
    //ShowMessage(inttostr(length(GetUserName)) + '|' + inttostr(length(GetUserPass)));
  end;

  ConDlg := TConnectDialog.Create(Application);
  with ConDlg do begin
    ConnectButton := 'Соединить';
    CancelButton := 'Отмена';
    Caption := 'Соединение:';
    ServerLabel := 'Сервер:';
    UsernameLabel := 'Логин:';
    PasswordLabel := 'Пароль:';
    StoreLogInfo := false;
  end;
  Ses.ConnectDialog := ConDlg;
  Ses.LoginPrompt := true;

  FindedNewVers := false;
  try
    Ses.Connect;
    SetUserName(Ses.Username);
    SetUserPass(Ses.Password);
    RUserWrite;
    CheckVersion(Ses,'DWHLegator.exe',FindedNewVers,VersID,VersNum,Enhancements);
    if FindedNewVers then begin
      VersionProccessing(Ses,VersID);
    end;
    WinExec(PAnsiChar(Pchar(ExtractFilePath(Application.ExeName) + 'DWHLegator.exe')),SW_ShowNormal);
  finally
    Ses.Free;
    ConDlg.Free;
  end;
  Application.CreateForm(TfrmUploads, frmUploads);
  Application.Run;
end.
