unit untStartWindow;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, ComCtrls, StdCtrls;

type
  TfrmStartWindow = class(TForm)
    panProgress: TPanel;
    pBar: TProgressBar;
    Image1: TImage;
    labPBarCaption: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmStartWindow: TfrmStartWindow;

implementation

uses untU2SAdmin;

{$R *.dfm}

end.
