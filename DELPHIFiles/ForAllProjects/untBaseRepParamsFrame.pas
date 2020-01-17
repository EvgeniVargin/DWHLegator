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
    tmrRepParams: TTimer;
    chbToExcel: TCheckBox;
    procedure btnExRepClick(Sender: TObject);
    procedure tmrRepParamsTimer(Sender: TObject);
    procedure ExecRep;
    procedure ExpToExcel(DataSet :TDataSet; PivotDataBeginRow,PivotColCount :integer; Rows,Columns,Values :Array of integer);
    procedure ExpToExc;
  private
    { Private declarations }
    vQry,vQryOut :TOraQuery;
    vReportName :string;
    vPivotRows,vPivotColumns,vPivotValues :Array of integer;
    vPivotDataBeginRow,vPivotColCount :integer;
  public
    { Public declarations }
    vBegDt :TDateTime;
    vInProcess :boolean;
    vBtnCaption :string;
    constructor Create(AOwner :TComponent); override;
    procedure BuildParams(DataSet,DataSetOut :TDataSet; ReportName :string; PivotDataBeginRow,PivotColCount :integer; PivotRows,PivotColumns,PivotValues :Array of integer); overload;
    procedure BuildParams(DataSet,DataSetOut :TDataSet; ReportName :string); overload;
    procedure ExecuteReport(DataSet :TDataSet);
  end;

type TParamEdit = class(TEdit)
  private
    vKeyVal :Variant;
    vDataType :string;
    procedure SetDataType(Val :string);
    function  GetDataType :string;
    procedure OnChangeParamEdit(Sender :TObject);
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
    procedure SetQryVal(Qry :TOraQuery);
    function  GetQryVal :TOraQuery;
    procedure OnChangeSelectEdt(Sender :TObject);
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
    procedure OnChangeDTPEdit(Sender :TObject);
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
    MyFrame :TComponent;
    constructor Create(CreateSuspended :boolean; AOwner :TComponent); overload;
    procedure Execute; override;
end;

implementation

uses untBaseSelectForm,untBaseDateTimeForm, untUtility, DBAccess;

{$R *.dfm}

constructor TMyThread.Create(CreateSuspended :boolean; AOwner :TComponent);
begin
  inherited Create(CreateSuspended);
  MyFrame := AOwner;
end;

constructor TfrBaseRepParams.Create(AOwner :TComponent);
begin
  inherited;
  vBtnCaption := self.btnExRep.Caption;
  vInProcess := false;
end;

constructor TParamEdit.Create(AOwner :TComponent);
begin
  inherited;
  Parent := TWinControl(AOwner);
  left := 4;
  width := TControl(AOwner).Width - 46;
  OnChange := OnChangeParamEdit;
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
  OnChange := OnChangeDTPEdit;
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
        with TSelectEdt(TScrollBox(Sender).FindComponent(TSelectEdt(Sender).GetChildNames.Strings[i])).QryVal do begin
          if Filtered then Filtered := false;
          Filter := Fields[2].FieldName + '=' + Char(39) + TSelectEdt(Sender).QryVal.Fields[1].AsString + Char(39);
          Filtered := true;
          TSelectEdt(TScrollBox(Sender).FindComponent(TSelectEdt(Sender).GetChildNames.Strings[i])).KeyVal := Null;
          TSelectEdt(TScrollBox(Sender).FindComponent(TSelectEdt(Sender).GetChildNames.Strings[i])).Clear;
        end;
end;

procedure TParamEdit.OnChangeParamEdit(Sender :TObject);
begin
  if DataType = 'String' then if length(Text) > 0 then KeyVal := Text else KeyVal := Null;
  if DataType = 'Double' then  if length(Text) > 0 then KeyVal := strtofloat(Text) else KeyVal := Null;
  if DataType = 'DateTime' then  if length(Text) > 0 then KeyVal := StrToDateTime(Text) else KeyVal := Null;
  if DataType = 'Boolean' then  if length(Text) > 0 then KeyVal := strtoint(Text) else KeyVal := Null;
end;

procedure TNumEdit.OnKeyPressNumEdit(Sender :TObject;var Key: Char);
begin
  if not(Key in ['0'..'9',#8,#9,DecimalSeparator]) then Key := #0;
end;

procedure TDTPEdit.OnKeyPressDTPEdit(Sender :TObject; var Key: Char);
begin
  if not(Key in ['0'..'9',#8,#9,'.']) then Key := #0;
end;

procedure TDTPEdit.OnChangeDTPEdit(Sender :TObject);
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
end;

procedure TSelectBtn.OnClickSelectBtn(Sender :TObject);
begin
  if Owner.ClassType = TDTPEdit then
    with TfrmDateTime.Create(TDTPEdit(Owner)) do begin
      if length(TDTPEdit(Owner).Text) > 0 then DateTime := StrToDateTime(TDTPEdit(Owner).Text);
      ShowModal;
    end
  else
    with TfrmSelect.Create(TSelectEdt(Owner),TSelectEdt(Owner).QryVal) do ShowModal;
end;

procedure TParamCheckBox.OnClickParamCheckBox(Sender :TObject);
begin
  inherited;
  if Checked then KeyVal := 1 else KeyVal := 0;
end;

procedure TfrBaseRepParams.BuildParams(DataSet,DataSetOut :TDataSet; ReportName :string);
begin
  BuildParams(DataSet,DataSetOut,ReportName,0,0,[],[],[]);
end;

procedure TfrBaseRepParams.BuildParams(DataSet,DataSetOut :TDataSet; ReportName :string; PivotDataBeginRow,PivotColCount :integer; PivotRows,PivotColumns,PivotValues :Array of integer);
var vPrevCompName :string;
    i :integer;
begin
  if PivotDataBeginRow > 0 then vPivotDataBeginRow := PivotDataBeginRow else vPivotDataBeginRow := TOraQuery(DataSetOut).ParamCount + 2;
  if PivotColCount > 0 then vPivotColCount := PivotColCount else vPivotColCount := DataSet.RecordCount + 1;
  setlength(vPivotRows,length(PivotRows));
  if length(vPivotRows) > 0 then for i := 0 to length(vPivotRows) - 1 do vPivotRows[i] := PivotRows[i];
  setlength(vPivotColumns,length(PivotColumns));
  if length(vPivotColumns) > 0 then for i := 0 to length(vPivotColumns) - 1 do vPivotColumns[i] := PivotColumns[i];
  setlength(vPivotValues,length(PivotValues));
  if length(vPivotValues) > 0 then for i := 0 to length(vPivotValues) - 1 do vPivotValues[i] := PivotValues[i];


  vReportName := ReportName;
  scrlBox.DestroyComponents;
  vQry := TOraQuery(DataSet);
  vQryOut := TOraQuery(DataSetOut);
  vPrevCompName := '';
  with vQry do begin
    if not(Active) then Open;
    first;
    while not(Eof) do begin
        if not(Fields[2].AsString = 'Boolean') then
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
        if (Fields[2].AsString = 'Double') and Fields[3].IsNull then
          with TNumEdit.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else KeyVal := Fields[5].AsFloat;
            Text := Fields[5].AsString;
          end;
        if (Fields[2].AsString = 'String') and Fields[3].IsNull then
          with TParamEdit.Create(scrlBox) do begin
            Parent :=  scrlBox;
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            width := scrlBox.Width - 24;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else KeyVal := Fields[5].AsString;
            Text := Fields[5].AsString;
          end;
        if (Fields[2].AsString = 'DateTime') then begin
          with TDTPEdit.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := Null else KeyVal := Fields[5].AsDateTime;
            Text := Fields[5].AsString;
          end;
          with TSelectBtn.Create(TSelectEdt(scrlBox.FindComponent(vPrevCompName))) do
          begin
            Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top;
            Name := 'dbtn' + Fields[1].AsString;
          end;
        end;
        if (Fields[2].AsString = 'Boolean') then
          with TParamCheckBox.Create(scrlBox) do begin
            if length(vPrevCompName) > 0 then Top := TControl(scrlBox.FindComponent(vPrevCompName)).Top + TControl(scrlBox.FindComponent(vPrevCompName)).Height + 4
              else Top := 4;
            Name := Fields[1].AsString;
            Caption := Fields[4].AsString;
            vPrevCompName := Name;
            DataType := Fields[2].AsString;
            if Fields[5].IsNull then KeyVal := 0 else KeyVal := Fields[5].AsInteger;
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
              if Fields[2].AsString = 'String' then KeyVal := Fields[5].AsString;
              if Fields[2].AsString = 'Double' then KeyVal := Fields[5].AsFloat;
              if Fields[2].AsString = 'DateTime' then KeyVal := Fields[5].AsDateTime;
              if Fields[2].AsString = 'Boolean' then KeyVal := Fields[5].AsInteger;
            end;
            Text := Fields[6].AsString;
            Tag := RecNo - 1;
            if not(Fields[7].IsNull) then
              TSelectEdt(scrlBox.FindComponent(Fields[7].AsString)).GetChildNames.Append(Fields[1].AsString);
            vQryVal := TOraQuery.Create(self);
            with vQryVal do begin
              Connection := vQry.Connection;
              SQL.Text := vQry.Fields[3].AsString;
              Open;
              Fields[0].DisplayLabel :=  vQry.Fields[4].AsString;
              Fields[1].Visible := false;
            end;
            if not(Fields[7].IsNull) then begin
                vQryVal.Filter := vQryVal.Fields[2].FieldName + '=' + Char(39) + TSelectEdt(scrlBox.FindComponent(Fields[7].AsString)).KeyVal + Char(39);
                vQryVal.Filtered := true;
              end;
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

end;

procedure TfrBaseRepParams.ExecuteReport(DataSet :TDataSet);
var i :integer;
    vParam :TComponent;
begin
  if not(Assigned(vQry)) or not(Assigned(vQryOut)) then exit;
  if TOraQuery(DataSet).Active then TOraQuery(DataSet).Close;
  if TOraQuery(DataSet).Params.Count = 0 then begin
    TOraQuery(DataSet).Open;
    Exit;
  end;

  {if TOraQuery(DataSet).Params.Count <> vParamType.Count then begin
    MessageDlg('Спецификация параметров не соответствует параметрам запроса:' + Char(10) +
               'в спецификации - ' +  inttostr(vParamType.Count) + Char(10) +
               'в запросе - ' + inttostr(TOraQuery(DataSet).Params.Count)
              ,mtInformation,[mbOk],0);
    exit;
  end;}

  for i := 0 to TOraQuery(DataSet).Params.Count - 1 do begin
    vParam := scrlBox.FindComponent(TOraQuery(DataSet).Params[i].Name);
    if vParam.ClassParent = TParamEdit then
      with TParamEdit(vParam) do begin
        if DataType = 'String' then TOraQuery(DataSet).Params[i].DataType := ftString;
        if DataType = 'Double' then TOraQuery(DataSet).Params[i].DataType := ftFloat;
        if DataType = 'DateTime' then TOraQuery(DataSet).Params[i].DataType := ftDateTime;

        //if DataType = 'String' then KeyVal := Text;
        //if DataType = 'Double' then KeyVal := StrToFloat(Text);
        //if DataType = 'DateTime' then KeyVal := StrToDateTime(Text);

        TOraQuery(DataSet).Params[i].Value := KeyVal;
      end
    else
      with TParamCheckBox(vParam) do begin
        TOraQuery(DataSet).Params[i].DataType := ftInteger;
        TOraQuery(DataSet).Params[i].Value := KeyVal;
      end;
  end;
  TOraQuery(DataSet).Open;
end;

procedure TfrBaseRepParams.ExecRep;
begin
  if assigned(vQryOut) then ExecuteReport(vQryOut);
end;

procedure TMyThread.Execute;
var i :integer;
begin
  with TfrBaseRepParams(MyFrame) do begin
    for i := 0 to ControlCount - 1 do begin Controls[i].Enabled := false; Font.Color := clGrayText; end;
    btnExRep.Enabled := false;
    chbToExcel.Enabled := false;
    //
    ExecRep;
    //
    for i := 0 to ControlCount - 1 do begin Controls[i].Enabled := true; Font.Color := clBlack; end;
    btnExRep.Enabled := true;
    chbToExcel.Enabled := true;
    btnExRep.Caption := vBtnCaption;
    vInProcess := false;
  end;
end;

procedure TfrBaseRepParams.btnExRepClick(Sender: TObject);
begin
  vBegDt := Now;
  vInProcess := true;
  with TMyThread.Create(true,self) do begin
    Priority := tpLower;
    FreeOnTerminate := true;
    Resume;
  end;
end;

procedure TfrBaseRepParams.tmrRepParamsTimer(Sender: TObject);
begin
  with btnExRep do if vInProcess then Caption := ti_as_hms(Now - vBegDt)
    else if chbToExcel.Checked and vQryOut.Active then begin
           ExpToExcel(vQryOut,vPivotDataBeginRow,vPivotColCount,vPivotRows,vPivotColumns,vPivotValues);
           if vQryOut.Active then vQryOut.Close;
         end;
end;

procedure TfrBaseRepParams.ExpToExc;
begin
  ExpToExcel(vQryOut,vPivotDataBeginRow,vPivotColCount,vPivotRows,vPivotColumns,vPivotValues);
end;

procedure TfrBaseRepParams.ExpToExcel(DataSet :TDataSet; PivotDataBeginRow,PivotColCount :integer; Rows,Columns,Values :Array of integer);
var
    ExcelApp, Workbook, Range, Cell1, Cell2, ArrayData  : Variant;
    BeginCol, BeginRow, i, j, RowCount, ColCount : integer;
    PC,PT :Variant; //PivotCashes,PivotTable
    PivotRange,CellValue :string;
begin
  // Создание Excel
  ExcelApp := CreateOleObject('Excel.Application');
  ExcelApp.SheetsInNewWorkbook := 1;

  // Отключаем реакцию Excel на события,
  //чтобы ускорить вывод информации
  ExcelApp.Application.EnableEvents := false;

  //  Создаем Книгу (Workbook)
  // Если заполняем шаблон, то
  // Workbook := ExcelApp.WorkBooks.Add('C:\MyTemplate.xls');
  Workbook := ExcelApp.WorkBooks.Add;

  //Обработка параметров и заголовка
  Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[1,1],Workbook.WorkSheets[1].Cells[1,2]];
  Range.Font.Color := RGB(50, 110, 70);
  Range.Font.Bold := true;
  Range.Font.Size := 18;

  //Заполнение заголовка и параметров
  Workbook.WorkSheets[1].Cells[1,1]:= vReportName;
  for j:=1 to TOraQuery(DataSet).ParamCount do begin
  if scrlBox.FindComponent(TOraQuery(DataSet).Params[j-1].Name).ClassType = TParamCheckBox then
    Workbook.WorkSheets[1].Cells[1+j,1]:= TParamCheckBox(scrlBox.FindComponent(TOraQuery(DataSet).Params[j-1].Name)).Caption
  else Workbook.WorkSheets[1].Cells[1+j,1]:= TLabel(scrlBox.FindComponent('lab' + TOraQuery(DataSet).Params[j-1].Name)).Caption;
  Workbook.WorkSheets[1].Cells[1+j,2]:= TOraQuery(DataSet).Params[j-1].AsString;
  end;


  //Форматирование заголовков
  Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[TOraQuery(DataSet).ParamCount + 2,1],Workbook.WorkSheets[1].Cells[TOraQuery(DataSet).ParamCount + 2,DataSet.Fields.Count]];
  Range.Font.Bold := true;
  Range.Font.Color := clWhite;
  Range.Interior.Color := RGB(50, 110, 70);
  Range.Borders.Color := clWhite;

  //Заполнение заголовков
  for j:=1 to DataSet.Fields.Count do
   if DataSet.Fields[j-1].Visible
     then Workbook.WorkSheets[1].Cells[TOraQuery(DataSet).ParamCount + 2,j]:= DataSet.Fields[j-1].DisplayLabel;

  // Координаты левого верхнего угла области,
  //в которую будем выводить данные
  BeginCol := 1;
  BeginRow := 2;

  //Фитчим все строки
  DataSet.Last;
  DataSet.First;

  // Размеры выводимого массива данных
  RowCount := DataSet.RecordCount;
  ColCount := DataSet.Fields.Count;


  // Создаем Вариантный Массив,
  //который заполним выходными данными
  ArrayData := VarArrayCreate([1, RowCount, 1, ColCount],varVariant);

  // Заполняем массив
  DataSet.DisableControls;
  for I := 1 to RowCount do
    begin
      for J := 1 to ColCount do
        if DataSet.Fields[j-1].Visible then
          case DataSet.Fields[j-1].DataType of
            ftFloat : ArrayData[I, J] := DataSet.Fields[j-1].AsFloat;
            ftDateTime :ArrayData[I, J] := DataSet.Fields[j-1].AsDateTime;
          else ArrayData[I, J] := DataSet.Fields[j-1].AsString;
          end;
      DataSet.Next;
    end;
 DataSet.EnableControls;
  // Левая верхняя ячейка области,
  //в которую будем выводить данные
  Cell1 := WorkBook.WorkSheets[1].Cells[TOraQuery(DataSet).ParamCount + 1 + BeginRow, BeginCol];
  // Правая нижняя ячейка области,
  //в которую будем выводить данные
  Cell2 := WorkBook.WorkSheets[1].Cells[TOraQuery(DataSet).ParamCount + 1 + BeginRow  + RowCount - 1,
           BeginCol + ColCount - 1];

  // Область, в которую будем выводить данные
  Range := WorkBook.WorkSheets[1].Range[Cell1, Cell2];

  // А вот и сам вывод данных
  // Намного быстрее поячеечного присвоения
  Range.Value := ArrayData;

  //Подгоняем столбцы по ширине
  for j:=1 to DataSet.Fields.Count do
    Workbook.WorkSheets[1].Columns[j].EntireColumn.AutoFit;

  try
  //ЕСЛИ НЕОБХОДИМА СВОДНАЯ ТАБЛИЦА
  if DataSet.RecordCount > 0 then begin
  if length(vPivotRows) > 0 then begin
    //Добавление нового листа для сводной таблицы
    Workbook.Sheets.Add;
    WorkBook.Worksheets[1].Name := 'Сводные данные';
    //Формирование строки, определяющей источник данных для сводной таблицы
    PivotRange := 'Лист1!R'+inttostr(vPivotDataBeginRow) + 'C1:R' +
                  inttostr(vPivotDataBeginRow + RowCount) + 'C' +
                  inttostr(BeginCol + ColCount - 1);

    //Обработка параметров и заголовка
    Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[1,1],Workbook.WorkSheets[1].Cells[1,2]];
    Range.Font.Color := RGB(50, 110, 70);
    Range.Font.Bold := true;
    Range.Font.Size := 18;

    //Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[vDataBeginRow,1],Workbook.WorkSheets[1].Cells[vDataBeginRow + length(vPivotColumns) + 1,DataSet.FieldCount + 2]];
    //Range.Font.Color := RGB(50, 110, 70);
    //Range.Font.Bold := true;
    //Range.Font.Size := 18;

    //Заполнение заголовка и параметров
    Workbook.WorkSheets[1].Cells[1,1]:= vReportName;
    for j:=1 to TOraQuery(DataSet).ParamCount do begin
    if scrlBox.FindComponent(TOraQuery(DataSet).Params[j-1].Name).ClassType = TParamCheckBox then
      Workbook.WorkSheets[1].Cells[1+j,1]:= TParamCheckBox(scrlBox.FindComponent(TOraQuery(DataSet).Params[j-1].Name)).Caption
    else Workbook.WorkSheets[1].Cells[1+j,1]:= TLabel(scrlBox.FindComponent('lab' + TOraQuery(DataSet).Params[j-1].Name)).Caption;
    Workbook.WorkSheets[1].Cells[1+j,2]:= TOraQuery(DataSet).Params[j-1].AsString;
    end;

    PC := WorkBook.PivotCaches.Create(1,PivotRange);
    PC.CreatePivotTable(WorkBook.Worksheets[1].Cells[vPivotDataBeginRow,1],'PivotTable1');
    PT := WorkBook.Worksheets[1].PivotTables('PivotTable1');
    WorkBook.Worksheets[1].Cells[vPivotDataBeginRow,1].Select;

    for i := 1 to length(vPivotRows) do begin
      PT.PivotFields(TOraQuery(DataSet).Fields[vPivotRows[i-1]-1].DisplayLabel).Orientation := 1; //строка
      PT.PivotFields(TOraQuery(DataSet).Fields[vPivotRows[i-1]-1].DisplayLabel).Position := i;
    end;
    for i := 1 to length(vPivotColumns) do begin
      PT.PivotFields(TOraQuery(DataSet).Fields[vPivotColumns[i-1]-1].DisplayLabel).Orientation := 2; //столбец
      PT.PivotFields(TOraQuery(DataSet).Fields[vPivotColumns[i-1]-1].DisplayLabel).Position := i;
    end;
    for i := 1 to length(vPivotValues) do begin
      PT.PivotFields(TOraQuery(DataSet).Fields[vPivotValues[i-1]-1].DisplayLabel).Orientation := 4; //данные
      //PT.PivotFields(TOraQuery(DataSet).Fields[vPivotValues[i-1]-1].DisplayLabel).function := 'xlSum';
      //PT.PivotFields('Сумма по полю ' + TOraQuery(DataSet).Fields[vPivotValues[i-1]-1].DisplayLabel).Caption := Char(34) + TOraQuery(DataSet).Fields[vPivotValues[i-1]-1].DisplayLabel + Char(34);
    end;

    Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[vPivotDataBeginRow,1],Workbook.WorkSheets[1].Cells[vPivotDataBeginRow + length(vPivotColumns) + 1,vPivotColCount]];
    Range.Font.Bold := true;
    Range.Font.Color := clWhite;
    Range.Interior.Color := RGB(50, 110, 70);
    Range.Borders.Color := clWhite;

    //Подгоняем 1-й столбец по ширине
    Workbook.WorkSheets[1].Columns[1].EntireColumn.AutoFit;

    //
    CellValue := 'Start';
    i := vPivotDataBeginRow + length(vPivotColumns);
    while length(CellValue) > 0 do begin
      i := i + 1;
      CellValue := Workbook.WorkSheets[1].Cells[i,1].Value;
    end;
    Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[i-1,1],Workbook.WorkSheets[1].Cells[i-1,vPivotColCount]];
    Range.Font.Bold := true;
    Range.Font.Color := clWhite;
    Range.Interior.Color := RGB(50, 110, 70);
    Range.Borders.Color := clWhite;
  end;
  end;
  //КОНЕЦ СВОДНАЯ ТАБЛИЦА

  // Делаем Excel видимым
  finally
    WorkBook.Worksheets[1].Cells[1,1].Select;
    ExcelApp.Visible := true;
    ExcelApp := unAssigned;
  end;
end;

end.
