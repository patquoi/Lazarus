unit patience_f;

{$MODE Delphi}

//---------------------------------------------------------------------------
interface
//---------------------------------------------------------------------------
uses
  ComCtrls, SysUtils, Variants,
  Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls;
//---------------------------------------------------------------------------
type

  { TFormPatience }

  TFormPatience = class(TForm)
    Panel: TPanel;
    ProgressBar: TProgressBar;
    procedure FormCreate(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;
//---------------------------------------------------------------------------
var
  FormPatience: TFormPatience;
//---------------------------------------------------------------------------
implementation
//---------------------------------------------------------------------------
{$R *.lfm}
//---------------------------------------------------------------------------
procedure TFormPatience.FormCreate(Sender: TObject);
begin
DoubleBuffered:=True // Evite le scintillement
end;
//---------------------------------------------------------------------------
end.
