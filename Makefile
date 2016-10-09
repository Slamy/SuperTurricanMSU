CFLAGS= -g

all: adrConv slamyWav2msu \
	out/supertur_msu1.msu \
	out/supertur_msu1_pal_sd2snes.ips \
	out/supertur_msu1_pal_higan.ips \
	out/supertur_msu1_ntsc_higan.ips \
	out/supertur_msu1_ntsc_sd2snes.ips


out/supertur_msu1_pal_sd2snes.ips: SuperTurricanMSU_PAL.asm
	cp -r Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_pal_sd2snes.sfc
	bass                    -o out/supertur_msu1_pal_sd2snes.sfc SuperTurricanMSU_PAL.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_pal_sd2snes.sfc out/supertur_msu1_pal_sd2snes.ips

out/supertur_msu1_pal_higan.ips: SuperTurricanMSU_PAL.asm
	cp -r Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_pal_higan.sfc
	bass -d EMULATOR_VOLUME -o out/supertur_msu1_pal_higan.sfc   SuperTurricanMSU_PAL.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_pal_higan.sfc out/supertur_msu1_pal_higan.ips
	
	#cp out/supertur_msu1_pal_higan.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/program.rom

out/supertur_msu1_ntsc_higan.ips: SuperTurricanMSU_NTSC.asm
	cp -r Super\ Turrican\ \(USA\).sfc out/supertur_msu1_ntsc_higan.sfc
	bass -d EMULATOR_VOLUME -o out/supertur_msu1_ntsc_higan.sfc   SuperTurricanMSU_NTSC.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_ntsc_higan.sfc out/supertur_msu1_ntsc_higan.ips
	
	

out/supertur_msu1_ntsc_sd2snes.ips: SuperTurricanMSU_NTSC.asm
	cp -r Super\ Turrican\ \(USA\).sfc out/supertur_msu1_ntsc_sd2snes.sfc
	bass                    -o out/supertur_msu1_ntsc_sd2snes.sfc SuperTurricanMSU_NTSC.asm
	wine flips --create Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_ntsc_sd2snes.sfc out/supertur_msu1_ntsc_sd2snes.ips
	
	cp out/supertur_msu1_ntsc_sd2snes.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/program.rom

out/supertur_msu1.msu:
	touch out/supertur_msu1.msu

sdcard: all
	cp out/supertur_msu1_ntsc_sd2snes.sfc /media/andre/9016-4EF8/MSU/SuperTurricanNTSC/supertur_msu1.sfc
	cp out/supertur_msu1_pal_sd2snes.sfc /media/andre/9016-4EF8/MSU/SuperTurricanPAL/supertur_msu1.sfc

compare: out/supertur_msu1.sfc
	hexdump out/supertur_msu1.sfc -C > compareA
	hexdump Super\ Turrican\ \(Europe\).sfc -C > compareB
	diff compareA compareB

clean:
	rm -f out/*.sfc out/*.ips

adrConv: adrConv.c

slamyWav2msu: slamyWav2msu.c

