unit untBaseMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, DBAccess, OdacVcl, DB, Ora, DAScript,
  OraScript, untBaseSQLTreeFrame, ComCtrls;

type
  TfrmBaseMainForm = class(TForm)
    panList: TPanel;
    Splitter1: TSplitter;
    panBody: TPanel;
    Session: TOraSession;
    frTree: TfrBaseSQLTree;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure frTreetvSQLTreeChange(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
    vBaseCaption :string;
    vChilds :array of TForm;
    procedure SetChildSize(Child :TForm);
  protected
    vActiveForm :TForm;
    procedure AddChild(i :integer; Child :TForm);
  public
    { Public declarations }
    function  GetChild(i :integer) :TForm;
    procedure ShowForm(FormName :string);
  end;

var
  frmBaseMainForm: TfrmBaseMainForm;

implementation

uses untRegistry, untUtility;

{$R *.dfm}

procedure TfrmBaseMainForm.AddChild(i :integer; Child :TForm);
begin
  if not Assigned(vChilds) then exit;
  if Child <> nil then begin
    vChilds[i] := Child;
    with TForm(vChilds[i]) do
      begin
        Parent := panBody;
        Align := alClient;
        BorderStyle := bsNone;
        Color := panBody.Color;
      end;
  end;    
end;

function  TfrmBaseMainForm.GetChild(i :integer) :TForm;
begin
  result := vChilds[i];
end;

procedure TfrmBaseMainForm.FormCreate(Sender: TObject);
begin
  vBaseCaption := Caption + ' (' + FileVersion(Application.ExeName) + ')';
  Caption := Caption + ' (' + FileVersion(Application.ExeName) + ')';
  setlength(vChilds,1024);
end;

procedure TfrmBaseMainForm.SetChildSize(Child :TForm);
begin
  with Child do
    begin
      Left := 0;
      Top := 0;
      Height := panBody.Height;
      Width := panBody.Width;
    end;
end;

procedure TfrmBaseMainForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
var i :integer;
begin
  for i := 0 to length(vChilds) - 1 do if vChilds[i] <> nil then vChilds[i].Close;
  with Session do if Connected then Disconnect;
  Action := caFree;
end;

procedure TfrmBaseMainForm.ShowForm(FormName :string);
var i :integer;
    vFinded :boolean;
begin
  vFinded := false;
  for i := 0 to length(vChilds) - 1 do begin
    if vFinded then break;
    if Assigned(vChilds[i]) and (vChilds[i].Name = FormName) then begin
      frTree.tvSQLTree.Items[i].Selected := true;
      vFinded := true;
    end;
  end;
end;

procedure TfrmBaseMainForm.frTreetvSQLTreeChange(Sender: TObject;
  Node: TTreeNode);
begin
  frTree.tvSQLTreeChange(Sender, Node);
  self.Caption := vBaseCaption + ' - ' + frTree.GetNodeName(Node);
  if Assigned(vActiveForm) then vActiveForm.Hide;

        if Assigned(vChilds[Node.AbsoluteIndex]) then begin
          vActiveForm := TForm(vChilds[Node.AbsoluteIndex]);
          SetChildSize(vActiveForm);
          vActiveForm.Repaint;
          vActiveForm.Show;
        end;
end;

end.
