//************************************************************//
//  PhoneBook 1.04 source code                                //
//  RonyaSoft  2004  All rights reserved                      //
//  url: www.ronyasoft.nm.ru                                  //
//************************************************************//
unit TElDov;

interface

uses
  Windows, SysUtils, Thread, Progress, ExtCtrls, ComCtrls, Menus,
  ToolWin, DBCtrls, ImgList, Classes, Controls, StdCtrls, Grids,
  DB, DBTables, DBGrids, Forms, Messages, Dialogs,Clipbrd;

type
  TPhoneForm = class(TForm)
    DataSource1: TDataSource;
    Table1: TTable;
    StatusBar1: TStatusBar;
    GroupBox1: TGroupBox;
    Search: TButton;
    ToolBar1: TToolBar;
    ExitButton: TToolButton;
    EraseButton: TToolButton;
    SearchButton: TToolButton;
    HelpButton: TToolButton;
    DBGrid1: TDBGrid;
    ImageList1: TImageList;
    SortButton: TToolButton;
    PopupMenu1: TPopupMenu;
    ImageList2: TImageList;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    PopupMenu2: TPopupMenu;
    DBNavigator1: TDBNavigator;
    procedure FormCreate(Sender: TObject);
    procedure SearchClick(Sender: TObject);
    procedure AOM(var Msg: tagMSG; var Handled: Boolean);
    procedure EraseButtonClick(Sender: TObject);
    procedure MyPopupHandler(Sender: TObject);
    procedure MyPopupHandler2(Sender: TObject);
    procedure MyEditPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MInMaxSize(var Message: TMessage); message WM_GETMINMAXINFO;
    procedure N20Click(Sender: TObject);
    procedure N13Click(Sender: TObject);
    procedure N14Click(Sender: TObject);
    procedure N15Click(Sender: TObject);
    procedure N16Click(Sender: TObject);
    procedure ExitButtonClick(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure CreatePopupFields;
    procedure UpdateStatusBar;
    procedure CalculateEditSize;
    procedure SortMode (Sender: tObject);
    procedure ReadIni;
    procedure WriteIni; // Ini-file
  public
  end;

var
  PhoneForm: TPhoneForm;
  Inputs : array [0..4] of TEdit;
  MyThread: DataThread;
  bool: boolean;
  ColumnIndex: integer;

const
  SortName : array[0..2] of string =('по Телефону','по Имени','по Улице');
  IndexName : array [0..2] of string =('ByNumTel','ByFamil','ByStreet');
  COPY_TO_CLIPBOARD = 'Копировать';
  PASTE_FROM_CLIPBOARD = 'Вставить';

function IndexOfItem(Item: string): integer;

implementation

uses IniFiles, DBITypes, DBIProcs, Graphics,ShellApi;
{$R *.dfm}

procedure TPhoneForm.FormCreate(Sender: TObject);
var i, j: integer;
    item : tMenuItem;
begin
  Table1.TableName := sDataFile;
  Table1.Open;
  CreatePopupFields;
  CalculateEditSize;
  UpDateStatusBar;
  ReadIni;
  Application.onMessage := Aom;
  Application.HelpFile := sHelpFile;
end;

procedure TPhoneForm.MyPopupHandler(Sender: TObject);
begin
  if Sender is TMenuItem then with (Sender as TMenuItem) do
  begin
    case tag of
      0..2: begin Table1.IndexName := IndexName[(Sender as TMenuItem).tag ];
                SortMode(Sender);
            end;
      4: Clipboard.AsText := DBGrid1.SelectedField.DisplayText;
    end;
    UpdateStatusBar;
  end;
end;                          

procedure TPhoneForm.CreatePopupFields;
var
    i: integer;
    MyPopupMenuItem : array [0..4] of TMenuItem;
    MenuItem: TMenuItem;
begin
    for i := 0 to 4 do  //Створення полей вводу
   begin
     Inputs[i] := TEdit.Create(self);
     Inputs[i].Parent := GroupBox1;
     Inputs[i].PopupMenu := PopupMenu2;
     Inputs[i].OnContextPopup := MyEditPopup;
     Inputs[i].Tag := i;
   end;
   for i := 0 to 4 do with PopupMenu1 do
   begin          //Створення меню сортування
     MyPopupMenuItem[i] := TMenuItem.Create(self);
     if i<3 then MyPopupMenuItem[i].Caption := SortName[i];
     MyPopupMenuItem[i].Tag := i;
     MyPopupMenuItem[i].OnClick := MyPopupHandler;
     PopupMenu1.Items.add(MyPopupMenuItem[i]);
   end;
     MyPopupMenuItem[3].Caption := '-';
     MyPopupMenuItem[4].Caption := COPY_TO_CLIPBOARD;
     MyPopupMenuItem[4].ShortCut := ShortCut(Word('C'), [ssCtrl]);
   PopupMenu1.Items[0].Checked := true;

     MenuItem := TMenuItem.Create(self);
     MenuItem.Caption := PASTE_FROM_CLIPBOARD;
     MenuItem.OnClick := MyPopupHandler2;
     PopupMenu2.Items.add(MenuItem);

   MyEditPopup(nil, Point(0,0), bool);
end;

procedure TPhoneForm.CalculateEditSize;
var
 i: integer;
 OffSet: integer;
begin
   offset :=13;      //Розміри полей вводу
   for i := 0 to 4 do
   begin
     Inputs[i].Left := Offset;
     Offset := Offset + DbGrid1.Columns[i].width + 8;
     Inputs[i].Width := DBGrid1.Columns[i].width;
     Inputs[i].Top := 24;
     Inputs[i].MaxLength :=Table1.Fields[i].Size;
   end;
end;

procedure TPhoneForm.UpdateStatusBar;
var SortMode: string;
begin
   statusBar1.Panels[0].Text := '   Найдено абонентов: '+ InttoStr(Table1.RecordCount);
   Sortmode := SortName[0];
   if PopupMenu1.Items[1].Checked then sortMode := SortName[1];
   if PopupMenu1.Items[2].Checked then sortMode := SortName[2];
   statusbar1.Panels[1].Text := '   Отсортировано: '+SortMode;
end;

procedure tPhoneForm.AOM(var Msg: tagMSG; var Handled: Boolean);
var key : word;
begin
  handled := false;
  if msg.message = Wm_keydown then
  begin                  // Обробка клавіш
    key := msg.wParam;
    handled := true;
    case key of                  // Обробка клавіш
      vk_up: SendMessage(DBGrid1.Handle,wm_keydown, vk_up, 0);
      vk_Down: SendMessage(DBGrid1.Handle,wm_keydown, vk_down, 0);
      vk_Prior: SendMessage(DBGrid1.Handle,wm_keydown, vk_Prior, 0);
      vk_Next: SendMessage(DBGrid1.Handle,wm_keydown, vk_Next, 0);
      vk_return: Search.OnClick(Search);
      vk_f8: EraseButton.Click;
      vk_f1: Application.HelpCommand(HELP_CONTENTS, 0);
      else handled := false;
    end;
  end;
end;

procedure TPhoneForm.SearchClick(Sender: TObject);
var
 filters: string;
 i: integer;
begin
  filters := '';
  for i:= 0 to 4 do //with table1 do
    begin
      if Inputs[i].Text <> ''
      then filters := filters + '('+Table1.Fields[i].FieldName + '='+ QuotedStr(Inputs[i].Text + '*')+ ') and';
    end;
     if filters <> '' then
     Filters := copy(Filters, 0, Length(filters)-4);
    table1.Filter := filters;
  UpdateStatusBar;
end;

procedure TPhoneForm.EraseButtonClick(Sender: TObject);
var
 i: integer;
begin
 for i := 0 to 4 do Inputs[i].Text := '';
end;

procedure TPhoneForm.SortMode (Sender: tObject);
var
 i: integer;
begin
 for i := 0 to 2 do
 PopupMenu1.Items[i].Checked := false;
 (sender as TMenuItem).Checked := true;
end;

procedure TPhoneForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   application.OnMessage := MainForm.progressAom;
   WriteIni;
   postMessage(MainForm.Handle, WM_CLOSE, 0, 0);
end;

procedure TPhoneForm.ReadIni;
begin
  with TIniFile.Create(ExtractFilePath(Application.exename)+sIniFile) do
  begin
    table1.IndexName := IndexName[ReadInteger('Defaults','SortIndex', 0)];
    Left := ReadInteger('Position','left', 100);
    top := ReadInteger('Position','top', 100);
    Height := ReadInteger('Position','height', 50);
  end;
end;

function IndexOfItem(Item: string): integer;
begin
  if Item = SortName[1] then result := 1
  else if Item = SortName[2] then result := 2
  else result := 0;
end;

procedure TPhoneForm.WriteIni;
begin
  with TIniFile.Create(ExtractFilePath(Application.exename)+sIniFile) do
  begin
    WriteInteger('Defaults','SortIndex', IndexOfItem(Table1.indexName));
    WriteInteger('Position','left', PhoneForm.left);
    WriteInteger('Position','top', PhoneForm.top);
    WriteInteger('Position','height', PhoneForm.height);
  end;
end;

procedure TPhoneForm.MInMaxSize(var Message: TMessage);
begin
  with TwmGetMinMaxInfo(Message) do
  begin
    MinMaxInfo.ptMaxTrackSize.X := PhoneForm.Width;
    MinMaxInfo.ptMaxTrackSize.y := Screen.Height- 100;
    MinMaxInfo.ptMinTrackSize.X := PhoneForm.Width;
    MinMaxInfo.ptMinTrackSize.y := 200;
  end;
end;

procedure TPhoneForm.MyPopupHandler2(Sender: TObject);
begin
 if Sender is TMenuItem then
   if Clipboard.HasFormat(CF_TEXT) then       // number of edit send by popupmenu2.tag
     Inputs[PopupMenu2.Tag].Text := Clipboard.AsText;
end;

procedure TPhoneForm.MyEditPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  PopupMenu2.Items[0].Enabled := Clipboard.HasFormat(CF_TEXT);
  if Sender is TEdit  then PopupMenu2.Tag := (Sender as TEdit).Tag
end;

procedure TPhoneForm.N20Click(Sender: TObject);
begin
  Application.HelpCommand(HELP_WM_HELP ,0);
end;

procedure TPhoneForm.N13Click(Sender: TObject);
begin
  Table1.First;
end;

procedure TPhoneForm.N14Click(Sender: TObject);
begin
  Table1.Prior;
end;

procedure TPhoneForm.N15Click(Sender: TObject);
begin
  Table1.Next;
end;

procedure TPhoneForm.N16Click(Sender: TObject);
begin
  Table1.Last;
end;

procedure TPhoneForm.ExitButtonClick(Sender: TObject);
begin
  Table1.Close;
  PhoneForm.Close;
end;

procedure TPhoneForm.SearchButtonClick(Sender: TObject);
begin
  Search.OnClick(Sender);
end;

procedure TPhoneForm.HelpButtonClick(Sender: TObject);
begin
  PostMessage(PhoneForm.handle, WM_KEYDOWN,  vk_f1, 0);
end;

procedure TPhoneForm.FormDestroy(Sender: TObject);
begin
  Application.HelpCommand(HELP_QUIT,0);
end;

end.
