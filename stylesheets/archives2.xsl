<xsl:stylesheet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="fn" xmlns="urn:isbn:1-931666-33-4"
    xpath-default-namespace="urn:isbn:1-931666-33-4"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0"
    exclude-result-prefixes="fn xsl xs">
    
    <xsl:output method="text"/>
    
    <xsl:function name="fn:rows" as="xs:string+">
        <xsl:param name="str" as="xs:string"/>
        <xsl:analyze-string select="concat($str, ',')" regex="([^\t][^\t]*)\t?|\t">
            <xsl:matching-substring>
                <xsl:sequence select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:variable name="docs"
        select="collection('../metadata-wrangling/archives/aor-ualberta-archives?select=*.xml;recurse=yes')"/>
    <xsl:param name="doc" select="'file:///home/mparedes/main-metadata.git/metadata-wrangling/archives/Mimsy_entities_uploaded.tsv'"/>

    <xsl:param name="pPat">"</xsl:param>
    <xsl:param name="pRep">\\"</xsl:param>
    
    <xsl:template match="/">
        <xsl:text>typeOfEntity&#09;authorizedFormOfName&#09;nameEntry-part&#09;datesOfExistence&#09;history&#09;biogHist&#09;XML file&#xa;</xsl:text>
        <xsl:for-each select="$docs//nameEntry">
            <xsl:variable name="file" select="replace(base-uri(), 'file:/home/mparedes/main-metadata.git/metadata-wrangling/archives/aor-ualberta-archives/', '')"/>
            <xsl:variable name="name" select="tokenize(replace($file, '.xml', ''), '-')"/>
            <xsl:value-of select="$name[1]"/>
            <xsl:text>&#xa;</xsl:text>
<!--            <xsl:value-of select="$name"/>
            <xsl:value-of select="$name1"/>
            <xsl:text>&#xa;</xsl:text>-->
            <xsl:variable name="boghist" select="../../description/biogHist/p"/>
            
            <xsl:choose>
                <xsl:when test="unparsed-text-available($doc)">
                    <xsl:variable name="tsv" select="unparsed-text($doc)"/>
                    <xsl:variable name="lines" select="tokenize($tsv, '&#xa;')" as="xs:string+"/>
                    <xsl:for-each select="$lines[position() &gt; 1]">
                        <xsl:variable name="lineItems" select="fn:rows(.)" as="xs:string+"/>
                        <xsl:variable name="Aname" select="translate($lineItems[2], '', '')"/>
                        <xsl:variable name="Aname" select="replace($Aname, $pPat, '')"/>
                        <xsl:variable name="Aname" select="replace($Aname, $pRep, '')"/>
                        <xsl:variable name="Aname" select="tokenize($Aname, ',')"/>
                        <xsl:value-of select="$Aname[1]"/>
                        <xsl:text>&#xa;</xsl:text>
                        <!--<xsl:choose>
                            <xsl:when test="$name[1] = $Aname[1]">
                                <xsl:value-of select="$name"/>
                                <!-\-<xsl:value-of select="$lineItems[1]"/>
                                <xsl:text>&#09;</xsl:text>
                                <xsl:value-of select="$lineItems[2]"/>
                                <xsl:text>&#09;</xsl:text>
                                <xsl:value-of select="$name"/>
                                <xsl:text>&#09;</xsl:text>
                                <xsl:value-of select="$lineItems[3]"/>
                                <xsl:text>&#09;</xsl:text>
                                <xsl:value-of select="$lineItems[4]"/>
                                <xsl:text>&#09;</xsl:text>
                                <xsl:value-of select="$boghist"/>
                                <xsl:text>&#09;</xsl:text>
                                <xsl:value-of select="$file"/>
                                <xsl:text>&#xa;</xsl:text>-\->
                            </xsl:when>
                        </xsl:choose> -->                      
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>

        </xsl:for-each>

    </xsl:template>

</xsl:stylesheet>
