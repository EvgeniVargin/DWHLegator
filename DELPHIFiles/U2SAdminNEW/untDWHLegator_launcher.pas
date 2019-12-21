unit untDWHLegator_launcher;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Ora, DB, DBAccess;

type
  TfrmLauncher = class(TForm)
    Ses: TOraSession;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmLauncher: TfrmLauncher;

implementation

uses untUtility;

{$R *.dfm}

procedure TfrmLauncher.FormCreate(Sender: TObject);
var AppVers,LastVers :string;
    Qry :TOraQuery;
begin
  try
    AppVers := FileVersion(ExtractFilePath(Application.ExeName) + 'DWHLegator.exe');
  except
    AppVers := '1.0.0.1';
  end;
  try
    Ses := TOraSession.Create(Application);
    with Ses do begin
      Options.Direct := true;
      Server := '172.21.25.19:1521:ofsa';
      Username := 'STAGE';
      Password := 'stage';
      Connect;
    end;
    Qry := TOraQuery.Create(Application);
    Qry.Session := Ses;
    Qry.SQL.Add('SELECT vers_num,vers_file FROM tb_version_registry WHERE vers_num = (SELECT MAX(vers_num) FROM tb_version_registry)');
    Qry.Open;
    LastVers := Qry.FieldByName('VERS_NUM').AsString;
    if strtoint(StringReplace(AppVers,'.','',[rfReplaceAll])) < strtoint(StringReplace(LastVers,'.','',[rfReplaceAll])) then begin
      ShowMessage('Доступна новая версия ' + LastVers);
      TBlobField(Qry.FieldByName('VERS_FILE')).SaveToFile(ExtractFilePath(Application.ExeName) + 'DWHLegator.exe');
    end;
    WinExec(Pchar(ExtractFilePath(Application.ExeName) + 'DWHLegator.exe'),SW_ShowNormal);
  finally
    Ses.Free;
    Qry.Free;
  end;
end;

procedure TfrmLauncher.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action :=caFree;
end;

end.
