unit untBaseDateTimeForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls;

type
  TfrmDateTime = class(TForm)
    MonthCalendar: TMonthCalendar;
    procedure MonthCalendarDblClick(Sender: TObject);
    function  GetDateTime :TDateTime;
    procedure SetDateTime(DateTime :TDateTime);
  private
    { Private declarations }
    vDateTime :TDateTime;
    Mouse :TMouse;
    Screen :TScreen;
  public
    { Public declarations }
    constructor Create(Sender :TComponent); override;
    property DateTime :TDateTime READ GetDateTime WRITE SetDateTime;
  end;

var
  frmDateTime: TfrmDateTime;

implementation

uses untBaseRepParamsFrame;

{$R *.dfm}

constructor TfrmDateTime.Create(Sender :Tcomponent);
begin
  inherited;
  self.Width := MonthCalendar.Width;
  self.Height := MonthCalendar.Height;
  if Screen.Height - Mouse.CursorPos.Y < self.Height then
    self.Top := Mouse.CursorPos.Y - Self.Height else self.Top := Mouse.CursorPos.Y;
  if Mouse.CursorPos.X < self.Width then
    self.Left := Mouse.CursorPos.X else self.Left := Mouse.CursorPos.X - self.Width;
  self.BorderStyle := bsNone;
end;

function  TfrmDateTime.GetDateTime :TDateTime;
begin
  result := vDateTime;
end;

procedure TfrmDateTime.SetDateTime(DateTime :TDateTime);
begin
  vDateTime := DateTime;
  MonthCalendar.Date := vDateTime;
end;

procedure TfrmDateTime.MonthCalendarDblClick(Sender: TObject);
begin
  TDTPEdit(Owner).Text := DateToStr(TMonthCalendar(Sender).Date);
  TDTPEdit(Owner).KeyVal := DateToStr(TMonthCalendar(Sender).Date);
  Close;
end;

end.
