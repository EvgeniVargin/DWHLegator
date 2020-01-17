unit untChartNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Ora, DB, untBaseChart, Menus, StdCtrls, ExtCtrls,
  untBaseRepParamsFrame;

type
  TfrmChartNew = class(TForm)
    frMaster: TfrBaseChart;
    frParams: TfrBaseRepParams;
    Splitter1: TSplitter;
    tmrRefresh: TTimer;
    //procedure MenuClick(Sender :TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure frDetailbtnExRepClick(Sender: TObject);
    procedure tmrRefreshTimer(Sender: TObject);
  private
    { Private declarations }
    vTimerInterval :integer;
    vAutoRefresh :boolean;
  protected
    vPQry,vMQry :TOraQuery;
  public
    { Public declarations }
    Attrs :TStringList;
    constructor Create(AOwner :TComponent; FormName :string); overload;
    //procedure SetTimerInterval(inIntervalMS :integer);                                          
  end;

var
  frmChartNew: TfrmChartNew;

implementation

uses untRegistry, untUtility;

{$R *.dfm}

constructor TfrmChartNew.Create(AOwner :TComponent; FormName :string);
var vQL,ChartFields :TStringList;
begin
  inherited Create(AOwner);

  self.Name := FormName;
  Attrs := TStringList.Create;
  AddAttrs(self.Name,Attrs);

  vTimerInterval := strtoint(Attrs.Values['TimerInterval']);
  vAutoRefresh := strtobool(Attrs.Values['TimerEnabled']);
  //ShowMessage(Attrs.Values['TimerInterval'] + '|' + Attrs.Values['TimerEnabled']);

  //Если необходимо строить наборы и все что с ними связано
  if strtobool(Attrs.Values['BuildQueries']) then begin
    vQL := TStringList.Create;
    BuildQueries(self,vQL);
    vMQry := TOraQuery(self.FindComponent(vQL.Strings[0]));

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

    vQL.Free;

  //BuildPopupMenu(pmnuMaster,vMQry);

  {if pmnuMaster.Items.Count > 0 then
    for i := 0 to pmnuMaster.Items.Count - 1 do begin
      pmnuMaster.Items[i].OnClick := MenuClick;
      if TActionMenuItem(pmnuMaster.Items[i]).GetButton <> nil then TActionMenuItem(pmnuMaster.Items[i]).GetButton.OnClick := MenuClick;
    end;}
  end;

  ChartFields := TStringList.Create;
  ParseStrIntoArray(Attrs.Values['ChartFields'],',',ChartFields);
  frMaster.SetFields(ChartFields.Values['SERIES'],ChartFields.Values['DT'],ChartFields.Values['VAL']);
  //ShowMEssage(ChartFields.Text);
  frMaster.SetQuery(vMQry);
  frMaster.ShowLegend(strtobool(Attrs.Values['ChartShowLegend']));

  frParams.ParamQuery := vPQry;
  //ShowMessage(frParams.ParamQuery.SQL.Text);
  frParams.BuildParams;
  if strtobool(Attrs.Values['PQueryAutoOpen']) then vMQry.Open;

  if vAutoRefresh and not tmrRefresh.Enabled then tmrRefresh.Enabled := true;
end;

procedure TfrmChartNew.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmChartNew.frDetailbtnExRepClick(Sender: TObject);
var i :integer;
    vParam :TComponent;
begin
  if vMQry.Active then vMQry.Close;
  if vMQry.Params.Count = 0 then begin
    vMQry.Open;
    Exit;
  end;

  for i := 0 to vMQry.Params.Count - 1 do begin
    vParam := frParams.scrlBox.FindComponent(vMQry.Params[i].Name);
    try
      if vParam.ClassName = 'TSelectEdt' then vMQry.Params[i].Value := TParamEdit(vParam).KeyVal
        else vMQry.Params[i].Value := TParamEdit(vParam).Text;
      //ShowMEssage(varToStr(TParamEdit(vParam).KeyVal));
      //ShowMEssage(vMQry.Params[i].AsString);
    except
      vMQry.Params[i].Value := TParamCheckBox(vParam).KeyVal;
    end;
  end;
  frMaster.BuildChart;
end;

procedure TfrmChartNew.tmrRefreshTimer(Sender: TObject);
begin
  if not self.Visible then exit;
  frParams.btnExRep.Click;
end;

end.
