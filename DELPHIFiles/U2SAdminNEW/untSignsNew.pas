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
  if MessageDlg('Все результаты расчетов показателя также будут удалены!'#10#13'Вы действительно хотите удалить показатель?',mtConfirmation,mbYesNoCancel,0) = mrYes then
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
      if MessageDlg('При изменении способа хранения, хранение показателя переносится в другую таблицу.'#10#13 +
                    'Сегмент с показателем в предыдущей таблице должен быть удален!'#10#13 +
                    'Удалить сегмент?',mtWarning,[mbYes,mbNo],0) = mrYes
        then begin
          sqlDelOldPart.ParamByName('INPARTNAME').Value := qrySignsSIGN_NAME.AsString;
          sqlDelOldPart.Execute;
          MessageDlg('Сегмент хранения "' + qrySignsSIGN_NAME.AsString + '" успешно удален из таблицы "' +
                     sqlDelOldPart.ParamByName('OLDTABLE').AsString + '".' + #10#13 +
                     'Сегмент хранения для показателя "' + qrySignsSIGN_NAME.AsString + '" в таблице ' +
                     sqlDelOldPart.ParamByName('NEWTABLE').AsString + '" ' +
                     'будет создан при первом запуске расчета',mtInformation,[mbOk],0);
        end
      else begin
        MessageDlg('Отмена изменения способа хранения показателя "' + qrySignsSIGN_NAME.AsString + '".',mtInformation,[mbOk],0);
        qrySignsHIST_FLG.NewValue := qrySignsHIST_FLG.OldValue;
        abort;
      end;
  end;
end;

end.
