unit untSignsNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBasePCEdtNew, untBasePCEFrame, DBAccess, Ora, DB, MemDS,
  Menus;

type
  TfrmSignsNew = class(TfrmBasePCEdtNew)
    qrySigns: TOraQuery;
    qrySignsSIGN_NAME: TStringField;
    qrySignsDataType: TStringField;
    qrySignsSIGN_DESCR: TStringField;
    qrySignsEntityName: TStringField;
    qrySignsID: TFloatField;
    qrySignsSP_CODE: TStringField;
    qrySignsSIGN_SQL: TMemoField;
    qrySignsHIST_FLG: TIntegerField;
    qrySignsENTITY_ID: TFloatField;
    qrySignsDATA_TYPE: TStringField;
    dsSigns: TOraDataSource;
    spGetId: TOraStoredProc;
    spDropSign: TOraStoredProc;
    qryDataType: TOraQuery;
    qryDataTypeID: TStringField;
    qryDataTypeNAME: TStringField;
    qryEntity: TOraQuery;
    sqlCheckOldPart: TOraSQL;
    sqlDelOldPart: TOraSQL;
    qrySignsMASS_SQL: TMemoField;
    qrySignsFINAL_PLSQL: TMemoField;
    qrySignsARCHIVE_FLG: TFloatField;
    qrySignsCONDITION: TMemoField;
    procedure frButtonsbtnDelClick(Sender: TObject);
    procedure qrySignsBeforePost(DataSet: TDataSet);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSignsNew: TfrmSignsNew;

implementation

{$R *.dfm}

procedure TfrmSignsNew.FormCreate(Sender: TObject);
begin
  vMDS := dsSigns;
  vMQry := TOraQuery(vMDS.DataSet);
  frMaster.SetCheckBoxFields(['ARCHIVE_FLG','HIST_FLG']);
  frMaster.SetDrawCells('ARCHIVE_FLG',[1],[clWindow],[clGrayText],1);
  inherited;
end;

procedure TfrmSignsNew.frButtonsbtnDelClick(Sender: TObject);
begin
  if MessageDlg('��� ���������� �������� ���������� ����� ����� �������!'#10#13'�� ������������� ������ ������� ����������?',mtConfirmation,mbYesNoCancel,0) = mrYes then
    with spDropSign do begin
      ParamByName('INSIGN').Value := qrySignsSIGN_NAME.AsString;
      Execute;
      showmessage(ParamByName('OUTRES').AsString);
      qrySigns.Refresh;
    end;
end;

procedure TfrmSignsNew.qrySignsBeforePost(DataSet: TDataSet);
begin
  if qrySignsHIST_FLG.OldValue <> qrySignsHIST_FLG.NewValue then
    with sqlCheckOldPart do begin
      ParamByName('INPARTNAME').Value := qrySignsSIGN_NAME.AsString;
      Execute;
    if ParamByName('OUTHAVEOLDPART').AsInteger = 1 then
      if MessageDlg('��� ��������� ������� ��������, �������� ���������� ����������� � ������ �������.'#10#13 +
                    '������� � ����������� � ���������� ������� ������ ���� ������!'#10#13 +
                    '������� �������?',mtWarning,[mbYes,mbNo],0) = mrYes
        then begin
          sqlDelOldPart.ParamByName('INPARTNAME').Value := qrySignsSIGN_NAME.AsString;
          sqlDelOldPart.Execute;
          MessageDlg('������� �������� "' + qrySignsSIGN_NAME.AsString + '" ������� ������ �� ������� "' +
                     sqlDelOldPart.ParamByName('OLDTABLE').AsString + '".' + #10#13 +
                     '������� �������� ��� ���������� "' + qrySignsSIGN_NAME.AsString + '" � ������� ' +
                     sqlDelOldPart.ParamByName('NEWTABLE').AsString + '" ' +
                     '����� ������ ��� ������ ������� �������',mtInformation,[mbOk],0);
        end
      else begin
        MessageDlg('������ ��������� ������� �������� ���������� "' + qrySignsSIGN_NAME.AsString + '".',mtInformation,[mbOk],0);
        qrySignsHIST_FLG.NewValue := qrySignsHIST_FLG.OldValue;
        abort;
      end;
  end;
end;

end.
