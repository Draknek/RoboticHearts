#!/bin/sh

#AMAZON="-airDownloadURL http://www.amazon.com/gp/mas/dl/android?p=com.adobe.air"

bin/adt -package -target apk $AMAZON -storetype pkcs12 -keystore sampleCert.pfx -storepass 1234 hearts.apk app.xml hearts.swf thumb36.png thumb48.png thumb72.png
