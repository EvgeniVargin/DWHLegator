unit untBaseFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, DBCtrls, Grids, DB, Ora, StdCtrls,
  Buttons, ComObj, DBGridEh;

type
  TfrBase = class(TFrame)
    edtSearch: TEdit;
    dbGrid: TDBGridEh;
    panTopFilter: TPanel;
    sbExpToExcel: TSpeedButton;
    sbExpToHTML: TSpeedButton;
    procedure edtSearchChange(Sender: TObject);
    procedure dbGridCellClick(Column: TColumnEh);
    procedure dbGridKeyPress(Sender: TObject; var Key: Char);
    procedure dbGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumnEh; State: TGridDrawState);
    procedure sbExpToExcelClick(Sender: TObject);
    procedure dbGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure sbExpToHTMLClick(Sender: TObject);
  private
    { Private declarations }
    FSearchColumn :integer;
    FQry :TOraQuery;
    FDataSource :TDataSource;
    FDrawField :string;
    FDrawBrushColor,FDrawFontColor :Array of TColor;
    FDrawValue :Array of variant;
    FDrawColumns :Array of string;
  public
    { Public declarations }
    constructor Create(AOwner :TComponent); override;
    procedure SetConnection(Connection :TOraSession);
    procedure SetDataSource(inDataSource :TDataSource);
    function  GetDataSource :TDataSource;
    function  GetQry :TOraQuery;
    procedure SetDrawColumns(ColorFields :array of string);
    procedure SetDrawCells(Field :string; Value,BrushColor,FontColor :Array of variant; AllVarCount :integer);
    procedure SetColWidth;
    procedure DrawCheckBoxes(FieldNames :array of string);
    procedure SetSearchColumn(Value :integer);
    function  GetSearchColumn :integer;
    function  GetSearchColName :string;
    procedure ExpToHTML(Grid :TDBGridEh);
  end;

implementation

uses untUtility,untRegistry;

{$R *.dfm}

constructor TfrBase.Create(AOwner :TComponent);
begin
  inherited Create(AOwner);
end;

function TfrBase.GetSearchColName :string;
begin
  result := dbGrid.Columns.Items[FSearchColumn].FieldName;
end;

procedure TfrBase.SetConnection(Connection :TOraSession);
begin
  if Assigned(FQry) then FQry.Session := Connection;
end;

procedure TfrBase.DrawCheckBoxes(FieldNames :array of string);
var i,j :integer;
begin
  with dbGrid.Columns do
    for i := 0 to Count - 1 do
      for j := 0 to length(FieldNames) - 1 do
        if Items[i].FieldName = FieldNames[j] then begin
           Items[i].Checkboxes := true;
           Items[i].KeyList.Add('1');
           Items[i].KeyList.Add('0');
           Items[i].KeyList.Add('-1');
        end;
end;

procedure TfrBase.SetDataSource(inDataSource: TDataSource);
begin
  FDataSource := inDataSource;
  dbGrid.DataSource := FDataSource;
  FQry := TOraQuery(FDataSource.DataSet);
  SetSearchColumn(0);
end;

function TfrBase.GetDataSource;
begin
  result := FDataSource;
end;

function TfrBase.GetQry;
begin
  result := FQry;
end;

procedure TfrBase.SetDrawColumns(ColorFields :array of string);
var i,y :integer;
begin
  //Установка полей, которые необходитмо раскрашивать
  //Если nil, - то раскрашиваем всю строку
  SetLength(FDrawColumns,dbGrid.Columns.Count);
    for i := 0 to Length(FDrawColumns) - 1 do
        //--if Length(ColorFields) > 0 then
          for y := 0 to Length(ColorFields) - 1 do
            if LowerCase(ColorFields[y]) = LowerCase(dbGrid.Columns.Items[i].FieldName) then FDrawColumns[i] := dbGrid.Columns.Items[i].FieldName;
end;

procedure TfrBase.SetDrawCells(Field :string; Value,BrushColor,FontColor :Array of variant; AllVarCount :integer);
var i :integer;
begin
  //Установка наименования поля, по которому смотреть раскраску
  FDrawField := Field;
  //Установка значений поля, в зависимости от которых раскрашивать
  SetLength(FDrawValue,AllVarCount);
  for i := 0 to AllVarCount - 1 do FDrawValue[i] := Value[i];
  //Установка значений цветов фона и шрифта
  SetLength(FDrawBrushColor,AllVarCount);
  SetLength(FDrawFontColor,AllVarCount);
  for i := 0 to AllVarCount - 1 do
    begin
      FDrawBrushColor[i] := BrushColor[i];
      FDrawFontColor[i] := FontColor[i];
    end;
end;

procedure TfrBase.SetSearchColumn(Value: Integer);
begin
  FSearchColumn := Value;
end;

function TfrBase.GetSearchColumn;
begin
  result := FSearchColumn;
end;

procedure TfrBase.sbExpToExcelClick(Sender: TObject);
begin
  ExpToExcel(dbGrid);
end;

procedure TfrBase.sbExpToHTMLClick(Sender: TObject);
begin
  ExpToHTML(dbGrid);
end;

procedure TfrBase.dbGridCellClick(Column: TColumnEh);
begin
  SetSearchColumn(Column.Index);
  Column.Grid.Hint := Column.Field.AsString;
end;

procedure TfrBase.dbGridDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumnEh; State: TGridDrawState);
var vField :TField;
    i :integer;
begin
  vField := TDBGridEh(Sender).DataSource.DataSet.FindField(FDrawField);
  if not(Assigned(vField)) then exit;
  if Length(FDrawColumns) = 0 then
    begin
      SetLength(FDrawColumns,TDBGridEh(Sender).Columns.Count);
      for i := 0 to TDBGridEh(Sender).Columns.Count - 1 do FDrawColumns[i] := TDBGridEh(Sender).Columns.Items[i].FieldName;
    end;

  for i := 0 to Length(FDrawValue) - 1 do
    begin
      if not Column.Checkboxes then
      if (TDBGridEh(Sender).DataSource.DataSet.FieldByName(FDrawField).Value = FDrawValue[i])
          and  (Column.FieldName = FDrawColumns[Column.Index]) then
        with TDBGridEh(Sender).Canvas do
          begin
            if State <> State - [gdSelected] then
              begin
                Brush.Color := clHighLight;
                Font.Color := clYellow;
              end
            else
              begin
                Brush.Color := FDrawBrushColor[i];
                Font.Color := FDrawFontColor[i];
              end;
          //ColColors[Column.Field.DataSet.RecNo - 1,Column.Index] := [ColorToString(FDrawBrushColor[i]),ColorToString(FDrawFontColor[i])];
          FillRect(Rect);
            case  Column.Alignment of
              taRightJustify: TextOut(Rect.Right - 2 - TextWidth(Column.Field.Text),Rect.Top+2,Column.Field.Text);
              taLeftJustify:   TextOut(Rect.Left + 2, Rect.Top + 2, Column.Field.Text);
            else
              TextOut(Round(Rect.Left + (Rect.Right-Rect.Left)/2) - Round(TextWidth(Column.Field.Text)/2),Rect.Top+2,Column.Field.Text);
            end;
          end;
    end;
end;

procedure TfrBase.dbGridKeyPress(Sender: TObject; var Key: Char);
begin
  case  Key of
  #13: Key := #0;
  #8: edtSearch.Clear;
  #9: edtSearch.Clear;
  #46: begin end;
  else edtSearch.Text := edtSearch.Text+Char(Key);
  end;
end;

procedure TfrBase.edtSearchChange(Sender: TObject);
begin
    with FQry do
      begin
        try
          if Assigned(FQry) and Filtered then Filtered := false;
          //showmessage(dbGrid.Columns.Items[GetSearchColumn].FieldName+' LIKE ''%'+edtSearch.Text+'%''');
          if not(dbGrid.Columns.Items[GetSearchColumn].Field.DataType in [ftDate,ftDateTime]) then
            Filter := dbGrid.Columns.Items[GetSearchColumn].FieldName + ' LIKE ''%'+edtSearch.Text+'%''';
          if Length(edtSearch.Text)>0 then Filtered :=true;
        except
        end;
      end;
end;

procedure TfrBase.SetColWidth;
var i :integer;
begin
  with dbGrid do
    for i := 0 to Columns.Count - 1 do
      begin
        //ShowMessage(Columns[i].FieldName + ' BEFORE - ' + inttostr(Columns[i].Field.DisplayWidth));
        if Columns[i].Field.Visible then begin
          Columns[i].Width := Columns[i].Field.DisplayWidth;
        end;
        //ShowMessage(Columns[i].FieldName + ' AFTER - ' + inttostr(Columns[i].Field.DisplayWidth));
      end;
end;

procedure TfrBase.dbGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F5 then if Assigned(FQry) and FQry.Active then FQry.Refresh;
end;

procedure TfrBase.ExpToHTML(Grid :TDBGridEh);
var
j : integer;
SaveDlg :TOpenDialog;
HTML :TStringList;
Buffer,vColorFieldName,vBrushColor,vFontColor,vRepName :string;
SQL :TOraSQL;
vQryColors :TOraQuery;

begin
  HTML := TStringList.Create;
  SaveDlg := TSaveDialog.Create(Grid.Owner);
  SaveDlg.Filter := '*.html|*.html';
  vRepName := '';

  try
    try
      HTML.Add('<!DOCTYPE html>');
      HTML.Add('<html>');
      HTML.Add('<head>');

      SQL := TOraSQL.Create(Grid.Owner);
      SQL.SQL.Add('BEGIN :OUTRES := pkg_etl_signs.GetVarValue(''HTMLEncoding''); END;');
      SQL.ParamByName('OUTRES').ParamType := ptOutput;
      SQL.ParamByName('OUTRES').DataType := ftString;
      SQL.Execute;
      HTML.Add(SQL.ParamByName('OUTRES').AsString);

      SQL.SQL.Clear;
      SQL.SQL.Add('DECLARE vRes VARCHAR2(4000); BEGIN vRes := pkg_etl_signs.GetVarValue(''HTMLTableStyle''); :OUTRES := vRes; END;');
      SQL.ParamByName('OUTRES').ParamType := ptOutput;
      SQL.ParamByName('OUTRES').DataType := ftString;
      SQL.Execute;
      HTML.Add(SQL.ParamByName('OUTRES').AsString);

      HTML.Add('</head>');
      HTML.Add('<body>');

      SQL.SQL.Clear;
      SQL.SQL.Add('DECLARE vRes VARCHAR2(4000); BEGIN vRes := pkg_etl_signs.GetVarValue(''HTMLLogo''); :OUTRES := vRes; END;');
      SQL.ParamByName('OUTRES').ParamType := ptOutput;
      SQL.ParamByName('OUTRES').DataType := ftString;
      SQL.Execute;
      HTML.Add(SQL.ParamByName('OUTRES').AsString);

      if not Assigned(vQryColors) then vQryColors := TOraQuery.Create(Grid.DataSource.DataSet.Owner);
      if vQryColors.Active then vQryColors.Close;

      vQryColors.SQL.Clear;
      vQryColors.SQL.Add('SELECT query_descr' + #13#10 +
                         '  FROM tb_query_registry q' + #13#10 +
                         '       LEFT JOIN tb_form_registry f' + #13#10 +
                         '         ON f.id = q.form_id' + #13#10 +
                         '  WHERE  q.query_name = ''' + Grid.DataSource.DataSet.Name + '''' + #13#10 +
                         '    AND (f.form_name IS NULL OR f.form_name IS NOT NULL AND f.form_name = ''' + Grid.DataSource.DataSet.Owner.Name + ''')');
      vQryColors.Open;
      vRepName := vQryColors.FieldByName('QUERY_DESCR').AsString;
      vQryColors.Close;
     if length(vRepName) > 0 then  HTML.Add('<br><br><span id = "RepName"><strong>' + vRepName + '</strong></span><br><br>');
     HTML.Add('<table>');

      //Заполнение заголовков
      Buffer := '<tr>';
      for j:=1 to Grid.Columns.Count do
       if Grid.Columns.Items[j-1].Visible
         then Buffer := Buffer + '<th>' + Grid.Columns.Items[j-1].Title.Caption + '</th>';
      Buffer := Buffer + '</tr>';
      HTML.Add(Buffer);
      //Окончание заполнения заголовков

      //Фетчим все строки
      Grid.DataSource.DataSet.Last;
      Grid.DataSource.DataSet.First;
      //Окончание фетчинга строк

      // Заполнение ячеек таблицы

      vQryColors.SQL.Clear;
      vQryColors.SQL.Add('SELECT fld.field_name' + #13#10 +
                         '  FROM tb_query_registry q' + #13#10 +
                         '       LEFT JOIN tb_form_registry f ON q.form_id = f.id' + #13#10 +
                         '       LEFT JOIN tb_field_registry fld ON fld.query_id = q.id AND fld.is_color_field = 1' + #13#10 +
                         '  WHERE q.query_name = ''' + Grid.DataSource.DataSet.Name + '''' + #13#10 +
                         '    AND (f.form_name IS NULL OR f.form_name IS NOT NULL AND f.form_name = ''' + Grid.DataSource.DataSet.Owner.Name + ''')');
      vQryColors.Open;
      vColorFieldName := '';
      if not vQryColors.FieldByName('FIELD_NAME').IsNull then begin
        vColorFieldName := vQryColors.FieldByName('FIELD_NAME').AsString;
        vQryColors.Close;
        vQryColors.SQL.Clear;
        vQryColors.SQL.Add('SELECT fcl.fval,fcl.brush_color,fcl.font_color' + #13#10 +
                           '  FROM tb_query_registry q' + #13#10 +
                           '       LEFT JOIN tb_form_registry f ON q.form_id = f.id' + #13#10 +
                           '       LEFT JOIN tb_field_registry fld ON fld.query_id = q.id AND fld.is_color_field = 1' + #13#10 +
                           '       LEFT JOIN tb_fcolor_registry fcl ON fcl.field_id = fld.id' + #13#10 +
                           '  WHERE q.query_name = ''' + Grid.DataSource.DataSet.Name + '''' + #13#10 +
                           '    AND (f.form_name IS NULL OR f.form_name IS NOT NULL AND f.form_name = ''' + Grid.DataSource.DataSet.Owner.Name + ''')');
        vQryColors.Open;
      end;
      Grid.DataSource.DataSet.DisableControls;
      while not(Grid.DataSource.DataSet.Eof) do
        begin
          Buffer := '<tr>';
          if length(vColorFieldName) > 0 then vQryColors.Locate('FVAL',Grid.DataSource.DataSet.FieldByName(vColorFieldName).AsString,[loCaseInsensitive]);
          for j := 1 to Grid.Columns.Count do
            if Grid.Columns.Items[j-1].Visible then begin
              if length(vColorFieldName) > 0 then begin
                vBrushColor := vQryColors.FieldByName('BRUSH_COLOR').AsString;
                vBrushColor := Copy(vBrushColor,3,length(vBrushColor) - 2);
                vFontColor := vQryColors.FieldByName('FONT_COLOR').AsString;
                vFontColor := Copy(vFontColor,3,length(vFontColor) - 2);
                Buffer := Buffer + '<td><span style="backgroud-color:'+vBrushColor+';color:'+vFontColor+'">' + Grid.Columns.Items[j-1].Field.asstring + '</span></td>';
              end else
                Buffer := Buffer + '<td>' + Grid.Columns.Items[j-1].Field.AsString + '</td>';
            end;
          Buffer := Buffer + '</tr>';
          HTML.Add(Buffer);
          Grid.DataSource.DataSet.Next;
        end;
      Grid.DataSource.DataSet.EnableControls;
      //Окончание заполнения ячеек таблицы

      HTML.Add('</table>');
      HTML.Add('</body>');
      HTML.Add('</html>');
      if SaveDlg.Execute then begin
        HTML.SaveToFile(SaveDlg.FileName);
        MessageDlg('Успешно сохранено в Файл: ' + SaveDlg.FileName,mtInformation,[mbOk],0);
      end;
    except
      MessageDlg('Ошибка сохранения в файл: ' + SaveDlg.FileName,mtError,[mbOk],0);
    end;
  finally
    HTML.Free;
    SaveDlg.Free;
    SQL.Free;
    vQryColors.Free;
  end;
end;

end.
