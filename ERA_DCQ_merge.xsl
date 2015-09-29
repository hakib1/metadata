<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:foxml="info:fedora/fedora-system:def/foxml#"
    xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:ualterms="http://terms.library.ualberta.ca"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:eraterms="http://era.library.ualberta.ca/eraterms"
    xmlns:thesis="http://www.ndltd.org/standards/metadata/etdms/1.0/"
    xmlns:vivo="http://vivoweb.org/ontology/core"
    xmlns:marcrel="http://id.loc.gov/vocabulary/relators"
    xmlns:bibo="http://purl.org/ontology/bibo/"
    exclude-result-prefixes="xs xd"
    version="3.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Sep 28, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> mparedes</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:import href="newDCQ.xsl"/>
    <xsl:output method="xml" encoding="UTF-8"/>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="foxml:digitalObject">
        <xsl:copy>
            <xsl:namespace name="dcterms">http://purl.org/dc/terms/</xsl:namespace>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:if test="not(foxml:datastream[@ID='DCQ'])">
                <xsl:call-template name="newDCQ-theses"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="foxml:datastream[@ID='DCQ']">
        <xsl:call-template name="newDCQ-theses"/>
    </xsl:template>
    
    
    <!-- New DCQ datastream based on enhanced dc record and either DCQ or DC existing handle and proquest ids -->
    <xsl:template name="newDCQ-theses">
        <xsl:element name="foxml:datastream" inherit-namespaces="no">
            <xsl:attribute name="CONTROL_GROUP">X</xsl:attribute>
            <xsl:attribute name="ID">DCQ</xsl:attribute>
            <xsl:attribute name="STATE">A</xsl:attribute>
            <xsl:attribute name="VERSIONABLE">true</xsl:attribute>
            <xsl:element name="foxml:datastreamVersion" inherit-namespaces="no">
                <xsl:attribute name="ID">DCQ.0</xsl:attribute>
                <xsl:attribute name="LABEL">Item Metadata</xsl:attribute>
                <xsl:attribute name="MIMETYPE">text/xml</xsl:attribute>
                <xsl:element name="foxml:xmlContent">
                    <xsl:variable name="filename" select="concat('/I:/Hydra_DAMS/ERA/ERA_migration/FOXML_transformed/PSL/psl_15/new_data/',replace(//ualterms:fedora3uuid,':','_'),'.xml')"/>
                    <xsl:copy select="document($filename)/dc">
                        <xsl:apply-templates/>
                        <xsl:copy-of select="datastreamVersion[last()]//ualterms:fedora3handle"/>
                        <xsl:copy-of select="datastreamVersion[last()]//ualterms:proquest"/>
                    </xsl:copy>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    
    
</xsl:stylesheet>