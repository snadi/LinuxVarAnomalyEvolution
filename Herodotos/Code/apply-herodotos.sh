#!/bin/bash

# Automagischer Herodotos Skript
# 
#  * Erzeugt in $WORKDIR/kernel checkouts der Kernel Versionen
#    $KERNELS und lässt den undertaker auf diesen laufen.  
#  * Baut eine vollständige herodotos infrastruktur in
#    $WORKDIR/herodotos und verwendet diese, um korrelationen zwischen
#    den Kernel versionen zu bauen und zu visualisieren.

WORKDIR=$(pwd)
UPSTREAM=git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
KERNELS="v2.6.37 v2.6.38 v2.6.39 v3.0 v3.1 v3.2 v3.3 v3.4 v3.5 v3.6"
BITTENSOURCE=$(pwd)/
#PATH="$(pwd)/bin:/usr/local/bin:/usr/bin:/bin:/proj/i4vamos/tools/bin/"
LOGPATH=$(pwd)/logs
SUBCOMPONENTS="core=kernel"

echo $PATH

get_kernels () {
	[ -d repository ] || git clone $UPSTREAM repository
	for version in $KERNELS
	do
		if [ ! -d $version ]
		then
			cp -r repository $version
			cd $version
			git checkout $version
			cd ..
		fi
#		[ ! $version = "master" ] || (cd $i ; git remote update)
	done
}

__undertaker_run_internal () {
	cd $1
	pwd
	git clean -fdxq
	git reset --hard $1
	bash -x `which undertaker-kconfigdump`
	which undertaker-linux-tree
	nice -n 20 undertaker-linux-tree
	cd ..
}

run_undertaker () {
	undertaker -V
	for version in $KERNELS
	do
		#sleep 0
		__undertaker_run_internal $version > $LOGPATH/`date -I`-undertaker-$version.log 2>&1
	done
}

get_config () {
	cp -f $BITTENSOURCE/herodotos/Makefile .
	cp -f $BITTENSOURCE/herodotos/linux.hc .
}

run_herodotos () {
	echo "in here"
	herodotos --version
	make init
	make all
	make correl
	find results/kernel -name '*.orig.org' -exec sed -i '/>/d' {} \; #remove the lines starting with < causing errors
	find results -name '*correl*' -exec sed -i -e 's,\* TODO,* UNRELATED,g' {} \;
	make correl
	find results -name '*new*' -exec sed -i -e 's,\* TODO,* BUG,g' {} \;
	make correl
	make web
	for result in results/kernel/*.new.org;
	do
		herodotos --prefix $WORKDIR/kernel/ --parse_org $result --to-sql
		herodotos --prefix $WORKDIR/kernel/ --parse_org $result --to-sql-notes
	done >> `date -I`.sql
} #> $LOGPATH/`date -I`-herodotos.log 2>&1

__copy() {
	dest=${1%%=*}
	source=${1##*=}

	for version in $KERNELS
	do
		rm -rf $dest/$version
		mkdir -p $dest/$version
		echo cp -r kernel/$version/$source $dest/$version
		cp -r kernel/$version/$source $dest/$version
	done
}

copy () {
	for component in $SUBCOMPONENTS
	do
		__copy $component
	done
}

do_undertaker_run () {(
	mkdir -p kernel
	cd kernel
	get_kernels
	run_undertaker
)}

do_herodotos_run () {(
	#rm -rf cwd
	#mkdir -p cwd
	#cd cwd
	#mv ../kernel .
	#copy
	#get_config
	run_herodotos
	#mv kernel ..
)}

publish () {
	place=~/public_html/.herodotos-`date -I`
	if [ ! -d $place ]
	then
		cp -r cwd/website $place
	fi
}

main () {
	echo "in main"	
	run_herodotos	
	#do_undertaker_run
	#do_herodotos_run || (mv cwd/kernel . && exit 23)
	#publish
}

main
