unit untBasePCSQLTreeFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Buttons, ExtCtrls, untBaseSQLTreeFrame,
  untBaseButtonsFrame, ComCtrls, DB, Ora, DBCtrlsEh, ToolCtrlsEh, DBCtrls;

type TFrState = (fstAdd,fstEdt,fstDel,fstRfr,fstCopy,fstNone);

type
  TfrPCSQLTree = class(TFrame)
    pcTree: TPageControl;
    tshTree: TTabSheet;
    frButtons: TfrButtons;
    frTree: TfrBaseSQLTree;
    tshForm: TTabSheet;
    ScrollBox: TScrollBox;
    panDown: TPanel;
    bbCancel: TBitBtn;
    bbSave: TBitBtn;
    Timer: TTimer;
    procedure OraQueryBeforePost(DataSet: TDataSet);
    procedure frButtonsbtnAddClick(Sender: TObject);
    procedure frButtonsbtnRfrClick(Sender: TObject);
    procedure pcTreeChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure bbCancelClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure frButtonsbtnEdtClick(Sender: TObject);
    procedure frTreetvSQLTreeDblClick(Sender: TObject);
    procedure frButtonsbtnCopyClick(Sender: TObject);
    procedure frButtonsbtnDelClick(Sender: TObject);
  private
    { Private declarations }
    vFrState :TFrState;
    vAutoControls :boolean;
    mous :TMouse;
    vKeyField,vLookupKeyField,vLookupField  :TField;
    vQry :TOraQuery;
    vDataSource :TDataSource;
    vCheckBoxFields :TStringList;
    procedure CheckDataModified(inQry :TOraQuery);
    procedure OnButtonClickDBComboBoxEh(Sender: TObject; var Handled: Boolean);
    procedure EditClobDBEditEh(Sender: TObject; var Handled: Boolean);
    procedure EditBlob(Sender: TObject; var Handled: Boolean);
    procedure EditBlobKeyPress(Sender: TObject; var Key: Char);
  public
    { Public declarations }
    constructor Create(AOwner :TComponent); override;
    destructor  Destroy; override;
    procedure SetConnection(Connection :TOraSession);
    function  GetQuery :TOraQuery;
    procedure SetQuery(Query :TOraQuery);
    function  GetDataSource :TDataSource;
    procedure SetDataSource(inDataSource :TDataSource);
    procedure SetLookupValue(LookupField :TField);
    procedure SetKeyField(LookupField :TField);
    function  GetKeyField :TField;
    procedure SetLookupKeyField(LookupField :TField);
    function  GetLookupKeyField :TField;
    procedure SetLookupField(LookupField :TField);
    function  GetLookupField :TField;
    function  GetFrState :TFrState;
    procedure SetAutoControls(AutoControls :boolean);
    procedure SetCheckBoxFields(FieldNames :array of string);
  end;

implementation

uses untBaseLookupForm, untBaseEdtCLOB;

{$R *.dfm}

constructor TfrPCSQLTree.Create(AOwner :TComponent);
begin
  inherited Create(AOwner);
  vFrState := fstNone;
end;

destructor TfrPCSQLTree.Destroy;
begin
  if Assigned(vQry) then CheckDataModified(vQry);
  inherited;
end;

procedure TfrPCSQLTree.SetCheckBoxFields(FieldNames :array of string);
var i :integer;
begin
  if not Assigned(vCheckBoxFields) then begin
    vCheckBoxFields := TStringList.Create;
    for i := 0 to length(FieldNames) - 1 do vCheckBoxFields.Add(FieldNames[i]);
  end;
end;

procedure TfrPCSQLTree.SetAutoControls(AutoControls :boolean);
begin
  vAutoControls := AutoControls;
end;

procedure TfrPCSQLTree.SetConnection(Connection :TOraSession);
begin
  frTree.SetConnection(Connection);
end;

procedure TfrPCSQLTree.OraQueryBeforePost(DataSet: TDataSet);
begin
  if vFrState = fstAdd then
    frTree.GetQuery.FieldByName(frTree.GetParentID).Value := TRec(frTree.tvSQLTree.Selected.Data^).ID;
  if vFrState = fstEdt then
    if frTree.tvSQLTree.Selected.Parent <> nil then
      frTree.GetQuery.FieldByName(frTree.GetParentID).Value := TRec(frTree.tvSQLTree.Selected.Parent.Data^).ID;
end;

function TfrPCSQLTree.GetQuery;
begin
  result := frTree.GetQuery;
end;

procedure TfrPCSQLTree.SetQuery(Query :TOraQuery);
begin
  vQry := Query;
  frTree.SetQuery(vQry);
  vQry.BeforePost := OraQueryBeforePost;
end;

procedure TfrPCSQLTree.SetDataSource(inDataSource :TDataSource);
var i,j :integer;
begin
  vDataSource := inDataSource;
  vQry := TOraQuery(inDataSource.DataSet);
  SetQuery(vQry);
  //--------
    if vAutoControls then
      begin
        j := 0;
        for i := 0 to vQry.FieldCount - 1 do
          begin
            with vQry.Fields[i] do
              if Visible and Assigned(ScrollBox.FindChildControl(FieldName)) then
                with ScrollBox.FindChildControl(FieldName) do
                  begin
                    Left := 8;
                    Top := j * 2 * 25 + 16;
                    j := j + 1;
                  end else
            with vQry.Fields[i] do
              if (Visible or isBlob) and not(Assigned(ScrollBox.FindChildControl(FieldName))) then
                begin
                  if not(DataType = ftBoolean) and (vCheckBoxFields.IndexOf(FieldName) < 0) then
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
                      if vQry.Fields[i].DataType in [ftString,ftFloat,ftInteger] then
                        if (vCheckBoxFields.IndexOf(vQry.Fields[i].FieldName) >= 0) then
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
                      if vQry.Fields[i].DataType = ftDateTime then
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
                      if vQry.Fields[i].DataType = ftDate then
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
                      if vQry.Fields[i].DataType = ftBoolean then
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
                      if vQry.Fields[i].DataType = ftOraClob then
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
                      if vQry.Fields[i].DataType = ftOraBlob then
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
    vAutoControls := false;
end;

function  TfrPCSQLTree.GetDataSource :TDataSource;
begin
  result := vDataSource;
end;

procedure TfrPCSQLTree.OnButtonClickDBComboBoxEh(Sender: TObject; var Handled: Boolean);
begin
  SetLookupValue(TDBComboBoxEh(TEditButtonControlEh(Sender).Parent).Field);
end;

procedure TfrPCSQLTree.CheckDataModified(inQry :TOraQuery);
begin
if not(Assigned(inQry)) then exit;
  if (inQry.State = dsEdit) or (inQry.State = dsInsert) then
    case MessageDlg('Данные были изменены. Сохранить?',mtInformation,mbYesNoCancel,0) of
      mrYes: inQry.Post;
      mrNo: inQry.Cancel;
      mrCancel: abort;
    end;
end;

procedure TfrPCSQLTree.SetLookupValue(LookupField :TField);
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
          ShowModal;
      end;
end;

procedure TfrPCSQLTree.SetKeyField(LookupField :TField);
begin
  vKeyField := TOraQuery(LookupField.DataSet).FieldByName(LookupField.KeyFields);
end;

procedure TfrPCSQLTree.SetLookupKeyField(LookupField :TField);
begin
  vLookupKeyField := TOraQuery(LookupField.LookupDataSet).FieldByName(LookupField.LookupKeyFields);
end;

procedure TfrPCSQLTree.SetLookupField(LookupField :TField);
begin
  vLookupField := LookupField;
end;

function TfrPCSQLTree.GetKeyField :TField;
begin
  result := vKeyField;
end;

function TfrPCSQLTree.GetLookupKeyField :TField;
begin
  result := vLookupKeyField;
end;

function TfrPCSQLTree.GetLookupField :TField;
begin
  result := vLookupField;
end;

function  TfrPCSQLTree.GetFrState :TFrState;
begin
  result := vFrState;
end;

procedure TfrPCSQLTree.pcTreeChange(Sender: TObject);
begin
  if TPageControl(Sender).ActivePage = tshTree then CheckDataModified(vQry);
end;

procedure TfrPCSQLTree.TimerTimer(Sender: TObject);
begin
  if Assigned(vQry) then bbSave.Enabled :=  (vQry.State = dsInsert) or (vQry.State = dsEdit)
  else bbSave.Enabled := false;
end;

procedure TfrPCSQLTree.bbCancelClick(Sender: TObject);
begin
  with vQry do
  if (State = dsInsert) or (State = dsEdit) then Cancel;
  pcTree.ActivePageIndex := 0;
  vFrState := fstNone;
  if vQry.RecordCount > 0 then with frTree.tvSQLTree.Selected do Expanded := getFirstChild <> nil;
end;

procedure TfrPCSQLTree.bbSaveClick(Sender: TObject);
var vID :variant;
begin
  with vQry do begin
    if (State = dsInsert) or (State = dsEdit) then Post;
    RefreshRecord;
    vID := FieldByName(frTree.GetID).AsVariant;
  end;
  if vFrState in [fstAdd,fstCopy] then begin
    frTree.BuildTree;
    frTree.SearchNodeByID(vID).Selected := true;
  end
    else
      with frTree do begin
        tvSQLTree.Selected.Text := vQry.FieldByName(GetName).AsString;
      end;
  pcTree.ActivePageIndex := 0;
  vFrState := fstNone;
end;

procedure TfrPCSQLTree.frButtonsbtnAddClick(Sender: TObject);
begin
  vFrState := fstAdd;
  pcTree.ActivePageIndex := 1;
  vQry.Append;
end;

procedure TfrPCSQLTree.frButtonsbtnCopyClick(Sender: TObject);
begin
  vFrState := fstCopy;
  pcTree.ActivePageIndex := 1;
  vQry.Append;
end;

procedure TfrPCSQLTree.frButtonsbtnEdtClick(Sender: TObject);
begin
  vFrState := fstEdt;
  pcTree.ActivePageIndex := 1;
end;

procedure TfrPCSQLTree.frButtonsbtnRfrClick(Sender: TObject);
var vID :variant;
begin
  with frTree do begin
    vID := TRec(tvSQLTree.Selected.Data^).ID;
    if GetQuery.Active then GetQuery.Refresh;
    BuildTree;
    SearchNodeByID(vID).Selected := true;
  end;
end;

procedure TfrPCSQLTree.frButtonsbtnDelClick(Sender: TObject);
begin
  vFrState := fstDel;
  if frTree.tvSQLTree.Selected.getFirstChild <> nil then begin
    MessageDlg('Не возможно удалить элемент, содержащий дочерние записи.',mtWarning,[mbOk],0);
    exit;
  end;
  if MessageDlg('Удалить запись?',mtConfirmation,mbYesNoCancel,0) <> mrYes then exit;
  vQry.Delete;
  frTree.tvSQLTree.Selected.Delete;
  if vQry.RecordCount > 0 then frTree.SetNodePicture(frTree.tvSQLTree.Selected);
end;

procedure TfrPCSQLTree.frTreetvSQLTreeDblClick(Sender: TObject);
begin
  frButtons.btnEdt.Click;
end;

procedure TfrPCSQLTree.EditClobDBEditEh(Sender: TObject; var Handled: Boolean);
begin
  with TfrmBaseEdtCLOB.Create(TDBEditEh(TEditButtonControlEh(Sender).Owner),TDBEditEh(TEditButtonControlEh(Sender).Owner).DataSource,TDBEditEh(TEditButtonControlEh(Sender).Owner).Field) do
    begin
      Left := self.Left;
      Top := self.Top;
      Width := self.Width;
      Height := self.Height;
      ShowModal;
    end;
end;

procedure TfrPCSQLTree.EditBlob(Sender: TObject; var Handled: Boolean);
var odOpenFile :TOpenDialog;
    BlobField :TBlobField;
begin
  BlobField := TBlobField(TDBEditEh(TEditButtonControlEh(Sender).Owner).Field);
  if not(TOraQuery(BlobField.DataSet).State in [dsInsert,dsEdit]) then TOraQuery(BlobField.DataSet).Edit;
  odOpenFile := TOpenDialog.Create(self);
  if odOpenFile.Execute then BlobField.LoadFromFile(odOpenFile.FileName);
  odOpenFile.Free;
end;

procedure TfrPCSQLTree.EditBlobKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

end.
