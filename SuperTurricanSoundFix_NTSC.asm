arch snes.cpu

// **********
// * Macros *
// **********
// seek converts SNES LoROM address to physical address
macro seek(variable offset) {
  origin ((offset & $7F0000) >> 1) | (offset & $7FFF)
  base offset
}


//seek($dfb0) //0x5fb0 im headerless ROM


//0c8208 060208 stx $2140     [002140] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 nvmxdIzC //zu ersetzen, weil 16 bit write bei $2140 nicht erlaubt ist
//0c820b 06020b cpx $2140     [002140] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 nvmxdIzC
//0c820e 06020e bne $820b     [0c820b] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 NvmxdIzc
//0c8210 060210 lda $20       [000020] A:1300 X:0000 Y:0004 S:02f1 D:0000 B:00 nvmxdIZC
//0c8212 060212 sta $2142     [002142] A:e009 X:0000 Y:0004 S:02f1 D:0000 B:00 NvmxdIzC

//0c8236 060236 stx $2140     [002140] A:dc35 X:0005 Y:0003 S:02f1 D:0000 B:00 nvmxdIzC
//SPC Write 0 <= 05
//SPC Write 1 <= 00

seek($fea0) //physical 0x7ea0 im headerless ROM
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
    


seek($0ac5ad)
	jsl ModTitle


seek($dfb0) //0x5fb0 im headerless ROM
ModTitle:
	pha
	phx
	
	ldx.b #0
ModTitle_loop:
	
	lda.l modString,x
	beq ModTitle_loopEnd
	sta.w $2278,x
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
	db " SLAMY SOUNDFIX 0.1 ",0

