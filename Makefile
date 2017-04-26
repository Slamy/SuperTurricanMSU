CFLAGS= -g

all: adrConv slamyWav2msu \
	out/supertur_msu1.msu \
	out/PAL/supertur_msu1.bps \
	out/NTSC/supertur_msu1.bps \
	out/sd2snesRevF/PAL/supertur_msu1.bps \
	out/sd2snesRevF/NTSC/supertur_msu1.bps


out/PAL/supertur_msu1.bps: SuperTurricanMSU_PAL.asm Makefile
	cp -r Super\ Turrican\ \(Europe\).sfc out/PAL/supertur_msu1.sfc
	bass -d EMULATOR_VOLUME -o out/PAL/supertur_msu1.sfc SuperTurricanMSU_PAL.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/PAL/supertur_msu1.sfc out/PAL/supertur_msu1.bps

out/NTSC/supertur_msu1.bps: SuperTurricanMSU_NTSC.asm Makefile
	cp -r Super\ Turrican\ \(USA\).sfc out/NTSC/supertur_msu1.sfc
	bass -d EMULATOR_VOLUME -o out/NTSC/supertur_msu1.sfc SuperTurricanMSU_NTSC.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/NTSC/supertur_msu1.sfc out/NTSC/supertur_msu1.bps

out/sd2snesRevF/PAL/supertur_msu1.bps: SuperTurricanMSU_PAL.asm Makefile
	cp -r Super\ Turrican\ \(Europe\).sfc out/sd2snesRevF/PAL/supertur_msu1.sfc
	bass -o out/sd2snesRevF/PAL/supertur_msu1.sfc SuperTurricanMSU_PAL.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/sd2snesRevF/PAL/supertur_msu1.sfc out/sd2snesRevF/PAL/supertur_msu1.bps

out/sd2snesRevF/NTSC/supertur_msu1.bps: SuperTurricanMSU_NTSC.asm Makefile
	cp -r Super\ Turrican\ \(USA\).sfc out/sd2snesRevF/NTSC/supertur_msu1.sfc
	bass -o out/sd2snesRevF/NTSC/supertur_msu1.sfc SuperTurricanMSU_NTSC.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/sd2snesRevF/NTSC/supertur_msu1.sfc out/sd2snesRevF/NTSC/supertur_msu1.bps


out/supertur_msu1.msu:
	touch out/supertur_msu1.msu


sdcard: all
	cp out/NTSC/supertur_msu1.sfc /media/andre/9016-4EF8/MSU/SuperTurricanNTSC/supertur_msu1.sfc
	cp out/PAL/supertur_msu1.sfc /media/andre/9016-4EF8/MSU/SuperTurricanPAL/supertur_msu1.sfc

comparePAL: out/PAL/supertur_msu1.bps
	hexdump out/PAL/supertur_msu1.sfc -Cv > compareA
	hexdump Super\ Turrican\ \(Europe\).sfc -Cv > compareB
	meld compareA compareB

compareNTSC: out/NTSC/supertur_msu1.bps
	hexdump out/NTSC/supertur_msu1.sfc -Cv > compareA
	hexdump Super\ Turrican\ \(USA\).sfc -Cv > compareB
	meld compareA compareB

clean:
	rm -f out/*.sfc out/*.ips out/*.bps out/*/*.sfc out/*/*.ips out/*/*.bps out/*/*/*.ips out/*/*/*.bps

adrConv: adrConv.c

slamyWav2msu: slamyWav2msu.c

higanPAL: all
	cp out/PAL/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc
	cp out/PAL/manifest.bml /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/

higanNTSC: all
	cp out/NTSC/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc
	cp out/NTSC/manifest.bml /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/

higanLegacyPAL: all
	cp out/sd2snesRevF/PAL/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc
	cp out/PAL/manifest.bml /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/
	
higanLegacyNTSC: all
	cp out/sd2snesRevF/NTSC/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc
	cp out/NTSC/manifest.bml /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/


md5sum: all
	md5sum *.sfc ./out/*/*.sfc ./out/*/*/*.sfc 
