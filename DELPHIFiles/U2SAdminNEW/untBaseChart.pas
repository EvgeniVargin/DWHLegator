unit untBaseChart;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, ExtCtrls, TeeProcs, TeEngine, Chart, DbChart, Ora, Series, DB,
  MemDS, DBAccess;

type
  TfrBaseChart = class(TFrame)
    Chart: TDBChart;
  private
    { Private declarations }
    Qry,SerQry :TOraQuery;
    FSerName,FLabName,FValName :string;
    ArrQry :Array of TOraQuery;
  public
    { Public declarations }
    constructor Create(AOwner :TComponent); override;
    procedure SetQuery(inQry :TOraQuery);
    function GetQuery :TOraQuery;
    procedure SetFields(inFSerName,inFLabName,inFValName :string);
    procedure SetChartName(inName :string);
    procedure ShowLegend(inShowLegend :boolean);
    procedure BuildChart;
  end;

implementation

{$R *.dfm}

constructor TfrBaseChart.Create(AOwner :TComponent);
begin
  inherited Create(AOwner);
  Chart.Title.Text.Clear;
  Chart.Legend.Visible := false;
  Chart.Legend.Alignment := laTop;
  SerQry := TOraQuery.Create(self);
  SetLength(ArrQry,1);
end;

procedure TfrBaseChart.ShowLegend(inShowLegend :boolean);
begin
  Chart.Legend.Visible := inShowLegend;
end;

procedure TfrBaseChart.SetChartName(inName :string);
begin
  Chart.Title.Text.Add(inName);
end;

procedure TfrBaseChart.SetQuery(inQry :TOraQuery);
begin
  Qry := TOraQuery(inQry);
end;

function TfrBaseChart.GetQuery :TOraQuery;
begin
  result := Qry;
end;

procedure TfrBaseChart.SetFields(inFSerName,inFLabName,inFValName :string);
begin
  FSerName := inFSerName;
  FLabName := inFLabName;
  FValName := inFValName;
end;

procedure TfrBaseChart.BuildChart;
var
  i :integer;
  Ser :TLineSeries;
begin
  if not(Qry.Active) then Qry.Open else Qry.Refresh;
  Chart.SeriesList.Clear;
  for i := 0 to length(ArrQry) - 1 do if Assigned(ArrQry[i]) and ArrQry[i].Active then ArrQry[i].Close;

  SetLength(ArrQry,0);
  SetLength(ArrQry,1);

  with SerQry do begin
    If Active then Close;
    Session := GetQuery.Session;
    SQL.Clear;
    SQL.Add('SELECT DISTINCT ' + FSerName + ' FROM (' );
    SQL.Add(GetQuery.SQL.Text);
    SQL.Add(')');
    Prepare;
    for i := 0 to SerQry.ParamCount - 1 do Params[i].Value := Qry.Params[i].Value;
    Open;
  end;

  if SerQry.RecordCount > 1 then SetLength(ArrQry,SerQry.RecordCount);
  SerQry.First;

  for i := 0 to length(ArrQry) - 1 do ArrQry[i] := TOraQuery.Create(self);

  while not(SerQry.Eof) do begin
    Ser := TLineSeries.Create(Chart);
    Ser.ParentChart := Chart;
    Ser.LinePen.Width := 3;
    with Ser do begin
      Title := SerQry.FieldByName(FSerName).AsString;
      //if not GetQuery.Prepared then GetQuery.Prepare;
      DataSource := ArrQry[SerQry.Recno - 1];
      TOraQuery(DataSource).Session := GetQuery.Session;
      TOraQuery(DataSource).SQL.Clear;
      TOraQuery(DataSource).SQL.Add('SELECT * FROM (');
      TOraQuery(DataSource).SQL.Add(GetQuery.SQL.Text);
      TOraQuery(DataSource).SQL.Add(') WHERE ' + FSerName + ' = ''' + SerQry.FieldByName(FSerName).AsString + '''');
      for i := 0 to TOraQuery(DataSource).ParamCount - 1 do TOraQuery(DataSource).Params[i].Value := Qry.Params[i].Value;
      TOraQuery(DataSource).Open;
      XLabelsSource := FLabName;
      XValues.ValueSource := FLabName;
      if TOraQuery(DataSource).FieldByName(FLabName).DataType in [ftDateTime,ftDate] then XValues.DateTime := true;
      YValues.ValueSource := FValName;
    end;
    Chart.AddSeries(Ser);
    SerQry.Next;
  end;
  Chart.Refresh;
  SerQry.Close;
  Qry.Close;
  if Chart.View3D then Chart.View3D := false;
end;

end.
