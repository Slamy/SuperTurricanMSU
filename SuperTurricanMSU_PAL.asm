arch snes.cpu

// MSU memory map I/O
constant MSU_STATUS($2000)
constant MSU_ID($2002)
constant MSU_AUDIO_TRACK_LO($2004)
constant MSU_AUDIO_TRACK_HI($2005)
constant MSU_AUDIO_VOLUME($2006)
constant MSU_AUDIO_CONTROL($2007)

// SPC communication ports
constant SPC_COMM_0($2140)

// MSU_STATUS possible values
constant MSU_STATUS_TRACK_MISSING($8)
constant MSU_STATUS_AUDIO_PLAYING(%00010000)
constant MSU_STATUS_AUDIO_REPEAT(%00100000)
constant MSU_STATUS_AUDIO_BUSY($40)
constant MSU_STATUS_DATA_BUSY(%10000000)


// Variables
variable currentSoundbase($2C0)
variable fadeOut($2C1)
//variable workTemp($2C2)


// **********
// * Macros *
// **********
// seek converts SNES LoROM address to physical address
macro seek(variable offset) {
  origin ((offset & $7F0000) >> 1) | (offset & $7FFF)
  base offset
}


//0c803e wird gecallt, wenn eine Sounddatenbank geladen werden muss.
//A ist ID der Sounddatenbank
//0c803e sta $24       [000024] A:0001 X:0000 Y:0008 S:02ed D:0000 DB:00 nvMXdIzC
//0c8040 asl a                  A:0001 X:0000 Y:0008 S:02ed D:0000 DB:00 nvMXdIzC
//0c8041 clc                    A:0002 X:0000 Y:0008 S:02ed D:0000 DB:00 nvMXdIzc
//0c8042 adc $24       [000024] A:0002 X:0000 Y:0008 S:02ed D:0000 DB:00 nvMXdIzc
//0c8044 sta $24       [000024] A:0003 X:0000 Y:0008 S:02ed D:0000 DB:00 nvMXdIzc


seek($0c803e) //physical 0x6003e
	jml MSU_setSoundBase
  
//0c8191 wird gecallt, wenn ein Subtune der aktuellen Sounddatenbank gespielt werden soll.
//Y ist der zu spielende Subtune
//0c8191 phx                    A:0000 X:0000 Y:0000 S:02ee D:0000 DB:00 nvMXdIZC
//0c8192 ldx $2140     [002140] A:0000 X:0000 Y:0000 S:02ed D:0000 DB:00 nvMXdIZC
//0c8195 bne $8192     [0c8192] A:0000 X:0006 Y:0000 S:02ed D:0000 DB:00 nvMXdIzC
//0c8192 ldx $2140     [002140] A:0000 X:0006 Y:0000 S:02ed D:0000 DB:00 nvMXdIzC

//Leider ist am Anfang sofort eine Schleife... wir manipulieren deshalb die Caller von 0c8191
//Dieser scheint immer an Stelle 0c8006 zu liegen, welcher wiederrum per jsl von überall gecallt wird.

//Wird am Anfang eines Levels oft gecallt
//seek($00884a)
//	jsl MSU_playTRACK

//Wird am Ende für die Siegesmelodie gecallt
//seek($0084af)
//	jsl MSU_playTRACK

//Aus dem Soundtest werden Songs von 7f1443 gespielt.... Das ist aber im RAM
//7f1443 jsl $0c8006   [0c8006] A:0002 X:0000 Y:0002 S:02f1 D:0000 DB:00 nvMXdIzC
//0c8006 jmp $8191     [0c8191] A:0002 X:0000 Y:0002 S:02ee D:0000 DB:00 nvMXdIzC
//0c8191 phx                    A:0002 X:0000 Y:0002 S:02ee D:0000 DB:00 nvMXdIzC

//0ac453 -> 22 -> 7f1443
//;0ac454 -> 06 -> 7f1444
//0ac441 -> 80 -> 7f142f -> 80 -> 7f1445
//0ac442 -> 0c -> 7f1430 -> 0c -> 7f1446

//0ac43f -> 22 -> 7f142d
//0ac440 -> 03 -> 7f142e
//0ac441 -> fe -> 7f142f

//jsl $0c8006 ist hex 22 06 80 0c

//seek($0ac453)
//	db $22,(MSU_playTRACK&$ff)

//seek($0ac441)
//	db ((MSU_playTRACK>>8)&$ff),((MSU_playTRACK>>16)&$ff)


//seek($008440)
//	jsl MSU_playTRACK

//seek($009af1)
//	jsl MSU_playTRACK


seek($0c8191) //physical 0x60191
	jml MSU_playTRACK

seek($0085c4) //physical 0x5c4
	jsl MSU_setVolume

seek($0085f4) //physical 0x5f4
	jsl MSU_setVolume

seek($008852) //physical 0x852, Lautstärke setzen nach starten von Level
	jsl MSU_setVolume


//Decrunching Pfade für den modifizierten Jump bei $0ac447. 2 Fliegen mit einer Klappe

// 0ac447 -> 7f1435 -> 7f144b -> 7f145a
//                            -> 7f1495

// 0ac448 -> 7f1436 -> 7f144c -> 7f145b
//                            -> 7f1496

// 0ac449 -> 7f1437 -> 7f144d -> 7f145c
//                            -> 7f1497

// 0ac44a -> 7f1438 -> 7f144e -> 7f145d
//                            -> 7f1498
seek($0ac447) //physical 0x54447
	jsl MSU_setVolume
	
seek($0084b7) //phyiscal 0x4b7
	jsl MSU_setVolume

seek($009af9) //physical 0x1af9
	jsl MSU_setVolume



//seek($dfb0) //0x5fb0 im headerless ROM
seek($fe90) //physical 0x7ea0 im headerless ROM
scope MSU_playTRACK: {
	//Y Register ist der Subtune
	pha
	phy
	phx
	php
	
CheckAudioStatus:
	lda.w MSU_STATUS
	
	and.b #MSU_STATUS_AUDIO_BUSY
	bne CheckAudioStatus
	
	sep #$30
	//Erstmal Musik stoppen
	lda.b #0
	sta.w MSU_AUDIO_CONTROL
	
	//Subtune = SubtuneTable[SubtuneIndex[currentSoundbase]+Y]
	
	sty.b $10
	ldx.w currentSoundbase //X = currentSoundbase
	lda.l SubtuneIndex,x //A = SubtuneIndex[currentSoundbase] also A = currentSoundbase * 7
	clc
	adc.b $10 //A = SubtuneIndex[currentSoundbase] + Y
	tax
	lda.l SubtuneTable,x
	
	//A enthält nun die Nummer des MSU Tracks.
	//Ist diese -1, wird statt MSU der SPC benutzt.
	cmp.b #-1
	beq useSPC
	//jmp useSPC
	
useMSU:
	and #$7f
	
	cmp #$0e //Level 3-1
	//cmp #$06 //Level 1-2 for testing
	bne noEasterEggCheck //0e ist Level 3-1 Musik... Easter Egg
	
	tay

	lda.w $15fb //Buttons werden vom Spiel eingelesen und hier abgelegt
	and.b #$20  //L-Taste
	php
	tya
	plp
	beq noEasterEggCheck
	
	lda.b #22 //Lade Easter Egg Melodie
	
noEasterEggCheck:
	
	sta.w MSU_AUDIO_TRACK_LO
	
	lda.b #0
	sta.w MSU_AUDIO_TRACK_HI
	
CheckAudioStatus2:
	lda.w MSU_STATUS
	
	and.b #MSU_STATUS_AUDIO_BUSY
	bne CheckAudioStatus2
	
	
// Check if track is missing
	lda.w MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne useSPC
	
	
	lda SubtuneTable,x //Wenn das oberste Bit 1 ist, so mache es zu $02 -> Repeat
	rol
	rol
	rol
	and.b #$03
	ora.b #$01 //Audio play
	sta.w MSU_AUDIO_CONTROL
	
	lda.b #0
	sta.w fadeOut
	
	lda.b #$FF
	sta.w MSU_AUDIO_VOLUME
	
	// The MSU1 will now start playing.
	// Use lda #$03 to play a song repeatedly.
	
	//Den aktuell spielenden SPC Song abschalten. Nur notwendig, wenn von SPC auf MSU umgeschaltet wird.
	
	lda.b #3
	ldy.b #$2a
	jsl $0c818d
	
	
	plp
	plx
	ply
	pla
	rtl

useSPC:
	plp
	plx
	ply
	pla
	
	//Kopiert von 0c8191
	phx
useSPCloop: //normalerweise $8192
	ldx.w $2140
	bne useSPCloop
	sty.w $2141
	lda.b #$02
	sta.w $2140
	jml $0c81b3
}
	
	//Sounddatenbank zu MSU Index LUT
SubtuneIndex:
	db 0, 7, 7*2, 7*3, 7*4
SubtuneTable:
	//Sounddatenbank 0 - Welt 1
	
	db 128 | 4 //Level 1-1
	db 128 | 6 //Leve 1-2
	db -1 //Level 1-X geschafft
	db -1 //???
	db 128 | 8 //Level 1-1 Boss
	db 7 //Level 1-1 Boss Intro
	db 128 | 5 //Level 1-2
	
	//Sounddatenbank 1 - Welt 2
	
	db 128 | 9 //Level 2-1
	db 128 | 10 //Level 2-2
	db -1 //Level 2-X geschafft
	db -1 //???
	db 128 | 12 //Level 2-3 Boss Intro
	db 128 | 13 //Level 2-3 Boss
	db 128 | 11 //Level 2-3
	
	//Sounddatenbank 2 - Welt 3
	
	db 128 | 14 //Level 3-1
	db 128 | 16 //Level 3-2
	db -1 //Level 3-X geschafft
	db -1 //???
	db 128 | 18 //Unused boss theme ?
	db 128 | 17 //Level 3-3
	db 128 | 15 //Level 4-2. Was hat sich der Chris dabei gedacht? :D
	
	//Sounddatenbank 3 - Welt 4
	
	db 128 | 19 //Level 4-1 im Soundtest
	db 128 | 19 //Level 4-1 im Spiel..... lol wut? O.o
	db -1 //Level 4-X geschafft
	db -1 //???
	db 128 | 21 //Level 4-3 Boss
	db -1 //???
	db 128 | 20 //Level 4-3
	
	//Sounddatenbank 4 - Title und Abspann
	
	db 1 //Intro
	db 2 //Titel
	db 3 //Abspann
	
	
scope MSU_setSoundBase: {
	php
	sep #$30
	sta.l currentSoundbase
	plp
	
	//Überschriebene Routinen hier ausführen
	sta $24 
	asl
	clc
	
	jml $0c8042
	
}

scope MSU_NMI: {
	//Entferntes plb vorher ausführen, um die richtige DB zu erhalten.
	plb

	sep #$30
	
	lda.w fadeOut
	beq noFade //Wenn in fadeOut etwas anderes steht als 0, so dekrementiere und nimm es als Lautstärke
	
	dec
	dec
	dec
	dec
	dec
	dec
	
	sta.w MSU_AUDIO_VOLUME
	sta.w fadeOut
	
noFade:

	//Entferntes nachholen
	rep #$30
	lda.w $0300
	
	jml $00800b
}

scope MSU_setVolume: {
	
	cmp.b #$00
	bne noFade
	
	pha
	lda.b #252 //Muss durch 5 teilbar sein
	sta.w fadeOut
	pla
	
	jml $0c8012 //springe zur normalen Lautstärkeroutine

noFade:

	//Y scheint etwas mit faden zu tun zu haben.
	pha
	
	lda.w fadeOut
	beq noFadeActive
	lda.b #0
	sta.w MSU_AUDIO_CONTROL
noFadeActive:

	lda.b #0
	sta.w fadeOut
	pla
	
	//Lautstärke vom SPC ist von 0 bis 7f in A
	//Da die Lautstärke vom MSU von 0 bis ff geht, rechnen wir hier *2
	pha
	asl
	sta.w MSU_AUDIO_VOLUME
	pla
	
	//Der SPC ist zu laut... zumindest beim sd2snes.
	//>>1 ist ganz ok. Der SPC ist aber immer noch eine Idee zu laut
	//>>2 ist ganz ok. Der SPC ist aber manchmal zu leise.
	//>>1 + >>2
	
	//Wir halbieren seine Lautstärke testweise
	//if !{defined EMULATOR_VOLUME} {
	
	//lsr >>1 + >>2
	//sta.b workTemp
	//lsr
	//clc
	//adc.b workTemp
	
	//>>2: Schon ganz gut. Aber ein kleines bissle lauter könnte es.
	//lsr
	//lsr
	
	//>>2 + >>3
	//lsr
	//lsr
	//sta.b workTemp
	//lsr
	//clc
	//adc.b workTemp
	
	//}
	
	if {defined EMULATOR_VOLUME} {
	//Feste Lautstärke für SPC?
	lda.b #$7f
	} else {
	lda.b #$30
	}
	
	jml $0c8012
}

scope MSU_stopPlayback: {
	
	pha 
	lda.b #0
	sta.w MSU_AUDIO_CONTROL
	pla
	
	jml $0c8042
}

scope MSU_stopPlayback_withNMIDisable: {

	//Das entfernte abschalten des NMI nachholen
	lda #$00
	sta $4200
	
	lda.b #0
	sta.w MSU_AUDIO_CONTROL
	
	jml $00d332
}

//scope Title_ChangeText: {
//	lda #$0000
//	rtl
//}

//Ausgeführt, wenn neue SPC Daten geladen werden.
//seek($00ff5b) //physical 0x7f5b
//	jml MSU_stopPlayback //FIXME ich hack hier meinen eigenen Code O.o



//Verantwortlich für FadeOut
//009adb jsl $0c8012   [0c8012] A:0000 X:000a Y:0018 S:02f1 D:0000 DB:01 nvMXdIzc
seek($009adb) //physical 0x1adb
	jsl MSU_setVolume

//Lautstärke für Soundeffekte
//Instruktion ist str $0f3=#$7f für Volume auf 100%
//In Hex ist das 8F 7F F3
//Im ROM an nur 2 Stellen zu finden. Das ist schön ^^

//seek($c8f9f+1)
//	db $60

//seek($c8fa5+1)
//	db $60


//Stellt die Gesamtlautstärke für Musik und Soundeffekte im SPC ein
//009adb jsl $0c8012   [0c8012] A:0000 X:000a Y:0018 S:02f1 D:0000 DB:01 nvMXdIzc


//008007 plb                    A:0001 X:0000 Y:0080 S:02f0 D:0000 DB:00 nvmxdIzC
//008008 lda $0300     [000300] A:0001 X:0000 Y:0080 S:02f1 D:0000 DB:00 nvmxdIZC
//00800b and #$00ff             A:2c01 X:0000 Y:0080 S:02f1 D:0000 DB:00 nvmxdIzC

seek($008007) //physical 0x7
	jml MSU_NMI


//Wenn im Titelbildschirm Start gedrückt wird, wird NMI abgeschaltet. Der FadeOut funzt dann nicht mehr. Wir fangen dieses Ereignis ab und schalten den MSU auf Stopp
//00d32d lda #$00               A:0000 X:0000 Y:0019 S:02f9 D:0000 DB:00 nvMxdIZC
//00d32f sta $4200     [004200] A:0000 X:0000 Y:0019 S:02f9 D:0000 DB:00 nvMxdIZC
//00d332 lda #$ff               A:0000 X:0000 Y:0019 S:02f9 D:0000 DB:00 nvMxdIZC

seek($00d32d) //physical 0x532d
	jml MSU_stopPlayback_withNMIDisable

//TODO
//- Lautstärke wird am Level-Ende wieder auf voll zurückgesetzt
//- Level 5-1 hat normale Musik O.o


//Titeltext verändern
//Bei 7f1920 eine gute Chance einzusteigen.

//7f191c plb                    A:2232 X:007f Y:0070 S:02f4 D:4300 DB:7f nvMXdIzc
//7f191d rep #$30               A:2232 X:007f Y:0070 S:02f5 D:4300 DB:7f nvMXdIzc
//7f191f tax                    A:2232 X:007f Y:0070 S:02f5 D:4300 DB:7f nvmxdIzc
//7f1920 lda #$0000             A:2232 X:2232 Y:0070 S:02f5 D:4300 DB:7f nvmxdIzc
//7f1923 tcd                    A:0000 X:2232 Y:0070 S:02f5 D:4300 DB:7f nvmxdIZc
//7f1924 tay                    A:0000 X:2232 Y:0070 S:02f5 D:0000 DB:7f nvmxdIZc
//7f1925 stx $eb       [0000eb] A:0000 X:2232 Y:0000 S:02f5 D:0000 DB:7f nvmxdIZc


//Instruktion bei 7f1920 wird von 7f1240 geladen.
//Das kommt aber wiederrum von 7f11b6
//Das kommt dann aber von 7f038b
//Das kommt dann aber von 7f0144 etc.
//Am Ende sind wir bei 0ab3b0. Im ROM ist das $533b0

//seek($533b0)
//	jsl Title_ChangeText

//origin ($54f8A)
//	db "-MSU " //LICEN
//seek($0abe87) //S
//	db 'H'
//origin ($53c8c) //E
//	db 'A'
//origin ($53bed) //D
//	db 'C'
//seek($0abbee) //' '
//	db 'K'
//origin ($54f93) //NINTENDO
//	db " BY SLAMY- "
	

//origin ($54f8A)
//	db "ABCDE" //LICEN
//seek($0abe87) //S
//	db 'F'
//origin ($53c8c) //E
//	db 'G'
//origin ($53bed) //D
//	db 'H'
//seek($0abbee) //' '
//	db 'I'
//origin ($54f93) //NINTENDO
//	db "JKLMNOPQRST"


//7f19e8 jsr $1917     [7f1917] A:2232 X:0000 Y:0070 S:02f7 D:4300 DB:7f nvmxdIzc
//00df09 lda [$5a],y   [0ac6d2] A:8022 X:172c Y:c6d2 S:02f3 D:0000 DB:7f NVMxdIzc
//Hier springt er zur Ausgabe des Titelbild Strings über DMA. Der String ist also ausgepackt im Speicher


//7f19e8 jsr $1917     [7f1917] A:2232 X:0000 Y:0070 S:02f7 D:4300 DB:7f nvmxdIzc A:2
//7f1917 sep #$30               A:2232 X:0000 Y:0070 S:02f5 D:4300 DB:7f nvmxdIzc A:2
//7f1919 ldx #$7f               A:2232 X:0000 Y:0070 S:02f5 D:4300 DB:7f nvMXdIzc A:2
//7f191b phx                    A:2232 X:007f Y:0070 S:02f5 D:4300 DB:7f nvMXdIzc A:2
//7f191c plb                    A:2232 X:007f Y:0070 S:02f4 D:4300 DB:7f nvMXdIzc A:2
//7f191d rep #$30               A:2232 X:007f Y:0070 S:02f5 D:4300 DB:7f nvMXdIzc A:2
//7f191f tax                    A:2232 X:007f Y:0070 S:02f5 D:4300 DB:7f nvmxdIzc A:2
//7f1920 lda #$0000             A:2232 X:2232 Y:0070 S:02f5 D:4300 DB:7f nvmxdIzc A:2
//7f1923 tcd                    A:0000 X:2232 Y:0070 S:02f5 D:4300 DB:7f nvmxdIZc
//7f1924 tay                    A:0000 X:2232 Y:0070 S:02f5 D:0000 DB:7f nvmxdIZc
//7f1925 stx $eb       [0000eb] A:0000 X:2232 Y:0000 S:02f5 D:0000 DB:7f nvmxdIZc
//7f1927 rep #$20               A:0000 X:2232 Y:0000 S:02f5 D:0000 DB:7f nvmxdIZc
//7f1929 lda #


//0ac822 -> 7f1919
//0ac823 -> 7f191a
//0ac824 -> 7f191b
//0ac825 -> 7f191c
seek($0ac822) //physical 0x54822
	jsl ModTitle


seek($dfb0) //0x5fb0 im headerless ROM
ModTitle:
	pha
	phx
	
	ldx.b #0
ModTitle_loop:
	
	lda.l modString,x
	beq ModTitle_loopEnd
	sta.w $2282,x
	inx
	bra ModTitle_loop
	
ModTitle_loopEnd:

	plx
	pla
	
	
	//ersetzte zerstörte Instruktion
	ldx #$7f
	phx
	plb
	rtl

modString:
	db " SLAMY MSU HACK 0.4 ",0



seek($bfd70)

//0c8246 060246 sta $2140     [002140] A:0000 X:2d6d Y:2d6c S:02f1 D:0000 B:00 nvmxdIZC //zu ersetzen
//0c8249 060249 sep #$30               A:0000 X:2d6d Y:2d6c S:02f1 D:0000 B:00 nvmxdIZC
//0c824b 06024b rts                    A:0000 X:006d Y:006c S:02f1 D:0000 B:00 nvMXdIZC

scope workaround_16bitWrite3: {
    pha
    txa
    sep #$20 //A ist nun 8 bit
    sta $2140
    xba
    sta $2141
    rep #$20 //A ist nun wieder 16 bit
    pla
    
    sep #$30 //replace removed instruction
    rtl
    
}



//0c8216 060216 stx $2140     [002140] A:f781 X:0001 Y:00c7 S:02f7 D:0000 B:00 nvmxdIzC
//0c8219 060219 ldy #$0000             A:f781 X:0001 Y:00c7 S:02f7 D:0000 B:00 nvmxdIzC
//0c821c 06021c cpx $2140     [002140] A:ec89 X:0001 Y:0000 S:02ee D:0000 B:00 nvmxdIZC
scope workaround_16bitWrite4: {
    pha
    txa
    sep #$20 //A ist nun 8 bit
    sta $2140
    xba
    sta $2141
    rep #$20 //A ist nun wieder 16 bit
    pla
    
    ldy #$0000
    rtl
}



//0c8208 060208 stx $2140     [002140] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 nvmxdIzC //zu ersetzen, weil 16 bit write bei $2140 nicht erlaubt ist
//0c820b 06020b cpx $2140     [002140] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 nvmxdIzC
//0c820e 06020e bne $820b     [0c820b] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 NvmxdIzc
//0c8210 060210 lda $20       [000020] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 nvmxdIZC
//0c8212 060212 sta $2142     [002142] A:e009 X:0000 Y:0004 S:02f1 D:0000 B:00 NvmxdIzC

//0c8236 060236 stx $2140     [002140] A:dc35 X:0005 Y:0003 S:02f1 D:0000 B:00 nvmxdIzC
//SPC Write 0 <= 05
//SPC Write 1 <= 00

scope workaround_16bitWrite: {
    pha
    txa
    sep #$20 //A ist nun 8 bit
    sta $2140
    xba
    sta $2141
    rep #$20 //A ist nun wieder 16 bit
    pla
    
    //replaces overwritten loop
loop:
    cpx $2140
    bne loop
    
    jml $0c8210


    
//0c8227 060227 stx $2140     [002140] A:002c X:0008 Y:0006 S:02f1 D:0000 B:00 nvmxdIzC //zu ersetzen, weil 16 bit write bei $2140 nicht erlaubt ist
//0c822a 06022a iny                    A:002c X:0008 Y:0006 S:02f1 D:0000 B:00 nvmxdIzC

scope workaround_16bitWrite2: {
    pha
    txa
    sep #$20 //A ist nun 8 bit
    sta $2140
    xba
    sta $2141
    rep #$20 //A ist nun wieder 16 bit
    pla
    
    iny //replaces missing iny
    
    rtl


seek($0c8208)
    jml workaround_16bitWrite

seek($0c8227)
    jsl workaround_16bitWrite2

seek($0c8236)
    jsl workaround_16bitWrite2


seek($0c8246)
    jsl workaround_16bitWrite3
    nop

seek($0c8216)
    jsl workaround_16bitWrite4
    nop
    nop

