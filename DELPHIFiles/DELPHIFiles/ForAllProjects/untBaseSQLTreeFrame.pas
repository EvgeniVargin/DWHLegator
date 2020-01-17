unit untBaseSQLTreeFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseButtonsFrame, Ora, ComCtrls, ImgList, DB, StdCtrls,
  Buttons, ExtCtrls;


type
  TRec = record
    ID,ParentID,Name :variant;
  end;

  TfrBaseSQLTree = class(TFrame)
    tvSQLTree: TTreeView;
    imglSQLTree: TImageList;
    procedure tvSQLTreeChange(Sender: TObject; Node: TTreeNode);
    procedure tvSQLTreeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    vQry :TOraQuery;
    vID,vParentID,vName :string;
    ARec :Array of TRec;
  public
    { Public declarations }
    procedure SetConnection(Connection :TOraSession);
    function  GetQuery :TOraQuery;
    procedure SetQuery(Query :TOraQuery);
    procedure SetColumns(Columns :Array of string);
    function  GetID :string;
    function  GetParentID :string;
    function  GetName :string;

    function  GetNodeID(Node :TTreeNode) :variant;
    function  GetNodeParentID(Node :TTreeNode) :variant;
    function  GetNodeName(Node :TTreeNode) :variant;

    procedure SetNodeID(Node :TTreeNode; ID :variant);
    procedure SetNodeParentID(Node :TTreeNode; ParentID :variant);
    procedure SetNodeNameID(Node :TTreeNode; Name :variant);

    procedure BuildTree;
    function  AddNode(ParentNode :TTreeNode) :TTreeNode;
    procedure SetNodePicture(inNode :TTreeNode);

    function SearchNodeByID(ID :variant) :TTreeNode;
    function SearchNodeByName(Name :variant) :TTreeNode;

  end;

implementation

{$R *.dfm}

procedure TfrBaseSQLTree.SetConnection(Connection :TOraSession);
begin
  if Assigned(vQry) then vQry.Session := Connection;
end;

procedure TfrBaseSQLTree.SetColumns(Columns :Array of string);
var i :integer;
begin
  for i := 0 to length(Columns) - 1 do
    case i of
      0 :vID := Columns[i];
      1 :vParentID := Columns[i];
      2 :vName := Columns[i];
    end;
end;

function  TfrBaseSQLTree.GetID :string;
begin
  result := vID;
end;

function  TfrBaseSQLTree.GetParentID :string;
begin
  result := vParentID;
end;

function  TfrBaseSQLTree.GetName :string;
begin
  result := vName;
end;

function TfrBaseSQLTree.GetQuery;
begin
  result := vQry;
end;

procedure  TfrBaseSQLTree.SetQuery(Query :TOraQuery);
begin
  vQry := Query;
  if not Assigned(vQry) then exit;
  vQry.FetchAll := true;
  if not vQry.Active then begin
    vQry.Open;
    BuildTree;
  end;
end;

procedure TfrBaseSQLTree.BuildTree;
var i :integer;
begin
  tvSQLTree.Items.Clear;
  vQry.First;
  setlength(ARec,vQry.RecordCount);
  while not(vQry.Eof) do begin
    try
      AddNode(SearchNodeByID(vQry.FieldByName(GetParentID).AsVariant))
    except
      ShowMessage('ÎØÈÁÊÀ:' + vQry.FieldByName(GetParentID).AsString);
    end;
    vQry.Next;
  end;

  for i:= 0 to tvSQLTree.Items.Count - 1 do begin
    SetNodePicture(tvSQLTree.Items[i]);
  end;
  vQry.First;
  if tvSQLTree.Items.Count > 0 then tvSQLTree.Selected := tvSQLTree.Items[0];
end;

function  TfrBaseSQLTree.AddNode(ParentNode :TTreeNode) :TTreeNode;
var ChildNode :TTreeNode;
begin
  ChildNode := tvSQLTree.Items.AddChild(ParentNode,vQry.FieldByName(GetName).AsString);
  ARec[vQry.RecNo - 1].ID := vQry.FieldByName(GetID).AsVariant;
  ARec[vQry.RecNo - 1].ParentID := vQry.FieldByName(GetParentID).AsVariant;
  ARec[vQry.RecNo - 1].Name := vQry.FieldByName(GetName).AsVariant;
  ChildNode.Data := @ARec[vQry.RecNo - 1];
  result := ChildNode;
end;

function TfrBaseSQLTree.SearchNodeByID(ID :variant) :TTreeNode;
var i :integer;
    vNode :TTreeNode;
begin
  vNode := nil;
  if tvSQLTree.Items.Count > 0 then
    for i := 0 to tvSQLTree.Items.Count - 1 do begin
      vNode := tvSQLTree.Items[i];
      if TRec(vNode.Data^).ID = ID then break;
      vNode := nil;
    end;
  result := vNode;
end;

function TfrBaseSQLTree.SearchNodeByName(Name :variant) :TTreeNode;
var i :integer;
    vNode :TTreeNode;
begin
  vNode := nil;
  if tvSQLTree.Items.Count > 0 then
    for i := 0 to tvSQLTree.Items.Count - 1 do begin
      vNode := tvSQLTree.Items[i];
      if TRec(vNode.Data^).NAME = Name then break;
      vNode := nil;
    end;
  result := vNode;
end;

procedure TfrBaseSQLTree.SetNodePicture(inNode :TTreeNode);
begin
  if inNode.getFirstChild <> nil then begin
    inNode.Expanded := true;
    inNode.ImageIndex := 0;
  end
  else inNode.ImageIndex := 1;
    inNode.SelectedIndex := inNode.ImageIndex;
end;

function  TfrBaseSQLTree.GetNodeID(Node :TTreeNode) :variant;
begin
  if Node <> nil then result := TRec(Node.Data^).ID;
end;

function  TfrBaseSQLTree.GetNodeParentID(Node :TTreeNode) :variant;
begin
  result := TRec(Node.Data^).ParentID;
end;

function  TfrBaseSQLTree.GetNodeName(Node :TTreeNode) :variant;
begin
  result := TRec(Node.Data^).Name;
end;

procedure TfrBaseSQLTree.SetNodeID(Node :TTreeNode; ID :variant);
begin
  TRec(Node.Data^).ID := ID;
end;

procedure TfrBaseSQLTree.SetNodeParentID(Node :TTreeNode; ParentID :variant);
begin
  TRec(Node.Data^).ParentID := ParentID;
end;

procedure TfrBaseSQLTree.SetNodeNameID(Node :TTreeNode; Name :variant);
begin
  TRec(Node.Data^).Name := Name;
end;

procedure TfrBaseSQLTree.tvSQLTreeChange(Sender: TObject; Node: TTreeNode);
begin
  vQry.Locate(GetID,TRec(Node.Data^).ID,[loCaseInsensitive]);
end;

procedure TfrBaseSQLTree.tvSQLTreeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F5 then
    if Assigned(vQry) and vQry.Active then begin
      vQry.Refresh;
      BuildTree;
    end;
end;

end.
