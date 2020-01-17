unit untRegistry;

interface

uses Windows, Forms, Ora, SysUtils, Dialogs, Classes, Menus, DBGridEh, Variants, Graphics,
     DB, Controls, DBAccess, Math, ComCtrls, OdacVcl, Registry;

  type TActionMenuItem = class(TMenuItem)
    private
      vActId :integer;
      vBtn :TToolButton;
    public
      procedure SetActId(ID :integer);
      function  GetActId :integer;
      procedure SetButton(Button :TToolButton);
      function  GetButton :TToolButton;
  end;

  procedure SetUserName(UserName :string);
  procedure SetUserPass(UserPass :string);
  function GetUserName :string;
  function GetUserPass :string;
  procedure RUserWrite;
  procedure RUserRead;
  procedure SetOsUser(Owner :TComponent; out User,UserFIO :string);
  function StrToColor(ColorName :string) :TColor;
  procedure AddAttrs(FormName :String; Attrs :TStringList);
  function Registered(FormName :string) :boolean;
  function GetMasterKeyField(FormName,QueryName :string) :string;
  function GetDetailKeyField(FormName,QueryName :string) :string;
  procedure GetCheckBoxes(FormName,QueryName :string; out CheckBoxes :array of string);
  procedure GetDrawFieldCount(FormName,QueryName :string; out AllDrawFieldCount :integer);
  procedure GetDrawVarCount(FormName,QueryName :string; out AllVarCount :integer);
  procedure GetDrawColumns(FormName,QueryName :string; out DrawColumns :Array of string);
  procedure GetDrawCells(FormName,QueryName :string; out Field :string; out Values,BrushColors,FontColors :Array of variant);
  //----
  function CreateQuery(Form :TForm; QueryName :string) :TOraQuery;
  function CreateQueryByID(Form :TForm; QueryID :string) :TOraQuery;
  procedure BuildQueries(Form :TForm; QList :TStringList);
  function FindComp(StartComp :TComponent; CompName :string; out Finded :boolean) :TComponent;
  procedure BuildPopupMenu(PopupMenu :TPopupMenu; Query :TOraQuery);
  function CreateDataSource(Query :TOraQuery) :TOraDataSource;
  function GetDialogType(DialogType :string) :TMsgDlgType;
  function GetDialogButtons(Buttons :string) :TMsgDlgButtons;
  function GetQueryByAction(Form :TForm; ActionID :integer) :TOraQuery;
  function GetParamManualInput(ActionID :integer; ParamName :string) :boolean;
  procedure RefreshDetailQueries(StartQuery :TOraQuery);
  procedure RunAction(Query :TOraQuery; ActionID :integer);
  function CreateForm(Owner :TComponent; FormTypeName,FormName :string) :TForm;
  procedure CheckVersion(Session :TOraSession; ExeName :string; out FindedNew :boolean; out FindedID :integer; out FindedVersion,Enhancements :string);
  procedure VersionProccessing(Session :TOraSession; VersionID :integer);

implementation


uses untBaseTreeEdtNew, untBasePCEdtNew,
     untBaseMasterDetailNew,untU2SAdmin,
     untSignsNew,untDoubleViewerNew, untSignCalc,
  untStarExpand,StrUtils,untMTreeDetailNew,untMasterDTreeNew,
  untDependencyNew,untStartWindow, untViewerNew,untReportsNew,
  untReportResultNew,untMasterDetailCommentEditor,untUtility,untChartNew,untPMasterDetailNew;


var
  RUserName,RUserPass :string;

procedure SetUserName(UserName :string);
begin
  RUserName := UserName;
end;

procedure SetUserPass(UserPass :string);
begin
  RUserPass := UserPass;
end;

function GetUserName :string;
begin
  result := RUserName;
end;

function GetUserPass :string;
begin
  result := RUserPass;
end;

procedure RUserWrite;
var
 FReestr: TRegIniFile;
begin
  FReestr := TRegIniFile.Create('SOFTWARE');
  try
    FReestr.WriteString('DWHLegator','username',RUserName);
    FReestr.WriteString('DWHLegator','userpass',RUserPass);
  finally
    FreeAndNil(FReestr);
  end;
end;

procedure RUserRead;
var
 FReestr: TRegIniFile;
begin
  FReestr := TRegIniFile.Create('SOFTWARE');
  try
    FReestr.OpenKey('DWHLegator',true);
    SetUserName(FReestr.ReadString('','username',''));
    SetUserPass(FReestr.ReadString('','userpass',''));
  finally
    FreeAndNil(FReestr);
  end;
end;

procedure SetOsUser(Owner :TComponent; out User,UserFIO :string);
var
  SQL :TOraSQL;
begin
  SQL := TOraSQL.Create(Owner);
  try
    SQL.Session := frmU2SAdmin.Session;
    SQL.SQL.Add('DECLARE' + #13#10 +
'  vUser VARCHAR2(1000);' + #13#10 +
'  vFIO VARCHAR2(1000);' + #13#10 +
'BEGIN' + #13#10 +
'  SELECT DISTINCT sys_context(''userenv'',''OS_USER''),u.user_fio' + #13#10 +
'    INTO vUser,vFIO' + #13#10 +
'    FROM dual d' + #13#10 +
'         LEFT JOIN tb_user_registry u' + #13#10 +
'           ON LOWER(u.ad_login) = LOWER(sys_context(''userenv'',''OS_USER''));' + #13#10 +
':OUTUSER := vUser;' + #13#10 +
':OUTFIO := vFIO;' + #13#10 +
'END;');
    SQL.ParamByName('OUTUSER').ParamType := ptOutput;
    SQL.ParamByName('OUTUSER').DataType := ftString;
    SQL.ParamByName('OUTFIO').ParamType := ptOutput;
    SQL.ParamByName('OUTFIO').DataType := ftString;
    SQL.Execute;
    User := SQL.ParamByName('OUTUSER').AsString;
    UserFIO := SQL.ParamByName('OUTFIO').AsString;
  finally
    SQL.Free;
  end;
end;


procedure TActionMenuItem.SetActId(ID :integer);
begin
  vActId := ID;
end;

function TActionMenuItem.GetActId :integer;
begin
  result := vActID;
end;

procedure TActionMenuItem.SetButton(Button :TToolButton);
begin
  vBtn := Button;
end;

function  TActionMenuItem.GetButton :TToolButton;
begin
  result := vBtn;
end;

function StrToColor(ColorName :string) :TColor;
var vRes :TColor;
begin
vRes := clDefault;
if ColorName = 'clWindow' then vRes := clWindow;
if ColorName = 'clBtnFace' then vRes := clBtnFace;
if ColorName = 'clGrayText' then vRes := clGrayText;
if ColorName = 'clDarkGray' then vRes := clDkGray;
if ColorName = 'clMaroon' then vRes := clMaroon;
if ColorName = 'clBlue' then vRes := clBlue;
if ColorName = 'clGreen' then vRes := clGreen;
if ColorName = 'clYellow' then vRes := clYellow;
if ColorName = 'clNavy' then vRes := clNavy;
if ColorName = 'clPurple' then vRes := clPurple;
if ColorName = 'clRed' then vRes := clRed;
if ColorName = 'clBlack' then vRes := clBlack;
result := vRes;
end;

procedure AddAttrs(FormName :String; Attrs :TStringList);
var PQry :TOraQuery;
begin
  PQry := TOraQuery.Create(Application);
  PQry.SQL.Add('SELECT p.pname,p.pval FROM tb_form_registry f LEFT JOIN tb_fparam_registry p ON p.form_id = f.id WHERE UPPER(f.form_name) = ''' + UPPERCASE(FormName) + ''' ORDER BY p.ord');
  PQry.Open;
  if PQry.RecordCount > 0 then
    with PQry do
      while not Eof do begin
        Attrs.Add(FieldByName('PNAME').AsString + '=' + FieldByName('PVAL').AsString);
        next;
      end;
  PQry.Free;
end;

function Registered(FormName :string) :boolean;
var RQry :TOraQuery;
    vRes :integer;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT COUNT(1) AS cou FROM tb_form_registry WHERE UPPER(form_name) = ''' + UPPERCASE(FormName) + '''');
  RQry.Open;
  vRes := RQry.FieldByName('COU').AsInteger;
  RQry.Free;
  if vRes = 0 then result := false else result := true;
end;

function GetMasterKeyField(FormName,QueryName :string) :string;
var RQry :TOraQuery;
    vRes :string;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT q.master_key_field FROM tb_form_registry f LEFT JOIN tb_query_registry q ON q.form_id = f.id WHERE UPPER(f.form_name) = ''' + UPPERCASE(FormName) + ''' AND UPPER(q.query_name) = ''' + UPPERCASE(QueryName) + ''' ORDER BY q.ord');
  RQry.Open;
  vRes := RQry.FieldByName('MASTER_KEY_FIELD').AsString;
  RQry.Free;
  result := vRes;
end;

function GetDetailKeyField(FormName,QueryName :string) :string;
var RQry :TOraQuery;
    vRes :string;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT q.detail_key_field FROM tb_form_registry f LEFT JOIN tb_query_registry q ON q.form_id = f.id WHERE UPPER(f.form_name) = ''' + UPPERCASE(FormName) + ''' AND UPPER(q.query_name) = ''' + UPPERCASE(QueryName) + ''' ORDER BY q.ord');
  RQry.Open;
  vRes := RQry.FieldByName('DETAIL_KEY_FIELD').AsString;
  RQry.Free;
  result := vRes;
end;

procedure GetCheckBoxes(FormName,QueryName :string; out CheckBoxes :Array of string);
var RQry :TOraQuery;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add(
  'SELECT fl.field_name' + #13#10 +
  '  FROM tb_foption_registry fo' + #13#10 +
  '       INNER JOIN tb_field_registry fl ON fl.id = fo.field_id' + #13#10 +
  '       INNER JOIN tb_query_registry q ON q.id = fl.query_id' + #13#10 +
  '       INNER JOIN tb_form_registry f ON f.id = q.form_id' + #13#10 +
  '  WHERE fo.opt_name = ''CHECKBOX'' AND fo.opt_val = ''1''' + #13#10 +
  '    AND UPPER(f.form_name) = UPPER(''' + uppercase(FormName) + ''')' + #13#10 +
  '    AND UPPER(q.query_name) = UPPER(''' + uppercase(QueryName) + ''')');
  RQry.Open;

  while not RQry.Eof do begin
    CheckBoxes[RQry.RecNo - 1] := RQry.FieldByName('FIELD_NAME').AsString;
    RQry.next;
  end;
end;

procedure GetDrawFieldCount(FormName,QueryName :string; out AllDrawFieldCount :integer);
var FQry :TOraQuery;
begin
  FQry := TOraQuery.Create(Application);
  FQry.SQL.Add(
  'SELECT COUNT(1) AS FIELDCOUNT' + #13#10 +
  '  FROM tb_foption_registry fo' + #13#10 +
  '       INNER JOIN tb_field_registry fl ON fl.id = fo.field_id' + #13#10 +
  '       INNER JOIN tb_query_registry q ON q.id = fl.query_id' + #13#10 +
  '       INNER JOIN tb_form_registry f ON f.id = q.form_id' + #13#10 +
  '  WHERE fo.opt_name = ''DRAWCOLUMN'' AND fo.opt_val = ''1''' + #13#10 +
  '    AND UPPER(f.form_name) = UPPER(''' + uppercase(FormName) + ''')' + #13#10 +
  '    AND UPPER(q.query_name) = UPPER(''' + uppercase(QueryName) + ''')');
  FQry.Open;
  AllDrawFieldCount := FQry.FieldByName('FIELDCOUNT').AsInteger;
  FQry.Free;
end;

procedure GetDrawColumns(FormName,QueryName :string; out DrawColumns :Array of string);
var RQry :TOraQuery;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add(
  'SELECT fl.field_name' + #13#10 +
  '  FROM tb_foption_registry fo' + #13#10 +
  '       INNER JOIN tb_field_registry fl ON fl.id = fo.field_id' + #13#10 +
  '       INNER JOIN tb_query_registry q ON q.id = fl.query_id' + #13#10 +
  '       INNER JOIN tb_form_registry f ON f.id = q.form_id' + #13#10 +
  '  WHERE fo.opt_name = ''DRAWCOLUMN'' AND fo.opt_val = ''1''' + #13#10 +
  '    AND UPPER(f.form_name) = UPPER(''' + uppercase(FormName) + ''')' + #13#10 +
  '    AND UPPER(q.query_name) = UPPER(''' + uppercase(QueryName) + ''')');
  RQry.Open;

  while not RQry.Eof do begin
    DrawColumns[RQry.RecNo - 1] := RQry.FieldByName('FIELD_NAME').AsString;
    RQry.next;
  end;
end;

procedure GetDrawVarCount(FormName,QueryName :string; out AllVarCount :integer);
var RQry :TOraQuery;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add(
  'SELECT COUNT(1) AS varcount' + #13#10 +
  '    FROM tb_fcolor_registry fc' + #13#10 +
  '         INNER JOIN tb_field_registry fl ON fl.id = fc.field_id AND fl.is_color_field = 1' + #13#10 +
  '         INNER JOIN tb_query_registry q ON q.id = fl.query_id AND UPPER(q.query_name) = UPPER(''' + uppercase(QueryName) + ''')' + #13#10 +
  '         INNER JOIN tb_form_registry f ON f.id = q.form_id AND UPPER(f.form_name) = UPPER(''' + uppercase(FormName) + ''')');
  RQry.Open;
  AllVarCount := RQry.FieldByName('VARCOUNT').AsInteger;
  RQry.Free;
end;

procedure GetDrawCells(FormName,QueryName :string; out Field :string; out Values,BrushColors,FontColors :Array of variant);
var FQry,RQry :TOraQuery;
begin
  FQry := TOraQuery.Create(Application);
  FQry.SQL.Add(
  'SELECT fl.field_name' + #13#10 +
  '    FROM tb_field_registry fl' + #13#10 +
  '         INNER JOIN tb_query_registry q ON q.id = fl.query_id AND UPPER(q.query_name) = UPPER(''' + uppercase(QueryName) + ''')' + #13#10 +
  '         INNER JOIN tb_form_registry f ON f.id = q.form_id AND UPPER(f.form_name) = UPPER(''' + uppercase(FormName) + ''')' + #13#10 +
  '    WHERE fl.is_color_field = 1');
  FQry.Open;
  Field := FQry.FieldByName('FIELD_NAME').AsString;

  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add(
  'SELECT fc.fval,fc.brush_color,fc.font_color' + #13#10 +
  '    FROM tb_fcolor_registry fc' + #13#10 +
  '         INNER JOIN tb_field_registry fl ON fl.id = fc.field_id AND fl.is_color_field = 1' + #13#10 +
  '         INNER JOIN tb_query_registry q ON q.id = fl.query_id AND UPPER(q.query_name) = UPPER(''' + uppercase(QueryName) + ''')' + #13#10 +
  '         INNER JOIN tb_form_registry f ON f.id = q.form_id AND UPPER(f.form_name) = UPPER(''' + uppercase(FormName) + ''')');
  RQry.Open;

  while not RQry.Eof do begin
    Values[RQry.RecNo - 1] := RQry.FieldByName('FVAL').AsString;
    BrushColors[RQry.RecNo - 1] := StrToColor(RQry.FieldByName('BRUSH_COLOR').AsString);
    FontColors[RQry.RecNo - 1] := StrToColor(RQry.FieldByName('FONT_COLOR').AsString);
    RQry.next;
  end;
  FQry.Free;
  RQry.Free;
end;

procedure BuildQueries(Form :TForm; QList :TStringList);
var RQry,vQry :TOraQuery;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT q.id,q.query_name,q.is_lookup,f.form_name FROM tb_form_registry f INNER JOIN tb_query_registry q ON q.form_id = f.id WHERE UPPER(f.form_name) = ''' + UPPERCASE(Form.Name) + ''' AND is_report = 0 ORDER BY q.ord');
  RQry.Open;

  while not RQry.Eof do begin
    try
      vQry := CreateQuery(Form,RQry.FieldByName('QUERY_NAME').AsString);
      if RQry.FieldByName('IS_LOOKUP').AsInteger = 0 then QList.Add(vQry.Name);
    except
      MessageDlg('Ошибка при создании набора данных: Query.ID = ' + RQry.FieldByName('ID').AsString + ' | Query.Name = ' + RQry.FieldByName('QUERY_NAME').AsString + ' | Form.Name = ' + RQry.FieldByName('FORM_NAME').AsString,mtError,[mbOk],0);
    end;
    RQry.Next;
  end;
  RQry.Free;
end;

function CreateQuery(Form :TForm; QueryName :string) :TOraQuery;
var RQry,PQry,FQry,Qry :TOraQuery;
    FieldType :TFieldType;
    DS :TOraDataSource;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT q.id,q.query_name,q.query_sql,q.key_field,q.key_sequence,q.master_query_name,q.master_key_field,q.detail_key_field,q.is_lookup FROM tb_form_registry f LEFT JOIN tb_query_registry q ON q.form_id = f.id WHERE UPPER(f.form_name) = ''' + UPPERCASE(Form.Name) + ''' AND UPPER(q.query_name) = ''' + UPPERCASE(QueryName) + ''' ORDER BY q.ord');
  RQry.Open;

  FQry := TOraQuery.Create(Application);
  FQry.SQL.Add('SELECT ord,field_name,field_type' + #13#10 +
  '      ,VISIBLE,display_label,display_width,field_size,lookup_query,lookup_key,lookup_id,lookup_result' + #13#10 +
  '  FROM (' + #13#10 +
  '    SELECT f.ord,f.field_name,f.field_type,o.opt_name,o.opt_val,f.lookup_query,f.lookup_key,f.lookup_id,f.lookup_result' + #13#10 +
  '      FROM tb_field_registry f' + #13#10 +
  '           LEFT JOIN tb_foption_registry o' + #13#10 +
  '             ON o.field_id = f.id' + #13#10 +
  '    WHERE opt_name IN (''DISPLAY_LABEL'',''DISPLAY_WIDTH'',''VISIBLE'',''SIZE'')' + #13#10 +
  '      AND f.query_id = ' + RQry.FieldByName('ID').AsString {+ ' AND f.lookup_query IS NULL'} + #13#10 +
  '  ) PIVOT (MAX(opt_val) FOR opt_name IN (''DISPLAY_LABEL'' AS display_label,''DISPLAY_WIDTH'' AS display_width,''VISIBLE'' AS VISIBLE,''SIZE'' AS field_size))' + #13#10 +
  'ORDER BY ord');
  FQry.Open;

  PQry := TOraQuery.Create(Application);
  PQry.SQL.Add('SELECT id,query_id,pname,pval,ord,ptype FROM tb_qparam_registry WHERE query_id = ' + RQry.FieldByName('ID').AsString);
  PQry.Open;

  FieldType := ftUnknown;
  Qry := TOraQuery.Create(Form);
  with Qry do begin
    Name  := RQry.FieldByName('QUERY_NAME').AsString;
    while not FQry.Eof do begin
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftFloat' then FieldType := ftFloat;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftInteger' then FieldType := ftInteger;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftString' then FieldType := ftString;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftDateTime' then FieldType := ftDateTime;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftDate' then FieldType := ftDate;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftBoolean' then FieldType := ftBoolean;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftOraClob' then FieldType := ftOraClob;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftOraBlob' then FieldType := ftOraBlob;

      FieldDefs.Add(FQry.FieldByName('FIELD_NAME').AsString,FieldType);
      with FieldDefs.Items[FQry.FieldByName('ORD').AsInteger].CreateField(Qry) do begin
        if FQry.FieldByName('VISIBLE').AsInteger = 0 then Visible := false;
        if not FQry.FieldByName('DISPLAY_LABEL').IsNull then DisplayLabel := FQry.FieldByName('DISPLAY_LABEL').AsString;
        if not FQry.FieldByName('DISPLAY_WIDTH').IsNull then DisplayWidth := FQry.FieldByName('DISPLAY_WIDTH').AsInteger;
        if not FQry.FieldByName('FIELD_SIZE').IsNull then Size := FQry.FieldByName('FIELD_SIZE').AsInteger;
        if not FQry.FieldByName('LOOKUP_QUERY').IsNull then begin
          FieldKind := fkLookup;
          KeyFields := FQry.FieldByName('LOOKUP_KEY').AsString;
          LookupDataSet := TOraQuery(Form.FindComponent(FQry.FieldByName('LOOKUP_QUERY').AsString));
          LookupKeyFields := FQry.FieldByName('LOOKUP_ID').AsString;
          LookupResultField := FQry.FieldByName('LOOKUP_RESULT').AsString;
        end;
      end;
      FQry.next;
    end;

    SQL.Add(RQry.FieldByName('QUERY_SQL').AsString);
    KeyFields := RQry.FieldByName('KEY_FIELD').AsString;
    if not RQry.FieldByName('KEY_SEQUENCE').IsNull then KeySequence := RQry.FieldByName('KEY_SEQUENCE').AsString;

    FieldType := ftUnknown;
    if PQry.RecordCount > 0 then begin
      while not PQry.Eof do begin
        if PQry.FieldByName('PTYPE').AsString = 'ftInteger' then FieldType := ftInteger;
        if PQry.FieldByName('PTYPE').AsString = 'ftFloat' then FieldType := ftFloat;
        if PQry.FieldByName('PTYPE').AsString = 'ftString' then FieldType := ftString;
        if PQry.FieldByName('PTYPE').AsString = 'ftDateTime' then FieldType := ftDateTime;
        if PQry.FieldByName('PTYPE').AsString = 'ftDate' then FieldType := ftDate;
        if PQry.FieldByName('PTYPE').AsString = 'ftBoolean' then FieldType := ftBoolean;
        if PQry.FieldByName('PTYPE').AsString = 'ftOraClob' then FieldType := ftOraClob;
        if PQry.FieldByName('PTYPE').AsString = 'ftOraBlob' then FieldType := ftOraClob;

        Qry.ParamByName(PQry.FieldByName('PNAME').AsString).ParamType := ptInput;
        Qry.ParamByName(PQry.FieldByName('PNAME').AsString).DataType := FieldType;
        Qry.ParamByName(PQry.FieldByName('PNAME').AsString).Value := PQry.FieldByName('PVAL').AsVariant;

        PQry.Next;
      end;
    end;
    DS := CreateDataSource(Qry);
    if not RQry.FieldByName('MASTER_QUERY_NAME').IsNull then
      MasterSource := TOraDataSource(Form.FindComponent(RQry.FieldByName('MASTER_QUERY_NAME').AsString+'DS'));
  end;

  PQry.Free;
  FQry.Free;
  RQry.Free;

  result := Qry;
end;

function CreateQueryByID(Form :TForm; QueryID :string) :TOraQuery;
var RQry,PQry,FQry,Qry :TOraQuery;
    FieldType :TFieldType;
    DS :TOraDataSource;
begin
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT q.id,q.query_name,q.query_sql,q.key_field,q.key_sequence,q.master_query_name,q.master_key_field,q.detail_key_field,q.is_lookup FROM tb_query_registry q WHERE q.id = ' + QueryID);
  RQry.Open;

  FQry := TOraQuery.Create(Application);
  FQry.SQL.Add('SELECT ord,field_name,field_type' + #13#10 +
  '      ,VISIBLE,display_label,display_width,field_size,lookup_query,lookup_key,lookup_id,lookup_result' + #13#10 +
  '  FROM (' + #13#10 +
  '    SELECT f.ord,f.field_name,f.field_type,o.opt_name,o.opt_val,f.lookup_query,f.lookup_key,f.lookup_id,f.lookup_result' + #13#10 +
  '      FROM tb_field_registry f' + #13#10 +
  '           LEFT JOIN tb_foption_registry o' + #13#10 +
  '             ON o.field_id = f.id' + #13#10 +
  '    WHERE opt_name IN (''DISPLAY_LABEL'',''DISPLAY_WIDTH'',''VISIBLE'',''SIZE'')' + #13#10 +
  '      AND f.query_id = ' + RQry.FieldByName('ID').AsString {+ ' AND f.lookup_query IS NULL'} + #13#10 +
  '  ) PIVOT (MAX(opt_val) FOR opt_name IN (''DISPLAY_LABEL'' AS display_label,''DISPLAY_WIDTH'' AS display_width,''VISIBLE'' AS VISIBLE,''SIZE'' AS field_size))' + #13#10 +
  'ORDER BY ord');
  FQry.Open;

  PQry := TOraQuery.Create(Application);
  PQry.SQL.Add('SELECT id,query_id,pname,pval,ord,ptype FROM tb_qparam_registry WHERE query_id = ' + QueryID);
  PQry.Open;

  FieldType := ftUnknown;
  Qry := TOraQuery.Create(Form);
  with Qry do begin
    Name  := RQry.FieldByName('QUERY_NAME').AsString;
    while not FQry.Eof do begin
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftFloat' then FieldType := ftFloat;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftInteger' then FieldType := ftInteger;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftString' then FieldType := ftString;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftDateTime' then FieldType := ftDateTime;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftDate' then FieldType := ftDate;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftBoolean' then FieldType := ftBoolean;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftOraClob' then FieldType := ftOraClob;
      if FQry.FieldByName('FIELD_TYPE').AsString = 'ftOraBlob' then FieldType := ftOraBlob;

      FieldDefs.Add(FQry.FieldByName('FIELD_NAME').AsString,FieldType);
      with FieldDefs.Items[FQry.FieldByName('ORD').AsInteger].CreateField(Qry) do begin
        if FQry.FieldByName('VISIBLE').AsInteger = 0 then Visible := false;
        if not FQry.FieldByName('DISPLAY_LABEL').IsNull then DisplayLabel := FQry.FieldByName('DISPLAY_LABEL').AsString;
        if not FQry.FieldByName('DISPLAY_WIDTH').IsNull then DisplayWidth := FQry.FieldByName('DISPLAY_WIDTH').AsInteger;
        if not FQry.FieldByName('FIELD_SIZE').IsNull then Size := FQry.FieldByName('FIELD_SIZE').AsInteger;
        if not FQry.FieldByName('LOOKUP_QUERY').IsNull then begin
          FieldKind := fkLookup;
          KeyFields := FQry.FieldByName('LOOKUP_KEY').AsString;
          LookupDataSet := TOraQuery(Form.FindComponent(FQry.FieldByName('LOOKUP_QUERY').AsString));
          LookupKeyFields := FQry.FieldByName('LOOKUP_ID').AsString;
          LookupResultField := FQry.FieldByName('LOOKUP_RESULT').AsString;
        end;
      end;
      FQry.next;
    end;
    
    SQL.Add(RQry.FieldByName('QUERY_SQL').AsString);
    KeyFields := RQry.FieldByName('KEY_FIELD').AsString;
    if not RQry.FieldByName('KEY_SEQUENCE').IsNull then KeySequence := RQry.FieldByName('KEY_SEQUENCE').AsString;

    FieldType := ftUnknown;
    if PQry.RecordCount > 0 then begin
      while not PQry.Eof do begin
        if PQry.FieldByName('PTYPE').AsString = 'ftInteger' then FieldType := ftInteger;
        if PQry.FieldByName('PTYPE').AsString = 'ftFloat' then FieldType := ftFloat;
        if PQry.FieldByName('PTYPE').AsString = 'ftString' then FieldType := ftString;
        if PQry.FieldByName('PTYPE').AsString = 'ftDateTime' then FieldType := ftDateTime;
        if PQry.FieldByName('PTYPE').AsString = 'ftDate' then FieldType := ftDate;
        if PQry.FieldByName('PTYPE').AsString = 'ftBoolean' then FieldType := ftBoolean;
        if PQry.FieldByName('PTYPE').AsString = 'ftOraClob' then FieldType := ftOraClob;
        if PQry.FieldByName('PTYPE').AsString = 'ftOraBlob' then FieldType := ftOraBlob;

        Qry.ParamByName(PQry.FieldByName('PNAME').AsString).ParamType := ptInput;
        Qry.ParamByName(PQry.FieldByName('PNAME').AsString).DataType := FieldType;
        Qry.ParamByName(PQry.FieldByName('PNAME').AsString).Value := PQry.FieldByName('PVAL').AsVariant;

        PQry.Next;
      end;
    end;
    DS := CreateDataSource(Qry);
    if not RQry.FieldByName('MASTER_QUERY_NAME').IsNull then
      MasterSource := TOraDataSource(Form.FindComponent(RQry.FieldByName('MASTER_QUERY_NAME').AsString+'DS'));
  end;

  PQry.Free;
  FQry.Free;
  RQry.Free;

  result := Qry;
end;

function FindComp(StartComp :TComponent; CompName :string; out Finded :boolean) :TComponent;
var i :integer;
    Comp :TComponent;
begin
  if StartComp.Name = CompName then begin Comp := StartComp; Finded := true; end else
  if not Finded then
    for i := 0 to StartComp.ComponentCount - 1 do
    Comp := FindComp(StartComp.Components[i],CompName,Finded);
  result := Comp;
end;

procedure BuildPopupMenu(PopupMenu :TPopupMenu; Query :TOraQuery);
var RQry :TOraQuery;
    Mnu :TActionMenuItem;
    PFnd,Fnd :boolean;
    Btn :TToolButton;
begin
  PFnd := false;
  Fnd := false;
  RQry := TOraQuery.Create(Application);
  RQry.SQL.Add('SELECT qa.id,qa.act_name,qa.act_descr,qa.visible,qa.button_name,qa.btn_cont_name' + #13#10 +
               '  FROM tb_form_registry f' + #13#10 +
               '       INNER JOIN tb_query_registry q ON q.form_id = f.id AND UPPER(q.query_name) = ''' + uppercase(Query.Name) + '''' + #13#10 +
               '       INNER JOIN tb_qaction_registry qa ON qa.query_id = q.id' + #13#10 +
               '  WHERE UPPER(f.form_name) = ''' + uppercase(Query.Owner.Name) + '''' + #13#10 +
               'ORDER BY qa.ord');
  RQry.Open;

  if RQry.RecordCount > 0 then
    while not RQry.Eof do begin
      Mnu := TActionMenuItem.Create(PopupMenu);
      Mnu.Name := RQry.FieldByName('ACT_NAME').AsString + 'MNU';
      Mnu.Caption := RQry.FieldByName('ACT_DESCR').AsString;
      Mnu.SetActId(RQry.FieldByName('ID').AsInteger);
      if RQry.FieldByName('VISIBLE').AsInteger = 0 then Mnu.Visible := false;
      PopupMenu.Items.Add(Mnu);
      if not RQry.FieldByName('BUTTON_NAME').IsNull and not RQry.FieldByName('BTN_CONT_NAME').IsNull then begin
        Btn := TToolButton(FindComp(FindComp(Query.Owner,RQry.FieldByName('BTN_CONT_NAME').AsString,PFnd),RQry.FieldByName('BUTTON_NAME').AsString,Fnd));
        Btn.Tag := RQry.FieldByName('ID').AsInteger;
        Mnu.SetButton(Btn);
      end;
      RQry.Next;
    end;
  RQry.Free;
end;

function CreateDataSource(Query :TOraQuery) :TOraDataSource;
var DS :TOraDataSource;
begin
  DS := TOraDataSource.Create(TForm(Query.Owner));
  DS.Name := Query.Name + 'DS';
  DS.DataSet := Query;
  result := DS;
end;

function GetDialogType(DialogType :string) :TMsgDlgType;
var DlgType :TMsgDlgType;
begin
  DlgType := mtCustom;
  if DialogType = 'mtConfirmation' then DlgType := mtConfirmation;
  if DialogType = 'mtInformation' then DlgType := mtInformation;
  if DialogType = 'mtError' then DlgType := mtError;
  if DialogType = 'mtWarning' then DlgType := mtWarning;
  result := DlgType;
end;

function GetDialogButtons(Buttons :string) :TMsgDlgButtons;
var Btn :TMsgDlgButtons;
begin
  Btn := [mbOk];
  if Buttons = 'mbOkCancel' then Btn := [mbOK,mbCancel];
  if Buttons = 'mbYesNo' then Btn := [mbYes,mbNo];
  if Buttons = 'mbYesNoCancel' then Btn := [mbYes,mbNo,mbCancel];
  result := Btn;
end;

function GetQueryByAction(Form :TForm; ActionID :integer) :TOraQuery;
var AQry,Qry :TOraQuery;
begin
  Qry := nil;
  if ActionID <> null then begin
    AQry := TOraQuery.Create(Application);
    AQry.SQL.Add('SELECT q.query_name' + #13#10 +
                 '  FROM tb_qaction_registry qa INNER JOIN tb_query_registry q ON q.id = qa.query_id ' + #13#10 +
                 '  WHERE qa.id = ' + inttostr(ActionId));
    AQry.Open;
    Qry := TOraQuery(Form.FindComponent(AQry.FieldByNAme('QUERY_NAME').AsString));
    AQry.Free;
  end;
  result := Qry;
end;

function GetParamManualInput(ActionID :integer; ParamName :string) :boolean;
var PQry :TOraQuery;
begin
  PQry := TOraQuery.Create(Application);
  PQry.SQL.Add('SELECT manual_input FROM tb_aparam_registry WHERE action_id = ' + inttostr(ActionID) + ' AND UPPER(pname) = ''' + uppercase(ParamName) + '''');
  PQry.Open;
  result := PQry.FieldByName('MANUAL_INPUT').AsInteger = 1;
  PQry.Free;
end;

procedure RefreshDetailQueries(StartQuery :TOraQuery);
var i :integer;
begin
  for i := 0 to StartQuery.Owner.ComponentCount - 1 do
    if (StartQuery.Owner.Components[i].ClassName = 'TOraQuery') and
       Assigned(TOraQuery(StartQuery.Owner.Components[i]).MasterSource)
      then
      if TOraQuery(StartQuery.Owner.Components[i]).MasterSource.DataSet.Name = StartQuery.Name then
        TOraQuery(StartQuery.Owner.Components[i]).Refresh;
end;

procedure RunAction(Query :TOraQuery; ActionID :integer);
var BefMesTxt,BefMesBtn,BefMesType,AftMesTxt,AftMesBtn,AftMesType,ActName,ActSQL,OutParamName,ManualValue :string;
    YesActId,NoActId,FinalRefresh,i :integer;
    AQry,PQry :TOraQuery;
    vSQL :TOraSQL;
    MR :TModalResult;
    odFile :TOpenDialog;
begin
  if ActionID = -1000000000 then exit;
  AQry := TOraQuery.Create(Application);
  AQry.SQL.Add('SELECT act_name,act_plsql,before_mes_txt,before_mes_btn,before_mes_type,after_mes_txt,after_mes_btn,after_mes_type,yes_act_id,no_act_id,need_refresh' + #13#10 +
               '  FROM tb_qaction_registry  WHERE id = ' + inttostr(ActionId));
  AQry.Open;
  ActName := AQry.FieldByName('ACT_NAME').AsString;
  ActSQL := AQry.FieldByName('ACT_PLSQL').AsString;
  BefMesTxt := AQry.FieldByName('BEFORE_MES_TXT').AsString;
  BefMesBtn := AQry.FieldByName('BEFORE_MES_BTN').AsString;
  BefMesType := AQry.FieldByName('BEFORE_MES_TYPE').AsString;
  AftMesTxt := AQry.FieldByName('AFTER_MES_TXT').AsString;
  AftMesBtn := AQry.FieldByName('AFTER_MES_BTN').AsString;
  AftMesType := AQry.FieldByName('AFTER_MES_TYPE').AsString;
  If not AQry.FieldByName('YES_ACT_ID').IsNull then YesActId := AQry.FieldByName('YES_ACT_ID').AsInteger else YesActId := -1000000000;
  If not AQry.FieldByName('NO_ACT_ID').IsNull then NoActId := AQry.FieldByName('NO_ACT_ID').AsInteger else NoActId := -1000000000;
  FinalRefresh := AQry.FieldByName('NEED_REFRESH').AsInteger;
  if PosEx(':',AftMesTxt) = 1 then OutParamName := Copy(AftMesTxt,2,length(AftMesTxt) - 1);
  AQry.Free;

  MR := mrOk;
  if length(BefMesType) > 0 then MR := MessageDlg(BefMesTxt,GetDialogType(BefMesType),GetDialogButtons(BefMesBtn),0);
  if MR = mrCancel then exit;

  if MR in [mrOk,mrYes] then begin
    vSQL := TOraSQL.Create(Query.Owner);
    vSQL.Name := ActName;
    vSQL.SQL.Add(ActSQL);

    PQry := TOraQuery.Create(Application);
    PQry.SQL.Add('SELECT pname,pval,ptype,pdatatype,NVL(pdescr,pname) AS pdescr FROM tb_aparam_registry WHERE action_id = ' + inttostr(ActionID));
    PQry.Open;

    while not PQry.Eof do begin
      with vSQL do begin
        if PQry.FieldByName('PTYPE').AsString = 'ptInput' then ParamByName(PQry.FieldByName('PNAME').AsString).ParamType := ptInput
           else ParamByName(PQry.FieldByName('PNAME').AsString).ParamType := ptOutput;

        if PQry.FieldByName('PDATATYPE').AsString = 'ftInteger' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftInteger;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftFloat' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftFloat;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftString' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftString;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftDateTime' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftDateTime;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftDate' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftDate;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftBoolean' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftBoolean;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftOraClob' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftOraClob;
        if PQry.FieldByName('PDATATYPE').AsString = 'ftOraBlob' then ParamByName(PQry.FieldByName('PNAME').AsString).DataType := ftOraBlob;

        if PQry.FieldByName('PTYPE').AsString = 'ptInput' then
           if not(ParamByName(PQry.FieldByName('PNAME').AsString).DataType = ftOraBlob) then ParamByName(PQry.FieldByName('PNAME').AsString).Value := PQry.FieldByName('PVAL').AsVariant;
      end;
      PQry.Next;
    end;
    PQry.Free;

    try
      with vSQL do begin
        for i := 0 to ParamCount - 1 do
          if Params[i].ParamType = ptInput then
            if not GetParamManualInput(ActionID,Params[i].Name) then
              Params[i].Value := Query.FieldByName(Params[i].Name).AsVariant
              else if Params[i].DataType = ftOraBlob then begin
                     odFile := TOpenDialog.Create(Query.Owner);
                     if odFile.Execute then
                       try
                         Params[i].LoadFromFile(odFile.FileName,ftOraBlob);
                       finally
                         odFile.Free;
                       end
                   end else begin
                         ManualValue := Params[i].AsString;
                         if InputQuery('Параметр "' + Params[i].Name + '":','Введите значение:',ManualValue) then
                           Params[i].Value := ManualValue;
                       end;
        try
          Execute;
          AftMesTxt := vSQL.ParamByName(OutParamName).AsString;
        except
          AftMesTxt := '';
        end;
      end;
    finally
      vSQL.Free;
    end;
    if FinalRefresh = 1 then begin Query.Refresh; RefreshDetailQueries(Query); end;
  end
  else AftMesTxt := '';

  if length(AftMesType) > 0 then
    if PosEx('ERROR',AftMesTxt) = 1 then
      MR := MessageDlg(AftMesTxt,mtError,[mbOk],0)
      else if length(AftMesTxt) > 0 then MR := MessageDlg(AftMesTxt,GetDialogType(AftMesType),GetDialogButtons(AftMesBtn),0);

  if MR = mrCancel then exit;

  if MR in [mrYes,mrOk] then RunAction(GetQueryByAction(TForm(Query.Owner),YesActId),YesActId)
    else RunAction(GetQueryByAction(TForm(Query.Owner),NoActId),NoActId);
end;

function CreateForm(Owner :TComponent; FormTypeName,FormName :string) :TForm;
var Frm :TForm;
begin
  Frm := nil;
  if FormTypeName = 'TfrmSignsNew' then Frm := TfrmSignsNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmBaseTreeEdtNew' then Frm := TfrmBaseTreeEdtNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmBasePCEdtNew' then Frm := TfrmBasePCEdtNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmBaseMasterDetailNew' then Frm := TfrmBaseMasterDetailNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmMTreeDetailNew' then Frm := TfrmMTreeDetailNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmMasterDTreeNew' then Frm := TfrmMasterDTreeNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmDoubleViewerNew' then Frm := TfrmDoubleViewerNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmSignCalc' then Frm := TfrmSignCalc.Create(Owner,FormName);
  if FormTypeName = 'TfrmStarExpand' then Frm := TfrmStarExpand.Create(Owner,FormName);
  if FormTypeName = 'TfrmDependencyNew' then Frm := TfrmDependencyNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmViewerNew' then Frm := TfrmViewerNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmReportsNew' then Frm := TfrmReportsNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmReportResultNew' then Frm := TfrmReportResultNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmMasterDetailCommentEditor' then Frm := TfrmMasterDetailCommentEditor.Create(Owner,FormName);
  if FormTypeName = 'TfrmChartNew' then Frm := TfrmChartNew.Create(Owner,FormName);
  if FormTypeName = 'TfrmPMasterDetailNew' then Frm := TfrmPMasterDetailNew.Create(Owner,FormName);

  result := Frm;
end;

procedure CheckVersion(Session :TOraSession; ExeName :string; out FindedNew :boolean; out FindedID :integer; out FindedVersion,Enhancements :string);
var AppVers,LastVers :string;
    Qry :TOraQuery;
begin
  try
    AppVers := FileVersion(ExtractFilePath(Application.ExeName) + ExeName);
  except
    AppVers := '1.0.0.0';
  end;
  Qry := TOraQuery.Create(Application);
  try
    Qry.Session := Session;
    Qry.SQL.Add('SELECT id,vers_num,enhancements' + #13#10 +
      '  FROM tb_version_registry' + #13#10 +
      '  WHERE id = (SELECT MAX(id) KEEP (dense_rank LAST ORDER BY to_number(REPLACE(vers_num,''.'',''''))) AS ID FROM tb_version_registry WHERE exename = ''' + ExeName + ''')');

    Qry.Open;
    LastVers := Qry.FieldByName('VERS_NUM').AsString;
    if strtoint(StringReplace(AppVers,'.','',[rfReplaceAll])) < strtoint(StringReplace(LastVers,'.','',[rfReplaceAll])) then begin
      FindedNew := true;
    end;
    FindedID :=  Qry.FieldByName('ID').AsInteger;
    FindedVersion := LastVers;
    Enhancements := Qry.FieldByName('ENHANCEMENTS').AsString;
  finally
    Qry.Free;
  end;
end;

procedure VersionProccessing(Session :TOraSession; VersionID :integer);
var Qry :TOraQuery;
begin
  Qry := TOraQuery.Create(Application);
  try
    Qry.Session := Session;
    Qry.SQL.Add('SELECT vers_num,vers_file,exename FROM tb_version_registry WHERE id = ' + IntToStr(VersionID));
    Qry.Open;
    TBlobField(Qry.FieldByName('VERS_FILE')).SaveToFile(ExtractFilePath(Application.ExeName) + Qry.FieldByName('EXENAME').AsString);
  finally
    Qry.Free;
  end;
end;

end.
