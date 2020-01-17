//**************************************************************************************
//* !!! Спецификация полей Query, передаваемого в переменную Qry,                      *
//*     должна быть строго определенной !!!                                            *
//* 1 - ParamID; 2 - ParamName; 3 - ParamDataType; 4 - ParamSQL; 5 - ParamDescription  *
//* 6 - ParamDefVal; 7 - ParamDefDisplay; 8 - ParamParentName                          *
//* ParamSQL используется в случае, если значения параметра берутся из справочника     *
//* ParamParentID необходим в случае если необходимо фильтровать значения в списке     *
//* выбора нижестоящего параметра по вышестоящему                                      *
//**************************************************************************************
unit untBaseRepParamsFrame;

interface

uses
  SysUtils,
  Dialogs,
  Classes,
  Controls,
  Forms,
  Ora,
  DB,
  DBGridEh,
  StdCtrls,
  ComCtrls,
  ExtCtrls,
  Variants,
  ComObj,
  Graphics;

type TExcelPivotAggr = (xlSum,xlCount);

type
  TfrBaseRepParams = class(TFrame)
    scrlBox: TScrollBox;
    panBtn: TPanel;
    btnExRep: TButton;
    procedure btnExRepClick(Sender: TObject);
  private
    { Private declarations }
    vQry,vQryOut :TOraQuery;
    vGrid :TDBGridEh;
    sqlParamResult :TOraSQL;
    ScrollBoxHeight :integer;
  public
    { Public declarations }
    vBegDt :TDateTime;
    vInProcess :boolean;
    vBtnCaption :string;
    constructor Create(AOwner :TComponent); override;
    procedure SetQryParam(Qry :TOraQuery);
    function  GetQryParam :TOraQuery;
    function  GetQryReport :TOraQuery;
    procedure SetGrid(Grid :TDBGridEh);
    function  GetGrid :TDBGridEh;
    procedure BuildParams;
    procedure ExecuteReport(DataSet :TDataSet);
    //////
    property ParamQuery :TOraQuery READ GetQryParam WRITE SetQryParam;
  end;

type TParamEdit = class(TEdit)
  private
    vKeyVal :Variant;
    vDataType :string;
    procedure SetDataType(Val :string);
    function  GetDataType :string;
    //procedure OnChangeParamEdit(Sender :TObject);
  public
    constructor Create(AOwner :TComponent); override;
    procedure SetKeyVal(Val :Variant);
    function  GetKeyVal :Variant;
    property KeyVal :Variant READ GetKeyVal WRITE SetKeyVal;
    property DataType :string READ GetDataType WRITE SetDataType;
end;

type TParamCheckBox = class(TCheckBox)
  private
    vKeyValCHB :Integer;
    vDataTypeCHB :string;
    procedure SetKeyVal(Val :Integer);
    function  GetKeyVal :Integer;
    procedure SetDataType(Val :string);
    function  GetDataType :string;
    procedure OnClickParamCheckBox(Sender :TObject);
  public
    constructor Create(AOwner :TComponent); override;
    property KeyVal :Integer READ GetKeyVal WRITE SetKeyVal;
    property DataType :string READ GetDataType WRITE SetDataType;
end;

type TSelectEdt = class(TParamEdit)
  private
    vChildNames :TStringList;
    vQryVal :TOraQuery;
    function  GetChildNames :TStringList;
    procedure OnChangeSelectEdt(Sender :TObject);
    procedure SetQryVal(Qry :TOraQuery);
    function  GetQryVal :TOraQuery;
  public
    constructor Create(AOwner :TComponent); override;
    property QryVal :TOraQuery READ GetQryVal WRITE SetQryVal;
  end;

type TNumEdit = class(TParamEdit)
    procedure OnKeyPressNumEdit(Sender :TObject; var Key: Char);
  public
    constructor Create(AOwner :TComponent); override;
end;

type TDTPEdit = class(TParamEdit)
    procedure OnKeyPressDTPEdit(Sender :TObject; var Key: Char);
    //procedure OnChangeDTPEdit(Sender :TObject);
  public
    constructor Create(AOwner :TComponent); override;
end;

type TSelectBtn = class(TButton)
    procedure OnClickSelectBtn(Sender :TObject);
  public
    constructor Create(AOwner :TComponent); override;
end;

type TMyThread = class(TThread)
  protected
    MyFrame :TfrBaseRepParams;
    MyQuery :TOraQuery;
    constructor Create(CreateSuspended :boolean; Frame :TfrBaseRepParams; Query :TOraQuery); overload;
    procedure Execute; override;
end;

implementation

uses untBaseSelectForm,untBaseDateTimeForm, untUtility, DBAccess,
  untReportsNew, untBaseButtonsFrame, untReportResultNew, untRegistry,
  untBaseEdtCLOB, untChartNew;

{$R *.dfm}

constructor TMyThread.Create(CreateSuspended :boolean; Frame :TfrBaseRepParams; Query :TOraQuery);
begin
  inherited Create(CreateSuspended);
  MyFrame := Frame;
  MyQuery := Query;
end;

constructor TfrBaseRepParams.Create(AOwner :TComponent);
begin
  inherited;
  vBtnCaption := self.btnExRep.Caption;
  vInProcess := false;
  ScrollBoxHeight := scrlBox.Height;
end;

constructor TParamEdit.Create(AOwner :TComponent);
begin
  inherited;
  Parent := TWinControl(AOwner);
  left := 4;
  width := TControl(AOwner).Width - 46;
  //OnChange := OnChangeParamEdit;
  Anchors := [akTop,akLeft,akRight];
end;

constructor TParamCheckBox.Create(AOwner :TComponent);
begin
  inherited;
  Parent := TWinControl(AOwner);
  left := 4;
  width := TControl(AOwner).Width - 46;
  OnClick := OnClickParamCheckBox;
  Anchors := [akTop,akLeft,akRight];
end;

constructor TDTPEdit.Create(AOwner :TComponent);
begin
  inherited;
  OnKeyPress := OnKeyPressDTPEdit;
  //OnChange := OnChangeDTPEdit;
end;

constructor TNumEdit.Create(AOwner :TComponent);
begin
  inherited;
  width := TControl(AOwner).Width - 24;
  OnKeyPress := OnKeyPressNumEdit;
end;

constructor TSelectEdt.Create(AOwner :TComponent);
begin
  inherited;
  QryVal := TOraQuery.Create(self);
  KeyVal := null;
  
  vChildNames := TStringList.Create;
  OnChange := OnChangeSelectEdt;
end;

constructor TSelectBtn.Create(AOwner :TComponent);
begin
  inherited;
  Parent := TWinControl(AOwner).Parent;
  Left := 4 + TControl(AOwner).Width;
  width := TControl(AOwner).Height;
  height := TControl(AOwner).Height;
  Caption := '...';
  OnClick := OnClickSelectBtn;
  Anchors := [akTop,akRight];
end;

//////////////
procedure TfrBaseRepParams.SetQryParam(Qry :TOraQuery);
begin
  vQry := Qry;
end;

function TfrBaseRepParams.GetQryParam :TOraQuery;
begin
  result := vQry;
end;

function TfrBaseRepParams.GetQryReport :TOraQuery;
begin
  result := vQryOut;
end;

procedure TfrBaseRepParams.SetGrid(Grid :TDBGridEh);
begin
  vGrid := Grid;
end;

function TfrBaseRepParams.GetGrid :TDBGridEh;
begin
  result := vGrid;
end;

function  TParamEdit.GetKeyVal :Variant;
begin
  result := vKeyVal;
end;

procedure TParamEdit.SetKeyVal(Val :Variant);
begin
  vKeyVal := Val;
end;

procedure TParamEdit.SetDataType(Val :string);
begin
  vDataType := Val;
end;

function  TParamEdit.GetDataType :string;
begin
  result := vDataType;
end;

function  TParamCheckBox.GetKeyVal :Integer;
begin
  result := vKeyValCHB;
end;

procedure TParamCheckBox.SetKeyVal(Val :Integer);
begin
  vKeyValCHB := Val;
end;

procedure TParamCheckBox.SetDataType(Val :string);
begin
  vDataTypeCHB := Val;
end;

function  TParamCheckBox.GetDataType :string;
begin
  result := vDataTypeCHB;
end;

function TSelectEdt.GetChildNames :TStringList;
begin
  result := vChildNames;
end;

function TSelectEdt.GetQryVal :TOraQuery;
begin
  result := vQryVal;
end;

procedure TSelectEdt.SetQryVal(Qry :TOraQuery);
begin
  vQryVal := Qry;
end;

procedure TSelectEdt.OnChangeSelectEdt(Sender :TObject);
var i :integer;
begin
  if length(TSelectEdt(Sender).Text) = 0 then TSelectEdt(Sender).KeyVal := Null;
    if TSelectEdt(Sender).GetChildNames.Count > 0 then
      for i := 0 to TSelectEdt(Sender).GetChildNames.Count - 1 do
        with TSelectEdt(TScrollBox(TSelectEdt(Sender).Owner).FindComponent(TSelectEdt(Sender).GetChildNames.Strings[i])) do begin
          if QryVal.Filtered then QryVal.Filtered := false;
          if length(TSelectEdt(Sender).Text) > 0 then begin
            QryVal.Filter := QryVal.Fields[2].FieldName + '=' + Char(39) + TSelectEdt(Sender).QryVal.Fields[1].AsString + Char(39);
            QryVal.Filtered := true;
            end else begin
                  KeyVal := Null;
                  Clear;
                end;
        end;
end;

{procedure TParamEdit.OnChangeParamEdit(Sender :TObject);
begin
  if DataType = 'ftString' then if length(Text) > 0 then KeyVal := Text else KeyVal := Null;
  if DataType = 'ftFloat' then  if length(Text) > 0 then KeyVal := strtofloat(Text) else KeyVal := Null;
  if DataType = 'ftDateTime' then  if length(Text) > 0 then KeyVal := StrToDateTime(Text) else KeyVal := Null;
  if DataType = 'ftBoolean' then  if length(Text) > 0 then KeyVal := strtoint(Text) else KeyVal := Null;
end;}

procedure TNumEdit.OnKeyPressNumEdit(Sender :TObject;var Key: Char);
begin
  if not(Key in ['0'..'9',#8,#9,DecimalSeparator]) then Key := #0;
end;

procedure TDTPEdit.OnKeyPressDTPEdit(Sender :TObject; var Key: Char);
begin
  if not(Key in ['0'..'9',#8,#9,'.',' ',':']) then Key := #0;
end;

{procedure TDTPEdit.OnChangeDTPEdit(Sender :TObject);
var str :string;
begin
  str := TDTPEdit(Sender).Text;
  case length(str) of
    8  :if not((str[1] in ['0'..'3']) and (str[2] in ['0'..'9']) and (str[3] in ['.']) and
               (str[4] in ['0'..'1']) and (str[5] in ['0'..'9']) and (str[6] in ['.']) and
               (str[7] in ['0'..'9']) and (str[8] in ['0'..'9'])
              ) then TDTPEdit(Sender).KeyVal := Null else TDTPEdit(Sender).KeyVal := StrToDateTime(Text);
    10 :if not((str[1] in ['0'..'3']) and (str[2] in ['0'..'9']) and (str[3] in ['.']) and
               (str[4] in ['0'..'1']) and (str[5] in ['0'..'9']) and (str[6] in ['.']) and
               (str[7] in ['0'..'9']) and (str[8] in ['0'..'9']) and (str[9] in ['0'..'9']) and (str[10] in ['0'..'9'])
              ) then TDTPEdit(Sender).KeyVal := Null else TDTPEdit(Sender).KeyVal := StrToDateTime(Text);
    else TDTPEdit(Sender).KeyVal := Null;
  end;
end;}

procedure TSelectBtn.OnClickSelectBtn(Sender :TObject);
begin
  if Owner.ClassType = TDTPEdit then
    with TfrmDateTime.Create(TDTPEdit(Owner)) do begin
      if length(TDTPEdit(Owner).Text) > 0 then DateTime := StrToDateTime(TDTPEdit(Owner).Text);
      ShowModal;
    end
  else
    with TfrmSelect.Create(TSelectEdt(Owner),TSelectEdt(Owner).GetQryVal) do ShowModal;
end;

procedure TParamCheckBox.OnClickParamCheckBox(Sender :TObject);
begin
  inherited;
  if Checked then KeyVal := 1 else KeyVal := 0;
end;

procedure TfrBaseRepParams.BuildParams;
var vPrevCompName,vParamResult :string;
    vParamIsSQL :boolean;
begin
  if not Assigned(sqlParamResult) then sqlParamResult := TOraSQL.Create(self);
  scrlBox.DestroyComponents;
  vPrevCompName := '';
  with ParamQuery do begin
    if not(Active) then Open;
    first;
    while not(Eof) do begin
        if (Pos('DECLARE',uppercase(Fields[5].AsString)) = 1) and (Pos('BEGIN',uppercase(Fields[5].AsString)) > 0) then begin
          sqlParamResult.SQL.Clear;
          sqlParamResult.SQL.Add(Fields[5].AsString);
          sqlParamResult.ParamByName('OUTRES').ParamType := ptOutput;
          sqlParamResult.ParamByName('OUTRES').DataType := ftString;
          sqlParamResult.Execute;
          vParamResult := sqlParamResult.ParamByName('OUTRES').AsString;
          vParamIsSQL := true;
        end else vParamIsSQL := false;
        if not(Fields[2].AsString = 'ftBoolean') then
          with TLabel.Create(scrlBox) do begin
            Parent :=  scrlBox;
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Left := 4;
            width := scrlBox.Width - 24;
            Caption := Fields[4].AsString;
            AutoSize := true;
            Name := 'lab' + Fields[1].AsString;
            vPrevCompName := Name;
          end;
        if (Fields[2].AsString = 'ftFloat') and Fields[3].IsNull then
          with TNumEdit.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else if vParamIsSQL then KeyVal := strtofloat(vParamResult) else KeyVal := Fields[5].AsFloat;
            if vParamIsSQL then Text := vParamResult else Text := Fields[5].AsString;
          end;
        if (Fields[2].AsString = 'ftString') and Fields[3].IsNull then
          with TParamEdit.Create(scrlBox) do begin
            Parent :=  scrlBox;
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            width := scrlBox.Width - 24;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else if vParamIsSQL then KeyVal := vParamResult else KeyVal := Fields[5].AsString;
            if vParamIsSQL then Text := vParamResult else Text := Fields[5].AsString;
          end;
        if (Fields[2].AsString = 'ftDateTime') then begin
          with TDTPEdit.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else if vParamIsSQL then KeyVal := StrToDateTime(vParamResult) else KeyVal := Fields[5].AsDateTime;
            if vParamIsSQL then Text := vParamResult else Text := Fields[5].AsString;
          end;
          with TSelectBtn.Create(TSelectEdt(scrlBox.FindComponent(vPrevCompName))) do
          begin
            Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top;
            Name := 'dbtn' + Fields[1].AsString;
          end;
        end;
        if (Fields[2].AsString = 'ftBoolean') then
          with TParamCheckBox.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            Caption := Fields[4].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := 0 else if vParamIsSQL then KeyVal := StrToInt(vParamResult) else KeyVal := Fields[5].AsInteger;
            if KeyVal = 1 then Checked := true else Checked := false;
          end;
        if not(Fields[3].IsNull) then
          with TSelectEdt.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else begin
              if Fields[2].AsString = 'ftString' then KeyVal := Fields[5].AsString;
              if Fields[2].AsString = 'ftFloat' then KeyVal := Fields[5].AsFloat;
              if Fields[2].AsString = 'ftDateTime' then KeyVal := Fields[5].AsDateTime;
              if Fields[2].AsString = 'ftBoolean' then KeyVal := Fields[5].AsInteger;
            end;
            Text := Fields[6].AsString;
            Tag := RecNo - 1;

            if not(Fields[7].IsNull) then
              TSelectEdt(scrlBox.FindComponent(Fields[7].AsString)).GetChildNames.Append(Fields[1].AsString);

            with QryVal do begin
              Connection := ParamQuery.Connection;
              SQL.Text := ParamQuery.Fields[3].AsString;
              Open;
              Fields[0].DisplayLabel :=  ParamQuery.Fields[4].AsString;
              Fields[1].Visible := false;
            end;

            {if TSelectEdt(scrlBox.FindComponent(Fields[7].AsString)).KeyVal <> null then
              begin
                Filter := Char(39) + TSelectEdt(scrlBox.FindComponent(Fields[7].AsString)).KeyVal + Char(39);
                Filtered := true;
              end;}

            with TSelectBtn.Create(TSelectEdt(scrlBox.FindComponent(vPrevCompName))) do
            begin
              Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top;
              Name := 'sbtn' + Fields[1].AsString;
            end;
          end;
      next;
    end;
  Close;
  end;
  if TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 8 < ScrollBoxHeight
    then scrlBox.Height := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 8;
end;

procedure TfrBaseRepParams.ExecuteReport(DataSet :TDataSet);
var i :integer;
    vParam :TComponent;
begin
  if TOraQuery(DataSet).Active then TOraQuery(DataSet).Close;
  if TOraQuery(DataSet).Params.Count = 0 then begin
    TOraQuery(DataSet).Open;
    TfrmReportResultNew(DataSet.Owner).frMaster.SetColWidth;
    Exit;
  end;

  for i := 0 to TOraQuery(DataSet).Params.Count - 1 do begin
    vParam := scrlBox.FindComponent(TOraQuery(DataSet).Params[i].Name);
    try
      if vParam.ClassName = 'TSelectEdt' then TOraQuery(DataSet).Params[i].Value := TParamEdit(vParam).KeyVal
        else TOraQuery(DataSet).Params[i].Value := TParamEdit(vParam).Text;
      //ShowMEssage(varToStr(TParamEdit(vParam).KeyVal));
    except
      TOraQuery(DataSet).Params[i].Value := TParamCheckBox(vParam).KeyVal;
    end;
  end;
  TOraQuery(DataSet).Open;
  TfrmReportResultNew(DataSet.Owner).frMaster.SetColWidth;
end;

procedure TMyThread.Execute;
begin
  try
    TfrmReportResultNew(MyQuery.Owner).tmrReportResult.Enabled := true;
    MyFrame.ExecuteReport(MyQuery);
  finally
    TfrmReportResultNew(MyQuery.Owner).inProgress := false;
  end;  
end;

procedure TfrBaseRepParams.btnExRepClick(Sender: TObject);
var Frm :TForm;
begin
  Frm := CreateForm(Application,'TfrmReportResultNew',TfrmReportsNew(self.Owner).GetQryMaster.FieldByName('ID').AsString);
  TfrmReportResultNew(Frm).ReportName := TfrmReportsNew(self.Owner).GetQryMaster.FieldByName('QUERY_DESCR').AsString;
  Frm.WindowState := wsMinimized;
  Frm.Show;

  with TMyThread.Create(true,self,TfrmReportResultNew(Frm).GetQuery) do begin
    Priority := tpLower;
    FreeOnTerminate := true;
    Resume;
  end;
end;

end.
