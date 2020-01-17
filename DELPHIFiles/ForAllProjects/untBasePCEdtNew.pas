unit untBasePCEdtNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBasePCEFrame, Ora, Menus, ComCtrls;

type
  TfrmBasePCEdtNew = class(TForm)
    frMaster: TfrPCEBase;
    pmnuMaster: TPopupMenu;
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  protected
    vMQry :TOraQuery;
    vMDs :TOraDataSource;
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string); overload;
    procedure SetDataSource(DataSource :TOraDataSource);
    //************************************************************
  end;

var
  frmBasePCEdtNew: TfrmBasePCEdtNew;

implementation

uses untRegistry;

{$R *.dfm}

constructor TfrmBasePCEdtNew.Create(AOwner :TComponent; FormName :string);
var vQL :TStringList;
    MCheckBoxes,MDrawColumns :Array of string;
    i,MAllDrawFieldCount,MAllVarCount :integer;
    MColorField :string;
    MValues,MBrushColors,MFontColors :array of variant;
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frMaster.SetAutoControls(strtobool(Attrs.Values['AutoControls']));

  //Если необходимо строить наборы и все что с ними связано
  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vMDs := TOraDataSource(self.FindComponent(vMQry.Name + 'DS'));//CreateDataSource(vMQry);

    vQL.Free;

    BuildPopupMenu(pmnuMaster,vMQry);

    if pmnuMaster.Items.Count > 0 then
      for i := 0 to pmnuMaster.Items.Count - 1 do begin
        pmnuMaster.Items[i].OnClick := MenuClick;
        if TActionMenuItem(pmnuMaster.Items[i]).GetButton <> nil then TActionMenuItem(pmnuMaster.Items[i]).GetButton.OnClick := MenuClick;
      end;
  end;

  if strtobool(Attrs.Values['BuildQueries']) then begin
    MAllDrawFieldCount := 0;
    GetDrawFieldCount(Self.Name,vMQry.Name,MAllDrawFieldCount);
    MAllVarCount := 0;
    GetDrawVarCount(Self.Name,vMQry.Name,MAllVarCount);

    setlength(MCheckBoxes,vMQry.FieldCount);
    setlength(MDrawColumns,MAllDrawFieldCount);
    setlength(MValues,MAllVarCount);
    setlength(MBrushColors,MAllVarCount);
    setlength(MFontColors,MAllVarCount);

    GetCheckBoxes(Self.Name,vMQry.Name,MCheckBoxes);
    GetDrawColumns(Self.Name,vMQry.Name,MDrawColumns);
    GetDrawCells(Self.Name,vMQry.Name,MColorField,MValues,MBrushColors,MFontColors);

    frMaster.SetCheckBoxFields(MCheckBoxes);
  end;

  frMaster.SetDataSource(vMDs);

  if strtobool(Attrs.Values['BuildQueries']) then begin
    frMaster.SetDrawColumns(MDrawColumns);
    frMaster.SetDrawCells(MColorField,MValues,MBrushColors,MFontColors,MAllVarCount);
  end;
end;

procedure TfrmBasePCEdtNew.SetDataSource(DataSource :TOraDataSource);
begin
  vMDs := DataSource;
  vMQry := TOraQuery(vMDS.DataSet);

  frMaster.SetDataSource(vMDs);
  frMaster.SetFrState(fstNone);
  frMaster.PageControl.ActivePageIndex := 0;
end;

procedure TfrmBasePCEdtNew.MenuClick(Sender :TObject);
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

procedure TfrmBasePCEdtNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
