unit untU2SAdmin;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Math, Controls, Forms,
  Dialogs, untBaseMainForm, ExtCtrls, DBAccess, DB, Ora, StdCtrls,
  MemDS, jpeg, ImgList, DBCtrls, DAScript, OraScript, untBaseSQLTreeFrame,
  ComCtrls, OdacVcl;

type
  TfrmU2SAdmin = class(TfrmBaseMainForm)
    imgPict: TImage;
    tmrVers: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure tmrVersTimer(Sender: TObject);
  private
    { Private declarations }
    procedure BuildLabels;
    procedure BuildForms;
    procedure SetPict;
  public
    { Public declarations }
    VersID :integer;
    VersNum,Enhancements :string;
    FindedNewVers :boolean;
  end;

type TCheckVersThread = class(TThread)
  protected
     procedure Execute; override;
  end;

var
  frmU2SAdmin: TfrmU2SAdmin;

implementation

uses
  untSignCalc,untStarExpand,untRegistry, untStartWindow, untUtility;

{$R *.dfm}

procedure TfrmU2SAdmin.FormCreate(Sender: TObject);
begin
  inherited;
  Session.Connect;
  //Дочерние формы
  if Session.Connected then
      begin
        with frmStartWindow do begin
          Show;
          Update;
         BuildLabels;
          labPBarCaption.Caption := 'Создаем формы:';
          Update;
        end;
        //****************** Создание форм **************************
        BuildForms;
        //****************** Окончание создания форм ****************
        //--------- Установка случайной стартовой картинки --------------
        SetPict;
      end;
  FindedNewVers := false;
  try
    CheckVersion(Session,'DWHLegator_launcher.exe',FindedNewVers,VersID,VersNum,Enhancements);
    if FindedNewVers then begin
      VersionProccessing(Session,VersID);
    end;
  except
  end;
  tmrVers.Enabled := true;
  self.BringToFront;
end;

procedure TfrmU2SAdmin.BuildLabels;
var vQry :TOraQuery;
begin
vQry := TOraQuery.Create(self);
vQry.SQL.Add('SELECT id,parent_id,caption,ord FROM TABLE(pkg_etl_signs.GetLabels(get_osuser)) CONNECT BY PRIOR ID = parent_id START WITH parent_id IS NULL ORDER BY LEVEL,ord');

frTree.SetColumns(['ID','PARENT_ID','CAPTION']);
frTree.SetQuery(vQry);
end;

procedure TfrmU2SAdmin.BuildForms;
var RQry :TOraQuery;
    Pos :integer;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT c.class_name,f.form_name,l.id,l.ord' + #13#10 +
  '  FROM tb_form_registry f' + #13#10 +
  '       INNER JOIN tb_class_registry c' + #13#10 +
  '         ON c.id = f.class_id' + #13#10 +
  '       INNER JOIN TABLE(pkg_etl_signs.GetLabels(get_osuser)) l' + #13#10 +
  '         ON l.form_id = f.id' + #13#10 +
  'ORDER BY l.ord');
  RQry.FetchAll := true;
  RQry.Open;

  with frmStartWindow.pBar do begin
    Min := 0;
    Max := RQry.RecordCount;
    //ShowMessage(inttostr(RQry.RecordCount));
    Position := 0;
  end;

  while not RQry.Eof do begin
    try
      if Assigned(frmStartWindow) then begin
        frmStartWindow.labPBarCaption.Caption := 'Создаем формы: ' + RQry.FieldByName('FORM_NAME').AsString;
        //frmStartWindow.Update;
      end;
      AddChild(frTree.SearchNodeByID(RQry.FieldByName('ID').AsInteger).AbsoluteIndex,CreateForm(self,RQry.FieldByName('CLASS_NAME').AsString,RQry.FieldByName('FORM_NAME').AsString));
    except
      MessageDlg('Не удалось создать форму "' + RQry.FieldByName('FORM_NAME').AsString + '"',mtError,[mbOk],0);
    end;
    frmStartWindow.pBar.Position := frmStartWindow.pBar.Position + 1;
    frmStartWindow.Update;
    RQry.Next;
  end;
  RQry.Free;
end;

procedure TfrmU2SAdmin.SetPict;
var jpg : TJPEGImage;
    vQry :TOraQuery;
begin
  vQry := TOraQuery.Create(self);
  vQry.SQL.Add('SELECT id,pict FROM tb_signs_pictures');
  vQry.Open;

  Randomize;
  with vQry do begin
    Locate('ID',Random(RecordCount)+1,[loCaseInsensitive]);
    try
      jpg := TJpegImage.Create;
      jpg.LoadFromStream(CreateBlobStream(FieldByName('PICT'), bmRead));
      imgPict.Picture.Bitmap.Assign(jpg);
    finally
      jpg.Free;
    end;
  end;
  vQry.Free;
end;

procedure TCheckVersThread.Execute;
begin
  CheckVersion(frmU2SAdmin.Session,'DWHLegator.exe',frmU2SAdmin.FindedNewVers,frmU2SAdmin.VersID,frmU2SAdmin.VersNum,frmU2SAdmin.Enhancements);
end;

procedure TfrmU2SAdmin.tmrVersTimer(Sender: TObject);
var CheckThread :TCheckVersThread;
begin
  if FindedNewVers then MessageDlg(ExtractFileName(Application.ExeName) + ' доступна новая версия ' + VersNum + #10#13#10#13 + '-------- Список изменений ---------' + #10#13 + Enhancements + #10#13 + '-----------------------------------' + #10#13#10#13 + 'Рекомендуется перезапустить приложение.',mtInformation,[mbOk],0);
  CheckThread := TCheckVersThread.Create(true);
  with CheckThread do begin
    FreeOnTerminate := true;
    Priority := tpLower;
    Resume;
  end;
end;

end.                                          

