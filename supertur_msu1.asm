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

// Constants
if {defined EMULATOR_VOLUME} {
	constant FULL_VOLUME($50)
	constant DUCKED_VOLUME($20)
} else {
	constant FULL_VOLUME($FF)
	constant DUCKED_VOLUME($60)
}

constant FADE_DELTA(FULL_VOLUME/45)

// Variables
variable currentSoundbase($2C0)
variable fadeOut($2C1)

// FADE_STATE possibles values
constant FADE_STATE_IDLE($00)
constant FADE_STATE_FADEOUT($01)
constant FADE_STATE_FADEIN($02)

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


seek($0c803e)
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
//0ac454 -> 06 -> 7f1444
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


seek($0c8191)
	jml MSU_playTRACK

seek($0085c4)
	jsl MSU_setVolume

seek($0085f4)
	jsl MSU_setVolume

seek($008852) //Lautstärke setzen nach starten von Level
	jsl MSU_setVolume

seek($0ac447)
	jsl MSU_setVolume
	
seek($0084b7)
	jsl MSU_setVolume

seek($009af9)
	jsl MSU_setVolume



//seek($dfb0) //0x5fb0 im headerless ROM
seek($fea0) //7ea0 im headerless ROM
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
	db 128 | 5 //Leve 1-2
	db -1 //Level 1-X geschafft
	db -1 //???
	db 128 | 8 //Level 1-1 Boss
	db 7 //Level 1-1 Boss Intro
	db 128 | 6 //Level 1-2
	
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
	beq noFade //Wenn in fadeOut etwas anderes steht als 0, so dekrentiere und nimm es als Lautstärke
	
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
	//Wir halbieren seine Lautstärke testweise
	lsr
	

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

//Ausgeführt, wenn neue SPC Daten geladen werden.
seek($00ff5b)
	jml MSU_stopPlayback


//Verantwortlich für FadeOut
//009adb jsl $0c8012   [0c8012] A:0000 X:000a Y:0018 S:02f1 D:0000 DB:01 nvMXdIzc
seek($009adb)
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

seek($008007)
	jml MSU_NMI


//Wenn im Titelbildschirm Start gedrückt wird, wird NMI abgeschaltet. Der FadeOut funzt dann nicht mehr. Wir fangen dieses Ereignis ab und schalten den MSU auf Stopp
//00d32d lda #$00               A:0000 X:0000 Y:0019 S:02f9 D:0000 DB:00 nvMxdIZC
//00d32f sta $4200     [004200] A:0000 X:0000 Y:0019 S:02f9 D:0000 DB:00 nvMxdIZC
//00d332 lda #$ff               A:0000 X:0000 Y:0019 S:02f9 D:0000 DB:00 nvMxdIZC
seek($00d32d)
	jml MSU_stopPlayback_withNMIDisable

//TODO
//- Lautstärke wird am Level-Ende wieder auf voll zurückgesetzt
//- Level 5-1 hat normale Musik O.o

