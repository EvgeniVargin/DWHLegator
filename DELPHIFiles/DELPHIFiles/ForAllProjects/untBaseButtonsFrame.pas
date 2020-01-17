unit untBaseButtonsFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, ComCtrls, ToolWin, ImgList, ExtCtrls;

type
  TfrButtons = class(TFrame)
    ImageList: TImageList;
    ControlBar1: TControlBar;
    ToolBar: TToolBar;
    btnAdd: TToolButton;
    btnEdt: TToolButton;
    btnRfr: TToolButton;
    btnDel: TToolButton;
    btnCopy: TToolButton;
    Separator1: TToolButton;
    DImageList: TImageList;
  private
    { Private declarations }
    //FQry :TADOQuery;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
