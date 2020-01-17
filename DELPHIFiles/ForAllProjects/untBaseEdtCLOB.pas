unit untBaseEdtCLOB;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ExtCtrls, StdCtrls, DBCtrls, DBCtrlsEh, Buttons;

type
  TfrmBaseEdtCLOB = class(TForm)
    memCLOB: TDBMemo;
    panButtons: TPanel;
    Splitter1: TSplitter;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    tmrChange: TTimer;
    procedure tmrChangeTimer(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    vDataSource :TDataSource;
    vField :TField;
    vText :string;
  public
    { Public declarations }
    constructor Create(AOwner :TComponent; DataSource :TDataSource; Field :TField); overload;
  end;

var
  frmBaseEdtCLOB: TfrmBaseEdtCLOB;

implementation

{$R *.dfm}

constructor TfrmBaseEdtCLOB.Create(AOwner :TComponent; DataSource :TDataSource; Field :TField);
begin
  inherited Create(AOwner);
  vDataSource := DataSource;
  vField := Field;
  memCLOB.DataSource := vDataSource;
  memCLOB.DataField := vField.FieldName;
  vText := vField.AsString;
end;

procedure TfrmBaseEdtCLOB.tmrChangeTimer(Sender: TObject);
begin
  btnOk.Enabled := vField.DataSet.State in [dsInsert,dsEdit];
end;

procedure TfrmBaseEdtCLOB.btnCancelClick(Sender: TObject);
begin
  if vField.DataSet.State in [dsInsert,dsEdit] then vField.Value := vText;
  Close;
end;

procedure TfrmBaseEdtCLOB.btnOkClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmBaseEdtCLOB.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
