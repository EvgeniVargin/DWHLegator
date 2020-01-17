unit untBasePCEFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Buttons, ExtCtrls,  ComCtrls, Ora, DBCtrls, DB, DBCtrlsEh, ToolCtrlsEh,
  ToolWin, untBaseFrame,untBaseButtonsFrame, Mask;

type TFrState = (fstAdd,fstEdt,fstDel,fstRfr,fstCopy,fstNone);

type
  TfrPCEBase = class(TFrame)
    PageControl: TPageControl;
    tshList: TTabSheet;
    panButtons: TPanel;
    frButtons: TfrButtons;
    frList: TfrBase;
    tshForm: TTabSheet;
    panDown: TPanel;
    bbCancel: TBitBtn;
    bbSave: TBitBtn;
    Timer: TTimer;
    ScrollBox: TScrollBox;
    procedure PageControlChange(Sender: TObject);
    procedure bbCancelClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TimerTimer(Sender: TObject);
    procedure frButtonsbtnRfrClick(Sender: TObject);
    procedure frButtonsbtnDelClick(Sender: TObject);
    procedure frButtonsbtnAddClick(Sender: TObject);
    procedure frButtonsbtnEdtClick(Sender: TObject);
    procedure frListdbGridDblClick(Sender: TObject);
    procedure frButtonsbtnCopyClick(Sender: TObject);
  private
    { Private declarations }
    vFrState :TFrState;
    vAutoControls :boolean;
    vQry :TOraQuery;
    vDataSource :TDataSource;
    mous :TMouse;
    vKeyField,vLookupKeyField,vLookupField  :TField;
    vCheckBoxFields :array of string;
    procedure OnButtonClickDBComboBoxEh(Sender: TObject; var Handled: Boolean);
    procedure EditClobDBEditEh(Sender: TObject; var Handled: Boolean);
    procedure EditBlob(Sender: TObject; var Handled: Boolean);
    procedure EditBlobKeyPress(Sender: TObject; var Key: Char);
    function IsCheckBox(FieldName :string) :boolean;
  public
    { Public declarations }
    constructor Create(AOwner :TComponent); override;
    destructor  Destroy; override;
    procedure SetDrawColumns(ColorFields :array of string);
    procedure SetDrawCells(Field :string; Value,BrushColor,FontColor :Array of variant; AllVarCount :integer);
    procedure SetConnection(Connection :TOraSession);
    procedure SetDataSource(inDataSource :TDataSource);
    function  GetDataSource :TDataSource;
    function  GetQuery :TOraQuery;
    procedure SetLookupValue(LookupField :TField);
    procedure SetKeyField(LookupField :TField);
    function  GetKeyField :TField;
    procedure SetLookupKeyField(LookupField :TField);
    function  GetLookupKeyField :TField;
    procedure SetLookupField(LookupField :TField);
    function  GetLookupField :TField;
    procedure CheckDataModified(inQry :TOraQuery);
    procedure SetFrState(FrState :TFrState);
    function  GetFrState :TFrState;
    procedure SetAutoControls(AutoControls :boolean);
    //function  GetAutoControls :boolean;
    procedure SetCheckBoxFields(FieldNames :array of string);
  end;
implementation

uses untBaseLookupForm, DBGridEh, untBaseEdtCLOB, untRegistry, DBAccess;

{$R *.dfm}

constructor TfrPCEBase.Create(AOwner :TComponent);
begin
  inherited Create(AOwner);
  vFrState := fstNone;
end;

destructor TfrPCEBase.Destroy;
begin
  if Assigned(vQry) then CheckDataModified(vQry);
  inherited;
end;

procedure TfrPCEBase.SetCheckBoxFields(FieldNames :array of string);
var i :integer;
begin
  setlength(vCheckBoxFields,length(FieldNames));
  for i := 0 to length(vCheckBoxFields) - 1 do vCheckBoxFields[i] := FieldNames[i];
end;

function TfrPCEBase.IsCheckBox(FieldName :string) :boolean;
var i :integer;
begin
  result := false;
  if vCheckBoxFields <> nil then
    for i := 0 to length(vCheckBoxFields) - 1 do
      if FieldName = vCheckBoxFields[i] then result := true;
end;

procedure TfrPCEBase.SetConnection(Connection :TOraSession);
begin
  if Assigned(vQry) then vQry.Session := Connection;
  frList.SetConnection(Connection);
end;

procedure TfrPCEBase.OnButtonClickDBComboBoxEh(Sender: TObject; var Handled: Boolean);
begin
  SetLookupValue(TDBComboBoxEh(TeditButtonControlEh(Sender).Parent).Field);
end;

procedure TfrPCEBase.SetLookupValue(LookupField :TField);
begin
  SetKeyField(LookupField);
  SetLookupKeyField(LookupField);
  SetLookupField(LookupField);

  if not(GetKeyField.DataSet.State IN [dsInsert,dsEdit])
    then GetKeyField.DataSet.Edit;
      with TfrmBaseLookupForm.Create(self) do
        begin
          CallSelectForm(GetKeyField,GetLookupKeyField,GetLookupField);
          Caption := LookupField.DisplayName;
          If mous.CursorPos.X - trunc(width/2) < 0 then Left := mous.CursorPos.X
             else If mous.CursorPos.X + width > screen.Width then Left := mous.CursorPos.X - width
                     else Left := mous.CursorPos.X - trunc(width/2);
          If mous.CursorPos.Y + height > screen.Height then Top := mous.CursorPos.Y - height
            else Top := mous.CursorPos.Y;
          Color := self.Color;
          frSelect.SetColWidth;
          ShowModal;
      end;
end;

procedure TfrPCEBase.SetDataSource(inDataSource :TDataSource);
var i,j :integer;
begin
  vDataSource := inDataSource;
  vQry := TOraQuery(vDataSource.DataSet);
  vQry.Open;

  frList.SetDataSource(vDataSource);
  frList.DrawCheckBoxes(vCheckBoxFields);
  //---
    if vAutoControls then
      begin
        j := 0;
        for i := 0 to GetQuery.FieldCount - 1 do
          begin
            with GetQuery.Fields[i] do
              if Visible and Assigned(ScrollBox.FindChildControl(FieldName)) then
                with ScrollBox.FindChildControl(FieldName) do
                  begin
                    Left := 8;
                    Top := j * 2 * 25 + 16;
                    j := j + 1;
                  end else
            with GetQuery.Fields[i] do
              if (Visible or isBlob) and not(Assigned(ScrollBox.FindChildControl(FieldName))) then
                begin
                  if not IsCheckBox(FieldName) then
                    with TLabel.Create(ScrollBox) do
                      begin
                        Parent := ScrollBox;
                        Name := 'lab' + FieldName;
                        Left := 8;
                        Top := j * 2 * 25;
                        Caption := DisplayName;
                      end;
                  if lookup then
                    with TDBComboBoxEh.Create(ScrollBox) do
                      begin
                        Name := FieldName;
                        EditButton.Style := ebsEllipsisEh;
                        OnButtonClick := OnButtonClickDBComboBoxEh;
                        DataSource := GetDataSource;
                        DataField :=  FieldName;
                        Parent := ScrollBox;
                        Left := 8;
                        Top := j * 2 * 25 + 16;
                        width := DisplayWidth;
                      end
                  else
                    begin
                      if GetQuery.Fields[i].DataType in [ftString,ftFloat,ftInteger] then
                        if IsCheckBox(FieldName) then
                          with TDBCheckBoxEh.Create(ScrollBox) do
                            begin
                              Name := FieldName;
                              DataSource := GetDataSource;
                              DataField :=  FieldName;
                              Parent := ScrollBox;
                              Left := 8;
                              Top := j * 2 * 25 + 16;
                              width := DisplayWidth;
                              Alignment := taLeftJustify;
                              ValueChecked := '1';
                              ValueUnchecked := '0';
                              Caption :=  DisplayLabel;
                             end else
                        with TDBEditEh.Create(ScrollBox) do
                          begin
                            Name := FieldName;
                            DataSource := GetDataSource;
                            DataField :=  FieldName;
                            Parent := ScrollBox;
                            Left := 8;
                            Top := j * 2 * 25 + 16;
                            width := DisplayWidth;
                          end;
                      if GetQuery.Fields[i].DataType = ftDateTime then
                        with TDBDateTimeEditEh.Create(ScrollBox) do
                          begin
                            Name := FieldName;
                            DataSource := GetDataSource;
                            DataField :=  FieldName;
                            Parent := ScrollBox;
                            Left := 8;
                            Top := j * 2 * 25 + 15;
                            width := DisplayWidth;
                            Kind := dtkDateTimeEh;
                            EditButton.Style := ebsEllipsisEh;
                           end;
                      if GetQuery.Fields[i].DataType = ftDate then
                        with TDBDateTimeEditEh.Create(ScrollBox) do
                          begin
                            Name := FieldName;
                            DataSource := GetDataSource;
                            DataField :=  FieldName;
                            Parent := ScrollBox;
                            Left := 8;
                            Top := j * 2 * 25 + 15;
                            width := DisplayWidth;
                            Kind := dtkDateEh;
                            EditButton.Style := ebsEllipsisEh;
                           end;
                      if GetQuery.Fields[i].DataType = ftBoolean then
                        with TDBCheckBoxEh.Create(ScrollBox) do
                          begin
                            Name := FieldName;
                            DataSource := GetDataSource;
                            DataField :=  FieldName;
                            Parent := ScrollBox;
                            Left := 8;
                            Top := j * 2 * 25 + 16;
                            width := DisplayWidth;
                            Alignment := taLeftJustify;
                            ValueChecked := 'true';
                            ValueUnchecked := 'false';
                            Caption :=  DisplayLabel;
                           end;
                      if GetQuery.Fields[i].DataType = ftOraClob then
                      with TDBEditEh.Create(ScrollBox) do
                        begin
                          Name := FieldName;
                          DataSource := GetDataSource;
                          DataField :=  FieldName;
                          Parent := ScrollBox;
                          Left := 8;
                          Top := j * 2 * 25 + 16;
                          width := DisplayWidth;
                          Font.Color := clGrayText;
                          with EditButtons.Add do
                            begin
                              Style := ebsEllipsisEh;
                              OnClick := EditClobDBEditEh;
                            end;
                          OnKeyPress := EditBlobKeyPress;
                        end;
                      if GetQuery.Fields[i].DataType = ftOraBlob then
                      with TDBEditEh.Create(ScrollBox) do
                        begin
                          Name := FieldName;
                          DataSource := GetDataSource;
                          DataField :=  FieldName;
                          Parent := ScrollBox;
                          Left := 8;
                          Top := j * 2 * 25 + 16;
                          width := DisplayWidth;
                          Font.Color := clGrayText;
                          with EditButtons.Add do
                            begin
                              Style := ebsEllipsisEh;
                              OnClick := EditBlob;
                            end;
                          OnKeyPress := EditBlobKeyPress;
                        end;
                    end;
                  j := j + 1;
                end;
          end;
      end;
    frList.SetColWidth;
    vAutoControls := false;
end;

procedure TfrPCEBase.SetKeyField(LookupField :TField);
begin
  vKeyField := TOraQuery(LookupField.DataSet).FieldByName(LookupField.KeyFields);
end;

procedure TfrPCEBase.SetLookupKeyField(LookupField :TField);
begin
  vLookupKeyField := TOraQuery(LookupField.LookupDataSet).FieldByName(LookupField.LookupKeyFields);
end;

procedure TfrPCEBase.SetLookupField(LookupField :TField);
begin
  vLookupField := LookupField;
end;

function TfrPCEBase.GetKeyField :TField;
begin
  result := vKeyField;
end;

function TfrPCEBase.GetLookupKeyField :TField;
begin
  result := vLookupKeyField;
end;

function TfrPCEBase.GetLookupField :TField;
begin
  result := vLookupField;
end;

function  TfrPCEBase.GetDataSource :TDataSource;
begin
  result := vDataSource;
end;

function  TfrPCEBase.GetQuery :TOraQuery;
begin
  result := vQry;
end;

procedure TfrPCEBase.bbCancelClick(Sender: TObject);
begin
  with vQry do
  if (State = dsInsert) or (State = dsEdit) then Cancel;
  PageControl.ActivePageIndex := 0;
end;

procedure TfrPCEBase.bbSaveClick(Sender: TObject);
begin
  TBitBtn(Sender).Cursor := crSQLWait;
  with vQry do
  if (State = dsInsert) or (State = dsEdit) then Post;
  PageControl.ActivePageIndex := 0;
  frButtons.btnRfr.Click;
  TBitBtn(Sender).Cursor := crDefault;
end;

procedure TfrPCEBase.CheckDataModified(inQry :TOraQuery);
begin
  if (vQry.State = dsEdit) or (vQry.State = dsInsert) then
    case MessageDlg('Данные были изменены. Сохранить?',mtInformation,mbYesNoCancel,0) of
      mrYes: vQry.Post;
      mrNo: vQry.Cancel;
      mrCancel: abort;
    end;
end;

procedure TfrPCEBase.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(vQry) then CheckDataModified(vQry);
end;

procedure TfrPCEBase.frButtonsbtnAddClick(Sender: TObject);
begin
  if frList.edtSearch.CanFocus then frList.edtSearch.SetFocus;
  vQry.Append;
  PageControl.ActivePageIndex := 1;
  vFrState := fstAdd;
end;

procedure TfrPCEBase.frButtonsbtnDelClick(Sender: TObject);
begin
  if MessageDlg('Удалить запись?',mtConfirmation,mbYesNoCancel,0) = mrYes
    then vQry.Delete;
  vFrState := fstDel;
end;

procedure TfrPCEBase.frButtonsbtnEdtClick(Sender: TObject);
begin
  PageControl.ActivePageIndex := 1;
  vFrState := fstEdt;
end;

procedure TfrPCEBase.frButtonsbtnRfrClick(Sender: TObject);
var id :variant;
begin
  id := vQry.FieldByName(vQry.KeyFields).AsVariant;
  if vQry.Active then vQry.Refresh;
  vQry.Locate(vQry.KeyFields,id,[loCaseInsensitive]);
  vFrState := fstRfr;
end;

procedure TfrPCEBase.frListdbGridDblClick(Sender: TObject);
begin
  frButtons.btnEdt.Click;
end;

procedure TfrPCEBase.PageControlChange(Sender: TObject);
begin
  if (TPageControl(Sender).ActivePage = tshList) and Assigned(vQry)
    then CheckDataModified(vQry);
end;

procedure TfrPCEBase.TimerTimer(Sender: TObject);
begin
  if Assigned(vQry) and vQry.Active then bbSave.Enabled :=  (vQry.State = dsInsert) or (vQry.State = dsEdit);
end;

procedure TfrPCEBase.frButtonsbtnCopyClick(Sender: TObject);
  var a :Array of variant;
      i :integer;
begin
  SetLength(a,vQry.FieldCount);
  for i := 0 to vQry.FieldCount - 1 do
    if not(vQry.KeyFields = vQry.Fields[i].FieldName) then a[i] := vQry.Fields[i].AsVariant
    else a[i] := null;
  vQry.Append;
  for i := 0 to vQry.FieldCount - 1 do
    vQry.Fields[i].Value := a[i];
  PageControl.ActivePageIndex := 1;
  vFrState := fstAdd;
end;

procedure TfrPCEBase.SetDrawColumns(ColorFields :array of string);
begin
  frList.SetDrawColumns(ColorFields);
end;

procedure TfrPCEBase.SetDrawCells(Field :string; Value,BrushColor,FontColor :Array of variant; AllVarCount :integer);
begin
  frList.SetDrawCells(Field,Value,BrushColor,FontColor,AllVarCount);
end;

procedure TfrPCEBase.SetFrState(FrState :TFrState);
begin
  vFrState := FrState;
end;

function  TfrPCEBase.GetFrState :TFrState;
begin
  result := vFrState;
end;

procedure TfrPCEBase.SetAutoControls(AutoControls :boolean);
begin
  vAutoControls := AutoControls;
end;

procedure TfrPCEBase.EditClobDBEditEh(Sender: TObject; var Handled: Boolean);
begin
  with TfrmBaseEdtCLOB.Create(TDBEditEh(TEditButtonControlEh(Sender).Owner),TDBEditEh(TEditButtonControlEh(Sender).Owner).DataSource,TDBEditEh(TEditButtonControlEh(Sender).Owner).Field) do
    begin
      Caption := TDBEditEh(TEditButtonControlEh(Sender).Owner).Field.DisplayLabel;
      Left := self.Left;
      Top := self.Top;
      Width := self.Width;
      Height := self.Height;
      ShowModal;
    end;
end;

procedure TfrPCEBase.EditBlob(Sender: TObject; var Handled: Boolean);
var odOpenFile :TOpenDialog;
    BlobField :TBlobField;
begin
  BlobField := TBlobField(vQry.FieldByName(TDBEditEh(TEditButtonControlEh(Sender).Owner).DataField));
  if not(TOraQuery(BlobField.DataSet).State in [dsInsert,dsEdit]) then TOraQuery(BlobField.DataSet).Edit;

  odOpenFile := TOpenDialog.Create(self);
  if odOpenFile.Execute then
    try
      BlobField.Clear;
      BlobField.LoadFromFile(odOpenFile.FileName);
    finally
      odOpenFile.Free;
    end;
end;

procedure TfrPCEBase.EditBlobKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

end.
