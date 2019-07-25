#!/bin/bash

# definicion arreglo de directorios
# directories=("original_foxml" "original_mods" "transformed")

# # cada i es el nombre de el directorio en el loop
# for i in "${directories[@]}"
# do
#    : 
#    # si no existe el directorio llamado $1 crealo
# 	if [ ! -d "$i" ]; then
# 		echo "Creating directories 'original_foxml', 'original_mods', and 'transformed'"
# 		mkdir ./$i
# 		echo "Directories created"
# 	fi
# done

echo "Getting list of Avalon records"
echo -n "Enter password:"
read -s pass
echo

#./prep_fixes.sh


##### Use lines below when getting foxml and other fedora 3 objects #####
# python3 ./get_query.py
# python3 ./get_list.py
# echo "Getting Avalon records"
##### Foxml #####
xargs -i wget --limit-rate=45k --wait=10 --random-wait --remote-encoding=utf-8 --user fedoraAdmin --password $pass -O './original_foxml/{}.xml' 'http://avalon.library.ualberta.ca:8080/fedora/objects/{}/objectXML' < avalon_pids.txt
##### SectionsMetadata #####
xargs -i wget --limit-rate=45k --wait=10 --random-wait --remote-encoding=utf-8 --user fedoraAdmin --password $pass -O './original_sectionsMetadata/{}.xml' 'http://avalon.library.ualberta.ca:8080/fedora/objects/{}/datastreams/sectionsMetadata/content' < MediaObject_pids.txt


##### Use when getting mods records post-migration #####
echo "Getting list of Avalon media objects"
wget -O 'MediaObject_pids.txt' 'http://avalon.library.ualberta.ca:8080/solr/avalon/select?q=has_model_ssim%3Ainfo%3Afedora%2Fafmodel%3AMediaObject&rows=10000&fl=id&wt=csv&indent=true'
sed 's%\(\(..\)\(..\)\(..\)\(..\).\)$%http:\/\/avalon6-test.library.ualberta.ca:8984\/fedora\/rest\/staging\/\2\/\3\/\4\/\5\/\{\1\}\/descMetadata%g' <MediaObject_pids.txt > MediaObject_urls.txt ##\{((..)(..)(..)(..).)$
#http://avalon6-test.library.ualberta.ca:8984/fedora/rest/staging/8s/45/q8/76/8s45q876k/descMetadata
#$2/$3/$4/$5/{$1}/descMetadata

##### Use when getting mods records pre-migration #####
# wget -O 'MediaObject_pids.txt' 'http://avalon.library.ualberta.ca:8080/solr/avalon/select?q=has_model_ssim%3A%22info%3Afedora%2Fafmodel%3AMediaObject%22&rows=1000000&fl=id&wt=csv&indent=true'
# sed 's%\(.*\)$%http:\/\/avalon.library.ualberta.ca:8080\/fedora\/objects\/\{\1\}\/datastreams\/descMetadata\/content%g' <MediaObject_pids.txt >MediaObject_urls.txt



echo "Getting Avalon mods records"
xargs -n 1 curl --limit-rate 45k --raw -u fedoraAdmin:$pass -o 'original_mods/#1.xml' < MediaObject_urls.txt


echo "Transforming records"
#run xslt(s)
# cd ~/metadata
rm original_mods/id.xml
rm original_mods/.gitignore
java -jar saxon9he.jar -s:original_mods -o:transformed -xsl:mods_transform.xsl
echo "*
!.gitignore" > original_mods/.gitignore
echo "Transformation successful"

# echo "Committing to Avalon Migration repository"
#add, commit and push to repo working branch
#add something to check difference?
#pull request?

date=$(date +%Y%m%d)
name="-avalon-mods.zip"
filename=$date$name
#zip folder with today's date
zip -r migration_packages/$filename transformed
echo "Transformation complete, files compressed into migration_packages/"$filename