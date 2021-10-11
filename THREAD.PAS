//************************************************************//
//  PhoneBook 1.04 source code                                //
//  RonyaSoft  2004  All rights reserved                      //
//  url: www.ronyasoft.nm.ru                                  //
//************************************************************//
unit Thread;

interface

uses
  Classes, Windows, sysUtils, Progress, forms, dialogs;

type
  DataThread = class(TThread)
  private
    procedure RemaskMDX;
  protected
    TempDir: PChar;
    procedure Execute; override;
    procedure UpdateProgress;
    procedure UpdateForm;
  end;

implementation

procedure DataThread.Execute;
var
    i, j: integer;
   prom: string;
begin
  freeOnTerminate := true;
  with MainForm do begin
    try
      Synchronize(UpdateForm);
      GetMem(TempDir, MAX_PATH);
      GetTempPath(MAx_Path,TempDir);
      CopyFile(PChar(ExtractFilePath(Application.ExeName)+sDataFile),
         PCHar(TempDir + sBuffFile2), true );        // переписуєм старий файл
      RemaskMDX;
      Table2.TableName := TempDir + sDataFile;
      Table1.TableName := TempDir + sBuffFile;
      Table1.Open;
      Table2.CreateTable;
      Table2.Open;
      Table2.Edit;
      j := 0;
      while not Table1.eof do
      begin
       for i:= 0 to Table1.FieldCount - 1 do
        begin
         prom := Table1.Fields[i].asString;
         // While pos('I',prom) <> 0 do
         //  prom[pos('I',prom)] := chr(178);
         // While pos(chr(73),prom) <> 0 do
         //  prom[pos(chr(73),prom)] := chr(178);
         // Table2.Fields[i].AsString := prom;
         Table2.Fields[i].AsString := Table1.Fields[i].asString;
        end;
        Table1.next;
        Table2.Append;
        Inc(j);
        If j > 1000 then
        begin
          SynchroNize(UpdateProgress);
          j := 0;
        end;
      end;
      Table1.Close;
      Table2.Close;

      CopyFile(PChar(TempDir + sDataFile),
      PChar(ExtractFilePath(Application.ExeName)+ sDataFile), false ); // копіюєм новий дата файл
      CopyFile(PChar(TempDir + sIndexFile),
      PChar(ExtractFilePath(Application.ExeName)+ sIndexFile), false ); // копіюєм новий індекс файл
      DeleteFile(TempDir + sBuffFile);
      DeleteFile(TempDir + sBuffFile2);
      DeleteFile(TempDir + sDataFile);
      DeleteFile(TempDir + sIndexFile);
      FreeMem(TempDir, MAX_PATH);

      PostMessage(MainFOrm.Handle, MM_ENDTHREAD, 0, 0);
    except
       on e: exception do PostMessage(MainFOrm.Handle, MM_DATAERROR, StrToInt(e.Message), 0)
    end;
  end;
end;

procedure DataThread.UpdateProgress;
var Persent: integer;
begin
  with MainFOrm do
  begin
    Persent := trunc(100*(Table1.RecNo/Table1.RecordCount));
    progressBar1.Position := Persent;
    lbPersent.Caption := InttoStr (Persent)+ ' %';
  end;
end;


procedure DataThread.RemaskMDX;
var
  OldFile, NewFile: tFileStream;
  Buffer : byte;
const index = 28;
begin
  OldFile := TFileStream.Create(TempDir + sBuffFIle2, fmOpenRead or fmShareDenyWrite);
  try
    NewFile := TFileStream.Create( TempDir + sBuffFile,fmCreate or fmOpenWrite);
    try
      NewFile.CopyFrom(OldFile ,OldFile.Size);
      NewFile.Position := index;
      Buffer := 0;
      NewFile.Write(Buffer, 1);
    finally
      FreeAndNil(NewFile);
    end;
  finally
    FreeAndNil(OldFile);
  end;
end;

procedure DataThread.UpdateForm;
begin
  with MainFOrm do
  begin
    Image1.Visible := false;
    ProgressBar1.Visible := true;
    LbPersent.Visible := true;
    lbMessage.Visible := true;
  end;
end;

end.
