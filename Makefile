CFLAGS= -g

all:	out/SuperTurricanSoundFix_PAL.bps \
	out/SuperTurricanSoundFix_NTSC.bps \

out/SuperTurricanSoundFix_PAL.bps: SuperTurricanSoundFix_PAL.asm Makefile
	cp -r Super\ Turrican\ \(Europe\).sfc out/SuperTurricanSoundFix_PAL.sfc
	bass -o out/SuperTurricanSoundFix_PAL.sfc SuperTurricanSoundFix_PAL.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/SuperTurricanSoundFix_PAL.sfc out/SuperTurricanSoundFix_PAL.bps

out/SuperTurricanSoundFix_NTSC.bps: SuperTurricanSoundFix_NTSC.asm Makefile
	cp -r Super\ Turrican\ \(USA\).sfc out/SuperTurricanSoundFix_NTSC.sfc
	bass -o out/SuperTurricanSoundFix_NTSC.sfc SuperTurricanSoundFix_NTSC.asm
	wine flips --create Super\ Turrican\ \(USA\).sfc out/SuperTurricanSoundFix_NTSC.sfc out/SuperTurricanSoundFix_NTSC.bps

	
sdcard: all
	cp out/SuperTurricanSoundFix_PAL.sfc /media/andre/9016-4EF8/SuperTurricanSoundFix_PAL.sfc
	cp out/SuperTurricanSoundFix_NTSC.sfc /media/andre/9016-4EF8/SuperTurricanSoundFix_NTSC.sfc

comparePAL: out/SuperTurricanSoundFix_PAL.bps
	hexdump out/SuperTurricanSoundFix_PAL.sfc -Cv > compareA
	hexdump Super\ Turrican\ \(Europe\).sfc -Cv > compareB
	meld compareA compareB

compareNTSC: out/SuperTurricanSoundFix_NTSC.bps
	hexdump out/SuperTurricanSoundFix_NTSC.sfc -Cv > compareA
	hexdump Super\ Turrican\ \(USA\).sfc -Cv > compareB
	meld compareA compareB

clean:
	rm -f out/*.sfc out/*.ips out/*.bps out/*/*.bps out/*/*.ips

higanPAL: all
	cp out/SuperTurricanSoundFix_PAL.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/supertur_msu1.sfc

higanOrigPAL: all
	cp Super\ Turrican\ \(Europe\).sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/supertur_msu1.sfc

higanNTSC: all
	cp out/SuperTurricanSoundFix_NTSC.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/supertur_msu1.sfc

