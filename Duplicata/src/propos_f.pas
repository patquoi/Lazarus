unit propos_f;

{$MODE Delphi}

//---------------------------------------------------------------------------
interface
//---------------------------------------------------------------------------
uses
  SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls, StdCtrls;
//---------------------------------------------------------------------------
type
  TFormAPropos = class(TForm)
    Image: TImage;
    LabelVersionOmbre: TLabel;
    LabelVersion: TLabel;
    LabelSousVersion: TLabel;
    Timer: TTimer;
    Memo: TMemo;
    LabelWeb: TLabel;
    LabelEMail: TLabel;
    procedure AllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure LabelWebClick(Sender: TObject);
    procedure LabelEMailClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;
//---------------------------------------------------------------------------
var
  FormAPropos: TFormAPropos;
//---------------------------------------------------------------------------
implementation
//---------------------------------------------------------------------------
uses LCLIntf, main_f, base;
//---------------------------------------------------------------------------
{$R *.lfm}
//---------------------------------------------------------------------------
procedure TFormAPropos.AllClick(Sender: TObject);
begin
Close // v1.4.8
end;
//---------------------------------------------------------------------------
procedure TFormAPropos.FormCreate(Sender: TObject);
begin // v1.5.3
with Memo do
  begin
  Text:=StringReplace(Memo.Text, 'ODSx', stVersionDico, [rfReplaceAll]);
  // v1.8.4 : évite le caret en première position à l'affichage : on le planque
  SelStart:=Length(Memo.Lines.Text)-12;
  SelLength:=0;
  end
end;
//---------------------------------------------------------------------------
procedure TFormAPropos.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if (Key=112) and (Shift=[]) then // v1.5.2 : accès l'aide en ligne (F1)
  with FormMain do
    ActionInfosAideExecute(ActionInfosAide)
end;
//---------------------------------------------------------------------------
procedure TFormAPropos.FormKeyPress(Sender: TObject; var Key: Char);
begin
if (Key=#13) or (Key=#27) or (Key=#32) then ModalResult:=mrOk;
end;
//---------------------------------------------------------------------------
procedure TFormAPropos.LabelEMailClick(Sender: TObject);
begin
 OpenURL('mailto:'+LabelEMail.Caption);
end;
//---------------------------------------------------------------------------
procedure TFormAPropos.LabelWebClick(Sender: TObject);
begin
OpenURL('http://'+LabelWeb.Caption);
end;
//---------------------------------------------------------------------------
procedure TFormAPropos.TimerTimer(Sender: TObject);
begin
ModalResult:=mrOk
end;
//---------------------------------------------------------------------------
end.
