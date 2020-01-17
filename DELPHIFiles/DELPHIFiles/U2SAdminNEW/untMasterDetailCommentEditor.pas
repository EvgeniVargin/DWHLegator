unit untMasterDetailCommentEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBasePCSQLTreeFrame, ExtCtrls, StdCtrls, Buttons, ComCtrls,
  DBCtrls, untBasePCEFrame, Menus, Ora, DB;

type
  TfrmMasterDetailCommentEditor = class(TForm)
    frMaster: TfrPCEBase;
    Splitter1: TSplitter;
    panRichButtons: TPanel;
    bbRichCancel: TBitBtn;
    bbRichSave: TBitBtn;
    tmrRichButtons: TTimer;
    pmnuMaster: TPopupMenu;
    Splitter2: TSplitter;
    memComment: TDBMemo;
    memCommentAdd: TMemo;
    procedure tmrRichButtonsTimer(Sender: TObject);
    procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bbRichSaveClick(Sender: TObject);
    procedure bbRichCancelClick(Sender: TObject);
  private
    { Private declarations }
  protected
    vMQry :TOraQuery;
    vMDs :TOraDataSource;
  public
    { Public declarations }
    vOSUser,vOSUserFIO :string;
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string); overload;
    procedure SetDataSource(DataSource :TOraDataSource);
  end;

var
  frmMasterDetailCommentEditor: TfrmMasterDetailCommentEditor;

implementation

uses untRegistry, untUtility;

{$R *.dfm}

constructor TfrmMasterDetailCommentEditor.Create(AOwner :TComponent; FormName :string);
var vQL :TStringList;
    MCheckBoxes,MDrawColumns :Array of string;
    i,MAllDrawFieldCount,MAllVarCount :integer;
    MColorField,MRichField :string;
    MValues,MBrushColors,MFontColors :array of variant;
begin
  inherited Create(AOwner);
  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);
  frMaster.SetAutoControls(strtobool(Attrs.Values['AutoControls']));
  MRichField := Attrs.Values['CommentField'];

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

  //if strtobool(Attrs.Values['BuildQueries']) then begin
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
  //end;

  frMaster.SetDataSource(vMDs);
  memComment.DataSource := vMDs;
  memComment.DataField := MRichField;

  //if strtobool(Attrs.Values['BuildQueries']) then begin
    frMaster.SetDrawColumns(MDrawColumns);
    frMaster.SetDrawCells(MColorField,MValues,MBrushColors,MFontColors,MAllVarCount);
  //end;

  SetOsUser(self,vOSUser,vOSUserFIO);
end;

procedure TfrmMasterDetailCommentEditor.SetDataSource(DataSource :TOraDataSource);
begin
  vMDs := DataSource;
  vMQry := TOraQuery(vMDS.DataSet);

  frMaster.SetDataSource(vMDs);
  frMaster.SetFrState(fstNone);
  frMaster.PageControl.ActivePageIndex := 0;
end;

procedure TfrmMasterDetailCommentEditor.MenuClick(Sender :TObject);
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

procedure TfrmMasterDetailCommentEditor.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMasterDetailCommentEditor.tmrRichButtonsTimer(
  Sender: TObject);
begin
  bbRichSave.Enabled := memCommentAdd.Modified and (memCommentAdd.GetTextLen > 0);
  bbRichCancel.Enabled := memCommentAdd.Modified and (memCommentAdd.GetTextLen > 0);
end;

procedure TfrmMasterDetailCommentEditor.bbRichSaveClick(Sender: TObject);
begin
  memCommentAdd.Lines.Text := vOSUserFIO + ' (' + vOSUser + ')  ' + DateToStr(Date) + ' ' + TimeToStr(Time) + ' | ' + memCommentAdd.Lines.Text + #10#13 + memComment.Lines.Text;
  if not(vMQry.State in [dsInsert,dsEdit]) then vMQry.Edit;
  memComment.Lines.Text := memCommentAdd.Lines.Text;
  frMaster.bbSave.Click;
  memCommentAdd.Clear;
end;

procedure TfrmMasterDetailCommentEditor.bbRichCancelClick(Sender: TObject);
begin
  memCommentAdd.Clear;
  frMaster.bbCancel.Click;
end;

end.
