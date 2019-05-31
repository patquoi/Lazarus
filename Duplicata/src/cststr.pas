unit cststr;

{$MODE Delphi}

 // v1.5
//---------------------------------------------------------------------------
interface
//---------------------------------------------------------------------------
// Feuille de match détaillée (Fdmd)
// v1.4 : Ajout Scores Joués + Définitions
// v1.4.7 : Ajout Nb Moyen de Solutions + 2 lignes pour les sous-titres de colonnes
// v1.4.8 : En-tête stats sur 3 niveaux avec regroupement des moyennes (le temps moyen rejoint scores, rangs et NbSol)
// v1.5 : permutation Temp Rang/Solution dans les moyenne pour conserver le même ordre
// v1.5 : découpage des chaînes EnTete et PdPage suite à panique du compilateur avec des constantes de chaînes trop longues (???)
// v1.5 : Unité spécialisée pour les longues constantes de chaînes faisant décaler les repères de localisation de sources
// v1.8.8 : Remplacement de alt par title pour affichage bulle d'aide dans les niveaux de difficulté
//---------------------------------------------------------------------------
const stHTMLSansNom    ='[Sans nom]'; stHTMLItaliqueSansNom='<I>'+stHTMLSansNom+'</I>';
      stHTMLImgNivDiff ='<img src="%s" width=55 height=13 title="%s">'; // v1.8.8 alt remplacé par title
      // v1.6 : Légende Niveau de difficulté mis en constante . v1.6.2 : ajout de retours chariot pour mettre sur 3 lignes et empêcher d'avoir un tableau de légende sur toute la largeur...
      stHTMLDefNivDiff ='<BR>'+stHTMLImgNivDiff+' = &eacute;valuation indisponible (pas de solution ou version &lt; v1.5), <BR>'+
                        stHTMLImgNivDiff+' = de ~79,5%% &agrave; 100%%, '+stHTMLImgNivDiff+' = de ~49%% &agrave; ~79,5%%, '+stHTMLImgNivDiff+' = de ~30,5%% &agrave; ~49%%, <BR>'+
                        stHTMLImgNivDiff+' = de ~19%% &agrave; ~30,5%%, '+stHTMLImgNivDiff+' = de ~11,5%% &agrave; ~19%%, '+stHTMLImgNivDiff+' = de ~7%% &agrave; ~11,5%%, '+stHTMLImgNivDiff+' = de ~4%% &agrave; ~7%%, <BR>'+
                        stHTMLImgNivDiff+' = de ~2%% &agrave; ~4%%, '+stHTMLImgNivDiff+' = de ~1%% &agrave; ~2%%, '+stHTMLImgNivDiff+' = de ~0,25%% &agrave; 1%%, '+stHTMLImgNivDiff+' = de 0%% &agrave; ~0,25%%.'+'</td></tr>'#13;

      stFrmHTMLFdmdEnT1='<?xml version="1.0" encoding="utf-8"?>'#13+'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'#13+
                        '<html><head><title>Feuille de match d&eacute;taill&eacute;e - Duplicata</title><meta content="Feuille de match d&eacute;taill&eacute;e Duplicata" name="description"><meta content="Feuille de match d&eacute;taill&eacute;e, Duplicata" name="keywords"></head>'#13+'<body text="#fffff" vlink="#a0a0ff" link="#00ffff" bgcolor="#000000">'#13+
                        '<center><h1>Feuille de match d&eacute;taill&eacute;e - Duplicata</h1></center>'#13'<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+
                        '<tr><td align="center" ROWSPAN=3><I>T.</I></td><td align="center" ROWSPAN=3><I>Tirage</I></td><td COLSPAN=2 align="center"><I>Proposition</I></td><td COLSPAN=2 align="center">';
                        // v1.4.9 (ci-dessous) : proposition JOUEE
                        // v1.5   (ci-dessous) : Ajout Bonus 50 entre Solutions et Niveau de difficulté
                        // v1.6 : ajout de Tps calcul solutions, Nb sol./s et les moyennes
      stFrmHTMLFdmdEnT2='<I>Solution jou&eacute;e</I></td>'+'<td COLSPAN=3 align="center"><I>Score Tour</I></td>'+'<td COLSPAN=3 align="center"><I>Score Partie</I></td>'+'<td COLSPAN=2 align="center"><I>Tps r&eacute;flexion</I></td>'+'<td COLSPAN=15 align="center"><I>Statistiques</I></td></tr>'#13+
                        '<tr><td align="center" ROWSPAN=2><I>Pos.</I></td>'+'<td ROWSPAN=2><I>Mot<br>principal</I></td>'+'<td align="center" ROWSPAN=2><I>Pos.</I></td>'+'<td ROWSPAN=2><I>Mot<br>principal</I></td>'+'<td ROWSPAN=2><I>Prp</I></td>'+'<td ROWSPAN=2><I>Jou&eacute;</I></td>'+'<td ROWSPAN=2><I>Top</I></td>'+'<td ROWSPAN=2><I>Prp</I></td>'+'<td ROWSPAN=2><I>Jou&eacute;</I></td>'+'<td ROWSPAN=2><I>Top</I></td>'+'<td ROWSPAN=2 align="center"><I>Tour</I></td>'+'<td ROWSPAN=2 align="center"><I>Partie</I></td>'+'<td ROWSPAN=2><I>Rang</I></td>'+'<td ROWSPAN=2><I>Solutions</I></td>'+'<td ROWSPAN=2><I>Dont<br>B.50</I></td>'+'<td ROWSPAN=2><I>Niveau de<br>difficult&eacute;</I></td>'+'<td ROWSPAN=2><I>Rech.<br>sol.(s)</I></td>'+'<td ROWSPAN=2><I>Nb Sol./s</I></td>'+'<td COLSPAN=7 align="center"><I>Moyennes</I></td>'+'<td COLSPAN=2 align="center"><I>Scores%s</I></td></tr>'#13+
                        '<tr><td><I>Temps</I></td>'+'<td><I>Rang</I></td>'+'<td><I>Solutions</I></td>'+'<td><I>B.50</I></td>'+'<td><I>Niv.de diff.</I></td>'+'<td><I>R.sol.(s)</I></td>'+'<td><I>Nb Sol./s</I></td>'+'<td align="center"><I>T.</I></td>'+'<td align="center"><I>P.</I></td></tr>'#13;

      // v1.5.5 : Le mot principal de la solution jouée n'est plus l'un des tops
      // v1.6.6 : Les nouveaux jetons du tirage sont en souligné
      stFrmHTMLFdmdPdP1='</tbody></table>'#13#13+'<H2>L&eacute;gende</H2>'#13+'<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+'<tr><td><B>Intitul&eacute;</B></td><td><B>Description</B></td></tr>'#13+
                        '<tr><td><I>T. (Tour)</I></td><td>Tour de jeu.</td></tr>'#13+
                        '<tr><td><I>Tirage</I></td><td>Contenu du chevalet. Les nouveaux jetons apparaissent en <U>soulign&eacute;</U>. Le joker est repr&eacute;sent&eacute; par un point d''interrogation (?).</td></tr>'#13+
                        '<tr><td><I>Mot principal de la proposition</I></td><td>Mot principal du coup propos&eacute; par le joueur et form&eacute; par les jetons pos&eacute;s &agrave; partir de la case indiqu&eacute;e par la position.</td></tr>'#13+
                        '<tr><td><I>Mot principal de la solution jou&eacute;e</I></td><td>Mot principal du coup jou&eacute;.</td></tr>'#13+
                        '<tr><td><I>Pos. (Position)</I></td><td>Coordonn&eacute;es de la case d&eacute;part du premier jeton pos&eacute; (le mot form&eacute; pouvant commencer avant).<BR>'+
                        'La lettre indique la ligne (de <TT>A</TT> &agrave; <TT>O</TT>) et le nombre indique la colonne (de <TT>1</TT> &agrave; <TT>15</TT>).<BR>'+
                        'Si les coordonn&eacute;es commencent par une lettre, les jetons sont pos&eacute;s horizontalement.<BR>'+
                        'Si les coordonn&eacute;es commencent par un chiffre, les jetons sont pos&eacute;s verticalement.</td></tr>'#13+
                        '<tr><td><I>Score Tour Prp (Propos&eacute;)</I></td><td>Score du coup propos&eacute; par le joueur. L''ast&eacute;risque indique qu''il s''agit d''un top.</td></tr>'#13+
                        '<tr><td><I>Score Tour Jou&eacute;</I></td><td>Score du coup (solution) qui a &eacute;t&eacute; jou&eacute;.</td></tr>'#13+
                        '<tr><td><I>Score Tour Top</I></td><td>Score du coup (solution) qui rapporte le plus de points possibles.</td></tr>'#13+
                        '<tr><td><I>Score Partie Prp (Propos&eacute;)</I></td><td>Cumul du score des coups propos&eacute;s &agrave; chaque tour par le joueur.</td></tr>'#13+
                        '<tr><td><I>Score Partie Jou&eacute;</I></td><td>Score de la partie jou&eacute;e.</td></tr>'#13+
                        '<tr><td><I>Score Partie Top</I></td><td>Cumul des scores les plus &eacute;lev&eacute;s de chaque tour.</td></tr>'#13+
                        '<tr><td><I>Tps r&eacute;flexion Tour</I></td><td>Temps de r&eacute;flexion &eacute;coul&eacute; entre le tirage et la proposition. Les temps atteignant ou d&eacute;passant la limite impartie sont en <font color="#FF000">rouge</font>.</td></tr>'#13+
                        '<tr><td><I>Tps r&eacute;flexion Partie</I></td><td>Temps de r&eacute;flexion &eacute;coul&eacute; depuis le d&eacute;but de la partie (cumul).</td></tr>'#13+
                        '<tr><td><I>Rang</I></td><td>Position de la proposition du joueur dans le classement de toutes les solutions possibles selon l''ordre d&eacute;croissant de leur score.</td></tr>'#13+
                        '<tr><td><I>Rang moyen</I></td><td>Position moyenne des propositions du joueur.</td></tr>'#13+
                        '<tr><td><I>Solutions</I></td><td>Nombre de solutions jouables distinctes (jetons pos&eacute;s diff&eacute;rents).</td></tr>'#13+
                        '<tr><td><I>Moyenne Solutions</I></td><td>Nombre moyen de solutions jouables distinctes (jetons pos&eacute;s diff&eacute;rents).</td></tr>'#13+
                        '<tr><td><I>B.50</I></td><td>Nombre de solutions jouables distinctes ayant le bonus 50 pour placement de tous les jetons du chevalet.<br>'#13+
                         '('#42') Au premier tour, le nombre est divis&eacute; par 14 (nombre de placements possibles d''un mot de 7 lettres au d&eacute;part).</td></tr>'#13+
                        '<tr><td><I>Moyenne B.50</I></td><td>Nombre moyen de solutions ayant le bonus 50 par tour au cours de la partie.</td></tr>'#13;
      // v1.6 : Légende Niveau de difficulté mis en constante (stHTMLDefNivDiff)
      stFrmHTMLFdmdPdP2='<tr><td><I>Score (%s) T. (Tour)</I></td><td>Rapport entre le Score et le Score Top. Les nuances de couleurs sont relatives &agrave; la performance&nbsp;: '+
                        '<font color="#FF0000">rouge</font>=tr&egrave;s faible, <font color="#FFA000">orange</font>=faible, <font color="#FFFF00">jaune</font>=moyenne, <font color="#00FF00">vert</font>=bonne et <font color="#00FFFF">ciel</font>=top.</td></tr>'#13+
                        '<tr><td><I>Score (%s) P. (Partie)</I></td><td>Rapport entre le Cumul et le Cumul Top.</td></tr>'#13+
                        '<tr><td><I>Temps moyen</I></td><td>Temps de r&eacute;flexion moyen (temps cumul&eacute;/nombre de tours). Les temps atteignant ou d&eacute;passant la limite impartie sont en <font color="#FF000">rouge</font>.</td></tr>'#13+
                        '<tr><td><I>Niveau de difficult&eacute;</I></td><td>Evaluation donn&eacute;e &agrave; partir du pourcentage de solutions atteignant au moins la moiti&eacute; du score du top&nbsp;: '+
                        stHTMLDefNivDiff;
      // v1.3.2 : Pour avoir plac...
      // v1.3.10 : joker posé (bleu foncé éclairci)
      // v1.5.6 : Parties joker (lettre substituée)
      stFrmHTMLFdmdPdP3='<tr><td><I>Rech.sol.</I></td><td>Temps n&eacute;cessaire qu''il a fallu pour calculer toutes les solutions (exprim&eacute; en secondes). Information pour les parties g&eacute;n&eacute;r&eacute;es avec une version 1.6 ou ult&eacute;rieure uniquement.</td></tr>'#13+
                        '<tr><td><I>Nb Sol./s</I></td><td>Nombre moyen de solutions trouv&eacute;es en une seconde. Information pour les parties g&eacute;n&eacute;r&eacute;es avec une version 1.6 ou ult&eacute;rieure uniquement.</td></tr>'#13+
                        '</tbody></table><p>'#13#13+
                        '<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+
                        '<tr><td><B>Nature et style</B></td><td><B>Description</B></td></tr>'#13+
                        '<tr><td><U>SCORE</U></td><td>Score (soulign&eacute;) incluant un bonus de 50 points pour avoir plac&eacute; les 7 jetons sur le plateau de jeu (sauf Score Top).</td></tr>'#13+
                        '<tr><td><U>LETTRE</U></td><td>Lettre (soulign&eacute;e) correspondant &agrave; un jeton pos&eacute; sur le plateau de jeu.</td></tr>'#13+
                        '<tr><td><U><FONT COLOR="#0000FF">L</FONT><FONT COLOR="#00FFFF">E</FONT><FONT COLOR="#FFC0C0">T</FONT><FONT COLOR="#FF0000">T</FONT>'+
                        '<FONT COLOR="#4040FF">R</FONT><FONT COLOR="#00FFFF">E</FONT>'+
                        '</U></td><td>Lettre (color&eacute;e) correspondant &agrave; un jeton pos&eacute; sur une case bonus de la m&ecirc;me couleur.</td></tr>'#13+
                        '<tr><td><I>LETTRE</I></td><td>Lettre (en italique) correspondant &agrave; un nouveau jeton du tirage.</td></tr>'#13+
                        '<tr><td>lettre</td><td>Lettre (en minuscule) attribu&eacute;e &agrave; un jeton joker pos&eacute; sur le plateau de jeu.</td></tr>'#13+
                        '<tr><td><FONT COLOR="#00FF00">LETTRE</FONT></td><td>Lettre substitu&eacute;e &agrave; un joker (parties "joker" uniquement).</td></tr>'#13+
                        '<tr><td>?</td><td>Jeton du tirage correspondant &agrave; un joker.</td></tr>'#13+
                        '</tbody></table>'#13'</body></html>';

      // v1.5 ligne ci-dessous : ajout code couleur pour les rapports (du rouge au vert via jaune/orange) en fonction de la performance.
      // v1.5 ligne ci-dessous : ajout espace insécable entre sur et %d pour empêcher le retour à la ligne automatique par le navigateur
      // v1.5 : ajout du nombre de bonus 50 (moyenne)
      // v1.6 : ajout du tps recherche solutions + nbsol/s
      // v1.8.3 : Tirage en police fixe (TT)
      stFrmHTMLFdmdLgn ='<tr><td align="right">%d.</td><td><TT>%s</TT></td>'+
                        '<td align="center"><TT>%s</TT></td><td>%s</td>'+
                        '<td align="center"><TT>%s</TT></td><td>%s</td>'+
                        '<td align="right">%s</td><td align="right">%s</td><td align="left">/%s</td>'+
                        '<td align="right">%d</td><td align="right">%d</td><td align="left">/%d</td>'+
                        '<td align="center">%s</td><td align="center">%s</td>'+
                        '<td align="right">%d%s</td><td align="left">sur&nbsp;%d</td>'+
                        '<td align="right">%s</td>'+
                        '<td align="center">'+stHTMLImgNivDiff+
                        '<td align="right">%s</td>'+
                        '<td align="right">%s</td>'+
                        '</td><td align="center">%s</td><td align="right">%d%s</td><td align="left">sur&nbsp;%d</td>'+
                        '<td align="right">%s</td>'+
                        '<td align="center">'+stHTMLImgNivDiff+
                        '<td align="right">%s</td>'+
                        '<td align="right">%s</td>'+
                        '<td align="right"><font color="%s">%.1f</font></td><td align="right"><font color="%s">%.1f</font></td></tr>'#13;

      // Liste des parties jouées (LdPJ)
      // v1.5 : pour les deux lignes ci-dessous, ajout de la date et de l'heure après le nom de partie
      // v1.6 : ajout temps de calcul des solutions + Nb de solutions par seconde
      stFrmHTMLLdPJEnT= '<?xml version="1.0" encoding="utf-8"?>'#13+
                        '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'#13+
                        '<html><head><title>Parties jou&eacute;es - Duplicata</title><meta content="Parties jou&eacute;es Duplicata" name="description"><meta content="Parties jou&eacute;es, Duplicata" name="keywords"></head>'#13+
                        '<body text="#fffff" vlink="#a0a0ff" link="#00ffff" bgcolor="#000000">'#13+
                        '<center><h1>Parties jou&eacute;es - Duplicata</h1></center>'#13+
                        '<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+
                        '<tr><td ROWSPAN=2 align="center"><I>N&deg;</I></td>'+
                        '<td ROWSPAN=2 align="center"><I>Nom</I>'+
                        '<td ROWSPAN=2 align="center"><I>Date Heure</I></td>'+
                        '<td ROWSPAN=2 align="center"><I>Coups</I></td>'#13+
                        '<td ROWSPAN=2 align="center"><I>Reliquat</I></td>'+
                        '<td ROWSPAN=2 align="center"><I>Temps</I></td>'+
                        '<td COLSPAN=3 align="center"><I>Score</I></td>'+
                        '<td COLSPAN=6 align="center"><I>Moyenne</I></td></tr>'#13+
                        '<tr><td align="center"><I>Propos&eacute;</I></td>'+
                        '<td align="center"><I>Jou&eacute;</I></td>'+
                        '<td align="center"><I>Top</I></td>'+
                        '<td align="center"><I>Rang</I></td>'+
                        '<td align="center"><I>Solutions</I></td>'+
                        '<td align="center"><I>Bonus&nbsp;50</I></td>'+
                        '<td align="center"><I>Niv.de diff.</I></td>'#13+
                        '<td align="center"><I>Rech.Sol.(s)</I></td>'#13+
                        '<td align="center"><I>Nb Sol./s</I></td></tr>'#13;

      // v1.6 : ajout temps de calcul des solutions + Nb de solutions par seconde
      stFrmHTMLLdPJPdP1='</tbody></table>'#13#13'<H2>L&eacute;gende</H2>'#13'<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+
                        '<tr><td><B>Intitul&eacute;</B></td><td><B>Description</B></td></tr>'#13+
                        '<tr><td><I>Nom</I></td><td>Nom de fichier de la partie enregistr&eacute;e. Si la partie n''a pas &eacute;t&eacute; enregistr&eacute;e, '+stHTMLItaliqueSansNom+' est affich&eacute;. Si le nom de partie est color&eacute;, il s''agit d''une partie de type non standard (<FONT COLOR="#00FF00">vert</FONT>=parties "joker")</td></tr>'#13+
                        '<tr><td><I>Date Heure</I></td><td>Date et heure auxquelles la partie s''est termin&eacute;e.</td></tr>'#13+
                        '<tr><td><I>Coups</I></td><td>Nombre de coups jou&eacute;s dans la partie.</td></tr>'#13+
                        '<tr><td><I>Reliquat</I></td><td>Jetons non jou&eacute;s (le cas &eacute;ch&eacute;ant).</td></tr>'#13+
                        '<tr><td><I>Score Propos&eacute;</I></td><td>Score de la partie concernant uniquement les propositions du joueur. Les nuances de couleurs sont relatives &agrave; la performance&nbsp;: '+
                        '<font color="#FF0000">rouge</font>=tr&egrave;s faible, <font color="#FFA000">orange</font>=faible, <font color="#FFFF00">jaune</font>=moyenne et <font color="#00FF00">vert</font>=bonne.</td></tr>'#13;
      stFrmHTMLLdPJPdP2='<tr><td><I>Score Jou&eacute;</I></td><td>Score de la partie concernant uniquement les propositions plac&eacute;es sur le plateau de jeu.</td></tr>'#13+
                        '<tr><td><I>Score Top</I></td><td>Score Top de la partie (cumul des scores des meilleurs coups possibles &agrave; chaque tour).</td></tr>'#13'<tr><td><I>Temps</I></td><td>Temps de r&eacute;flexion &eacute;coul&eacute; durant la partie.</td></tr>'#13+
                        '<tr><td><I>Rang</I></td><td>Position moyenne des propositions du joueur dans le classement de toutes les solutions possibles selon l''ordre d&eacute;croissant de leur score.</td></tr>'#13+
                        '<tr><td><I>Solutions</I></td><td>Nombre moyen de solutions jouables distinctes (jetons pos&eacute;s diff&eacute;rents).<br>'#13+
                        '('#42') Niveau de difficult&eacute; pond&eacute;r&eacute; sur le nombre de solutions (Parties jou&eacute;es avec la version 1.5 de Duplicata) et non le score top (versions 1.5.1 ou ult&eacute;rieures).</td></tr>'#13+
                        '<tr><td><I>Bonus 50</I></td><td>Nombre moyen par tour de solutions possibles ayant un bonus de 50 points pour placement de tous les jetons sur le plateau de jeu.</td></tr>'#13+
                        '<tr><td><I>Niv.de diff.</I></td><td>Evaluation du niveau de difficult&eacute; donn&eacute;e &agrave; partir du pourcentage de solutions atteignant au moins la moiti&eacute; du score du top&nbsp;: '#13;
      // v1.6 : Légende Niveau de difficulté mis en constante (stHTMLDefNivDiff).
      stFrmHTMLLdPJPdP3=stHTMLDefNivDiff+
                        '<tr><td><I>Rech.Sol.</I></td><td>Temps n&eacute;cessaire qu''il a fallu pour calculer toutes les solutions (exprim&eacute; en secondes). Information pour les parties g&eacute;n&eacute;r&eacute;es avec une version 1.6 ou ult&eacute;rieure uniquement.</td></tr>'#13+
                        '<tr><td><I>Nb Sol./s</I></td><td>Nombre moyen de solutions trouv&eacute;es en une seconde. Information pour les parties g&eacute;n&eacute;r&eacute;es avec une version 1.6 ou ult&eacute;rieure uniquement.</td></tr>'#13+
                        '</tbody></table>'#13'</body></html>';

      // v1.5 : pour les deux lignes ci-dessous, utilisation du format de rapport paramétré (% ou /20). '%d (%s)' au lieu de '%d (%.1f %%)'
      // v1.5 : pour les deux lignes ci-dessous, utilisation d'un code couleur de rouge vers vert pour quantifier la performance
      // v1.5 : pour la ligne ci-dessous : ajout espace insécable entre sur et %d pour empêcher le retour à la ligne automatique par le navigateur
      // v1.5 : pour les deux lignes ci-dessous, ajout de la date et de l'heure après le nom de partie (pour la moyenne, fusion de cellule)
      // v1.5.1 : pour la ligne ci-dessous, ajout de %s pour mettre un astérisque indiquant un niveau de difficulté NON pondéré par le score top (mais le nombre de solutions).
      // v1.5 : nb sol avec bonus 50
      // v1.6 : ajout temps de calcul des solutions + Nb de solutions par seconde
      stFrmHTMLLdPJLgn= '<tr><td align="right">%d.</td><td>%s</td><td align="center">%s</td><td align="right">%d</td><td><TT>%s</TT></td><td align="center">%s</td>'+'<td align="right">%d (<font color="%s">%s</font>)</td><td align="right">%d</td>'+'<td align="right">%d</td><td align="right">%d</td><td>sur&nbsp;%d%s</td>'+'<td align="right">%s</td>'#13+'<td align="center">'+stHTMLImgNivDiff+#13+'<td align="right">%s</td>'#13+'<td align="right">%s</td></tr>'#13;

      // v1.5.6 : ajout de 'des parties de type %s', align="left". v1.5 : nb sol avec bonus 50
      // v1.6 : ajout temps de calcul des solutions + Nb de solutions par seconde
      stFrmHTMLLdPJMoy= '<tr><td colspan=3><B>Moyenne des parties de type %s</B></td><td align="right"><B>%d</B></td><td><I>&nbsp;</I></td><td align="center"><B>%s</B></td>'+'<td align="right"><B>%d (<font color="%s">%s</font>)</B></td>'#13+'<td align="right"><B>%d</B></td><td align="right"><B>%d</B></td><td align="right"><B>%d</B></td><td><B>sur&nbsp;%d</B></td>'+'<td align="right"><B>%s</B></td>'#13+'<td align="center">'+stHTMLImgNivDiff+#13+'<td align="right"><B>%s</B></td>'#13+'<td align="right"><B>%s</B></td></tr>'#13;

      // v1.5.7 ci-dessous, colspan=3 pour les en-têtes Générale, Proposition et Top et ajout de Standard/Joker pour la ligne du dessous
      // v1.5.7 ci=dessous, EnT coupé en deux : Ent1 et Ent2
      stFrmHTMLLdREnT = '<?xml version="1.0" encoding="utf-8"?>'#13+'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'#13+'<html><head><title>Records - Duplicata</title>'+'<meta content="Records Duplicata" name="description"><meta content="Records, Duplicata" name="keywords"></head>'#13+'<body text="#fffff" vlink="#a0a0ff" link="#00ffff" bgcolor="#000000">'#13+'<center><h1>Records - Duplicata</h1></center>'#13+'<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+'<tr><th rowspan=2>Nature</th><th>Source</th><th colspan=3>G&eacute;n&eacute;rale</th>'+'<th colspan=3>Proposition</th><th colspan=3>Top</th></tr>'#13+'<tr><th>Niveau</th>'+'<th>Tour</th><th>Partie Standard</th><th><FONT COLOR="#00FF00">Partie Joker</FONT></th>'+'<th>Tour</th><th>Partie Standard</th><th><FONT COLOR="#00FF00">Partie Joker</FONT></th>'+'<th>Tour</th><th>Partie Standard</th><th><FONT COLOR="#00FF00">Partie Joker</FONT></th></tr>'#13;

      stFrmHTMLLdR1LMax='<tr><td colspan=2><b>%s</b></td>%s</tr>'#13;
      stFrmHTMLLdR2LMin='<tr><td rowspan=2><b>%s</b></td><td align="center"><b>Min*</b></td>%s</tr>'#13;
      stFrmHTMLLdR2LMax='<tr><td align="center"><b>Max</b></td>%s</tr>'#13;

      // v1.5.7 : stFrmHTMLLdRCell est décomposé en stFrmHTMLLdRTexte(stFrmHTMLLdRCell) pour pouvoir changer la couleur du texte suivant le type de partie
      stFrmHTMLLdRCell='<b>%s</b><br>%s<i>%s%s</i>%s'; // Valeur, Libellé, Nom Partie, Tour, Date Heure
      stFrmHTMLLdRTexte= '<td align="center">%s</td>';

      // v1.5.4 : balise incorrecte </br> supprimée ci-dessous
      // v1.6.2 : ajout des légendes de records liés au temps de calcul
      stFrmHTMLLdRPdP1= '</tbody></table>'#13'('#42') Valeur nulle exclue.'+'<H2>L&eacute;gende</H2>'#13+'<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+'<tr><th>Nature</th><th>Description</th>'#13+'<tr><td><I>D&eacute;tail du record</i></td><td align="center"><b>Valeur</b><br>(Infos&nbsp;compl&eacute;mentaires)<br><i>Nom&nbsp;de&nbsp;la&nbsp;partie&nbsp;:&nbsp;Tour</i><br>Date&nbsp;heure</td></tr>'#13+'<tr><td><b>Rang</b></td><td>Position des propositions du joueur dans le classement de toutes les solutions possibles selon l''ordre d&eacute;croissant de leur score.</td></tr>'#13;
      stFrmHTMLLdRPdP2= '<tr><td><b>Nombre de solutions (Nb sol.)</b></td><td>Nombre de solutions jouables distinctes (jetons pos&eacute;s diff&eacute;rents) lors d''un tour.</td></tr>'#13+'<tr><td><b>Top</b></td><td>Score maximal lors d''un tour ou somme des scores maximaux de chaque tour pour une partie.</td>'#13+'<tr><td><b>Rapport Score/Top</b></td><td>Rapport (en %% ou /20 selon l''option d''affichage des rapports) entre le score de la proposition et le top lors d''un tour.</td>'#13+'<tr><td><b>Niveau de difficult&eacute;</b></td><td>Evaluation du niveau de difficult&eacute; donn&eacute;e &agrave; partir du pourcentage de solutions atteignant au moins la moiti&eacute; du score du top&nbsp;:'#13;
      stFrmHTMLLdRPdP3= stHTMLDefNivDiff+
                        '<tr><td><B>Tps de calc. des sol.</B></td><td>Temps n&eacute;cessaire qu''il a fallu pour calculer toutes les solutions (exprim&eacute; en secondes).</td></tr>'#13+
                        '<tr><td><B>Nb sol. trouv&eacute;es / s.</B></td><td>Nombre moyen de solutions trouv&eacute;es en une seconde.</td></tr>'#13+
                        '</tbody></table>'#13'</body></html>';

      // v1.5.3 : défi n°1 : Mots de 15 lettres placés avec le moins de jetons possible
      stFrmHTMLD15lEnT= '<?xml version="1.0" encoding="utf-8"?>'#13+
                        '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'#13+
                        '<html><head><title>D&eacute;fi Duplicata n&deg;1 : Former un mot de 15 lettres avec le moins de jetons possible</title><meta content="D&eacute;fi n&deg;1 Duplicata" name="description"><meta content="D&eacute;fi n&deg;1, Duplicata" name="keywords"></head>'#13+
                        '<body text="#fffff" vlink="#a0a0ff" link="#00ffff" bgcolor="#000000">'#13+
                        '<center><h1>D&eacute;fi Duplicata n&deg;1&nbsp;:<br>Former un mot de 15 lettres avec le moins de jetons possible</h1></center>'#13+
                        'Voici la liste des d&eacute;fis relev&eacute;s. La liste est tri&eacute;e par ordre d&eacute;croissant de valeur des mots puis par ordre alphab&eacute;tique.<br>Vous trouverez la liste compl&egrave;te des mots <A HREF="./html/top15.txt">ici</A>.<br>'+' Le mot le plus difficile &agrave; placer jusqu''&agrave; ce jour appara&icirc;t en <b>gras</b>.<P>'#13+
                        '<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+
                        '<tr><th colspan=3>D&eacute;fi</th><th colspan=6>Performance</th></tr>'#13+
                        '<tr><th>N&deg;</th><th>Mot</th><th>Valeur</th><th>Jetons*</th><th>Coups*</th><th>Score</th><th>Cumul*</th><th>Date/Heure</th><th>Nom de partie</th></tr>'#13;

      stFrmHTMLD15lLgn= '<tr><td align="right">%s%d%s</td><td><TT>%s%s%s</TT></td><td align="right">%s%d%s</td><td align="right">%s%d%s</td><td align="right">%s%d%s</td>'+'<td align="right">%s%d%s</td><td align="right">%s%d%s</td><td align="center">%s%s%s</td><td><TT>%s%s%s</TT></td></tr>'#13;

      stFrmHTMLD15lPdp= '</tbody></table>'#13'('#42') Dernier coup du mot de 15 lettres <b>exclu</b>.'#13+
                        '<H2>L&eacute;gende</H2>'#13+
                        '<table cellspacing="1" cellpadding="2" border="1"><tbody>'#13+
                        '<tr><th>Nature</th><th>Description</th>'#13+
                        '<tr><td><b>Valeur</b></td><td>Cumul de la valeur des lettres du mot de quinze lettres, hors bonus et jokers</td></tr>'#13+
                        '<tr><td><b>Jetons</b></td><td>Nombre de jetons pos&eacute;s ne faisant pas partie du mot de quinze lettres</td></tr>'#13+
                        '<tr><td><b>Coups</b></td><td>Nombre de coups de pr&eacute;paration qu''il a fallu avant de pouvoir poser le mot de quinze lettres</td></tr>'#13+
                        '<tr><td><b>Score</b></td><td>Score obtenu lors de la pose du mot de quinze lettres</td></tr>'#13+
                        '<tr><td><b>Cumul</b></td><td>Cumul des scores avant la pose du mot de quinze lettres</td></tr>'#13+
                        '<tr><td><b>Date/Heure</b></td><td>Date et heure auxquelles le d&eacute;fi a &eacute;t&eacute; relev&eacute;</td></tr>'#13+
                        '<tr><td><b>Nom de partie</b></td><td>Nom de la partie dans le cas o&ugrave; elle a &eacute;t&eacute; enregistr&eacute;e</td></tr>'#13+
                        '</tbody></table>'#13'</body></html>';
//---------------------------------------------------------------------------
implementation
//---------------------------------------------------------------------------
end.

