#!/bin/bash
echo
echo this script must be run from within /trunk/public/scripts in order to work
echo
echo cd ../../../branches/hud_installer/
echo svn --force export hud ~/Desktop/hud
echo cd ~/Desktop/hud/pmog\@gamelayers.com/chrome/
echo not doing zip -r pmog.jar pmog/content/* pmog/skin/*
echo 
echo did not create pmog\@gamelayers.com/chrome/pmog.jar
echo 
echo cd ..
echo zip -r pmog.xpi install.rdf chrome.manifest chrome
echo mv pmog.xpi ../
echo
echo pmog.xpi in ~/Desktop/hud
echo move pmog.xpi into /trunk/public/firefox/ to publicly update
echo you can copy this line to do that yourself:
echo mv ~/Desktop/hud/pmog.xpi ../firefox/
echo
echo
echo use of this script is depricated - see trunk/doc/firefox_xpi_build.txt
echo