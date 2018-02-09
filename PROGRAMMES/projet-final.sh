#!/bin/bash

# Suppression des pages aspirées, des dumps, des contextes et des fichiers globaux à chaque lancement du script

rm -r ../PAGES-ASPIREES/*;
rm -r ../DUMP-TEXT/*;
rm -r ../CONTEXTES/*;
rm -r ../FICHIERS-GLOBAUX/*;

# Lecture des paramètres dans le fichier parametres.txt situé dans le répertoire PROGRAMMES

exec < parametres.txt;
read dossier_urls;
read tableau;
read mot; 

# Messages à l'utilisateur

echo "Les mots à chercher : $mot " ;
echo "Le répertoire contenant les urls à traiter : $dossier_urls " ;
echo "Les résultats de la recherche sous la forme d'un tableau html : $tableau " ;

# Initialisation d'un compteur pour compter les fichiers d'URLS 

compteur_tableau=1;

# Création d'une page html encodée en utf-8

echo "<html><head><meta charset = utf-8>" > $tableau ;

echo "<link href=\"https://cdn.datatables.net/select/1.2.0/css/select.jqueryui.min.css\" rel=\"stylesheet\" type=\"text/css\">" >> $tableau ;
echo "<style>" >> $tableau ;
echo "table { " >> $tableau ;
echo "border-collapse: collapse; text-align: center; " >> $tableau ;
echo "padding: 1px 10px;" >> $tableau ;
echo "}" >> $tableau ;
echo "tr:nth-child(1) {" >> $tableau ;
echo "background-color: #7199ff;" >> $tableau ;
echo "font-size: 20px;" >> $tableau ;
echo "color: white;" >> $tableau ;
echo "}" >> $tableau ;
echo "th, td {" >> $tableau ;
echo "padding: 10px;" >> $tableau ;
echo "text-align: center;" >> $tableau ;
echo "}" >> $tableau ;
echo "tr:nth-child(even) {" >> $tableau ;
echo "background-color: AliceBlue" >> $tableau ;
echo "}" >> $tableau ;
echo "</style>" >> $tableau ;

echo "</head>" >> $tableau ;
echo "<body>" >> $tableau ;

# Instructions à répéter pour chaque fichier d'URLS

for fichier in `ls $dossier_urls` 
{ 
    # Initialisation d'un compteur pour compter les URLS

    compteur_ligne=1; 

    # Initialisation d'un compteur pour compter les dumps

    nbdump=0; 

    # Création d'un tableau dans la page html

    # mise en page
    echo "<p align=\"center\"><hr color=\"blue\" width=\"85%\"/> </p>" >> $tableau ; 
    echo "<table id=\"example\" class=\"display\" align=\"center\" cellspacing=\"1\" width=\"85%\">" >> $tableau ; 

    case $fichier in
	URLS_alb.txt) echo "<tr><td colspan=\"10\" align=\"center\"><b>Tableau n° $compteur_tableau - Albanais</b></td></tr>" >> $tableau ; 
	;;
	URLS_ara.txt) echo "<tr><td colspan=\"10\" align=\"center\"><b>Tableau n° $compteur_tableau - Arabe</b></td></tr>" >> $tableau ; 
	;;
	URLS_fra.txt) echo "<tr><td colspan=\"10\" align=\"center\"><b>Tableau n° $compteur_tableau - Français</b></td></tr>" >> $tableau ; 
	;;
	esac

    # titres des colonnes
    echo "<tr><td align=\"center\"><b>N&deg;</b></td>
    <td align=\"center\"><b>URL</b></td>
    <td align=\"center\"><b>Page</b></td>
    <td align=\"center\"><b>Encodage</b></td>
    <td align=\"center\"><b>Dump initial</b></td>
    <td align=\"center\"><b>Dump converti</b></td>
    <td align=\"center\"><b>Dump nettoyé</b></td>
    <td align=\"center\"><b>Contextes</b></td>
    <td align=\"center\"><b>Fréquence</b></td>
    <td align=\"center\"><b>Index</b></td>
    </tr>" >> $tableau ; 

# Instructions à répéter pour chaque URL

for ligne in `cat $dossier_urls/$fichier` 
	
    {
	
		echo "Téléchargement de $ligne vers ../PAGES-ASPIREES/${fichier%.*}/$x.html";
		curl $ligne -o ../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html; # téléchargement de la page à l'aide de curl
        
        echo "Code retour curl : $?"; # code curl pour vérifier si la commande a fonctionné

        status_curl1=$(curl -sI $ligne | head -n 1); 
        status_curl2=$(curl --silent --output ../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html --write-out "%{http_code}" $ligne);
		
        echo "Statut curl : $status_curl2"; # statut curl pour vérifier si la commande a fonctionné

        if [[ $status_curl2 = "200" ]] # la commande curl a fonctionné
			then
                encodage=$(file -i ../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html | cut -d= -f2); # détection de l'encodage
			    echo "Encodage intitial : $encodage"; 

            if [[ $encodage == "utf-8" ]] # c'est encodé en utf-8
					then 
					    echo "Dump de $ligne via lynx"; 
                        
                        lynx -dump -nolist -assume_charset=$encodage -display_charset=$encodage ../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html > ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-initial.txt ;
                        
                        # nettoyage du dump
                        cat ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-initial.txt | sh process_sed.sh > ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt;

                        # recherche du motif
                        egrep -i -A 1 -B 1 "$mot" ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt > ../CONTEXTES/$compteur_tableau-$compteur_ligne.txt; # récupération du contexte du mot

                        # programme minigrep
                        perl ../minigrepmultilingue-html/minigrepmultilingue.pl "utf-8" ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt ../minigrepmultilingue-html/motif-regexp.txt ;
						mv resultat-extraction.html ../CONTEXTES/$compteur_tableau-$compteur_ligne.html ;
                        
                        nbmotif=$(egrep -coi $mot ../CONTEXTES/$compteur_tableau-$compteur_ligne.txt);

                        # création index
                        egrep -o "\w+" ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt | sort | uniq -c | sort -r > ../DUMP-TEXT/index-$compteur_tableau-$compteur_ligne.txt ;
                        
                        # écriture dans le tableau
                        echo "Ecriture des résultats dans le tableau"; 
					    echo "<tr><td align=\"center\">$compteur_ligne</td>
                        <td align=\"center\"><a href=\"$ligne\">URL n°$compteur_ligne</a></td>
                        <td align=\"center\"><a href=\"../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html\">Page n° $compteur_tableau-$compteur_ligne</a></td>
                        <td align=\"center\">$encodage</td>
                        <td align=\"center\"><a href=\"../DUMP-TEXT/$compteur_tableau-$compteur_ligne-initial.txt\">Dump n°$compteur_tableau-$compteur_ligne</a></td>
                        <td align=\"center\">-</td>
                        <td align=\"center\"><a href=\"../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt\">Dump n°$compteur_tableau-$compteur_ligne</a></td>
                        <td align=\"center\"><a href=\"../CONTEXTES/$compteur_tableau-$compteur_ligne.html\">Contextes $compteur_tableau-$compteur_ligne</a></td>
                        <td align=\"center\">$nbmotif</td>
                        <td align=\"center\"><a href=\"../DUMP-TEXT/index-$compteur_tableau-$compteur_ligne.txt\">Index n°$compteur_ligne</a></td>
                        </tr>" >> $tableau;

                        # création des fichiers globaux
                        echo "<file=$nbdump>" >> ../FICHIERS-GLOBAUX/contextes-globaux-$compteur_tableau.txt ;
						echo "<file=$nbdump>" >> ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt ;

						cat ../CONTEXTES/$compteur_tableau-$compteur_ligne.txt >> ../FICHIERS-GLOBAUX/contextes-globaux-$compteur_tableau.txt ;
						cat ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt >> ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt ;

                    else 
                    
                        # ce n'est pas encodé en utf-8
                        encodage2=$(file -i ../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html | cut -d= -f2);
                        echo "Encodage récupéré : $encodage2 ";

                        # vérifier si l'encodage est reconnu par la commande iconv
                        test_encodage=$(iconv -l | egrep -o -i $encodage2 | sort -f -u); 
						echo "Vérification de l'encodage : $test_encodage";

                        if [[ $test_encodage == " " ]]
							
                            then # l'encodage n'est pas reconnu par iconv
								echo "Encodage non reconnu"; 
                                echo "Ecriture des résultats dans le tableau";
								echo "<tr><td align=\"center\">$compteur_ligne</td>
                                <td align=\"center\"><a href=\"$ligne\">URL n°$compteur_ligne</a></td>
                                <td align=\"center\"><a href=\"../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html\">Pages n° $compteur_tableau-$compteur_ligne</a></td>
                                <td align=\"center\">$encodage</td>
                                <td align=\"center\">-</td>
                                <td align=\"center\">-</td>
                                <td align=\"center\">-</td>
                                <td align=\"center\">-</td>
                                <td align=\"center\">-</td>
                                </tr>" >> $tableau;
                            
                            else 
                            
                                # l'encodage est reconnu par iconv
                                echo "Dump de $ligne via lynx"; 
								lynx -dump -nolist -assume_charset=$encodage2 -display_charset=$encodage2 ../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html > ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-initial.txt;
                                
                                # conversion
                                iconv -f $encodage2 -t UTF-8 ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-initial.txt > ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-converti.txt; 
                                
                                # nettoyage du dump
                                cat ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-converti.txt | sh process_sed.sh > ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt;
                                
                                # recherche du motif
                                egrep -i -A 1 -B 1 "$mot" ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt > ../CONTEXTES/$compteur_tableau-$compteur_ligne.txt ;
								
                                # minigrep
                                perl ../minigrepmultilingue-html/minigrepmultilingue.pl "utf-8" ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt ../minigrepmultilingue-html/motif-regexp.txt;
					        	mv resultat-extraction.html ../CONTEXTES/$compteur_tableau-$compteur_ligne.html ;

                                nbmotif=$(egrep -coi $mot ../CONTEXTES/$compteur_tableau-$compteur_ligne.txt);

                                # création index
                                egrep -o "\w+" ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt | sort | uniq -c | sort -r > ../DUMP-TEXT/index-$compteur_tableau-$compteur_ligne.txt ;
                                
								# Affichage des résultats dans le tableau
								echo "Ecriture des résultats dans le tableau" ;
								echo "<tr><td align=\"center\">$compteur_ligne</td>
                                <td align=\"center\"><a href=\"$ligne\">URL n°$compteur_ligne</a></td>
                                <td align=\"center\"><a href=\"../PAGES-ASPIREES/$compteur_tableau-$compteur_ligne.html\">Page n° $compteur_tableau-$compteur_ligne</a></td>
                                <td align=\"center\">$encodage</td>
                                <td align=\"center\"><a href=\"../DUMP-TEXT/$compteur_tableau-$compteur_ligne-initial.txt\">Dump n° $compteur_tableau-$compteur_ligne</a></td>
                                <td align=\"center\"><a href=\"../DUMP-TEXT/$compteur_tableau-$compteur_ligne-converti.txt\">Dump n° $compteur_tableau-$compteur_ligne</a></td>
                                <td align=\"center\"><a href=\"../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt\">Dump n° $compteur_tableau-$compteur_ligne</a></td>
                                <td align=\"center\"><a href=\"../CONTEXTES/$compteur_tableau-$compteur_ligne.html\">Contextes $compteur_tableau-$compteur_ligne</a></td>
                                <td align=\"center\">$nbmotif</td>
                                <td align=\"center\"><a href=\"../DUMP-TEXT/index-$compteur_tableau-$compteur_ligne.txt\">Index n°$compteur_ligne</a></td>
                                </tr>" >> $tableau;

                                # création des fichiers globaux
                                echo "<file=$nbdump>" >> ../FICHIERS-GLOBAUX/contextes-globaux-$compteur_tableau.txt ;
						        echo "<file=$nbdump>" >> ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt ;

						        cat ../CONTEXTES/$compteur_tableau-$compteur_ligne.txt >> ../FICHIERS-GLOBAUX/contextes-globaux-$compteur_tableau.txt ;
						        cat ../DUMP-TEXT/$compteur_tableau-$compteur_ligne-nettoyé.txt >> ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt ;

						fi
            fi
        
            else

            echo "Erreur de téléchargement"; # la commande curl n'a pas fonctionné
        fi
    let "nbdump=nbdump+1" ;
    let "compteur_ligne=compteur_ligne+1"; # on passe à l'url suivante
    }

    egrep -o "\w+" ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt | sort | uniq -c | sort -r > ../FICHIERS-GLOBAUX/index-dump-$compteur_tableau.txt ;
	egrep -o "\w+" ../FICHIERS-GLOBAUX/contextes-globaux-$compteur_tableau.txt | sort | uniq -c | sort -r > ../FICHIERS-GLOBAUX/index-contexte-$compteur_tableau.txt ;
	
    # nettoyage du dump
    cat ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt | sh sed_trameur.sh > ../FICHIERS-GLOBAUX/dump-global-$compteur_tableau-nettoyé.txt;

    echo "<tr><td align=\"center\" colspan=\"7\"</td>
    <td align=\"center\" width=\"100\"><a href="../FICHIERS-GLOBAUX/dump-global-$compteur_tableau.txt">Dump<br/>global</a><br/><small>$nbdump fichier(s)</small></td>
    <td align=\"center\" width=\"100\"><a href="../FICHIERS-GLOBAUX/contextes-globaux-$compteur_tableau.txt">Contextes<br/>globaux</a><br/><small>$nbdump fichier(s)</small></td>
    <td colspan="3"</td></tr>" >> $tableau;

	echo "<tr><td align=\"center\" colspan=\"7\"</td>
    <td align=\"center\" width=\"100\"><a href="../FICHIERS-GLOBAUX/index-dump-$compteur_tableau.txt">Index<br/>dump<br/>global</a><br/><small>$nbdump fichier(s)</small></td>
    <td align=\"center\" width=\"100\"><a href="../FICHIERS-GLOBAUX/index-contexte-$compteur_tableau.txt">Index<br/>contextes<br/>globaux</a><br/><small>$nbdump fichier(s)</small></td>
    <td colspan="3"</td></tr>" >> $tableau;

	echo "</table>" >> $tableau;

let "compteur_tableau=compteur_tableau+1"; # on passe au fichier suivant
}
echo "</body></html>" >> $tableau ; # fermeture de la page html


