unit untMasterDTreeNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBasePCSQLTreeFrame, ExtCtrls, untBasePCEFrame, Menus, Ora, DB, ComCtrls, DBGridEh;

type
  TfrmMasterDTreeNew = class(TForm)
    frMaster: TfrPCEBase;
    Splitter1: TSplitter;
    frDetail: TfrPCSQLTree;
    pmnuMaster: TPopupMenu;
    pmnuDetail: TPopupMenu;
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MasterDataChange(Sender: TObject; Field: TField);
  private
    { Private declarations }
    procedure DQryBeforePost(DataSet: TDataSet);
  protected
    vMQry,vDQry :TOraQuery;
    vMDs,vDDs :TOraDataSource;
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string);
  end;

var
  frmMasterDTreeNew: TfrmMasterDTreeNew;

implementation

uses untRegistry;

{$R *.dfm}

constructor TfrmMasterDTreeNew.Create(AOwner :TComponent; FormName :string);
var vQL :TStringList;
    MCheckBoxes,DCheckBoxes,MDrawColumns :Array of string;
    i,MAllDrawFieldCount,MAllVarCount :integer;
    MColorField :string;
    MValues,MBrushColors,MFontColors :array of variant;
begin
  inherited Create(AOwner);
  self.Name := FormName;

  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frMaster.SetAutoControls(strtobool(Attrs.Values['AutoControls']));
  frDetail.SetAutoControls(strtobool(Attrs.Values['AutoControls']));

  frDetail.frTree.SetColumns([Attrs.Values['ID'],Attrs.Values['ParentID'],Attrs.Values['Name']]);

  //Если необходимо строить наборы и все что с ними связано
  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vMDs := TOraDataSource(self.FindComponent(vMQry.Name + 'DS'));//CreateDataSource(vMQry);

    vDQry := TOraQuery(self.FindComponent(vQL.Strings[1]));
    vDDs := TOraDataSource(self.FindComponent(vDQry.Name + 'DS'));//CreateDataSource(vDQry);
    //vDQry.MasterSource := vMDs;
    vQL.Free;

    BuildPopupMenu(pmnuMaster,vMQry);
    BuildPopupMenu(pmnuDetail,vDQry);

    if pmnuMaster.Items.Count > 0 then
      for i := 0 to pmnuMaster.Items.Count - 1 do begin
        pmnuMaster.Items[i].OnClick := MenuClick;
        if TActionMenuItem(pmnuMaster.Items[i]).GetButton <> nil then TActionMenuItem(pmnuMaster.Items[i]).GetButton.OnClick := MenuClick;
      end;

    if pmnuDetail.Items.Count > 0 then
      for i := 0 to pmnuDetail.Items.Count - 1 do begin
        pmnuDetail.Items[i].OnClick := MenuClick;
        if TActionMenuItem(pmnuDetail.Items[i]).GetButton <> nil then TActionMenuItem(pmnuDetail.Items[i]).GetButton.OnClick := MenuClick;
      end;
  end;

  MAllDrawFieldCount := 0;
  GetDrawFieldCount(Self.Name,vMQry.Name,MAllDrawFieldCount);
  MAllVarCount := 0;
  GetDrawVarCount(Self.Name,vMQry.Name,MAllVarCount);

  setlength(MCheckBoxes,vMQry.FieldCount);
  setlength(MDrawColumns,MAllDrawFieldCount);
  setlength(MValues,MAllVarCount);
  setlength(MBrushColors,MAllVarCount);
  setlength(MFontColors,MAllVarCount);

  setlength(DCheckBoxes,vDQry.FieldCount);


  GetCheckBoxes(Self.Name,vMQry.Name,MCheckBoxes);
  GetDrawColumns(Self.Name,vMQry.Name,MDrawColumns);
  GetDrawCells(Self.Name,vMQry.Name,MColorField,MValues,MBrushColors,MFontColors);

  GetCheckBoxes(Self.Name,vDQry.Name,DCheckBoxes);

  frMaster.SetCheckBoxFields(MCheckBoxes);
  frDetail.SetCheckBoxFields(DCheckBoxes);

  frMaster.SetDataSource(vMDs);
  frMaster.SetDrawColumns(MDrawColumns);
  frMaster.SetDrawCells(MColorField,MValues,MBrushColors,MFontColors,MAllVarCount);

  frDetail.SetDataSource(vDDs);
  vDQry.BeforePost := DQryBeforePost;

  vMDs.OnDataChange := MasterDataChange;
end;

procedure TfrmMasterDTreeNew.DQryBeforePost(DataSet: TDataSet);
begin
  vDQry.FieldByName(GetDetailKeyField(self.Name,vDQry.Name)).Value := vMQry.FieldByName(GetMasterKeyField(self.Name,vDQry.Name)).AsVariant;
  if vDQry.State in [dsInsert] then
    vDQry.FieldByName(frDetail.frTree.GetParentID).Value := frDetail.frTree.GetNodeID(frDetail.frTree.tvSQLTree.Selected);
  if vDQry.State in [dsEdit] then
    if frDetail.frTree.tvSQLTree.Selected.Parent <> nil then
      vDQry.FieldByName(frDetail.frTree.GetParentID).Value := frDetail.frTree.GetNodeParentID(frDetail.frTree.tvSQLTree.Selected);
end;

procedure TfrmMasterDTreeNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMasterDTreeNew.MenuClick(Sender :TObject);
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

procedure TfrmMasterDTreeNew.MasterDataChange(Sender: TObject; Field: TField);
begin
  frDetail.frTree.BuildTree;
end;

end.
