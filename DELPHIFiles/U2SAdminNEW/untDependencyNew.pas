unit untDependencyNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseSQLTreeFrame, untBasePCEFrame, ExtCtrls, untBaseFrame, Ora, DB, ComCtrls,
  Menus, DBGridEh;

type
  TfrmDependencyNew = class(TForm)
    frMaster: TfrBase;
    frDetail: TfrPCEBase;
    frTree: TfrBaseSQLTree;
    pmnuMaster: TPopupMenu;
    pmnuDetail: TPopupMenu;
    Splitter1: TSplitter;
    panClient: TPanel;
    Splitter2: TSplitter;
    pmnuTree: TPopupMenu;
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TreeAfterRefresh(DataSet :TDataSet);
    procedure DetailAfterPost(DataSet :TDataSet);
  private
    { Private declarations }
    vMQry,vDQry,vTQry :TOraQuery;
    vMDs,vDDs,vTDs :TOraDataSource;
    procedure DetailBeforePost(DataSet: TDataSet);
  public
    { Public declarations }
    Attrs :TStringList;
    { Public declarations }
    constructor Create(AOwner :TComponent; FormName :string);
  end;

var
  frmDependencyNew: TfrmDependencyNew;

implementation

uses untRegistry;

{$R *.dfm}

constructor TfrmDependencyNew.Create(AOwner :TComponent; FormName :string);
var vQL :TStringList;
    MCheckBoxes,MDrawColumns,DCheckBoxes,DDrawColumns :Array of string;
    i,MAllDrawFieldCount,DAllDrawFieldCount,MAllVarCount,DAllVarCount :integer;
    MColorField,DColorField :string;
    MValues,MBrushColors,MFontColors,DValues,DBrushColors,DFontColors :array of variant;
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frDetail.SetAutoControls(strtobool(Attrs.Values['AutoControls']));
  frTree.SetColumns([Attrs.Values['ID'],Attrs.Values['ParentID'],Attrs.Values['Name']]);

  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vMDs := TOraDataSource(self.FindComponent(vMQry.Name + 'DS'));//CreateDataSource(vMQry);
    vMQry.Open;

    vDQry := TOraQuery(self.FindComponent(vQL.Strings[1]));
    vDDs := TOraDataSource(self.FindComponent(vDQry.Name + 'DS'));//CreateDataSource(vDQry);
    //vDQry.MasterSource := vMDs;
    vDQry.BeforePost := DetailBeforePost;

    vTQry := TOraQuery(self.FindComponent(vQL.Strings[2]));
    vTDs := TOraDataSource(self.FindComponent(vTQry.Name + 'DS'));//CreateDataSource(vTQry);
    //vTQry.MasterSource := vMDs;

    vQL.Free;

    BuildPopupMenu(pmnuMaster,vMQry);
    BuildPopupMenu(pmnuDetail,vDQry);
    BuildPopupMenu(pmnuTree,vTQry);

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

    if pmnuTree.Items.Count > 0 then
      for i := 0 to pmnuTree.Items.Count - 1 do begin
        pmnuTree.Items[i].OnClick := MenuClick;
      end;
  end;

  MAllDrawFieldCount := 0;
  GetDrawFieldCount(Self.Name,vMQry.Name,MAllDrawFieldCount);
  MAllVarCount := 0;
  GetDrawVarCount(Self.Name,vMQry.Name,MAllVarCount);
  DAllDrawFieldCount := 0;
  GetDrawFieldCount(Self.Name,vDQry.Name,DAllDrawFieldCount);
  DAllVarCount := 0;
  GetDrawVarCount(Self.Name,vDQry.Name,DAllVarCount);

  setlength(MCheckBoxes,vMQry.FieldCount);
  setlength(MDrawColumns,MAllDrawFieldCount);
  setlength(MValues,MAllVarCount);
  setlength(MBrushColors,MAllVarCount);
  setlength(MFontColors,MAllVarCount);

  setlength(DCheckBoxes,vDQry.FieldCount);
  setlength(DDrawColumns,DAllDrawFieldCount);
  setlength(DValues,DAllVarCount);
  setlength(DBrushColors,DAllVarCount);
  setlength(DFontColors,DAllVarCount);

  GetCheckBoxes(Self.Name,vMQry.Name,MCheckBoxes);
  GetDrawColumns(Self.Name,vMQry.Name,MDrawColumns);
  GetDrawCells(Self.Name,vMQry.Name,MColorField,MValues,MBrushColors,MFontColors);

  GetCheckBoxes(Self.Name,vDQry.Name,DCheckBoxes);
  GetDrawColumns(Self.Name,vDQry.Name,DDrawColumns);
  GetDrawCells(Self.Name,vDQry.Name,DColorField,DValues,DBrushColors,DFontColors);

  frMaster.SetDataSource(vMDs);
  frMaster.SetColWidth;
  frMaster.DrawCheckBoxes(MCheckBoxes);
  frMaster.SetDrawColumns(MDrawColumns);
  frMaster.SetDrawCells(MColorField,MValues,MBrushColors,MFontColors,MAllVarCount);

  frDetail.SetCheckBoxFields(DCheckBoxes);
  frDetail.SetDataSource(vDDs);
  frDetail.SetDrawColumns(DDrawColumns);
  frDetail.SetDrawCells(DColorField,DValues,DBrushColors,DFontColors,DAllVarCount);

  frTree.SetQuery(vTQry);
  vTQry.AfterRefresh := TreeAfterRefresh;
  vDQry.AfterPost := DetailAfterPost;
  vDQry.AfterDelete := DetailAfterPost;
end;

procedure TfrmDependencyNew.DetailBeforePost(DataSet: TDataSet);
begin
 vDQry.FieldByName(GetDetailKeyField(self.Name,vDQry.Name)).Value := vMQry.FieldByName(GetMasterKeyField(self.Name,vDQry.Name)).AsVariant;
end;

procedure TfrmDependencyNew.MenuClick(Sender :TObject);
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


procedure TfrmDependencyNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmDependencyNew.TreeAfterRefresh(DataSet :TDataSet);
begin
  frTree.BuildTree;
end;

procedure TfrmDependencyNew.DetailAfterPost(DataSet :TDataSet);
begin
  vTQry.Refresh;
end;

end.
