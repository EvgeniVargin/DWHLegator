unit untMTreeDetailNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBasePCEFrame, ExtCtrls, untBaseSQLTreeFrame, Ora, DB, ComCtrls,
  Menus;

type
  TfrmMTreeDetailNew = class(TForm)
    frMaster: TfrBaseSQLTree;
    Splitter1: TSplitter;
    frDetail: TfrPCEBase;
    pmnuMaster: TPopupMenu;
    pmnuDetail: TPopupMenu;
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure DetailBeforePost(DataSet: TDataSet);
  protected
    vMQry,vDQry :TOraQuery;
    vMDs,vDDs :TOraDataSource;
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string);
  end;

var
  frmMTreeDetailNew: TfrmMTreeDetailNew;

implementation

uses untRegistry;

{$R *.dfm}

constructor TfrmMTreeDetailNew.Create(AOwner :TComponent; FormName :string);
var vQL :TStringList;
    DCheckBoxes,DDrawColumns :Array of string;
    i,DAllDrawFieldCount,DAllVarCount :integer;
    DColorField :string;
    DValues,DBrushColors,DFontColors :array of variant;
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frDetail.SetAutoControls(strtobool(Attrs.Values['AutoControls']));

  frMaster.SetColumns([Attrs.Values['ID'],Attrs.Values['ParentID'],Attrs.Values['Name']]);

  //Если необходимо строить наборы и все что с ними связано
  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vMDs := TOraDataSource(self.FindComponent(vMQry.Name + 'DS'));//CreateDataSource(vMQry);

    vDQry := TOraQuery(self.FindComponent(vQL.Strings[1]));
    vDDs := TOraDataSource(self.FindComponent(vDQry.Name + 'DS'));//CreateDataSource(vDQry);
    //vDQry.MasterSource := vMDs;
    vDQry.BeforePost := DetailBeforePost;
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

  DAllDrawFieldCount := 0;
  GetDrawFieldCount(Self.Name,vDQry.Name,DAllDrawFieldCount);
  DAllVarCount := 0;
  GetDrawVarCount(Self.Name,vDQry.Name,DAllVarCount);

  setlength(DCheckBoxes,vDQry.FieldCount);
  setlength(DDrawColumns,DAllDrawFieldCount);
  setlength(DValues,DAllVarCount);
  setlength(DBrushColors,DAllVarCount);
  setlength(DFontColors,DAllVarCount);

  GetCheckBoxes(Self.Name,vDQry.Name,DCheckBoxes);
  GetDrawColumns(Self.Name,vDQry.Name,DDrawColumns);
  GetDrawCells(Self.Name,vDQry.Name,DColorField,DValues,DBrushColors,DFontColors);

  frMaster.SetQuery(vMQry);

  frDetail.SetCheckBoxFields(DCheckBoxes);
  frDetail.SetDataSource(vDDs);
  frDetail.SetDrawColumns(DDrawColumns);
  frDetail.SetDrawCells(DColorField,DValues,DBrushColors,DFontColors,DAllVarCount);

end;

procedure TfrmMTreeDetailNew.DetailBeforePost(DataSet: TDataSet);
begin
 vDQry.FieldByName(GetDetailKeyField(self.Name,vDQry.Name)).Value := vMQry.FieldByName(GetMasterKeyField(self.Name,vDQry.Name)).AsVariant;
end;

procedure TfrmMTreeDetailNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMTreeDetailNew.MenuClick(Sender :TObject);
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

end.
