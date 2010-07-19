#!/bin/sh

OS=`uname -s`
echo "We are $OS"

OPT_ROOT=/usr

echo "Opt is $OPT_ROOT"
echo

YUM="yum -y"
MV="mv -v"
CP="cp -v"
RM="rm -v"
MKDIR="mkdir -v"
LN='ln -v -s'

export PATH=$OPT_ROOT/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

