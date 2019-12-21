unit untSignCalc;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseFrame, ExtCtrls, DB, DBAccess, Ora, MemDS, ComCtrls,
  StdCtrls, Buttons, Menus, Mask, DBGridEh, untBaseSQLTreeFrame, DAScript,
  OraScript;

type
  TfrmSignCalc = class(TForm)
    panLeft: TPanel;
    Splitter1: TSplitter;
    panRight: TPanel;
    qryLeft: TOraQuery;
    dsLeft: TOraDataSource;
    panTop: TPanel;
    qryTop: TOraQuery;
    dsTop: TOraDataSource;
    qryTopGROUP_NAME: TStringField;
    qryTopSIGN_NAME: TStringField;
    frTop: TfrBase;
    qryTopCALCFLG: TFloatField;
    btnLoad: TBitBtn;
    dtpLoad: TDateTimePicker;
    sqlLoad: TOraSQL;
    panDownLeft: TPanel;
    dtpBeg: TDateTimePicker;
    dtpEnd: TDateTimePicker;
    chbCalcLater: TCheckBox;
    dtpDat: TDateTimePicker;
    dtpTim: TDateTimePicker;
    qryTopHIST_FLG: TIntegerField;
    labComment1: TLabel;
    qryLeftGROUP_ID: TFloatField;
    qryLeftPARENT_GROUP_ID: TFloatField;
    qryLeftGROUP_NAME: TStringField;
    frLeft: TfrBaseSQLTree;
    rgCalc: TRadioGroup;
    dtpLBeg: TDateTimePicker;
    dtpLEnd: TDateTimePicker;
    sqlGluing: TOraSQL;
    Splitter2: TSplitter;
    panDownRight: TPanel;
    Splitter3: TSplitter;
    panDown: TPanel;
    qryTopANLT_CODE: TStringField;
    qryLeftLEVEL: TFloatField;
    pmnuCalcAll: TPopupMenu;
    pmSignsByStar: TMenuItem;
    N3: TMenuItem;
    pmSignsByGroup: TMenuItem;
    pmAnltByGroup: TMenuItem;
    sqlCalcAll: TOraSQL;
    procedure btnLoadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chbCalcLaterClick(Sender: TObject);
    procedure frTopdbGridCellClick(Column: TColumnEh);
    procedure rgCalcClick(Sender: TObject);
    procedure pmnuCalcAllPopup(Sender: TObject);
    procedure pmSignsByStarClick(Sender: TObject);
    procedure pmSignsByGroupClick(Sender: TObject);
    procedure pmAnltByGroupClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string);
  end;

var
  frmSignCalc: TfrmSignCalc;

implementation

uses untU2SAdmin, untUtility, untRegistry;

{$R *.dfm}

constructor TfrmSignCalc.Create(AOwner :TComponent; FormName :string);
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);

  dtpLoad.Date := Now - 1;
  dtpBeg.Date := Now - 1;
  dtpEnd.Date := Now - 1;
  dtpLBeg.Date := Now - 1;
  dtpLEnd.Date := Now - 1;
  //
  dtpDat.DateTime := Now;
  dtpTim.DateTime := Now;

  frLeft.SetColumns(['GROUP_ID','PARENT_GROUP_ID','GROUP_NAME']);
  frLeft.SetQuery(qryLeft);

  frTop.SetDataSource(dsTop);
  qryTop.Open;
  frTop.SetColWidth;
  frTop.DrawCheckBoxes(['CALCFLG']);

end;

procedure TfrmSignCalc.btnLoadClick(Sender: TObject);
var vUnit,vBeg,vEnd,vParentID,vSQL,vSignName :string;
    vLocateName :array of string;
    vCou :integer;
begin
    setlength(vLocateName,2);
    vSignName := 'SELECT sign_name AS id FROM dm_skb.tb_signs_pool WHERE sign_name IN (';
    vParentID := '';
    vSQL := '';
    vCou := 0;

    case rgCalc.ItemIndex of
      0: begin
           vUnit := '''dm_skb.pkg_etl_signs.load_sign''';
           vBeg := datetostr(dtpLoad.Date);
           vEnd := datetostr(dtpLoad.Date);
         end;
      1: begin
           vUnit := '''dm_skb.pkg_etl_signs.load_sign''';
           vBeg := datetostr(dtpLBeg.Date);
           vEnd := datetostr(dtpLEnd.Date);
         end;
      2: begin
           vUnit := '''dm_skb.pkg_etl_signs.mass_load''';
           vBeg := datetostr(dtpBeg.Date);
           vEnd := datetostr(dtpEnd.Date);
         end;
      3: begin
           vUnit := '''dm_skb.pkg_etl_signs.sign_gluing''';
         end;
    end;

    with qryTop do begin
      vLocateName[0] := FieldByName('GROUP_NAME').AsString;
      vLocateName[1] := FieldByName('SIGN_NAME').AsString;
      DisableControls;
      first;
      while not(Eof) do begin
        if FieldByName('CALCFLG').AsInteger = 1 then begin
          vSignName := vSignName + '''' + FieldByName('SIGN_NAME').AsString + ''',';

          if vCou > 0 then vSQL := vSQL + 'UNION ALL' + char(10);
          if rgCalc.ItemIndex in [0,1,2] then begin
            vSQL := vSQL + 'SELECT ''' + FieldByName('SIGN_NAME').AsString + '|' + StringReplace(FieldByName('ANLT_CODE').AsString,'NULL','',[rfReplaceAll,rfIgnoreCase]) + ''' AS id,' + char(10) +
                    '''' + vParentID + ''' AS parent_id,' + char(10) +
                    vUnit + ' AS unit,' + char(10) +
                    '''' + vBeg + '#!#' + vEnd + '#!#' +
                    FieldByName('SIGN_NAME').AsString + '#!#' + StringReplace(FieldByName('ANLT_CODE').AsString,'NULL','',[rfReplaceAll,rfIgnoreCase]) + '#!#1'' AS params,0 AS skip' + char(10) +
                    '  FROM dual' + char(10);
            //if rgCalc.ItemIndex = 2 then vParentID := FieldByName('SIGN_NAME').AsString + '|' + StringReplace(FieldByName('ANLT_CODE').AsString,'NULL','',[rfReplaceAll,rfIgnoreCase]);
          end;

          if rgCalc.ItemIndex = 3 then //Склеивание
            vSQL := vSQL + 'SELECT ''' + FieldByName('SIGN_NAME').AsString + '|' + StringReplace(FieldByName('ANLT_CODE').AsString,'NULL','',[rfReplaceAll,rfIgnoreCase]) + ''' AS id,' + char(10) +
                    '''' + vParentID + ''' AS parent_id,' + char(10) +
                    vUnit + ' AS unit,' + char(10) +
                    '''' + FieldByName('SIGN_NAME').AsString + '#!#' + StringReplace(FieldByName('ANLT_CODE').AsString,'NULL','',[rfReplaceAll,rfIgnoreCase]) + '#!#'' AS params,0 AS skip' + char(10) +
                    '  FROM dual' + char(10);

          vCou := vCou + 1;
        end;
        next;
      end;
      Locate([FieldByName('GROUP_NAME'),FieldByName('SIGN_NAME')],vLocateName,[loCaseInsensitive]);
      EnableControls;
    end;
    vSignName := Copy(vSignName,1,length(vSignName) - 1) + ')';

    //Если расчитываются показатели, а не аналитики то необходимо учитывать зависимости
    if rgCalc.ItemIndex in [0,1,2] then
      if qryLeft.FieldByName('LEVEL').AsInteger <= 2 then
        vSQL := 'WITH' + char(10) +
        '  a AS (' + vSignName + ')' + char(10) +
        'SELECT a.id,b.prev_sign_name AS parent_id,' + char(10) +
        vUnit + ' AS unit,' + char(10) +
        '''' + vBeg + '#!#' + vEnd + '#!#''||a.id||''#!##!#1'' AS params,0 AS skip' + char(10) +
        ' FROM a LEFT JOIN dm_skb.tb_sign_2_sign b' + Char(10) +
        ' ON b.sign_name = a.id AND b.prev_sign_name IN (SELECT id FROM a)';


    if vCou = 0 then begin
      MessageDlg('Необходимо указать хотя бы один показатель для расчета',mtInformation,[mbOk],0);
      Exit;
    end;

  if MessageDlg('Будет произведен расчет ' + inttostr(vCou) + ' показателей. Продолжить?'
               ,mtInformation,[mbYes,mbNo],0) <> mrYes then exit;

  with sqlLoad do begin
    ParamByName('INSQL').Value := vSql;
    if chbCalcLater.Checked then ParamByName('INSTARTTIME').Value := DateToStr(dtpDat.Date) + ' ' + TimeToStr(dtpTim.Time)
      else  ParamByName('INSTARTTIME').Value := Now;
    Execute;
    //ShowMessage(vSQL);
    if MessageDlg('Запущен расчет показателей.'#10#13'Перейти на форму просмотра логов?',mtConfirmation,[mbYes,mbNo],0) = mrYes
      then frmU2SAdmin.ShowForm('frmLogsNew');
  end;
end;

procedure TfrmSignCalc.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmSignCalc.chbCalcLaterClick(Sender: TObject);
begin
  dtpDat.Enabled := TCheckBox(Sender).Checked;
  dtpTim.Enabled := TCheckBox(Sender).Checked;
end;

procedure TfrmSignCalc.frTopdbGridCellClick(Column: TColumnEh);
begin
  frTop.dbGridCellClick(Column);
  btnLoad.Enabled := not((qryTop.FieldByName('HIST_FLG').AsInteger = 0) AND (rgCalc.ItemIndex = 3));
end;

procedure TfrmSignCalc.rgCalcClick(Sender: TObject);
begin
  with dtpLoad do begin
    Enabled := rgCalc.ItemIndex = 0;
    if rgCalc.ItemIndex = 0 then Color := clWindow else Color := clBtnFace;
  end;
  with dtpBeg do begin
    Enabled := rgCalc.ItemIndex = 2;
    if rgCalc.ItemIndex = 2 then Color := clWindow else Color := clBtnFace;
  end;
  with dtpEnd do begin
    Enabled := rgCalc.ItemIndex = 2;
    if rgCalc.ItemIndex = 2 then Color := clWindow else Color := clBtnFace;
  end;
  with dtpLBeg do begin
    Enabled := rgCalc.ItemIndex = 1;
    if rgCalc.ItemIndex = 1 then Color := clWindow else Color := clBtnFace;
  end;
  with dtpLEnd do begin
    Enabled := rgCalc.ItemIndex = 1;
    if rgCalc.ItemIndex = 1 then Color := clWindow else Color := clBtnFace;
  end;
  btnLoad.Enabled := not((qryTop.FieldByName('HIST_FLG').AsInteger = 0) AND (rgCalc.ItemIndex = 3));
end;

procedure TfrmSignCalc.pmnuCalcAllPopup(Sender: TObject);
begin
  pmSignsByStar.Enabled := (rgCalc.ItemIndex in [0,1]) and (qryLeftLEVEL.AsInteger = 1);
  pmSignsByGroup.Enabled := (rgCalc.ItemIndex in [0,1]) and (qryLeftLEVEL.AsInteger IN [1,2]);
  pmAnltByGroup.Enabled := (rgCalc.ItemIndex in [0,1]) and (qryLeftLEVEL.AsInteger = 3);
  with sqlCalcAll do begin
    case rgCalc.ItemIndex of
      0: begin
           ParamByName('INBEGDATE').Value := dtpLoad.Date;
           ParamByName('INENDDATE').Value := dtpLoad.Date;
         end;
      1: begin
           ParamByName('INBEGDATE').Value := dtpLBeg.Date;
           ParamByName('INENDDATE').Value := dtpLEnd.Date;
         end;
    end;
    ParamByName('INGROUPID').Value := qryLeftGROUP_ID.AsInteger;
  end;
end;

procedure TfrmSignCalc.pmSignsByStarClick(Sender: TObject);
begin
  with sqlCalcAll do begin
    ParamByName('INUNIT').Value := 'pkg_etl_signs.CalcSignsByStar';
    If MessageDlg('Выполнить расчет всех показателей, включая вложенные?'
        ,mtConfirmation,[mbYes,mbCancel],0) = mrYes then Execute else Exit;
  end;
  If MessageDlg('Запущен расчет всех показателей, включая вложенные.'#10#13'Перейти на форму просмотра логов?',mtConfirmation,[mbYes,mbNo],0) = mrYes
    then frmU2SAdmin.ShowForm('frmLogsNew');
end;

procedure TfrmSignCalc.pmSignsByGroupClick(Sender: TObject);
begin
  with sqlCalcAll do begin
    ParamByName('INUNIT').Value := 'pkg_etl_signs.CalcSignsByGroup';
    If MessageDlg('Выполнить расчет всех показателей по группе?'
        ,mtConfirmation,[mbYes,mbCancel],0) = mrYes then Execute else Exit;
  end;
  If MessageDlg('Запущен расчет всех показателей по группе.'#10#13'Перейти на форму просмотра логов?',mtConfirmation,[mbYes,mbNo],0) = mrYes
    then frmU2SAdmin.ShowForm('frmLogsNew');
end;

procedure TfrmSignCalc.pmAnltByGroupClick(Sender: TObject);
begin
  with sqlCalcAll do begin
    ParamByName('INUNIT').Value := 'pkg_etl_signs.CalcAnltByGroup';
    If MessageDlg('Выполнить расчет всех аналитик по группе?'
         ,mtConfirmation,[mbYes,mbCancel],0) = mrYes then Execute else Exit;
  end;
  If MessageDlg('Запущен расчет всех аналитик по группе.'#10#13'Перейти на форму просмотра логов?',mtConfirmation,[mbYes,mbNo],0) = mrYes
    then frmU2SAdmin.ShowForm('frmLogsNew');
end;

end.
