unit fdmatch_f;

{$MODE Delphi}

//---------------------------------------------------------------------------
interface
//---------------------------------------------------------------------------
uses
  SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ComCtrls, RichMemo, RichMemoHelpers, base;
//---------------------------------------------------------------------------
type
  TFormFeuilleMatch = class(TForm)
    StatusBar: TStatusBar;
    RichMemo: TRichMemo;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    procedure InitialisePartie;
    procedure AjouteLigne(stMotPrp : String;
                          const XPrp, YPrp : TCoordonnee;
                          const dPrp : TDirection;
                          const ChevaletPrp : TChevalet;
                          const DebutPrp, FinPrp : TOrdreJetonChevalet;
                          stMotSol : String;
                          const XSol, YSol : TCoordonnee;
                          const dSol : TDirection;
                          const ChevaletSol : TChevalet;
                          const DebutSol, FinSol : TOrdreJetonChevalet);
    function FormatLettreMotPrincipal(const Tour : Integer; const Cible : TCibleStats; const iLettre : Integer;
                                      var Lettre : Char; var Style : TFontStyles; var Bonus : TBonus;
                                      var SubstitutJoker : Boolean) : Boolean; // v1.5.6 : ajout de var SubstitutJoker : Boolean
    function FormatLettreTirage(const Tour : Integer; const iLettre : Integer; var Lettre : Char; var Style : TFontStyles) : Boolean;
    procedure AjusteHauteur;
    procedure CalculeLargeurMax; // v1.6.5
    procedure InverseCouleurTexte; // v1.5
  end;
//---------------------------------------------------------------------------
const
  LargeurClientFdMMin : Integer = 475; // v1.4. v1.6.5 : Selon la version large ou étroite comme l'en-tête ci-dessous. v1.8.3 : une seule taille
  // 1.6.5 En-tête plus étroite : les totaux sont calculés à la fin
  stEntete : array [0..1] of String       = ('Tour Tirage  Pos Proposition     Pos Solution        Score/Joué/Top',
                                             '-------------------------------------------------------------------');
  stFormatLigneStatut                     =  'Cumuls Score/Joué/Top : %4d %4d %4d'; // v1.6.5 (pour ligne de statut). vLaz : impossible d'aligner les totaux avec le mémo
//---------------------------------------------------------------------------
var
  FormFeuilleMatch: TFormFeuilleMatch;
//---------------------------------------------------------------------------
implementation
//---------------------------------------------------------------------------
uses Math, LCLType, StrUtils, main_f, tirage_f;
//---------------------------------------------------------------------------
{$R *.lfm}
//---------------------------------------------------------------------------
const
  // v1.6.3 : ci-dessous : indicateur '*' pour un top trouvé à gauche du score (%1s%4d)
  stFormatLigne = '%3d. %-7s %-3s %-15s %-3s %-15s%1s%4d %4d %4d';
  iDebutTirage  = 4;
  iDebutPartie  = 67; // v1.4
  iDebutMot     : array [TCibleStats] of Integer = (16, 36);
  iDebutScore   : array [TCibleStats] of Integer = (52, 57);
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.FormCreate(Sender: TObject);
begin // v1.4
Self.AutoAdjustLayout(lapAutoAdjustForDPI, 96, Screen.PixelsPerInch, Self.Width, ScaleX(Self.Width, 96)); // v1.8.3
if (Screen.Width<800) or
   (Screen.Height<600) then
  begin
  FormMain.AfficheMessage(stResolutionMinimale, stResolution, MB_ICONEXCLAMATION);
  Application.Terminate
  end;

// v1.6.5 : Contraintes de largeur déplacée dans FormShow à cause de la version fichier
//ClientWidth:=LargeurClientFdMMin;
//Constraints.MaxWidth:=Width;
//FLargeur:=LargeurParDefaut; // Par défaut mais modifiée dans FormShow
if FormTirage<>nil then
  Height:=FormMain.Height-FormTirage.Height;
Canvas.Font:=RichMemo.Font;
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.FormHide(Sender: TObject);
begin
FormMain.ActionAffichageFeuilleMatch.Checked:=False;
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.FormKeyPress(Sender: TObject; var Key: Char);
begin // v1.4.1
// Cas du choix de placement : on envoie la saisie au plateau de jeu (touche '+' ou saisie en cours)
if FormMain.ReflexionEnCours and
   (FormMain.ChoixPoseClavierEnCours or (Key='+') or (Key='#')) then // v1.5.2 : ajout de '#' (test placement)
  begin
  FormMain.FormKeyPress(Self, Key);
  Exit
  end;
// Gestion du chevalet au clavier : on envoie la saisie au chevalet
if ((Key>='0') and (Key<=IntToStr(NbMaxJetonsTirage)[1])) or (Key='*') then // v1.5.9 : on remplace '7' par IntToStr(NbMaxJetonsTirage)
  if (FormTirage<>nil) and FormTirage.Visible then
    with FormTirage do
      begin
      SetFocus;
      FormKeyPress(Self, Key);
      Exit
      end
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.FormShow(Sender: TObject);
begin
FormMain.ActionAffichageFeuilleMatch.Checked:=True;
CalculeLargeurMax;
if DeltaHeight=0 then // v1.8.3 (définition unique de DeltaHeight pendant que FormMain.Top est... au top même si c'est pas top :^/)
  DeltaHeight:=FormMain.Top+8;
Top:=FormTirage.Top+FormTirage.Height+DeltaHeight; // vLaz (DeltaHeight)
Left:=FormMain.Left+FormMain.Width;
Height:=FormMain.Height-FormTirage.Height-DeltaHeight; // v1.8.3 (DeltaHeight)
AjusteHauteur
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.InitialisePartie;
begin
CalculeLargeurMax; // v1.6.5
with RichMemo.Lines do
  begin
  Clear;
  Add(stEntete[0]);
  Add(stEntete[1]);
  end;
with RichMemo do // v1.8.3 en mode haute résolution (Screen.PixelsPerInch>96)
  begin
  SelStart:=0;
  SelLength:=Length(RichMemo.Lines.Text);
  SelAttributes.Color:=Font.Color;
  SelStart:=0;
  SelLength:=0;
  end;
StatusBar.SimpleText:='' // v1.6.5
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.AjouteLigne(stMotPrp : String;
                                        const XPrp, YPrp : TCoordonnee;
                                        const dPrp : TDirection;
                                        const ChevaletPrp : TChevalet;
                                        const DebutPrp, FinPrp : TOrdreJetonChevalet;
                                        stMotSol : String;
                                        const XSol, YSol : TCoordonnee;
                                        const dSol : TDirection;
                                        const ChevaletSol : TChevalet;
                                        const DebutSol, FinSol : TOrdreJetonChevalet);
var i,
    iDebutMotPrp,
    iDebutMotSol,
    iDebutDrnLigne,
    ScorePrp, ScoreSol,
    CumulPrp, CumulSol,
    NbJetonsPlaces,
    Diminution          : Integer;
    iChevalet           : TOrdreJetonChevalet;
    Style               : TFontStyles;
    stTirage            : String;
begin
// A. PROPOSITION
// A0.On enregistre les coordonnées
p.EnregistreProposition(XPrp, YPrp, dPrp);
iDebutMotPrp:=0; ScorePrp:=0;
if (Length(stMotPrp)>0) and (dPrp>dIndefinie) then
  begin // A1.On cherche le début du mot principal relativement à la case départ
  while CoordonneesValides(XPrp+(iDebutMotPrp-1)*dx[dPrp],
                           YPrp+(iDebutMotPrp-1)*dy[dPrp]) and
        (p.c[XPrp+(iDebutMotPrp-1)*dx[dPrp],
             YPrp+(iDebutMotPrp-1)*dy[dPrp]]>0) do
    Dec(iDebutMotPrp);
  // A2.On calcule les points
  ScorePrp:=p.ScorePose(XPrp, YPrp, dPrp,
                        ChevaletPrp,
                        DebutPrp,
                        FinPrp)
  end;
CumulPrp:=ScorePrp+
          IfThen(p.Tour>Low(TTour),
                 p.Cumul[Pred(p.Tour)],
                 0);
// A3.On remplace les jokers par un '?' dans le tirage
stTirage:=p.stTirage[p.Tour];
for i:=1 to Length(stTirage) do
  if (p.t[i]>0) and
     (stTirage[i]=stLettreJeton[tjJoker]) then
    stTirage[i]:=stJoker;

// A4.On met en minuscule les jokers posés (mais pas ceux qui sont déjà posés)
iChevalet:=DebutPrp;
for i:=0 to Length(stMotPrp)-1 do
  if p.c[XPrp+(i+iDebutMotPrp)*dx[dPrp],
         YPrp+(i+iDebutMotPrp)*dy[dPrp]]=0 then
    begin
    while ChevaletPrp[iChevalet]=0 do Inc(iChevalet);
    if (TypeJeton[ChevaletPrp[iChevalet]]=tjJoker) then
      stMotPrp[i+1]:=Chr(Ord(stMotPrp[i+1])+Ord('a')-Ord('A'));
    Inc(iChevalet);
    end{if};

// B. PROPOSITION
// B1.On cherche le début du mot principal relativement à la case départ
iDebutMotSol:=0;
while CoordonneesValides(XSol+(iDebutMotSol-1)*dx[dSol],
                         YSol+(iDebutMotSol-1)*dy[dSol]) and
      (p.c[XSol+(iDebutMotSol-1)*dx[dSol],
           YSol+(iDebutMotSol-1)*dy[dSol]]>0) do
 Dec(iDebutMotSol);

// B2.On calcule les points
ScoreSol:=p.ScorePose(XSol, YSol, dSol,
                      ChevaletSol,
                      DebutSol,
                      FinSol);
CumulSol:=ScoreSol+
          IfThen(p.Tour>Low(TTour),
              p.CumulPartie[Pred(p.Tour)], // v1.4 (CumulPartie)
              0);

// B3.On remplace les jokers par un '?' dans le tirage
stTirage:=p.stTirage[p.Tour];
for i:=1 to Length(stTirage) do
  if (p.t[i]>0) and
     (stTirage[i]=stLettreJeton[tjJoker]) then
    stTirage[i]:=stJoker;

// B4.On met en minuscule les jokers posés (mais pas ceux qui sont déjà posés)
iChevalet:=DebutSol;
for i:=0 to Length(stMotSol)-1 do
  if p.c[XSol+(i+iDebutMotSol)*dx[dSol],
         YSol+(i+iDebutMotSol)*dy[dSol]]=0 then
    begin
    while ChevaletSol[iChevalet]=0 do Inc(iChevalet);
    if (TypeJeton[ChevaletSol[iChevalet]]=tjJoker) then
      stMotSol[i+1]:=Chr(Ord(stMotSol[i+1])+Ord('a')-Ord('A'));
    Inc(iChevalet);
    end{if};

iDebutDrnLigne:=Length(RichMemo.Lines.Text); // v1.5

// C. On ajoute la ligne sur la feuille de match
  // v1.8.3 : plus qu'une seule version de feuille de match. Parties antérieures à v1.4 non supportées
RichMemo.Lines.Add(Format(stFormatLigne, [p.Tour,
                                          stTirage,
                                          IfThen(stMotPrp='','',p.stCoordonnees(XPrp, YPrp, dPrp)), // v1.10.1 : on n'affiche pas de position de proposition en mode démo
                                          stMotPrp,
                                          p.stCoordonnees(XSol, YSol, dSol),
                                          stMotSol,
                                          stTopTrouve[(p.VersionFichier >= $163) and (ScorePrp=p.ScoreTop[p.Tour])], // v1.6.3 : indicateur de top trouvé
                                          ScorePrp, ScoreSol, p.ScoreTop[p.Tour]])); // v1.4 (ScoreTop)
StatusBar.SimpleText:=Format(stFormatLigneStatut, [CumulPrp, CumulSol, p.CumulTop[p.Tour]]); // v1.6.5 : Cumuls sur la ligne de statut
// v1.5 : On force ici la ligne en blanc car des fichiers de la version < 1.5 restait en noir...
with RichMemo do
  begin
  SelStart:=iDebutDrnLigne;
  SelLength:=Length(RichMemo.Lines.Text)-iDebutDrnLigne;
  SelAttributes.Color:=Font.Color;
  end;

// D. On "enrichit" la ligne

// Pour la proposition et la solution
// - En souligné les jetons posés (et bonussables dont colorisables)
// - En minuscule les jokers
// - En couleurs les bonus comptabilisés
// Pour le tirage
// - En souligné les lettres nouvellement tirées
// Pour les scores (hors cumul)
// - En souligné les bonus pour Scrabble (50 points)
iDebutDrnLigne:=Pos(Format(Copy(stFormatLigne, 1, 5), // v1.6.5 : Largeur. v1.8.3 : plus qu'une seule taille
                           [p.Tour]),
                RichMemo.Lines.Text)-1; // vLaz : -1

// v1.4 : on met en gras le score du joueur (tour/Partie)
with RichMemo do
  begin
  Diminution:=Ord(p.Score[p.Tour]<1000)+Ord(p.Score[p.Tour]<100);
  SelStart:=iDebutDrnLigne+iDebutScore[csHumain]+Diminution;
  SelLength:=4-Diminution;
  SelAttributes.Style:=[fsBold];
  Diminution:=Ord(p.Cumul[p.Tour]<1000)+Ord(p.Cumul[p.Tour]<100);
  end;

// D1. On met en évidence le tirage (nouveaux jetons tirés)
with RichMemo do
  if p.PremierJetonTire>0 then
    begin
    SelStart:=iDebutDrnLigne+iDebutTirage+p.PremierJetonTire-1;
    SelLength:=Length(p.stTirage[p.Tour])-p.PremierJetonTire+1;
    if p.VersionFichier>=$166 then // v1.6.6 : Les nouveaux jetons sont en souligné depuis la version 1.6.6 (version de création du fichier de partie)
      SelAttributes.Style:=[fsUnderline]
    else
      SelAttributes.Style:=[fsItalic]
    end;

// D2a.On met en évidence la PROPOSITION (jetons posés, jokers & bonus appliqués)
NbJetonsPlaces:=0;
for i:=0 to Length(stMotPrp)-1 do
  begin
  Style:=RichMemo.SelAttributes.Style;
  if p.c[XPrp+(i+iDebutMotPrp)*dx[dPrp],
         YPrp+(i+iDebutMotPrp)*dy[dPrp]]=0 then
    begin
    Inc(NbJetonsPlaces);
    RichMemo.SelStart:=iDebutDrnLigne+iDebutMot[csHumain]+i;
    RichMemo.SelLength:=1;
    Style:=[fsUnderline];
    if BonusCase[XPrp+(i+iDebutMotPrp)*dx[dPrp],
                 YPrp+(i+iDebutMotPrp)*dy[dPrp]]>bAucun then
      RichMemo.SelAttributes.Color:=
          CouleurBonus[BonusCase[XPrp+(i+iDebutMotPrp)*dx[dPrp],
                                 YPrp+(i+iDebutMotPrp)*dy[dPrp]]];
    end{if}
  else // v1.5.6 : On regarde si le jeton déjà placé est un substitut de joker (parties de type "joker"). Dans ce cas, on met la lettre en vert
    if p.SubstitutJoker[p.c[XPrp+(i+iDebutMotPrp)*dx[dPrp],
                            YPrp+(i+iDebutMotPrp)*dy[dPrp]]] then
      begin
      RichMemo.SelStart:=iDebutDrnLigne+iDebutMot[csHumain]+i;
      RichMemo.SelLength:=1;
      Style:=[];
      RichMemo.SelAttributes.Color:=CouleurEncreSubstitutJokerFdM;
      end;
  RichMemo.SelAttributes.Style:=Style;
  end{for};
RichMemo.SelLength:=0;
RichMemo.SelStart:=0;

// D2b.On souligne le score si bonus de Scrabble
Style:=RichMemo.SelAttributes.Style;
if NbJetonsPlaces=NbMaxJetonsTirage then
  begin
  p.BonusScrabblePrp[p.Tour]:=True;
  Diminution:=Ord(p.Score[p.Tour]<1000)+
              Ord(p.Score[p.Tour]<100);
  RichMemo.SelStart:=iDebutDrnLigne+
                     iDebutScore[csHumain]+
                     Diminution;
  RichMemo.SelLength:=4-Diminution;
  Style:=[fsUnderline, fsBold];
  RichMemo.SelAttributes.Style:=Style;
  end
else
  p.BonusScrabblePrp[p.Tour]:=False;

// D2c.On met en évidence la SOLUTION (jetons posés, jokers & bonus appliqués)
NbJetonsPlaces:=0;
for i:=0 to Length(stMotSol)-1 do
  begin
  Style:=RichMemo.SelAttributes.Style;
  if p.c[XSol+(i+iDebutMotSol)*dx[dSol],
         YSol+(i+iDebutMotSol)*dy[dSol]]=0 then
    begin
    Inc(NbJetonsPlaces);
    RichMemo.SelStart:=iDebutDrnLigne+iDebutMot[csMachine]+i;
    RichMemo.SelLength:=1;
    Style:=[fsUnderline];
    if BonusCase[XSol+(i+iDebutMotSol)*dx[dSol],
                 YSol+(i+iDebutMotSol)*dy[dSol]]>bAucun then
      RichMemo.SelAttributes.Color:=
          CouleurBonus[BonusCase[XSol+(i+iDebutMotSol)*dx[dSol],
                                 YSol+(i+iDebutMotSol)*dy[dSol]]];
    end
  else // v1.5.6 : On regarde si le jeton déjà placé est un substitut de joker (parties de type "joker"). Dans ce cas, on met la lettre en vert
    if p.SubstitutJoker[p.c[XSol+(i+iDebutMotSol)*dx[dSol],
                            YSol+(i+iDebutMotSol)*dy[dSol]]] then
      begin
      RichMemo.SelStart:=iDebutDrnLigne+iDebutMot[csMachine]+i;
      RichMemo.SelLength:=1;
      Style:=[];
      RichMemo.SelAttributes.Color:=CouleurEncreSubstitutJokerFdM;
      end;
  RichMemo.SelAttributes.Style:=Style;
  end{for};
RichMemo.SelStart:=0;
RichMemo.SelLength:=0;

// D2d.On met en gras le score si bonus de Scrabble
Style:=RichMemo.SelAttributes.Style;
if NbJetonsPlaces=NbMaxJetonsTirage then
  begin
  p.BonusScrabbleSol[p.Tour]:=True;
  Diminution:=Ord(p.ScoreTop[p.Tour]<1000)+
              Ord(p.ScoreTop[p.Tour]<100);
  RichMemo.SelStart:=iDebutDrnLigne+
                     iDebutScore[csMachine]+
                     Diminution;
  RichMemo.SelLength:=4-Diminution;
  Style:=[fsUnderline];
  RichMemo.SelAttributes.Style:=Style;
  end
else
  p.BonusScrabbleSol[p.Tour]:=False;

AjusteHauteur
end;
//---------------------------------------------------------------------------
function TFormFeuilleMatch.FormatLettreMotPrincipal(const Tour : Integer; const Cible : TCibleStats; const iLettre : Integer;
                                                    var Lettre : Char; var Style : TFontStyles; var Bonus : TBonus;
                                                    var SubstitutJoker : Boolean) : Boolean; // v1.5.6 : ajout de var SubstitutJoker : Boolean
var iDebutLigne : Integer;
begin
iDebutLigne:=Pos(Format(Copy(stFormatLigne, 1, 5), [Tour]),
                 RichMemo.Lines.Text);
if iDebutLigne>0 then
  begin
  RichMemo.SelStart:=iDebutLigne+iDebutMot[Cible]+iLettre-2; // v1.8.3 (-2)
  RichMemo.SelLength:=1;
  Style:=RichMemo.SelAttributes.Style;
  SubstitutJoker:=(RichMemo.SelAttributes.Color=CouleurEncreSubstitutJokerFdm); // v1.5.6
  if not SubstitutJoker then // v1.5.6
    begin
    Bonus:=High(TBonus);
    while (Bonus<>bAucun) and
          (CouleurBonus[Bonus]<>RichMemo.SelAttributes.Color) do
      Bonus:=Pred(Bonus);
    end
  else // v1.5.6
    Bonus:=bAucun;
  Lettre:=RichMemo.Lines.Text[iDebutLigne+iDebutMot[Cible]+iLettre];
  Result:=True
  end
else
  Result:=False
end;
//---------------------------------------------------------------------------
function TFormFeuilleMatch.FormatLettreTirage(const Tour : Integer; const iLettre : Integer; var Lettre : Char; var Style : TFontStyles) : Boolean;
var iDebutLigne : Integer;
begin
iDebutLigne:=Pos(Format(Copy(stFormatLigne, 1, 5), [Tour]),
                 RichMemo.Lines.Text);
if iDebutLigne>0 then
  begin
  RichMemo.SelStart:=iDebutLigne+iDebutTirage+iLettre-2;  // v1.8.3 (-2)
  RichMemo.SelLength:=1;
  Style:=RichMemo.SelAttributes.Style;
  Lettre:=RichMemo.Lines.Text[iDebutLigne+iDebutTirage+iLettre];
  Result:=True
  end
else
  Result:=False
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.AjusteHauteur;
var MinHauteur : Integer;
begin
MinHauteur:=(4+p.Tour)*Canvas.TextHeight('X')+(Height-RichMemo.Height);
if Height<MinHauteur then Height:=MinHauteur
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.CalculeLargeurMax;
begin // v1.6.5
Width:=FormTirage.Width;  // v1.8.3 : même largeur que le tirage
end;
//---------------------------------------------------------------------------
procedure TFormFeuilleMatch.InverseCouleurTexte; // v1.5. // vLaz : on force la couleur au lieu d'inverser Noir/Blanc
var i, n           : Integer;
    b              : TBonus; // vLaz
    CouleurInverse : TColor; // vLaz : on force la couleur au lieu d'inverser Noir/Blanc
    Laisser        : Boolean;
begin
n:=Length(RichMemo.Lines.Text); // vLaz
for i:=0 to n do
  with RichMemo do
    begin
    SelStart:=i;
    SelLength:=1;
    if i=0 then // vLaz : on détermine tout de suite la couleur à forcer
      case SelAttributes.Color of
        clBlack: CouleurInverse:=clWhite;
        clWhite: CouleurInverse:=clBlack;
      end;
    Laisser:=False; // vLaz : on teste les couleurs bonus
    for b:=Low(TBonus) to High(TBonus) do
      if SelAttributes.Color=CouleurBonus[b] then
        begin
        Laisser:=True;
        break;
        end;
    if not Laisser then // vLaz : Si pas couleur bonus alors on force la couleur
      SelAttributes.Color:=CouleurInverse;
    end;
with RichMemo do
  begin
  SelStart:=0;
  SelLength:=0
  end
end;
//---------------------------------------------------------------------------
end.
