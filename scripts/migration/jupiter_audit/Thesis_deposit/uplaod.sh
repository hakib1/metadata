FILES="/home/danydvd/git/remote/metadata/scripts/migration/jupiter_audit/Thesis_deposit/embargo-jul132108/*"
for f in $FILES
do
	echo $f
	curl -H 'Content-Type: text/turtle' --upload-file $f -X POST "http://206.167.181.124:9999/blazegraph/namespace/Thesis_deposit_Jul132018/sparql"
done
