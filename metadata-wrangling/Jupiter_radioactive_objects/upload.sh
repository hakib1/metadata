for file in ./*/*.xml ;
do	
	echo "uploading $file"
      curl -H 'Content-Type: application/rdf+xml' --upload-file $file -X POST "http://sheff.library.ualberta.ca:9999/blazegraph/namespace/radioactive/sparql"
done

