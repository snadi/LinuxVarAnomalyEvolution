#!/bin/bash

. common.sh

ALL=1

while read RELEASE; do
		ID=$(echo $RELEASE | cut -d' ' -f1)
		NAME=$(echo $RELEASE | cut -d' ' -f2)
		DATE=$(echo $RELEASE | cut -d' ' -f3)
		VERSION=$(echo $NAME | tr -d v)

		MAIN=$(echo $VERSION | cut -d'.' -f1)
		MAJOR=$(echo $VERSION | cut -d'.' -f2)
		MINOR=$(echo $VERSION | cut -d'.' -f3)

		if [ -z "$MINOR" ]; then
				echo "insert into versions (version_name, main, major, release_date) values ('$ID', $MAIN, $MAJOR, timestamp '$DATE');"
		else
				echo "insert into versions (version_name, main, major, minor, release_date) values ('$ID', $MAIN, $MAJOR, $MINOR, timestamp '$DATE');"
		fi

		if [ -n "$ALL" ]; then
				FULL=$LINUXES/$NAME
				LEN=$[${#FULL} + 1]
				for FN in $(find $LINUXES/$NAME -iname "*\.[chS]"); do
						ALLDIR=$(dirname $FN)
						DIR=${ALLDIR:$LEN}"/"
						FILE=$(basename $FN)

						FAMILY=$(echo $DIR | cut -d'/' -f1)
						TYPE=$(echo $DIR | cut -d'/' -f2)
						IMPL=$(echo $DIR | cut -d'/' -f3)
						OTHER=$(echo $DIR | cut -d'/' -f4-)

						echo "insert into file_names (file_name, family_name, type_name, impl_name, other_name)"
						echo "  select '$DIR$FILE', '$FAMILY', '$TYPE', '$IMPL', '$OTHER'"
						echo "    where not exists (select * from file_names f where f.file_name='$DIR$FILE');"
						echo "insert into files (file_name, version_name) values ('$DIR$FILE', '$ID');"
				done
				echo
		fi

done < $VERSION_FILE