#!/bin/tcsh

set LIBDIR = ~/Projects/LONLibsRepository/org.apache.cocoon/org.apache.cocoon-2.1.5.1
set XALAN = ${LIBDIR}/xalan-2.6.0.jar
set XMLAPI = ${LIBDIR}/xml-apis.jar
set XERCES = ${LIBDIR}/xercesImpl-2.6.2.jar

if ( "$1" == "") then
	echo "Usage xsl <xsl-file> <input-file> <output-file>"
	exit(1)
endif

set XSL = ${1}
set INPUTDOC = ${2}
set OUTPUTDOC = ${3}
shift
shift
shift
set OPTIONS = $*

java -cp ${XALAN}:${XMLAPI}:${XERCES} org.apache.xalan.xslt.Process ${OPTIONS} -IN ${INPUTDOC} -OUT ${OUTPUTDOC} -XSL ${XSL}

#Patch missing EOL at end of file
cat nl.txt >>${OUTPUTDOC}

cat ${OUTPUTDOC}

#bbedit ${OUTPUTDOC}
