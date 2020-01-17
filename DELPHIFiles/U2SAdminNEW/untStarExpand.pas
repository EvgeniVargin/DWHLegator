unit untStarExpand;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, MemDS, DBAccess, Ora, untBaseSQLTreeFrame, ExtCtrls,
  StdCtrls, Buttons, ComCtrls;

type
  TfrmStarExpand = class(TForm)
    frTree: TfrBaseSQLTree;
    qryTree: TOraQuery;
    qryTreeGROUP_ID: TFloatField;
    qryTreePARENT_GROUP_ID: TFloatField;
    qryTreeGROUP_NAME: TStringField;
    Splitter1: TSplitter;
    panLeft: TPanel;
    Splitter2: TSplitter;
    panButton: TPanel;
    rgCalc: TRadioGroup;
    btnStarExpand: TBitBtn;
    dtpDate: TDateTimePicker;
    dtpBeg: TDateTimePicker;
    dtpEnd: TDateTimePicker;
    chbCalcLater: TCheckBox;
    dtpDat: TDateTimePicker;
    dtpTim: TDateTimePicker;
    sqlExpand: TOraSQL;
    panDown: TPanel;
    chbCalcAnlt: TCheckBox;
    chbCalcSign: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rgCalcClick(Sender: TObject);
    procedure chbCalcLaterClick(Sender: TObject);
    procedure btnStarExpandClick(Sender: TObject);
    procedure frTreetvSQLTreeChange(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string); overload;
  end;

var
  frmStarExpand: TfrmStarExpand;

implementation

uses untU2SAdmin, untRegistry;

{$R *.dfm}

constructor TfrmStarExpand.Create(AOwner :TComponent; FormName :string);
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frTree.SetColumns([Attrs.Values['ID'],Attrs.Values['ParentID'],Attrs.Values['Name']]);

  frTree.SetQuery(qryTree);

  dtpDate.Date := Now - 1;
  dtpBeg.Date := Now - 1;
  dtpEnd.Date := Now - 1;
  dtpDat.DateTime := Now;
  dtpTim.DateTime := Now;
end;

procedure TfrmStarExpand.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmStarExpand.rgCalcClick(Sender: TObject);
begin
  with dtpDate do begin
    Enabled := rgCalc.ItemIndex = 0;
    if rgCalc.ItemIndex = 0 then Color := clWindow else Color := clBtnFace;
  end;
  with dtpBeg do begin
    Enabled := rgCalc.ItemIndex = 1;
    if rgCalc.ItemIndex = 1 then Color := clWindow else Color := clBtnFace;
  end;
  with dtpEnd do begin
    Enabled := rgCalc.ItemIndex = 1;
    if rgCalc.ItemIndex = 1 then Color := clWindow else Color := clBtnFace;
  end;
end;

procedure TfrmStarExpand.chbCalcLaterClick(Sender: TObject);
begin
  with dtpDat do begin
    Enabled := TCheckBox(Sender).Checked;
    if TCheckBox(Sender).Checked then Color := clWindow else Color := clBtnFace;
  end;
  with dtpTim do begin
    Enabled := TCheckBox(Sender).Checked;
    if TCheckBox(Sender).Checked then Color := clWindow else Color := clBtnFace;
  end;
end;

procedure TfrmStarExpand.btnStarExpandClick(Sender: TObject);
var m1,m2,StartTime :string;
begin
  if chbCalcSign.Checked then m1 := '1' else m1 := '0';
  if chbCalcAnlt.Checked then m2 := '1' else m2 := '0';
  if chbCalcLater.Checked then StartTime := DateToStr(dtpDat.Date) + ' ' + TimeToStr(dtpTim.Time)
    else  StartTime := DateTimeToStr(Now);
  //-------------------- За дату --------------------------
  if rgCalc.ItemIndex = 0 then
      if MessageDlg('Будет произведено обновление куба (звезды) за дату "' + datetostr(dtpDate.Date) + '".'#10#13'Продолжить?'
           ,mtInformation,[mbYes,mbNo],0) = mrYes then
        with sqlExpand do begin
          ParamByName('INBEGDATE').Value := datetostr(dtpDate.Date);
          ParamByName('INENDDATE').Value := datetostr(dtpDate.Date);
          ParamByName('INGROUPID').Value := frTree.GetNodeID(frTree.tvSQLTree.Selected);
          ParamByName('INMASK').Value := m1 + m2;
          ParamByName('INSTARTTIME').Value := StartTime;
          Execute;
          if MessageDlg('Запущено обновление куба (звезды).'#10#13'Перейти на форму просмотра логов?',mtConfirmation,[mbYes,mbNo],0) = mrYes
            then frmU2SAdmin.ShowForm('frmLogsNew');
        end;
  ////------------- Массово за период ------------------------
  if rgCalc.ItemIndex = 1 then
      if MessageDlg('Будет произведено обновление куба (звезды) за период "' + datetostr(dtpBeg.Date) + '" - "' + datetostr(dtpEnd.Date) + '".'#10#13'Продолжить?'
             ,mtInformation,[mbYes,mbNo],0) = mrYes then
        with sqlExpand do begin
          ParamByName('INBEGDATE').Value := datetostr(dtpBeg.Date);
          ParamByName('INENDDATE').Value := datetostr(dtpEnd.Date);
          ParamByName('INGROUPID').Value := frTree.GetNodeID(frTree.tvSQLTree.Selected);
          ParamByName('INMASK').Value := m1 + m2;
          ParamByName('INSTARTTIME').Value := StartTime;
          Execute;
          if MessageDlg('Запущено обновление куба (звезды).'#10#13'Перейти на форму просмотра логов?',mtConfirmation,[mbYes,mbNo],0) = mrYes
            then frmU2SAdmin.ShowForm('frmLogsNew');
        end;
end;

procedure TfrmStarExpand.frTreetvSQLTreeChange(Sender: TObject;
  Node: TTreeNode);
begin
  frTree.tvSQLTreeChange(Sender, Node);
  btnStarExpand.Enabled := frTree.tvSQLTree.Selected.Parent = nil;
end;

end.
