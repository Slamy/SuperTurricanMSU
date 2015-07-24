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
variable currentSoundbase($bf0)

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

//seek($dfb0) //0x5fb0 im headerless ROM
seek($fea0) //7ea0 im headerless ROM
scope MSU_playTRACK: {
	//Y Register ist der Subtune
	pha
	phy
	php
	
	sep #$30
	//Erstmal Musik stoppen
	lda.b #0
	sta.w MSU_AUDIO_CONTROL
	
	//Subtune = SubtuneTable[SubtuneIndex[currentSoundbase]+Y]
	
	sty.b $10
	ldy.w currentSoundbase
	lda SubtuneIndex,y
	clc
	adc.b $10
	tay
	lda SubtuneTable,y
	
	//A enthält nun die Nummer des MSU Tracks.
	//Ist diese -1, wird statt MSU der SPC benutzt.
	cmp.b #-1
	beq useSPC
	//jmp useSPC
	
useMSU:
	and #$7f
	sta.w MSU_AUDIO_TRACK_LO
	
	lda.b #0
	sta.w MSU_AUDIO_TRACK_HI
	
	lda SubtuneTable,y //Wenn das oberste Bit 1 ist, so mache es zu $02 -> Repeat
	rol
	rol
	rol
	and #$03
	ora #$01 //Audio play
	sta.w MSU_AUDIO_CONTROL
	
	lda.b #$30
	sta.w MSU_AUDIO_VOLUME
	
	// The MSU1 will now start playing.
	// Use lda #$03 to play a song repeatedly.
	
	plp
	ply
	pla
	rtl

useSPC:
	plp
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
	
	db 128 | 3 //Level 1-1
	db 4 //Leve 1-3
	db -1 //Level 1-X geschafft
	db -1 //???
	db 7 //Level 1-1 Boss
	db 6 //Level 1-1 Boss Intro
	db 5 //Level 1-2
	
	//Sounddatenbank 1 - Welt 2
	
	db 8 //Level 2-1
	db 9 //Level 2-2
	db -1 //Level 2-X geschafft
	db -1 //???
	db 11 //Level 2-3 Boss Intro
	db 12 //Level 2-3 Boss
	db 10 //Level 2-3
	
	//Sounddatenbank 2 - Welt 3
	
	db 13 //Level 3-1
	db 15 //Level 3-2
	db -1 //Level 3-X geschafft
	db -1 //???
	db 17 //Unused boss theme ?
	db 16 //Level 3-3
	db 14 //Level 4-2. Was hat sich der Chris dabei gedacht? :D
	
	//Sounddatenbank 3 - Welt 4
	
	db 18 //Level 4-1
	db -1 //???
	db -1 //Level 4-X geschafft
	db -1 //???
	db 20 //Level 4-3 Boss
	db -1 //???
	db 19 //Level 4-3
	
	//Sounddatenbank 4 - Title und Abspann
	
	db 0
	db 1
	db 2
	
	
scope MSU_setSoundBase: {
	php
	sep #$30
	sta.w currentSoundbase
	plp
	
	//Überschriebene Routinen hier ausführen
	sta $24 
	asl
	clc
	
	
	jml $0c8042
	
}
