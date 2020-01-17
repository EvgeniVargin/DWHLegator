unit untReportsNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseRepParamsFrame, ExtCtrls, untBaseFrame, Ora, DB, ComCtrls,
  Menus, Buttons, DBGridEh;

type
  TfrmReportsNew = class(TForm)
    frMaster: TfrBase;
    Splitter1: TSplitter;
    pmnuMaster: TPopupMenu;
    frDetail: TfrBaseRepParams;
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MasterDataChange(Sender: TObject; Field: TField);
  private
    { Private declarations }
    vMQry,vDQry :TOraQuery;
    vMDs,vDDs :TOraDataSource;
  public
    { Public declarations }
    Attrs :TStringList;
    vInProgress :boolean;
    vBegDT :TDateTime;
    constructor Create(AOwner :TComponent; FormName :string);
    function GetQryMaster :TOraQuery;
  end;

var
  frmReportsNew: TfrmReportsNew;
  MyThread: TMyThread;

implementation

uses untRegistry, untUtility, untReportResultNew;

{$R *.dfm}

constructor TfrmReportsNew.Create(AOwner :TComponent; FormName :string);
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


  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vMDs := TOraDataSource(self.FindComponent(vMQry.Name + 'DS'));
    vMQry.Open;

    vDQry := TOraQuery(self.FindComponent(vQL.Strings[1]));
    vDDs := TOraDataSource(self.FindComponent(vDQry.Name + 'DS'));
    vDQry.MasterSource := vMDs;
    vDQry.Open;

    vQL.Free;

    BuildPopupMenu(pmnuMaster,vMQry);

    if pmnuMaster.Items.Count > 0 then
      for i := 0 to pmnuMaster.Items.Count - 1 do begin
        pmnuMaster.Items[i].OnClick := MenuClick;
        if TActionMenuItem(pmnuMaster.Items[i]).GetButton <> nil then TActionMenuItem(pmnuMaster.Items[i]).GetButton.OnClick := MenuClick;
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

  GetCheckBoxes(Self.Name,vMQry.Name,MCheckBoxes);
  GetDrawColumns(Self.Name,vMQry.Name,MDrawColumns);
  GetDrawCells(Self.Name,vMQry.Name,MColorField,MValues,MBrushColors,MFontColors);

  frMaster.DrawCheckBoxes(MCheckBoxes);
  frMaster.SetDataSource(vMDs);
  frMaster.SetDrawColumns(MDrawColumns);
  frMaster.SetDrawCells(MColorField,MValues,MBrushColors,MFontColors,MAllVarCount);

  frDetail.ParamQuery := vDQry;
  frDetail.BuildParams;

  frMaster.SetColWidth;
  vMDs.OnDataChange := MasterDataChange;
end;

function TfrmReportsNew.GetQryMaster :TOraQuery;
begin
  result := vMQry;
end;

procedure TfrmReportsNew.MenuClick(Sender :TObject);
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

procedure TfrmReportsNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmReportsNew.MasterDataChange(Sender: TObject; Field: TField);
begin
  frDetail.BuildParams;
end;

end.
