;This itself does not changes the player direction, but merely changes
;the planned direction when Mario hits a turn special.
;Behaves $25 or $130

incsrc "../../../../SSPDef/Defines.asm"
incsrc "Defines_SwitchablePrepTurn.asm"

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
BodyInside:
HeadInside:
	;Check pipe state
		LDA !Freeram_SSP_PipeDir	;\If not in pipe mode, Return as being a solid block
		AND.b #%00001111		;|
		BEQ Return			;/
	;Render passable
		LDY #$00			;\Become passable when in pipe.
		LDX #$25			;|
		STX $1693|!addr			;/
	;Check if the block should be merely passable.
		CMP #$09			;\If traveling in any direction, do nothing except be passable.
		BCS Return			;/
	;Adjust player pipe travel direction and centering
		JSR DistanceFromTurnCornerCheck
		BCC Return
	;Set prep directions
		LDX #$00
		LDA !SSP_RamSwitch
		BEQ .Direction1
		
		.Direction2
			INX
		.Direction1
		
		LDA !Freeram_SSP_PipeDir		;\Set planned direction based on switches.
		AND.b #%00001111			;|
		ORA.l PrepTurnDirections,x		;|
		STA !Freeram_SSP_PipeDir		;/
WallFeet:
WallBody:
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Return:
	RTL
	DistanceFromTurnCornerCheck:
	;Prevents such glitches where as the player leaves a special turn corner
	;and activates a special direction block while touching the previous corner
	;would cause the player to travel in the wrong direction.
	;
	;$00-$03 holds the position "point" on Mario/yoshi's feet:
	;$00-$01 is the X position in units of block
	;$02-$03 is Y position in units of block
	;
	;AND #$FFF0 rounds DOWN to the nearest #$0010 value
	;Carry is set if the player's position point is inside the block and clear if outside.
	
	LDA $187A|!addr		;\Yoshi Y positioning
	ASL			;|
	TAX			;/
	
	REP #$20
	LDA $94				;\Get X position
	CLC				;|
	ADC #$0008			;|
	AND #$FFF0			;|
	STA $00				;/
	LDA $96				;\Get Y position
	CLC				;|
	ADC FootDistanceYpos,x		;|
	AND #$FFF0			;|
	STA $02				;/
	
	LDA $9A				;\if X position point is within this block
	AND #$FFF0			;|
	CMP $00				;|
	BNE +				;/
	LDA $98				;\if Y position point is within this block
	AND #$FFF0			;|
	CMP $02				;|
	BNE +				;/
	SEC
	SEP #$20
	RTS
	+
	CLC
	SEP #$20
	RTS
	FootDistanceYpos:
	dw $0018, $0028, $0028
	
	PrepTurnDirections:
	db %00000000
	db %00100000
if !Setting_SSP_Description != 0
	print "Sets Mario's pipe prep direction to NULL if $", hex(!SSP_RamSwitch), " is zero, otherwise RIGHT instead."
endif