//************************************************************//
//  PhoneBook 1.04 source code                                //
//  RonyaSoft  2004  All rights reserved                      //
//  url: www.ronyasoft.nm.ru                                  //
//************************************************************//
unit Progress;

interface

uses
  Windows, SysUtils, Classes, Forms, Dialogs, StdCtrls,
  DB, DBTables, Controls, ComCtrls, Registry,ShellApi, Messages, Graphics,
  ExtCtrls ;

const
   MM_BASE = WM_USER;
   MM_OKSTART = MM_BASE + $1;   // Файл данных наявний
   MM_DATAERROR = MM_BASE + $2;  // Файл данных выдсутній
   MM_KeyDown = MM_BASE + $3;
   MM_ENDTHREAD = MM_BASE + $4;

type
  TMainForm = class(TForm)
    ProgressBar1: TProgressBar;
    lbPersent: TLabel;
    Table2: TTable;
    Image1: TImage;
    Table1: TTable;
    Timer1: TTimer;
    lbMessage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ProgressAOM (var MSG: tagMSG; var Handled: boolean);
    procedure RegApplication;
    procedure DataError(var Message: TMessage); message MM_DATAERROR;
    procedure Timer1Timer(Sender: TObject);
    procedure EndThread(var Message:TMessage); message MM_ENDTHREAD;
  private
    IsCanStart: boolean;
    FStartTime: cardinal;
    function SearchFile(FileName: string): boolean;
  public
    { Public declarations }
  end;

  type EPhoneException = class (Exception);

var
  MainForm: TMainForm;
  tick: cardinal;
  IsFirst : boolean = true;
  
const
   sDataFile  = 'Data.dbf';
   sIndexFile  = 'Data.mdx';
   sBuffFile  = 'DataBuff.dbf';
   sBuffFile2  = 'DataBuff2.dbf';
   sShortappname = 'LutskPhone';
   sIniFile = 'options.ini';
   sHelpFile = 'help.hlp';

   sDataFileError = 'Помилка при роботі з базою данних Lutsk.dbf'+#10#13+
      'Перевірте наявність даного файлу!';

   sBDEError = 'Помилка роботи з BDE.'+ #10#13+' Можливо відсутні Dll - бібліотеки.'
      + #10 + #13+' Для вирішення проблеми спробуйте встановити BDE або Delphi6';

implementation

uses TelDov, Thread, ActiveX, ComObj, ShlObj;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
 mess: tagmsg;
 handled :boolean;
begin
 try
   IsCanStart := false;
   // FStartTime := $FFFFFFFF;
   // Application.HelpFile := sHelpFile;
   Top := (Screen.Height - Height) div 2-200;
   Left := (Screen.Width - Width) div 2;
   Application.OnMessage := ProgressAOM ;
   // создание ярлыка, запись в реестр
   // RegApplication;
   try
     Table1.TableName := sBuffFile;// Check BDE
     Table1.CreateTable;
     Table1.Close;
     // ShowMessage(DBIgetErrorString);
     DeleteFile(ExtractFilePath(ParamStr(0))+'/'+sBuffFile);
   except
     raise EPhoneException.Create(sBDEError); // error BDE
   end;
   if not SearchFile(sDataFile)
   then raise EPhoneException.Create(sDataFileError);
   if not SearchFile(sIndexFile)
   then DataThread.create(false)
   else IsCanStart := true;
  except
    on E: Exception do
    begin
      MessageDlg(e.Message, mtError, [mbOk],0);
      PostMessage(MainFOrm.Handle, MM_DATAERROR, 0, 0);
    end;
  end;
 //  FStartTime := GetTickCount;
 Invalidate;
end;

procedure TMainForm.ProgressAOM (var MSG: tagMSG; var Handled: boolean);
begin
  if MSG.message = MM_OKSTART then
  begin
    Timer1.Enabled := false;
    Application.CreateForm(TPhoneForm, PhoneForm);
    MainFOrm.Hide;
    PhoneForm.Show;
    Application.OnMessage := PhoneForm.AOM;
  end;
end;

function TMainForm.SearchFile(FileName: string): boolean;
var
 CurrFile : TSearchRec;
begin
 if FindFirst(GetCurrentDir +'\'+FileName, faAnyFile, CurrFIle)=0
 then Result := true
 else Result := false;
end;

procedure TMainForm.RegApplication;
var
  R: TRegIniFile;
  IsRegister: boolean; // Признак зареєстрованої програми
  Directory: string;
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  WFileNAme: WideString;
begin
  IsRegister := false;
  R := TRegIniFile.Create('');
  with R do
  begin
    RootKey := HKey_Current_User;
    if Openkey('Software\RonyaSoft\'+ sShortappname, true)
    then IsRegister := ReadBool('','Register',false);
    if not(IsRegister)
    then
     begin
        //Регіструєм
      DeleteKey('','(По умолчанию)');
      WriteBool('','Register',true);
        // Створюєм ярлик на робочому столі
      CloseKey;  // Закриваєм попередній ключ
      MyObject := CreateComObject(CLSID_ShellLink);
      MySLink := MyObject as IShellLink;
      MyPFile := MyObject as IPersistFile;
      with MySLink do
      begin
        SetPath(PChar(Application.exename));
        SetWorkingDirectory(PChar(ExtractFilePath(Application.exename)));
      end;
      OpenKey('Software\MicroSoft\Windows\CurrentVersion\Explorer', false);
      Directory := ReadString('Shell Folders','Desktop','');
      WFileNAme := Directory + '\' + sShortAppName +'.lnk';
      MyPFile.Save(PWChar(WFIleName), false);
    end;
  end;
  r.Free;
end;

procedure TMainForm.DataError(var Message: TMessage);
begin
  Close;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if IsFirst then
  begin
    IsFirst := false;
    FStartTime := 0; // GetTickCount;
  end;
  if IsCanStart then
  begin 
     Tick := GetTickCount;
    if Tick > (FStartTime + 0) // 1000
       then  PostMessage(MainFOrm.Handle, MM_OKSTART, 1, 0);
  end
end;

procedure TMainForm.EndThread(var Message: TMessage);
begin
  Image1.Visible := true;
  Caption := '';
  lbPersent.Visible := false;
  lbMessage.Visible := false;
  ProgressBar1.Visible := false;
  IsCanStart := true;
end;

end.
