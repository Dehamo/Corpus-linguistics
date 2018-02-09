#!/usr/bin/perl
use locale;
use English;
use Getopt::Std;
use Encode::Encoding;
use Encode::CN;
use Encode::KR;
use Encode::TW;
use Encode::JP;
use Unicode::String qw(utf8);

my $VERSION="2.2";
my $CMD="minigrepmultilingue";
my $MODIFIED="10/12/2010";
my $HELP="
___________________________________________________________________________

$CMD $VERSION (c) Serge Fleury, Pierre Marchal SYLED/CLA2T PLURITAL $MODIFIED
___________________________________________________________________________

OBJECTIF : un mini-grep-multilingue 

SYNTAXE :   $CMD [options] <fichier-codage> <fichier-a-filtrer> <fichier-avec-motif> 

OPTIONS :
  -h        imprime le mode d'emploi de ce programme
  -c        version \"classique\" de minigrepmultilingue

EXEMPLES:
    perl mini-grep-multilingue.pl \"UTF-8\" RU_Convention_UTF8.txt motif.txt

___________________________________________________________________________


";
###########################################################################
# parse command line
###########################################################################
getopts('hdtc');
if (defined($opt_h)) {
  print STDERR "$HELP";
  exit(1);
}

my $classique=0;
if (defined($opt_c)) {
  print STDERR "\nmode \"classique\" active\n";
  $classique=1;
}
#----------------------------------------------------------------------------
if ((!($ARGV[0])) || (!($ARGV[1])) || (!($ARGV[2])))  {
    print "___________________________________________________________________________\n\nERREUR : Le programme necessite 3 arguments : \n 1. un encodage,\n 2. un fichier a filtrer,\n 3. un fichier contenant le motif à filtrer \n\n";
    print "Exemple de lancement : \n";
    print "___________________________________________________________________________\n\n";
    print "perl mini-grep-multilingue.pl \"UTF-8\" RU_Convention_UTF8.txt motif.txt \n\n";
    exit;
}
###########################################################################
# A. Lecture des arguments du programme 
my $tmpcodage=$ARGV[0];
chomp($tmpcodge);
my $filein=$ARGV[1];
print "Fichier en entree : $filein \n";
my $filewithforme=$ARGV[2];
my $fileout="resultat-extraction.html";
###########################################################################
print "extraction du motif...\n";
# B. le fichier contenant la forme à extraire
open(FILE0,"<:encoding($tmpcodage)",$filewithforme) or die "Pb sur l'ouverture du fichier $filewithforme !!! ";
my $formein=<FILE0>;
chomp($formein);
$formein=~/MOTIF=(.+)$/;
my $forme=$1;
utf8($forme);
#print "Forme a rechercher : $forme \n";
close(FILE0);
###########################################################################
my $points="...";
utf8($points);
###########################################################################
print "extraction de la forme et ecriture du resultat dans $fileout \n";
# C. Parcours du fichier et extraction du motif
open(FILEIN,"<:encoding($tmpcodage)",$filein) or  die "Pb sur l'ouverture du fichier $filein !!! ";
open(FILEOUT,">:encoding(UTF-8)",$fileout) or  die "Pb sur l'ouverture du fichier $fileout !!! ";

print FILEOUT "<html>\n<head>\n<title>mini-egrep multi-encodage pour le projet : la vie des mots sur le web</title>\n";
print FILEOUT "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf8\" />\n";
print FILEOUT "<body bgcolor=\"white\">\n";
print FILEOUT "<p align=\"justify\"><font color=\"blue\"><b>Fichier de travail (INPUT) :</b></font> $filein </p>\n"; 
print FILEOUT "<p align=\"justify\"><font color=\"blue\"><b>Encodage utilisé (INPUT) :</b></font> $tmpcodage </p>\n";
print FILEOUT "<p align=\"justify\"><font color=\"blue\"><b>Forme recherchée :</b></font> <font color=\"red\">$forme</font> </p>\n";
print FILEOUT "<font color=\"blue\">_________________________________________________________________________________________________ </font>\n";
my $i=1;
print FILEOUT "<blockquote>\n";
print FILEOUT "<ul>\n";

my $verif=0;
my $ligne_haut;

while (my $ligne=<FILEIN>)  {
    utf8($ligne);

    # si la ligne precedente contenait le motif on l'imprime : contexte apres
    if ($verif == 1) {
	unless (($ligne=~/^\s*$/)||($classique==1)) {
	    print FILEOUT "<font color=\"#3366CC\"><i>Ligne n°",$i,"</i></font> : <font color=\"#3366CC\"><i>$ligne$points</i></font>";
	    print FILEOUT "<br/>";
	}
	$verif=0;
    }

    while ($ligne =~/$forme/gi) { 
	my $motifreconnu= $&;
	my $gauche = $`;
	my $droite = $';
	my $test=0;
	# si le motif est trouve, il faut affiche 1 seule fois le contexte precedent stocke (cf infra)
	if (($ligne_haut ne "-------LIGNE_HAUT_DEJA_INSEREE----------------") && ($ligne_haut ne "") && ($classique==0)) {
	    print FILEOUT "<br/><font color=\"#3366CC\"><i>Ligne n°",$i-1,"</i></font> : <font color=\"#3366CC\"><i>".$points.$ligne_haut."</i></font>";
	    $test=1;
	    $ligne_haut="-------LIGNE_HAUT_DEJA_INSEREE----------------";
	}
	unless ($test == 1) {
	    print FILEOUT "<br/>"; #imprimer un retour à la ligne si ligne du haut non affichée
	}
	print FILEOUT "<li><font color=\"blue\"><b>Ligne n°$i</b></font> : $gauche<font color=\"red\"><b>$motifreconnu<\/b><\/font>$droite </li>";
	$verif=1;

    }	 

    # on stocke la ligne qui peut devenir le contexte precedent la prochaine recherche du motif
    if ($ligne=~/^$/) {
	$ligne_haut="";
    }
    else {
	$ligne_haut=$ligne;
    }
    $i++;
    
}
print FILEOUT "</ul>\n";
print FILEOUT "</blockquote>\n";
print FILEOUT "</html></body>";
###########################################################################
close(FILEIN);
close(FILEOUT);
###########################################################################
