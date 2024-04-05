#!/bin/bash
rm -r Duplicata/src/backup/
rm Duplicata/obj/*.*
rm Duplicata/src/*.stat
rm Duplicata/src/*.lps
rm Duplicata/bin/listemots.txt
rm Duplicata/bin/Records.html
mkdir backup
mv Duplicata/bin/*.html backup
mv Duplicata/bin/*.ini backup
mv Duplicata/bin/Duplicata backup
rm duplazlnxsrc.tar.gz
tar -zcvf duplazlnxsrc.tar.gz ./Duplicata ./Download ./prepare.sh
mv backup/*.* Duplicata/bin/
mv backup/Duplicata Duplicata/bin/
rmdir backup/
ls -alrt duplazlnxsrc.tar.gz

