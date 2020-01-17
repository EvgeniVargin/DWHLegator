unit untBaseEdtChLBFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, untBaseChLBFrame, DB, Ora;

type
  TfrBaseEdtChLB = class(TFrame)
    panButtons: TPanel;
    panClient: TPanel;
    bbCancel: TBitBtn;
    bbSave: TBitBtn;
    frList: TfrBaseChLB;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    vQry :TOraQuery;
    vBegCheckedState :Array of boolean;
  public
    { Public declarations }
    procedure SetQry(inQry :TOraQuery);
    function  GetQry :TOraQuery;
    procedure SetList(inId,inName,inHeader :string; inHeaderVal :Array of variant);
    procedure SetBegCheckedState(i :integer; val :boolean);
    function GetBegCheckedState(i :integer) :boolean;
    function GetSaveEnabled :boolean;
    property BegCheckedState[i :integer] :boolean READ GetBegCheckedState WRITE SetBegCheckedState;
  end;

implementation

uses CheckLst;

{$R *.dfm}

procedure TfrBaseEdtChLB.SetBegCheckedState(i :integer; val :boolean);
begin
  vBegCheckedState[i] := val;
end;

function TfrBaseEdtChLB.GetBegCheckedState(i :integer) :boolean;
begin
  result := vBegCheckedState[i];
end;

procedure TfrBaseEdtChLB.SetList(inId,inName,inHeader :string; inHeaderVal :Array of variant);
var i :integer;
begin
  frList.SetList(inId,inName,inHeader,inHeaderVal);
  SetLength(vBegCheckedState,frList.chlbList.Items.Count);
  for i := 0 to frList.chlbList.Items.Count - 1 do SetBegCheckedState(i,frList.chlbList.Checked[i]);
end;

procedure TfrBaseEdtChLB.SetQry(inQry :TOraQuery);
begin
  vQry := inQry;
  frList.SetQry(vQry);
end;

function  TfrBaseEdtChLB.GetQry :TOraQuery;
begin
  result := vQry;
end;

function TfrBaseEdtChLB.GetSaveEnabled :boolean;
var i :integer;
begin
  result := false;
  with frList.chlbList do
      for i := 0 to Items.Count - 1 do
        begin
          result := not(Checked[i] = BegCheckedState[i]);
          if result then break;
        end;
end;

procedure TfrBaseEdtChLB.Timer1Timer(Sender: TObject);
begin
  bbSave.Enabled := GetSaveEnabled;
end;

end.
