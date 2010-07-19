#!/bin/sh 

source ./config.sh

myFile=$1

sudo echo ""

gem sources -a http://gems.github.com

while [ 1 ]
do
	read name version || break
	echo " Gemming $name $version"
	if [ -n "$version" ]; then
	  echo $OPT_ROOT/bin/gem install $name -v $version
	  sudo $OPT_ROOT/bin/gem install $name -v $version
        else
	  echo $OPT_ROOT/bin/gem install $name
	  sudo $OPT_ROOT/bin/gem install $name
	fi

done < $myFile 

