#!/bin/sh
if [ -z "$1" ]; then
	echo "need a filename"
	exit 1
fi

echo "Is $1 the Application you want to clean up? [y/N]"
read A

case $A in
	[Yy]* )
		echo "* Running cleanup"
		;;
	[Nn]* )
		echo "Aborting..."
		exit 1
		;;
	* )
		echo you did not say yes or no;;
esac

echo "* Pre cleanup size:" $(du -sh $1 | awk '{print $1}')
echo "* Removing hicolors icon theme"
rm -rf $1/Contents/Resources/share/icons/hicolor
echo "* Stripping libraries"
find $1 -name '*.dylib' -exec strip -u -r {} +
echo "* Done, size:" $(du -sh $1 | awk '{print $1}')
