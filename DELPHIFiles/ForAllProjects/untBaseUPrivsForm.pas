unit untBaseUPrivsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGridEh, ExtCtrls, DB, DBAccess, Ora, MemDS,
  untBaseFrame, DAScript, OraScript, StdCtrls, Buttons;

type
  TfrmBaseUPrivs = class(TForm)
    qryRoles: TOraQuery;
    dsRoles: TOraDataSource;
    panRoles: TPanel;
    Splitter1: TSplitter;
    panButtons: TPanel;
    panPrivs: TPanel;
    qryPrivs: TOraQuery;
    dsPrivs: TOraDataSource;
    qryPrivsNAME: TStringField;
    qryPrivsSELECT: TFloatField;
    qryPrivsINSERT: TFloatField;
    qryPrivsUPDATE: TFloatField;
    qryPrivsDELETE: TFloatField;
    frPrivs: TfrBase;
    frRoles: TfrBase;
    Scr: TOraScript;
    bbCancel: TBitBtn;
    bbSave: TBitBtn;
    qryRolesNAME: TStringField;
    qryRolesGRANT: TFloatField;
    qryPrivsOBJECT_TYPE: TStringField;
    qryPrivsEXCUTE: TFloatField;
    procedure qryPrivsBeforeOpen(DataSet: TDataSet);
    procedure bbSaveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure qryRolesAfterOpen(DataSet: TDataSet);
    procedure FormCreate(Sender: TObject);
    procedure qryPrivsAfterOpen(DataSet: TDataSet);
    procedure qryRolesBeforeOpen(DataSet: TDataSet);
  private
    { Private declarations }
    vUser :string;
    vSchema :string;
    vBegPrivs :Array of Array of integer;
    vBegRoles :Array of integer;
    procedure SetBegPrivs;
    procedure SetBegRoles;
    procedure SetScript;
  public
    { Public declarations }
    //constructor Create(AOwner :TComponent; User :string); overload;
    constructor Create(AOwner :TComponent; User,Schema :string); overload;
    procedure SetUser(inUser :string);
    function GetUser :string;
    procedure SetSchema(inSchema :string);
    function GetSchema :string;
  end;

var
  frmBaseUPrivs: TfrmBaseUPrivs;

implementation

{$R *.dfm}

constructor TfrmBaseUPrivs.Create(AOwner :TComponent; User,Schema :string);
begin
  inherited Create(AOwner);
  Caption := 'Роли и привилегии ' + uppercase(User);
  SetUser(User);
  SetSchema(Schema);
  qryPrivs.Open;
  qryRoles.Open;
end;

procedure TfrmBaseUPrivs.SetScript;
var i :integer; str :string;
begin
  Scr.SQL.Clear;

  frPrivs.dbGrid.DataSource := nil;
  frRoles.dbGrid.DataSource := nil;

  qryRoles.First;
  while not(qryRoles.Eof) do
    begin
      if not(vBegRoles[qryRoles.RecNo - 1] = qryRoles.Fields.Fields[1].AsInteger)
        then begin
               case qryRoles.Fields.Fields[1].AsInteger of
                 1 : str := frRoles.dbGrid.Columns.Items[1].FieldName +
                            ' ' +  qryRoles.Fields.Fields[0].AsString +
                            ' TO ' + GetUser + ';';
               else str := 'REVOKE ' +  qryRoles.Fields.Fields[0].AsString +
                            ' FROM ' + GetUser + ';';
               end;
               Scr.SQL.Append(str);
             end;
    qryRoles.Next;
   end;
  qryRoles.Cancel;
  qryRoles.First;

  if qryPrivs.Filtered then qryPrivs.Filtered := false;
  qryPrivs.First;
  while not(qryPrivs.Eof) do
    begin
      for i := 0 to 4 do
        if not(vBegPrivs[qryPrivs.RecNo - 1,i] = qryPrivs.Fields.Fields[i].AsInteger)
           and ((qryPrivs.Fields.Fields[i].FieldName = 'SELECT') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'VIEW')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'SELECT') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'TABLE')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'INSERT') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'TABLE')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'UPDATE') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'TABLE')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'DELETE') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'TABLE')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'EXECUTE') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'PACKAGE')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'EXECUTE') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'PROCEDURE')
                or
                (qryPrivs.Fields.Fields[i].FieldName = 'EXECUTE') and (qryPrivs.FieldByName('OBJECT_TYPE').AsString = 'FUNCTION')
               )

          then begin
                 case qryPrivs.Fields.Fields[i].AsInteger of
                   1 : str := 'GRANT ' + frPrivs.dbGrid.Columns.Items[i+1].FieldName +
                              ' ON ' +  qryPrivs.Fields.Fields[5].AsString +
                              ' TO ' + GetUser + ';';
                 else str := 'REVOKE ' + frPrivs.dbGrid.Columns.Items[i+1].FieldName +
                              ' ON ' +  qryPrivs.Fields.Fields[5].AsString +
                              ' FROM ' + GetUser + ';';
                 end;
                 Scr.SQL.Append(str);
               end;
      qryPrivs.Next;
    end;
  qryPrivs.Cancel;
  qryPrivs.First;

  frPrivs.dbGrid.DataSource := dsPrivs;
  frRoles.dbGrid.DataSource := dsRoles;

  try
    Scr.Execute;
    MessageDlg('Права пользователя ' + GetUser + ' успешно изменены.',mtInformation,[mbOk],0);
  except
    MessageDlg('Ошибка изменения прав пользователя ' + GetUser,mtError,[mbOk],0);
  end;
end;

procedure TfrmBaseUPrivs.SetBegPrivs;
var i :integer;
begin
  frPrivs.dbGrid.DataSource := nil;

  SetLength(vBegPrivs,qryPrivs.RecordCount,5);

  qryPrivs.First;

  while not(qryPrivs.Eof) do
    begin
      for i := 0 to 4 do
        begin
          vBegPrivs[qryPrivs.RecNo - 1,i] := qryPrivs.Fields.Fields[i].AsInteger;
        end;
      qryPrivs.Next;
    end;

  qryPrivs.First;

  frPrivs.dbGrid.DataSource := dsPrivs;
end;

procedure TfrmBaseUPrivs.SetBegRoles;
begin
  //frRoles.dbGrid.DataSource := nil;
  if not qryRoles.ControlsDisabled then qryRoles.DisableControls;

  SetLength(vBegRoles,qryRoles.RecordCount);

  qryRoles.First;

  while not(qryRoles.Eof) do
    begin
      vBegRoles[qryRoles.RecNo - 1] := qryRoles.Fields.Fields[1].AsInteger;
      qryRoles.Next;
    end;

  qryRoles.First;

  //frRoles.dbGrid.DataSource := dsRoles;
  qryRoles.EnableControls;
end;

procedure TfrmBaseUPrivs.SetUser(inUser :string);
begin
  vUser := uppercase(inUser);
end;

function TfrmBaseUPrivs.GetUser :string;
begin
  result := vUser;
end;

procedure TfrmBaseUPrivs.SetSchema(inSchema :string);
begin
  vSchema := uppercase(inSchema);
end;

function TfrmBaseUPrivs.GetSchema :string;
begin
  result := vSchema;
end;

procedure TfrmBaseUPrivs.qryPrivsBeforeOpen(DataSet: TDataSet);
begin
  qryPrivs.ParamByName('inUserName').Value := GetUser;
  qryPrivs.ParamByName('inOwner').Value := GetSchema;
end;

procedure TfrmBaseUPrivs.qryRolesBeforeOpen(DataSet: TDataSet);
begin
  qryRoles.ParamByName('inUserName').Value := GetUser;
end;

procedure TfrmBaseUPrivs.bbSaveClick(Sender: TObject);
begin
  TBitBtn(Sender).Cursor := crSQLWait;
  if qryPrivs.Active and qryRoles.Active then SetScript;
  TBitBtn(Sender).Cursor := crDefault;
end;

procedure TfrmBaseUPrivs.FormCreate(Sender: TObject);
begin
   frRoles.SetDataSource(dsRoles);
   with frPrivs do
     begin
       SetDataSource(dsPrivs);
       SetDrawColumns(['NAME']);
       SetDrawCells('OBJECT_TYPE',['VIEW','TABLE','PACKAGE','PROCEDURE','FUNCTION'],[clWindow,clWindow,clWindow,clWindow,clWindow],[clGrayText,clBlack,clFuchsia,clBlue,clBlue],5);
     end;
end;

procedure TfrmBaseUPrivs.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  action := caFree;
end;

procedure TfrmBaseUPrivs.qryRolesAfterOpen(DataSet: TDataSet);
begin
  SetBegRoles;
end;

procedure TfrmBaseUPrivs.qryPrivsAfterOpen(DataSet: TDataSet);
begin
  SetBegPrivs;
end;

end.
