#!/bin/sh

VERSION=$(git describe)

echo "Current version: abraca-$VERSION"
echo -n "Keep? [Y/n] "

read NEW_TAG
if [ x$NEW_TAG = "xN" ] || [ x$NEW_TAG = "xn" ]; then
	echo -n "New version: "
	read VERSION
	git tag -s -m "Abraca $VERSION release." $VERSION
fi

git archive --format=tar --prefix=abraca-${VERSION}/ HEAD | gzip -cn9 > ../abraca-${VERSION}.tar.gz
gpg --armor --detach-sig ../abraca-${VERSION}.tar.gz
