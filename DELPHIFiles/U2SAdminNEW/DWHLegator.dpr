program DWHLegator;

uses
  Forms,
  untBaseButtonsFrame in '..\ForAllProjects\untBaseButtonsFrame.pas' {frButtons: TFrame},
  untBaseFrame in '..\ForAllProjects\untBaseFrame.pas' {frBase: TFrame},
  untBaseLookupForm in '..\ForAllProjects\untBaseLookupForm.pas' {frmBaseLookupForm},
  untBaseMainForm in '..\ForAllProjects\untBaseMainForm.pas' {frmBaseMainForm},
  untU2SAdmin in 'untU2SAdmin.pas' {frmU2SAdmin},
  untSignCalc in 'untSignCalc.pas' {frmSignCalc},
  untUtility in '..\ForAllProjects\untUtility.pas',
  untBaseSQLTreeFrame in '..\ForAllProjects\untBaseSQLTreeFrame.pas' {frBaseSQLTree: TFrame},
  untStarExpand in 'untStarExpand.pas' {frmStarExpand},
  untBasePCEFrame in '..\ForAllProjects\untBasePCEFrame.pas' {frPCEBase: TFrame},
  untBasePCSQLTreeFrame in '..\ForAllProjects\untBasePCSQLTreeFrame.pas' {frPCSQLTree: TFrame},
  untBaseEdtCLOB in '..\ForAllProjects\untBaseEdtCLOB.pas' {frmBaseEdtCLOB},
  untBasePCEdtNew in '..\ForAllProjects\untBasePCEdtNew.pas' {frmBasePCEdtNew},
  untBaseTreeEdtNew in '..\ForAllProjects\untBaseTreeEdtNew.pas' {frmBaseTreeEdtNew},
  untRegistry in 'untRegistry.pas',
  untBaseMasterDetailNew in '..\ForAllProjects\untBaseMasterDetailNew.pas' {frmBaseMasterDetailNew},
  untDoubleViewerNew in 'untDoubleViewerNew.pas' {frmDoubleViewerNew},
  untMasterDTreeNew in 'untMasterDTreeNew.pas' {frmMasterDTreeNew},
  untMTreeDetailNew in 'untMTreeDetailNew.pas' {frmMTreeDetailNew},
  untDependencyNew in 'untDependencyNew.pas' {frmDependencyNew},
  untStartWindow in 'untStartWindow.pas' {frmStartWindow},
  untViewerNew in 'untViewerNew.pas' {frmViewerNew},
  untBaseRepParamsFrame in 'untBaseRepParamsFrame.pas' {frBaseRepParams: TFrame},
  untBaseDateTimeForm in 'untBaseDateTimeForm.pas' {frmDateTime},
  untBaseSelectForm in 'untBaseSelectForm.pas' {frmSelect},
  untReportsNew in 'untReportsNew.pas' {frmReportsNew},
  untSignsNew in 'untSignsNew.pas' {frmSignsNew},
  untReportResultNew in 'untReportResultNew.pas' {frmReportResultNew},
  untMasterDetailCommentEditor in 'untMasterDetailCommentEditor.pas' {frmMasterDetailCommentEditor},
  untChartNew in 'untChartNew.pas' {frmChartNew},
  untBaseChart in 'untBaseChart.pas' {frBaseChart: TFrame},
  untBaseParFrame in '..\ForAllProjects\untBaseParFrame.pas' {frBaseParFrame: TFrame},
  untPMasterDetailNew in 'untPMasterDetailNew.pas' {frmPMasterDetailNew},
  untUploads in 'untUploads.pas' {frmUploads};

{$R *.res}

begin
  try
    KillTask('DWHLegator_launcher.exe');
  except
  end;
  Application.Initialize;
  Application.Title := 'Администрирование доступа к отчетности';
  frmStartWindow := TfrmStartWindow.Create(Application);
  Application.CreateForm(TfrmU2SAdmin, frmU2SAdmin);
  with frmStartWindow do begin
    Hide;
    Free;
  end;
  Application.Run;
end.
