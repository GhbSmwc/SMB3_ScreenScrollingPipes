incsrc "../../SSPDef/Defines.asm"

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
	LDA !Freeram_SSP_PipeDir	;\If not in pipe mode, Return as being a solid block
	AND.b #%00001111		;|
	BEQ Done			;/
	LDY #$00			;\Become passable when in pipe.
	LDX #$25			;|
	STX $1693|!addr			;/
	CMP #$05
	BCC .Direction
	SEC
	SBC #$04
	.Direction
	ASL
	TAX
	REP #$20
	LDA.l BlockPickXPos-2,x
	STA $00
	STZ $02
	SEP #$20
	%CheckIfPlayerBottom16x16CenterIsInBlock()
	BCS Done
	STZ $00
	%SSPSetVisibility()
;WallFeet:	; when using db $37
;WallBody:

SpriteV:
SpriteH:

MarioCape:
MarioFireball:
Done:
RTL

BlockPickXPos: ;Need to offset depending on left or right because Mario turns invisible after "peeking" out the other side.
	dw $0000
	dw $0002
	dw $0000
	dw $FFFE

print "Makes the player become visible when pass through during a screen scrolling pipe travel."
