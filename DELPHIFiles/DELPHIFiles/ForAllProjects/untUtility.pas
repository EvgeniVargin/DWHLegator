unit untUtility;

interface

uses

  Windows,Messages, SysUtils, Variants, Classes, ComObj,Tlhelp32
 ,DBGridEh
 , Dialogs, ComCtrls, ExtCtrls, DBCtrls, Grids, StdCtrls,
  Graphics, StrUtils, DB, Masks, Ora, Registry;

  procedure ExpToExcel(Grid :TDBGridEh);
  function Calculate(SMyExpression: string; digits: Byte): string;
  function RGB(r, g, b: Byte): TColor;
  procedure ScanFiles(Dir :String; FileList :TStrings); overload;
  procedure ScanFiles(Dir :String; Mask :Array of String; FileList :TStrings); overload;
  procedure ScanFilesDbf(Dir :String; FileList :TStrings; IDFieldName :string); overload;
  procedure ScanFilesDbf(Dir :String; Mask :Array of String; FileList :TStrings; IDFieldName :string); overload;
  function ti_as_hms(Days :real) :string;
  procedure ChildGridFilter(MasterGrid,DetailGrid :TDBGridEh; MasterField,DetailField :string);
  function  FileVersion(AFileName: string): string;
  function  KillTask(ExeFileName: string): integer;
  procedure ParseStrIntoArray(inStr,inSeparator :string;inStringArray :TStringList);

implementation

procedure ChildGridFilter(MasterGrid,DetailGrid :TDBGridEh; MasterField,DetailField :string);
var
 i: Integer;
 s: string;
begin
  if MasterGrid.SelectedRows.Count>0 then
    begin
      s := '';
      with MasterGrid.DataSource.DataSet do
      for i:=0 to MasterGrid.SelectedRows.Count-1 do
        begin
          GotoBookmark(pointer(MasterGrid.SelectedRows.Items[i]));
          s:=s+','+Char(39)+FieldByName(MasterField).AsString+Char(39);
          with DetailGrid.DataSource.DataSet do
            begin
              if filtered then filtered := false;
              Filter := DetailField + ' IN (' + copy(s,2,length(s)-1) + ')';
              filtered := true;
            end;
        end;
    end;
end;

function ti_as_hms(Days :real) :string;
var h,m,s :integer;
    hh,mm,ss :string;
begin
  h := trunc(Days*24*60*60/3600);
  m := trunc((trunc(Days*24*60*60) mod 3600)/60);
  s := (trunc(Days*24*60*60) mod 3600) mod 60;

  hh := inttostr(h);
  if m < 10 then mm := '0' + inttostr(m) else mm := inttostr(m);
  if s < 10 then ss := '0' + inttostr(s) else ss := inttostr(s);

  result := hh + ':' + mm + ':' + ss;
end;

function RGB(r, g, b: Byte): TColor;
begin
  Result := r + g * 256 + b * 256 * 256;
end;

procedure ScanFiles(Dir :String; FileList :TStrings);
begin
  ScanFiles(Dir,['*.*'],FileList);
end;

procedure ScanFiles(Dir :string; Mask :array of string; FileList :TStrings);
var SR :TSearchRec;
    FindRes,i :Integer;
begin
  FindRes:=FindFirst(Dir+'*.*',faAnyFile,SR);
  While FindRes=0 do
  begin
    if ((SR.Attr and faDirectory)=faDirectory) and ((SR.Name='.')or(SR.Name='..')) then
      begin
        FindRes:=FindNext(SR);
        Continue;
      end;

    if ((SR.Attr and faDirectory)=faDirectory) then {если найден каталог, то}
      begin
        ScanFiles(Dir+SR.Name+'\',Mask,FileList); {входим в процедуру поиска с параметрами текущего каталога + каталог, что мы нашли}
        FindRes:=FindNext(SR); {после осмотра вложенного каталога мы продолжаем поиск в этом каталоге}
        Continue;
      end;

    for i := 0 to length(Mask) - 1 do
      if MatchesMask(SR.Name, Mask[i]) then FileList.Append(Dir + SR.Name);

    FindRes:=FindNext(SR);
  end;
  FindClose(SR);
end;

procedure ScanFilesDbf(Dir :String; FileList :TStrings; IDFieldName :string);
begin
  ScanFilesDbf(Dir,['*.*'],FileList,IDFieldName);
end;

procedure ScanFilesDbf(Dir :String; Mask :Array of String; FileList :TStrings; IDFieldName :string);
var SR :TSearchRec;
    FindRes,i :Integer;
begin
  FindRes:=FindFirst(Dir+'*.*',faAnyFile,SR);
  While FindRes=0 do
  begin
    if ((SR.Attr and faDirectory)=faDirectory) and ((SR.Name='.')or(SR.Name='..')) then
      begin
        FindRes:=FindNext(SR);
        Continue;
      end;

    if ((SR.Attr and faDirectory)=faDirectory) then {если найден каталог, то}
      begin
        ScanFilesDbf(Dir+SR.Name+'\',Mask,FileList,IDFieldName); {входим в процедуру поиска с параметрами текущего каталога + каталог, что мы нашли}
        FindRes:=FindNext(SR); {после осмотра вложенного каталога мы продолжаем поиск в этом каталоге}
        Continue;
      end;

    for i := 0 to length(Mask) - 1 do
      if MatchesMask(SR.Name, Mask[i]) then FileList.Append(Dir + SR.Name + '=' + IDFieldName);

    FindRes:=FindNext(SR);
  end;
  FindClose(SR);
end;

procedure ExpToExcel(Grid :TDBGridEh);
var
    ExcelApp, Workbook, Range, Cell1, Cell2, ArrayData  : Variant;
    BeginCol, BeginRow, i, j, RowCount, ColCount : integer;
begin
  // Создание Excel
  ExcelApp := CreateOleObject('Excel.Application');

  // Отключаем реакцию Excel на события,
  //чтобы ускорить вывод информации
  ExcelApp.Application.EnableEvents := false;

  //  Создаем Книгу (Workbook)
  // Если заполняем шаблон, то
  // Workbook := ExcelApp.WorkBooks.Add('C:\MyTemplate.xls');
  Workbook := ExcelApp.WorkBooks.Add;

  //Форматирование заголовков
  Range := Workbook.WorkSheets[1].Range[Workbook.WorkSheets[1].Cells[1,1],Workbook.WorkSheets[1].Cells[1,Grid.Columns.Count]];
  Range.Borders.LineStyle := 1;
  Range.Font.Bold := true;
  Range.Font.Color := clWhite;
  Range.Interior.Color := RGB(50, 110, 70);
  Range.Borders.Color := clWhite;

  //Заполнение заголовков
  for j:=1 to Grid.Columns.Count do
   if Grid.Columns.Items[j-1].Visible
     then Workbook.WorkSheets[1].Cells[1,j]:= Grid.Columns.Items[j-1].Title.Caption;

  // Координаты левого верхнего угла области,
  //в которую будем выводить данные
  BeginCol := 1;
  BeginRow := 2;

  //Фитчим все строки
  Grid.DataSource.DataSet.Last;
  Grid.DataSource.DataSet.First;

  // Размеры выводимого массива данных
  RowCount := Grid.DataSource.DataSet.RecordCount;
  ColCount := Grid.Columns.Count;


  // Создаем Вариантный Массив,
  //который заполним выходными данными
  ArrayData := VarArrayCreate([1, RowCount, 1, ColCount],varVariant);

  // Заполняем массив
  Grid.DataSource.DataSet.DisableControls;
  for I := 1 to RowCount do
    begin
      for J := 1 to ColCount do
        if Grid.Columns.Items[j-1].Visible then
          ArrayData[I, J] := Grid.Columns.Items[j-1].Field.asstring;
      Grid.DataSource.DataSet.Next;
    end;
  Grid.DataSource.DataSet.EnableControls;
  // Левая верхняя ячейка области,
  //в которую будем выводить данные
  Cell1 := WorkBook.WorkSheets[1].Cells[BeginRow, BeginCol];
  // Правая нижняя ячейка области,
  //в которую будем выводить данные
  Cell2 := WorkBook.WorkSheets[1].Cells[BeginRow  + RowCount - 1,
           BeginCol + ColCount - 1];

  // Область, в которую будем выводить данные
  Range := WorkBook.WorkSheets[1].Range[Cell1, Cell2];

  // А вот и сам вывод данных
  // Намного быстрее поячеечного присвоения
  Range.Value := ArrayData;

  //Подгоняем столбцы по ширине
  for j:=1 to Grid.Columns.Count do
    Workbook.WorkSheets[1].Columns[j].EntireColumn.AutoFit;

  // Делаем Excel видимым
  ExcelApp.Visible := true;
end;

function Calculate(SMyExpression: string; digits: Byte): string;
   // Calculate a simple expression
   // Supported are:  Real Numbers, parenthesis
var
   z: Char;
   ipos: Integer;

   function StrToReal(chaine: string): Real;
   var
     r: Real;
     Pos: Integer;
   begin
     Val(chaine, r, Pos);
     if Pos > 0 then Val(Copy(chaine, 1, Pos - 1), r, Pos);
     Result := r;
   end;

   function RealToStr(inreal: Extended; digits: Byte): string;
   var
     S: string;
   begin
     Str(inreal: 0: digits, S);
     realToStr := S;
   end;

   procedure NextChar;
   var
     s: string;
   begin
     if ipos > Length(SMyExpression) then
     begin
       z := #9;
       Exit;
     end
     else
     begin
       s := Copy(SMyExpression, ipos, 1);
       z := s[1];
       Inc(ipos);
     end;
     if z = ' ' then nextchar;
   end;

   function Expression: Real;
   var
     w: Real;

     function Factor: Real;
     var
       ws: string;
     begin
       Nextchar;
       if z in ['0'..'9'] then
       begin
         ws := '';
         repeat
           ws := ws + z;
           nextchar
         until not (z in ['0'..'9', '.']);
         Factor := StrToReal(ws);
       end
       else if z = '(' then
       begin
         Factor := Expression;
         nextchar
       end
       else if z = '+' then Factor := +Factor
       else if Z = '-' then Factor := -Factor;
     end;

     function Term: Real;
     var
       W: Real;
     begin
       W := Factor;
       while Z in ['*', '/'] do
         if z = '*' then w := w * Factor
       else
         w := w / Factor;
       Term := w;
     end;
   begin
     w := term;
     while z in ['+', '-'] do
       if z = '+' then w := w + term
     else
       w := w - term;
     Expression := w;
   end;
 begin
   ipos   := 1;
   Result := RealToStr(Expression, digits);
 end;

function FileVersion(AFileName: string): string;
var
  szName: array[0..255] of Char;
  P: Pointer;
  Value: Pointer;
  Len: UINT;
  GetTranslationString: string;
  FFileName: PChar;
  FValid: boolean;
  FSize: DWORD;
  FHandle: DWORD;
  FBuffer: PChar;
begin
  try
    FFileName := StrPCopy(StrAlloc(Length(AFileName) + 1), AFileName);
    FValid := False;
    FSize := GetFileVersionInfoSize(FFileName, FHandle);
    if FSize > 0 then
    try
      GetMem(FBuffer, FSize);
      FValid := GetFileVersionInfo(FFileName, FHandle, FSize, FBuffer);
    except
      FValid := False;
      raise;
    end;
    Result := '';
    if FValid then
      VerQueryValue(FBuffer, '\VarFileInfo\Translation', p, Len)
    else
      p := nil;
    if P <> nil then
      GetTranslationString := IntToHex(MakeLong(HiWord(Longint(P^)),
        LoWord(Longint(P^))), 8);
    if FValid then
    begin
      StrPCopy(szName, '\StringFileInfo\' + GetTranslationString +
        '\FileVersion');
      if VerQueryValue(FBuffer, szName, Value, Len) then
        Result := StrPas(PChar(Value));
    end;
  finally
    try
      if FBuffer <> nil then
        FreeMem(FBuffer, FSize);
    except
    end;
    try
      StrDispose(FFileName);
    except
    end;
  end;
end;

function KillTask(ExeFileName: string): integer;

const PROCESS_TERMINATE=$0001;

var ContinueLoop: BOOL;
    FSnapshotHandle: THandle;
    FProcessEntry32: TProcessEntry32;

begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle,FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName))
        or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName)))
    then
      Result := Integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0),
                                                     FProcessEntry32.th32ProcessID), 0));
      ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure ParseStrIntoArray(inStr,inSeparator :string; inStringArray :TStringList);
var
  i :integer;
  buff :string;
begin
  buff := '';
  for i := 0 to length(inStr) do begin
    if (InStr[i+1] = inSeparator) or (i = length(inStr)) then begin
      inStringArray.Add(Buff + '=' + Buff);
      Buff := '';
    end else Buff := Buff + InStr[i+1];
  end;
end;

end.
