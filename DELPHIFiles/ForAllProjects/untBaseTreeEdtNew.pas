unit untBaseTreeEdtNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBasePCSQLTreeFrame, Ora, DB, MemDS, DBAccess, ComCtrls,
  Menus;

type
  TfrmBaseTreeEdtNew = class(TForm)
    frMaster: TfrPCSQLTree;
    pmnuMaster: TPopupMenu;
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    //vAutoControls :boolean;
  protected
    vQry :TOraQuery;
    vDs :TOraDataSource;
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string);
  end;

var
  frmBaseTreeEdtNew: TfrmBaseTreeEdtNew;

implementation

uses untRegistry;


{$R *.dfm}

constructor TfrmBaseTreeEdtNew.Create(AOwner :TComponent; FormName :string);
var vQL :TStringList;
    vCheckBoxes :Array of string;
    i :integer;
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frMaster.frTree.SetColumns([Attrs.Values['ID'],Attrs.Values['ParentID'],Attrs.Values['Name']]);
  frMaster.SetAutoControls(strtobool(Attrs.Values['AutoControls']));

  //Если необходимо строить наборы и все что с ними связано
  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vDs := TOraDataSource(self.FindComponent(vQry.Name + 'DS'));//CreateDataSource(vQry);
    vQL.Free;

    BuildPopupMenu(pmnuMaster,vQry);

    if pmnuMaster.Items.Count > 0 then
      for i := 0 to pmnuMaster.Items.Count - 1 do begin
        pmnuMaster.Items[i].OnClick := MenuClick;
        if TActionMenuItem(pmnuMaster.Items[i]).GetButton <> nil then TActionMenuItem(pmnuMaster.Items[i]).GetButton.OnClick := MenuClick;
      end;
  end;

  setlength(vCheckBoxes,vQry.FieldCount);
  GetCheckBoxes(Self.Name,vQry.Name,vCheckBoxes);
  frMaster.SetCheckBoxFields(vCheckBoxes);
  frMaster.SetDataSource(vDs);



end;

procedure TfrmBaseTreeEdtNew.MenuClick(Sender :TObject);
var Qry :TOraQuery;
    ActID :integer;
begin
  if Sender.ClassName = 'TToolButton' then begin
    Qry := GetQueryByAction(self,TToolButton(sender).Tag);
    ActId := TToolButton(sender).Tag;
  end;
  if Sender.ClassName = 'TActionMenuItem' then begin
    Qry := GetQueryByAction(self,TActionMenuItem(sender).GetActId);
    ActId := TActionMenuItem(sender).GetActId;
  end;
  RunAction(Qry,ActId);
end;

procedure TfrmBaseTreeEdtNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
