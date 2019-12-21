unit untBaseDbfToOraFrame;

interface

uses
  Windows, Messages, SysUtils, StrUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, Ora, OraScript, StdCtrls, ExtCtrls, DB, Halcn6db;

type TDMlOption = (dmlCreate,dmlTruncate,dmlAppend);

type
  TfrDbfToOra = class(TFrame)
    statMain: TStatusBar;
    pbFile: TProgressBar;
    pbAll: TProgressBar;
    lbLog: TListBox;
    panPB: TPanel;
    labPB: TLabel;
    btnStop: TButton;
    btnStart: TButton;
    odOpn: TOpenDialog;
    hdsMain: THalcyonDataSet;
    Timer1: TTimer;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    vStop :boolean;
    vOraSession :TOraSession;
    vDestTable :string;
    strFields,strFields1 :string;
    vDbfFileNames :TStringList;
    vFieldList :TStringList;
    vOraScript :TOraScript;
    vOraQuery :TOraQuery;
    vAllRecords :integer;
    vDmlOption :TDmlOption;
    vBegin :TDateTime;
    btnStartName :string;
    function DbfToOra(FileName,IDField :string) :integer;
  public
    { Public declarations }
    constructor Create(AOwner :TComponent); override;
    procedure SetOraSession(Session :TOraSession);
    procedure SetDestTable(DestTable :string; DmlOption :TDmlOption); overload;
    procedure SetDestTable(DestTable :string); overload;
    procedure AddDbfFileName(FileName,IDFieldName :string);
    procedure ClearDbfFiles;
    //
    function GetOraSession :TOraSession;
    function GetDestTable :string;
    function GetDbfFileNames :TStringList;
    function GetDbfFileName(Idx :integer) :string;
    function GetDbfFileValue(Idx :integer) :string;
    function StartLoading :string;
    //
    property OraSession :TOraSession READ GetOraSession WRITE SetOraSession;
    property DbfFileNames[Idx :integer] :string READ GetDbfFileName;
    property DbfFileValues[idx :integer] :string READ GetDbfFileValue;
  end;

implementation

uses untUtility;

{$R *.dfm}

constructor TfrDbfToOra.Create(AOwner :TComponent);
begin
  inherited;
  vDbfFileNames := TStringList.Create;
  vFieldList := TStringList.Create;
  vOraScript := TOraScript.Create(self);
  vOraQuery := TOraQuery.Create(self);
  vOraScript.Session := OraSession;
  vOraQuery.Session := OraSession;
  vAllRecords := 0;
  vStop := true;
  btnStartName := btnStart.Caption;
end;

////////

procedure TfrDbfToOra.SetOraSession(Session :TOraSession);
begin
  vOraSession := Session;
end;

procedure TfrDbfToOra.SetDestTable(DestTable :string; DmlOption :TDmlOption);
begin
  vDestTable := DestTable;
  vDmlOption := DmlOption;
end;

procedure TfrDbfToOra.SetDestTable(DestTable :string);
begin
  vDestTable := DestTable;
  vDmlOption := dmlAppend;
end;

function TfrDbfToOra.GetDbfFileNames :TStringList;
begin
  result := vDbfFileNames;
end;

procedure TfrDbfToOra.AddDbfFileName(FileName,IDFieldName :string);
begin
   vDbfFileNames.Append(FileName + '=' + IDFieldName);
end;

////////

function TfrDbfToOra.GetOraSession :TOraSession;
begin
  result := vOraSession;
end;

function TfrDbfToOra.GetDestTable :string;
begin
  result := vDestTable;
end;

function TfrDbfToOra.GetDbfFileName(Idx :integer) :string;
begin
  result := vDbfFileNames.Names[Idx];
end;

function TfrDbfToOra.GetDbfFileValue(Idx :integer) :string;
begin
  result := vDbfFileNames.ValueFromIndex[Idx];
end;

function TfrDbfToOra.StartLoading :string;
begin
  result := vDbfFileNames.Strings[0]+' - '+vDbfFileNames.ValueFromIndex[0];
end;

procedure TfrDbfToOra.ClearDbfFiles;
begin
  vDbfFileNames.Clear;
end;

function TfrDbfToOra.DbfToOra(FileName,IDField :string) :integer;
var str :string;
    i :integer;
begin
  with hdsMain do
    begin
      if Active then Close;
      TableName := FileName;
      Open;
      pbFile.Max := hdsMain.RecordCount;
      StatMain.Panels.Items[4].Text := 'Всего записей: ' + inttostr(hdsMain.RecordCount);
      First;
      while not(hdsMain.Eof) do
        begin
          Application.ProcessMessages;
          if vStop then break;
          vOraScript.SQL.Clear;
          if (RecNo = 1) then vFieldList.Clear;
          for i := 0 to FieldCount - 1 do
            begin
              str := 'INSERT INTO tmp_loaddbf_001 (filename,col_name,col_value,id_value) VALUES( ''' + FileName + ''',' +
                     '''' + Fields.Fields[i].FieldName + ''',' +
                     '''' +  StringReplace(Fields.Fields[i].AsString,'''','''||Chr(39)||''',[rfReplaceAll]) + ''',' +
                     '''' + hdsMain.FieldByName(IDField).AsString + ''' );';
              vOraScript.SQL.Append(str);
              if (RecNo = 1) then vFieldList.Append(Fields.Fields[i].FieldName);
            end;
          pbFile.Position := hdsMain.RecNo;
          vOraScript.Execute;
          vAllRecords := vAllRecords + 1;
          StatMain.Panels.Items[5].Text := 'Обработано: ' + inttostr(vAllRecords);
          hdsMain.Next;
        end;
    end;
  strFields := '';
  strFields1 := '';
  for i := 0 to vFieldList.Count - 1 do
    begin
      strFields := StrFields + ',' + Char(39) + vFieldList.Strings[i] + Char(39);
      strFields1 := StrFields1 + ',' + Char(34) + Char(39) + vFieldList.Strings[i] + Char(39) + Char(34) + ' AS ' + vFieldList.Strings[i];
    end;
  strFields := copy(strFields,2,length(strFields)-1);
  strFields1 := copy(strFields1,2,length(strFields1)-1);
  result := hdsMain.RecordCount;
end;

procedure TfrDbfToOra.btnStartClick(Sender: TObject);
var err,i,y :integer;
begin
  if (vDbfFileNames.Count = 0) then
    if MessageDlg('Сначала необходимо сформировать список файлов',mtInformation,[mbOk],0) = mrOk then exit;
      err := 0;
      StatMain.Font.Style := StatMain.Font.Style - [fsBold];
      StatMain.Panels.Items[0].Text := 'Файлов всего: ' + inttostr(vDbfFileNames.Count);
      pbAll.Max := vDbfFileNames.Count;
      y := 0;
      vStop := false;
      vBegin := Now;
      Timer1.Enabled := not(vStop);
      for i := 0 to vDbfFileNames.Count - 1 do
        begin
          btnStart.Enabled := vStop;
          btnStop.Enabled := not(vStop);
          If vStop then break;
          labPB.Caption := 'Обработка файла ' + extractfilename(vDbfFileNames.Names[i]);
          try
            y := DbfToOra(vDbfFileNames.Names[i],vDbfFileNames.ValueFromIndex[i]);
            StatMain.Panels.Items[2].Text := 'Успешно: ' + inttostr(i+1 - err);
          except
            err := err + 1;
            StatMain.Panels.Items[3].Text := 'Ошибка: ' + inttostr(err);
          end;
          lbLog.Items.Append(extractfilename(vDbfFileNames.Names[i]) + ' - обработано ' + inttostr(y) + ' записей');
          StatMain.Panels.Items[1].Text := 'Обработано: ' + inttostr(i+1);
          pbAll.Position := i+1;
        end;
        if not(vStop) then
          begin
            // Запись данных в дест таблицу
            labPB.Caption := 'Подготовка данных и запись в целевую таблицу';
            labPB.Refresh;
            cursor := crSQLWait;
            vOraScript.SQL.Clear;
            case vDmlOption of
            dmlCreate :
              vOraScript.SQL.Append('CREATE TABLE ' + GetDestTable + ' AS SELECT filename,' + strFields1 + ' FROM (SELECT filename,id_value,col_name,col_value  FROM tmp_loaddbf_001) PIVOT (MAX(col_value) FOR col_name IN (' + strFields + '));');
            dmlTruncate :
                vOraScript.SQL.Append('DROP TABLE ' + GetDestTable + '; CREATE TABLE ' + GetDestTable + ' AS SELECT filename,' + strFields1 + ' FROM (SELECT filename,id_value,col_name,col_value  FROM tmp_loaddbf_001) PIVOT (MAX(col_value) FOR col_name IN (' + strFields + '));');
            dmlAppend :
              vOraScript.SQL.Append('INSERT /*+ APPEND */ INTO ' + GetDestTable + ' SELECT filename,' + strFields1 + ' FROM (SELECT filename,id_value,col_name,col_value  FROM tmp_loaddbf_001) PIVOT (MAX(col_value) FOR col_name IN (' + strFields + '));');
            end;
            vOraScript.Execute;
            StatMain.Font.Style := StatMain.Font.Style + [fsBold];
            cursor := crDefault;
            labPB.Caption := 'Обработка завершена';
            vStop := true;
          end;
    btnStart.Enabled := vStop;
    btnStop.Enabled := not(vStop);
    Timer1.Enabled := not(vStop);
    btnStart.Caption := btnStartName;
end;

procedure TfrDbfToOra.btnStopClick(Sender: TObject);
begin
  vStop := true;
end;

procedure TfrDbfToOra.Timer1Timer(Sender: TObject);
begin
  if not(vStop) then btnStart.Caption := ti_as_hms(Now - vBegin) else btnStart.Caption := '';
end;

end.
