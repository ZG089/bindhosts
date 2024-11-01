#!/usr/bin/env sh
MODDIR="/data/adb/modules/bindhosts"

# grab own info (version)
versionCode=$(grep versionCode $MODDIR/module.prop | sed 's/versionCode=//g' )

# test out writables, prefer tmpfs
folder=$MODDIR
[ -w /debug_ramdisk ] && folder=/debug_ramdisk


echo "[+] bindhosts v$versionCode"
echo "[%] action.sh"
echo "[%] standalone hosts-based-adblocking implementation"
if [ ${KSU} = true ] ; then
	# it still works on magisk
	# do some checks later like if user has Adaway installed
	echo "[%] 🚨 not compatible with AdAway ❌"
fi

# just in case user deletes them
files="custom.txt blacklist.txt sources.txt whitelist.txt"
for i in $files ; do
	if [ ! -f $MODDIR/$i ] ; then
		# dont do anything weird, probably intentional
		echo "[-] $i not found."
		touch $MODDIR/$i
	fi	
done


if [ -w $MODDIR/system/etc/hosts ] ; then
	# probe for downloaders
     	# low pref, no ssl, b-b-b-b-but that libera/freenode(rip) meme
     	# https doesn't hide the fact that i'm using https so that's why i don't use encryption because everyone is trying to crack encryption so i just don't use encryption because no one is looking at unencrypted data because everyone wants encrypted data to crack
        busybox | grep wget > /dev/null 2>&1 && alias download='busybox wget --no-check-certificate -qO -'
        # higher pref, most of the times has ssl on android
        which curl > /dev/null 2>&1 && alias download='curl -s'
else
	# no fucking way
	echo "[x] unwritable hosts file 😭 needs correction 💢" ; sleep 5 ; exit 1
fi

##### functions
illusion () {
	x=$((RANDOM%4 + 6)); while [ $x -gt 1 ] ; do echo '[.]' ; sleep 0.1 ; x=$((x-1)) ; done &
}

adblock() {
	illusion
	# sources	
	echo "[+] processing sources"
	grep -v "#" $MODDIR/sources.txt | grep http > /dev/null || (echo "[x] no sources found 😭" ; echo "[x] sources.txt needs correction 💢")
	for url in $(grep -v "#" $MODDIR/sources.txt | grep http) ; do 
		echo "[+] grabbing.."
		echo "[*] >$url"
		download "$url" >> $folder/temphosts || echo "[x] failed downloading $url"
		 # add a newline incase they dont
		echo "" >> $folder/temphosts
	done
	# localhost
	printf "127.0.0.1 localhost\n::1 localhost\n" > $MODDIR/system/etc/hosts
	# always restore user's custom rules
	grep -v "#" $MODDIR/custom.txt >> $MODDIR/system/etc/hosts
	# blacklist.txt
	for i in $(grep -v "#" $MODDIR/blacklist.txt ); do echo "0.0.0.0 $i" >> $folder/temphosts; done
	# whitelist.txt
	echo "[+] processing whitelist"
	# optimization thanks to Earnestly from #bash on libera, TIL something 
	# sed strip out everything with #, double space to single space, replace all 127.0.0.1 with 0.0.0.0
	# then sort uniq, then grep out whitelist.txt from it
	sed '/#/d; s/  / /g; s/127.0.0.1/0.0.0.0/' $folder/temphosts | sort -u | grep -Fxvf $MODDIR/whitelist.txt >> $MODDIR/system/etc/hosts
	# mark it, will be read by service.sh to deduce
	echo "# bindhosts v$versionCode" >> $MODDIR/system/etc/hosts
}

reset() {
	echo "[+] reset toggled!" 
	# localhost
	printf "127.0.0.1 localhost\n::1 localhost\n" > $MODDIR/system/etc/hosts
	# always restore user's custom rules
	grep -v "#" $MODDIR/custom.txt >> $MODDIR/system/etc/hosts
        string="description=status: disabled ❌ "
        sed -i "s/^description=.*/$string/g" $MODDIR/module.prop
        illusion
        sleep 1
        echo "[+] hosts file reset!"
        # reset state
        rm $folder/bindhosts_state
        sleep 3
}
run() {
	adblock
	illusion
	sleep 1
	echo "[+] action.sh blocked $(grep -c "0.0.0.0" $MODDIR/system/etc/hosts ) hosts!"
	string="description=status: active ✅ | action.sh blocked $(grep -c "0.0.0.0" $MODDIR/system/etc/hosts ) hosts"
	sed -i "s/^description=.*/$string/g" $MODDIR/module.prop
	# ready for reset again
	(cd $MODDIR ; (cat blacklist.txt custom.txt sources.txt whitelist.txt ; date +%F) | md5sum | cut -f1 -d " " > $folder/bindhosts_state )
	# cleanup
	rm $folder/temphosts	
	sleep 3
}

# toggle
if [ -f $folder/bindhosts_state ]; then
	# handle rule changes, add date change detect, I guess a change of 1 day to update is sane.
	newhash=$(cd $MODDIR ; (cat blacklist.txt custom.txt sources.txt whitelist.txt ; date +%F) | md5sum | cut -f1 -d " ")
	oldhash=$(cat $folder/bindhosts_state)
	if [ $newhash == $oldhash ]; then
		# well if theres no rule change, user just wants to disable adblocking
		reset
	else
		echo "[+] rule change detected!"
		echo "[*] new: $newhash"
		echo "[*] old: $oldhash"
		run
	fi
else
	# basically if no bindhosts_state and hosts file is marked, it likely device rebooted, assume user is triggering an upgrade.
	grep "# bindhosts v" $MODDIR/system/etc/hosts > /dev/null 2>&1 && echo "[+] update triggered!"
	run
fi

# EOF
