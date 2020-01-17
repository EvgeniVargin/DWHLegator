unit untReportResultNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untBaseFrame, Ora, ExtCtrls;

type
  TfrmReportResultNew = class(TForm)
    frMaster: TfrBase;
    tmrReportResult: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrReportResultTimer(Sender: TObject);
  private
    { Private declarations }
    vReportName :string;
  public
    { Public declarations }
    Attrs :TStringList;
    vQry :TOraQuery;
    vDS :TOraDataSource;
    inProgress :boolean;
    vBegDt :TDateTime;
    constructor Create(AOwner :TComponent; FormName :string);
    property ReportName :string READ vReportName WRITE vReportName;
    function GetQuery :TOraQuery;
  end;

var
  frmReportResultNew: TfrmReportResultNew;

implementation

uses untRegistry, untUtility;

{$R *.dfm}

constructor TfrmReportResultNew.Create(AOwner :TComponent; FormName :string);
begin
  inherited Create(AOwner);
  Randomize;
  self.Name := 'frmREP' + FormName + '_' + inttostr(Random(1024));
  vQry := CreateQueryByID(self,FormName);
  //vQry.Debug := true;
  vDS := TOraDataSource(self.FindComponent(vQry.Name + 'DS'));//CreateDataSource(vQry);
  vBegDt := Now;
  inProgress := true;

  frMaster.DrawCheckBoxes([]);
  //frMaster.
  frMaster.SetDataSource(vDS);
end;

function TfrmReportResultNew.GetQuery :TOraQuery;
begin
  result := vQry;
end;

procedure TfrmReportResultNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmReportResultNew.tmrReportResultTimer(Sender: TObject);
begin
  if inProgress then self.Caption := ti_as_hms(Now - vBegDt) + ' - выполнение отчета "' + self.ReportName + '"'
    else begin
           self.Caption := 'Отчет: ' + self.ReportName + ' (время выполнения ' + ti_as_hms(Now - vBegDt) + ')';
           tmrReportResult.Enabled := false;
         end;
end;

end.
