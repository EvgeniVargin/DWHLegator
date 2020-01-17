unit untBaseLookupForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, Ora, untBaseFrame, StdCtrls, Buttons, ExtCtrls,
  DBAccess, MemDS;

type
  TfrmBaseLookupForm = class(TForm)
    panSelectDown: TPanel;
    bbOk: TBitBtn;
    bbCancel: TBitBtn;
    panSelectClient: TPanel;
    frSelect: TfrBase;
    DataSource: TOraDataSource;
    procedure bbOkClick(Sender: TObject);
    procedure bbCancelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    vQry :TOraQuery;
    vKeyField,vLookupKeyField,vLookupField :TField;
  public
    { Public declarations }
    procedure SetDrawColumns(ColorFields :array of string);
    procedure SetDrawCells(Field :string; Value,BrushColor,FontColor :Array of variant; AllVarCount :integer);
    procedure CallSelectForm(KeyField,LookupKeyField,LookupField :TField);
  end;

var
  frmBaseLookupForm: TfrmBaseLookupForm;

implementation

{$R *.dfm}

procedure TfrmBaseLookupForm.CallSelectForm(KeyField,LookupKeyField,LookupField :TField);
var KeyValue :variant;
begin
  vQry := TOraQuery(LookupKeyField.DataSet);
  DataSource.DataSet := TOraQuery(LookupKeyField.DataSet);
  KeyValue := KeyField.DataSet.FieldByName(KeyField.FieldName).AsVariant;
  if not(KeyValue = null) then vQry.Locate(LookupKeyField,KeyValue,[loPartialKey]);
  frSelect.SetDataSource(DataSource);
  vKeyField := KeyField;
  vLookupKeyField := LookupKeyField;
  vLookupField := LookupField;
end;

procedure TfrmBaseLookupForm.bbCancelClick(Sender: TObject);
begin
  self.Close;
end;

procedure TfrmBaseLookupForm.bbOkClick(Sender: TObject);
begin
  vKeyFIeld.Value := vLookupKeyField.AsVariant;
  self.Close;
end;

procedure TfrmBaseLookupForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  vQry.Filtered := false;
  Action := caFree;
end;

procedure TfrmBaseLookupForm.SetDrawColumns(ColorFields :array of string);
begin
  frSelect.SetDrawColumns(ColorFields);
end;

procedure TfrmBaseLookupForm.SetDrawCells(Field :string; Value,BrushColor,FontColor :Array of variant; AllVarCount :integer);
begin
  frSelect.SetDrawCells(Field,Value,BrushColor,FontColor,AllVarCount);
end;

end.
