unit untPMasterDetailNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseParFrame, untBasePCEFrame, ExtCtrls, Ora, Menus, DB;

type
  TfrmPMasterDetailNew = class(TForm)
    frMaster: TfrBaseParFrame;
    Splitter1: TSplitter;
    frDetail: TfrPCEBase;
    pmnuMaster: TPopupMenu;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MenuClick(Sender :TObject);
  private
    { Private declarations }
    procedure DetailBeforePost(DataSet: TDataSet);
  protected
    vPQry,vMQry,vDQry :TOraQuery;
    vMDs,vDDs :TOraDataSource;
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string); overload;
  end;

var
  frmPMasterDetailNew: TfrmPMasterDetailNew;

implementation

uses untRegistry, untUtility;

{$R *.dfm}

constructor TfrmPMasterDetailNew.Create(AOwner :TComponent; FormName :string);
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

  //Если необходимо строить наборы и все что с ними связано
  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));
    vMDs := TOraDataSource(self.FindComponent(vMQry.Name + 'DS'));

    if strtobool(Attrs.Values['QueryParamsAutoCreate']) then begin
      vPQry := TOraQuery.Create(self);
      vPQry.Name := vMQry.Name + 'Params';
      vPqry.SQL.Add('SELECT qp.id,qp.pname,qp.ptype,qp.plookupsql,qp.pdescr,qp.pval,qp.pvaldisplay,qp.pnameparent' + #13#10 +
                    '  FROM tb_form_registry f' + #13#10 +
                    '       INNER JOIN tb_query_registry q ON q.form_id = f.id AND q.query_name = ''' + vMQry.Name + '''' + #13#10 +
                    '       INNER JOIN tb_qparam_registry qp ON qp.query_id = q.id' + #13#10 +
                    '  WHERE f.form_name = ''' + self.Name + ''' ORDER BY qp.ord');
      vPQry.Open;
    end else begin
               vPQry := TOraQuery(self.FindComponent(vQL.Strings[1]));
               vPQry.Open;
             end;

    frMaster.ParamQry := vPQry;
    frMaster.ListQry := vMQry;
    frMaster.BuildParams;

    if strtobool(Attrs.Values['PQueryAutoOpen']) then vMQry.Open;

    vDQry := TOraQuery(self.FindComponent(vQL.Strings[1]));
    vDDs := TOraDataSource(self.FindComponent(vDQry.Name + 'DS'));
    vDQry.BeforePost := DetailBeforePost;

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

  frMaster.frList.SetDataSource(vMDs);

  frMaster.frList.SetColWidth;
  frMaster.frList.DrawCheckBoxes(MCheckBoxes);
  frMaster.frList.SetDrawColumns(MDrawColumns);
  frMaster.frList.SetDrawCells(MColorField,MValues,MBrushColors,MFontColors,MAllVarCount);

  frDetail.SetCheckBoxFields(DCheckBoxes);
  frDetail.SetDataSource(vDDs);
  frDetail.SetDrawColumns(DDrawColumns);
  frDetail.SetDrawCells(DColorField,DValues,DBrushColors,DFontColors,DAllVarCount);

end;

procedure TfrmPMasterDetailNew.DetailBeforePost(DataSet: TDataSet);
begin
 vDQry.FieldByName(GetDetailKeyField(self.Name,vDQry.Name)).Value := vMQry.FieldByName(GetMasterKeyField(self.Name,vDQry.Name)).AsVariant;
end;

procedure TfrmPMasterDetailNew.MenuClick(Sender :TObject);
var Qry :TOraQuery;
    ActID :integer;
begin
  if Sender.ClassName = 'TActionMenuItem' then begin
    Qry := GetQueryByAction(self,TActionMenuItem(sender).GetActId);
    ActId := TActionMenuItem(sender).GetActId;
  end;
  RunAction(Qry,ActId);
end;

procedure TfrmPMasterDetailNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
