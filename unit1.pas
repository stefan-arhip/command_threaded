unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, PairSplitter, ComCtrls, EditBtn, Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    DirectoryEdit1: TDirectoryEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    ImageList1: TImageList;
    Memo1: TMemo;
    Memo2: TMemo;
    PairSplitter1: TPairSplitter;
    PairSplitterSide1: TPairSplitterSide;
    PairSplitterSide2: TPairSplitterSide;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  TCmdThread = Class(TThread)
    Command, WorkingDirectory: String;
    Procedure Execute; Override;
  End;

var
  Form1: TForm1;

implementation

{$R *.lfm}

Var ActiveThreads, MaxThreads: Integer;
    StartTime: Double;
    sL: TStringList;

Procedure RunCmd(Command: String; Var ResultList: TStringList);
Const READ_BYTES = 2048;
Var MemStream : TMemoryStream;
    OurProcess : TProcess;
    OurResult: TStringList;
    NumBytes : LongInt;
    BytesRead : LongInt;
Begin
  MemStream := TMemoryStream.Create;
  BytesRead := 0;

  OurProcess := TProcess.Create(Nil);
  OurProcess.Executable:= 'cmd.exe';
  OurProcess.Parameters.Add('/c');
  OurProcess.CurrentDirectory:= Form1.DirectoryEdit1.Directory;
  OurProcess.Parameters.Add(Command);

  //OurProcess.ShowWindow := swoHIDE;
  OurProcess.ShowWindow := swoShow;
  OurProcess.Options := [poUsePipes];
  OurProcess.Execute;
  While True Do
    Begin
      MemStream.SetSize(BytesRead + READ_BYTES);
      NumBytes := OurProcess.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
      If NumBytes > 0
        Then
          Inc(BytesRead, NumBytes)
        Else
          Break;
    End;
  MemStream.SetSize(BytesRead);
  OurResult:= TStringList.Create;;
  OurResult.LoadFromStream(MemStream);
  //ResultList.Assign(OurResult);
  ResultList.AddStrings(OurResult);
  OurProcess.Free;
  OurResult.Free;
  MemStream.Free;
end;

procedure TCmdThread.Execute;
Const READ_BYTES = 2048;
Var MemStream : TMemoryStream;
    OurProcess : TProcess;
    OurResult: TStringList;
    NumBytes : LongInt;
    BytesRead : LongInt;
Begin
  MemStream := TMemoryStream.Create;
  BytesRead := 0;

  OurProcess := TProcess.Create(Nil);
  OurProcess.Executable:= 'cmd.exe';
  OurProcess.Parameters.Add('/c');
  OurProcess.CurrentDirectory:= WorkingDirectory;
  OurProcess.Parameters.Add(Command);

  OurProcess.ShowWindow := swoHIDE;
  //OurProcess.ShowWindow := swoShow;
  OurProcess.Options := [poUsePipes];
  OurProcess.Execute;
  While True Do
    Begin
      MemStream.SetSize(BytesRead + READ_BYTES);
      NumBytes := OurProcess.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
      If NumBytes > 0
        Then
          Inc(BytesRead, NumBytes)
        Else
          Break;
    End;
  MemStream.SetSize(BytesRead);
  OurResult:= TStringList.Create;;
  OurResult.LoadFromStream(MemStream);
  //ResultList.Assign(OurResult);
  sL.AddStrings(OurResult);
  OurProcess.Free;
  OurResult.Free;
  MemStream.Free;

  Dec(ActiveThreads);
  //Form1.StatusBar1.Panels[0].Text:= Format('%d threads', [ActiveThreads]);
  //Form1.StatusBar1.Panels[1].Text:= Format('%f ms elapsed', [GetTickCount- StartTime]);
end;

{ TForm1 }

procedure TForm1.ToolButton1Click(Sender: TObject);
Var s: String;
begin
  StartTime:= Windows.GetTickCount;
  Form1.StatusBar1.Panels[0].Text:= '';
  Form1.StatusBar1.Panels[1].Text:= '';
  Form1.Memo2.Lines.Clear;
  sL.Clear;
  For s In Memo1.Lines Do
    RunCmd(s, sL);
  Form1.Memo2.Lines.AddStrings(sL);

  Form1.StatusBar1.Panels[0].Text:= '';
  Form1.StatusBar1.Panels[1].Text:= Format('%f ms elapsed', [GetTickCount- StartTime]);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.DirectoryEdit1.Directory:= ExcludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
end;

procedure TForm1.ToolButton2Click(Sender: TObject);
Var s: String;
    t: TCmdThread;
begin
  StartTime:= Windows.GetTickCount;
  Form1.Memo2.Lines.Clear;
  sL.Clear;
  ActiveThreads:= 0;
  MaxThreads:= 5;
  For s In Memo1.Lines Do
    Begin
      Application.ProcessMessages;
      //Sleep(2);
      If ActiveThreads< MaxThreads Then
        Begin
          t:= TCmdThread.Create(True);
          Inc(ActiveThreads);
          t.Command:= s;
          t.WorkingDirectory:= Form1.DirectoryEdit1.Directory;
          t.FreeOnTerminate:= True;

          //Form1.StatusBar1.Panels[0].Text:= Format('%d threads', [ActiveThreads]);
          //Form1.StatusBar1.Panels[1].Text:= Format('%f ms elapsed', [GetTickCount- StartTime]);

          t.Start;
        End;
    End;

  While ActiveThreads> 0 Do
    Begin
      Application.ProcessMessages;
      //Sleep(2);
    End;
  Form1.Memo2.Lines.AddStrings(sL);

  Form1.StatusBar1.Panels[0].Text:= '';
  Form1.StatusBar1.Panels[1].Text:= Format('%f ms elapsed', [GetTickCount- StartTime]);
end;

Initialization
  sL:= TStringList.Create;

Finalization
  sL.Free;

end.

