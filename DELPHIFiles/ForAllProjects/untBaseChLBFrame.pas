unit untBaseChLBFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, CheckLst, Ora;

type
  TfrBaseChLB = class(TFrame)
    chlbList: TCheckListBox;
  private
    { Private declarations }
    vQry :TOraQuery;
  public
    { Public declarations }
    procedure SetQry(inQry :TOraQuery);
    function  GetQry :TOraQuery;
    procedure SetList(inId,inName,inHeader :string; inHeaderVal :Array of variant);
  end;

implementation

{$R *.dfm}

procedure TfrBaseChLB.SetQry(inQry :TOraQuery);
begin
  vQry := inQry;
end;

function TfrBaseChLB.GetQry :TOraQuery;
begin
  result := vQry;
end;

procedure TfrBaseChLB.SetList(inId,inName,inHeader :string; inHeaderVal :Array of variant);
var i,j :integer;
begin
  vQry.First;
  while not(vQry.Eof) do
    begin
      i := chlbList.Items.Add(vQry.FieldByName(inName).AsString);
      chlbList.Checked[i] := vQry.FieldByName(inId).AsInteger = 1;
      if length(inHeaderVal) > 0 then
        for j := 0 to length(inHeaderVal) - 1 do
          if not(chlbList.Header[i]) then chlbList.Header[i] := vQry.FieldByName(inHeader).AsInteger = inHeaderVal[j];
      vQry.Next;
    end;
end;

end.
