CFLAGS= -g

all: out/supertur_msu1.sfc out/supertur_msu1.msu adrConv slamyWav2msu

out/supertur_msu1.sfc: supertur_msu1.asm
	cp -r Super\ Turrican\ \(Europe\).sfc out/supertur_msu1.sfc
	hexdump -C out/supertur_msu1.sfc -v > hexdumpOrig 
	bass -o out/supertur_msu1.sfc supertur_msu1.asm
	cp out/supertur_msu1.sfc /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/program.rom
	cp out/manifest.bml /home/andre/Emulation/Super\ Famicom/supertur_msu1.sfc/manifest.bml
	hexdump -C out/supertur_msu1.sfc -v > hexdumpMod
	#diff hexdumpOrig hexdumpMod

out/supertur_msu1.msu:
	touch out/supertur_msu1.msu

clean:
	rm -f out/supertur_msu1.sfc out/supertur_msu1.msu

adrConv: adrConv.c

slamyWav2msu: slamyWav2msu.c
