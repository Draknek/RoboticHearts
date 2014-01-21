#!/bin/sh

/cygdrive/e/dev/air/ipa/mkipa app.xml hearts.ipa "$1" ../hearts.swf thumb*.png iTunesArtwork.png Default*

exit

#adt=/cygdrive/e/downloads/air-2.7-win/bin/adt.bat
#adt='sh /data/downloads/flex-4.5.1/bin/adt'

space=32m
#adt="wine java -Xms$space -Xmx$space -jar /data/downloads/air-2.7-win/lib/adt.jar"
#wine=wine
#java='C:/Program Files (x86)/Java/jre6/bin/java.exe'
java=java
jar="E:/downloads/air-2.7-win/lib/adt.jar"
#spaceargs="-Xms$space -Xmx$space"
#jar="/media/data/downloads/air-2.7-win/lib/adt.jar"
#jar="Z:\data\downloads\air-2.7-win\lib\adt.jar"
#jar="/data/downloads/lib/adt.jar"

#export WINEDEBUG=+heap

swf=hearts.swf

$wine "$java" $spaceargs -jar $jar -package -target ipa-app-store -provisioning-profile Distribution.mobileprovision -keystore Distribution.p12 -storetype pkcs12 hearts.ipa app.xml $swf thumb29.png thumb48.png thumb57.png thumb72.png thumb114.png iTunesArtwork.png 
