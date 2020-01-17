unit untUploads;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, DBAccess, Ora, MemDS,
  ComCtrls, Menus, DBGridEh, OdacVcl, untBaseFrame;

type
  TfrmUploads = class(TForm)
    frResult: TfrBase;
    qryUploads: TOraQuery;
    dsUploads: TOraDataSource;
    panButtons: TPanel;
    Button1: TButton;
    pcUploads: TPageControl;
    tshSQL: TTabSheet;
    tshResult: TTabSheet;
    memSQL: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string); overload;
  end;

var
  frmUploads: TfrmUploads;

implementation

uses untRegistry;

{$R *.dfm}

constructor TfrmUploads.Create(AOwner :TComponent; FormName :string);
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
end;

procedure TfrmUploads.Button1Click(Sender: TObject);
var i :integer;
begin
  if qryUploads.Active then qryUploads.Close;
  qryUploads.SQL.Clear;
  qryUploads.SQL.AddStrings(memSQL.Lines);
  TButton(Sender).Cursor := crSQLWait;
  qryUploads.Open;
  TButton(Sender).Cursor := crDefault;
  with frResult.dbGrid.Columns do
    for i := 0 to Count - 1 do
      Items[i].Width := 120;
  pcUploads.ActivePageIndex := 1;
end;

procedure TfrmUploads.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
