unit untBaseSelectForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseFrame, Ora, DB, StdCtrls;

type
  TfrmSelect = class(TForm)
    frSelect: TfrBase;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure frSelectdbGridDblClick(Sender: TObject);
  private
    { Private declarations }
    Mouse :TMouse;
    Screen :TScreen;
    vDataSource :TDataSource;
    vQry :TOraQuery;
  public
    { Public declarations }
    constructor Create(AOwner :TComponent; Qry :TOraQuery); overload;

  end;

var
  frmSelect: TfrmSelect;

implementation

uses untBaseRepParamsFrame;

{$R *.dfm}

constructor TfrmSelect.Create(AOwner :TComponent; Qry :TOraQuery);
begin
  inherited Create(AOwner);
  vQry := Qry;
  vDataSource := TDataSource.Create(self);
  vDataSource.DataSet := vQry;
  frSelect.SetDataSource(vDataSource);
  if Screen.Height - Mouse.CursorPos.Y < self.Height then
    self.Top := Mouse.CursorPos.Y - Self.Height else self.Top := Mouse.CursorPos.Y;
  if Mouse.CursorPos.X < self.Width then
    self.Left := Mouse.CursorPos.X else self.Left := Mouse.CursorPos.X - self.Width;
  frSelect.dbGrid.Columns[0].Width := 200;
  self.BorderStyle := bsToolWindow;
end;

procedure TfrmSelect.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmSelect.frSelectdbGridDblClick(Sender: TObject);
begin
  if TSelectEdt(Owner).DataType = 'ftString' then TSelectEdt(Owner).KeyVal := vQry.Fields[1].AsString;
  if TSelectEdt(Owner).DataType = 'ftFloat' then TSelectEdt(Owner).KeyVal := vQry.Fields[1].AsFloat;
  if TSelectEdt(Owner).DataType = 'ftDateTime' then TSelectEdt(Owner).KeyVal := vQry.Fields[1].AsDateTime;
  if TSelectEdt(Owner).DataType = 'ftBoolean' then TSelectEdt(Owner).KeyVal := vQry.Fields[1].AsInteger;
  TSelectEdt(Owner).Text := vQry.Fields[0].AsString;
  Close;
end;

end.
