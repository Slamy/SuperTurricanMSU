CFLAGS= -g

all: out/supertur_msu1_pal.sfc out/supertur_msu1.msu adrConv slamyWav2msu out/supertur_msu1_ntsc.sfc

out/supertur_msu1_pal.sfc: SuperTurricanMSU_PAL.asm
	cp -r Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_pal.sfc
	cp -r Super\ Turrican\ \(Europe\).sfc out/supertur_msu1_pal_higan.sfc
	
	bass                    -o out/supertur_msu1_pal.sfc       SuperTurricanMSU_PAL.asm
	bass -d EMULATOR_VOLUME -o out/supertur_msu1_pal_higan.sfc SuperTurricanMSU_PAL.asm
	
	#cp out/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/program.rom
	#cp out/manifest.bml /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/manifest.bml

out/supertur_msu1_ntsc.sfc: SuperTurricanMSU_NTSC.asm
	cp -r Super\ Turrican\ \(USA\).sfc out/supertur_msu1_ntsc.sfc
	cp -r Super\ Turrican\ \(USA\).sfc out/supertur_msu1_ntsc_higan.sfc
	
	bass                    -o out/supertur_msu1_ntsc.sfc       SuperTurricanMSU_NTSC.asm
	bass -d EMULATOR_VOLUME -o out/supertur_msu1_ntsc_higan.sfc SuperTurricanMSU_NTSC.asm
	
	cp out/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/program.rom


out/supertur_msu1.msu:
	touch out/supertur_msu1.msu

sdcard: out/supertur_msu1.sfc
	cp -v out/supertur_msu1.sfc /media/andre/9016-4EF8/MSU/

compare: out/supertur_msu1.sfc
	hexdump out/supertur_msu1.sfc -C > compareA
	hexdump Super\ Turrican\ \(Europe\).sfc -C > compareB
	diff compareA compareB

clean:
	rm -f out/supertur_msu1.sfc out/supertur_msu1.msu

adrConv: adrConv.c

slamyWav2msu: slamyWav2msu.c

