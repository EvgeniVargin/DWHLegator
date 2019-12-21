unit untBaseParFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, untBaseFrame, ExtCtrls, untBaseRepParamsFrame, Ora, DB;

type
  TfrBaseParFrame = class(TFrame)
    frListParams: TfrBaseRepParams;
    Splitter1: TSplitter;
    frList: TfrBase;
    procedure SetParamQry(Qry :TOraQuery);
    function GetParamQry :TOraQuery;
    procedure SetListQry(Qry :TOraQuery);
    function GetListQry :TOraQuery;
    procedure frListParamsbtnExRepClick(Sender: TObject);
  private
    { Private declarations }
    PQry,LQry :TOraQuery;
    vLDS :TDataSource;
    vDataSource :TDataSource;
    vCheckBoxFields :array of string;
  public
    { Public declarations }
    property ListQry :TOraQuery READ GetListQry WRITE SetListQry;
    property ParamQry :TOraQuery READ GetParamQry WRITE SetParamQry;
    procedure SetDataSource(inDataSource :TDataSource);
    procedure BuildParams;
  end;

implementation

{$R *.dfm}

procedure TfrBaseParFrame.SetParamQry(Qry :TOraQuery);
begin
  PQry := Qry;
  frListParams.ParamQuery := Qry;
end;

function TfrBaseParFrame.GetParamQry :TOraQuery;
begin
  result := PQry;
end;

procedure TfrBaseParFrame.SetListQry(Qry :TOraQuery);
begin
  LQry := Qry;
end;

function TfrBaseParFrame.GetListQry :TOraQuery;
begin
  result := LQry;
end;

procedure TfrBaseParFrame.frListParamsbtnExRepClick(Sender: TObject);
var i :integer;
    vParam :TComponent;
begin
  if ListQry.Params.Count > 0 then
    for i := 0 to ListQry.Params.Count - 1 do begin
      vParam := frListParams.scrlBox.FindComponent(ListQry.Params[i].Name);
      try
        if vParam.ClassName = 'TSelectEdt' then ListQry.Params[i].Value := TParamEdit(vParam).KeyVal
          else ListQry.Params[i].Value := TParamEdit(vParam).Text;
      except
        ListQry.Params[i].Value := TParamCheckBox(vParam).KeyVal;
      end;
    end;

  if ListQry.Active then ListQry.Refresh else ListQry.Open;
end;

procedure TfrBaseParFrame.BuildParams;
begin
  frListParams.BuildParams;
end;

procedure TfrBaseParFrame.SetDataSource(inDataSource :TDataSource);
begin
  vDataSource := inDataSource;
  frList.SetDataSource(vDataSource);
  frList.DrawCheckBoxes(vCheckBoxFields);
end;

end.
