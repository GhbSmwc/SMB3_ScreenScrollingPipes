;~@sa1
;This block will be solid if mario isn't in a pipe, if he is, will let him go
;through this block (mainly use as parts of a pipe that never changes his
;direction).
;behaves $130

incsrc "SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside



TopCorner:
MarioAbove:
MarioSide:
HeadInside:
BodyInside:
MarioBelow:
	LDA !Freeram_SSP_PipeDir	;\be a solid block if mario isn't pipe status.
	AND.b #%00001111		;|
	BEQ return			;/
	LDY #$00			;\become passable
	LDA #$25			;|
	STA $1693|!addr			;/
	
	LDA $14AF|!addr			;\If on/off switch is ON (#$00), don't flip direction.
	BEQ return			;/
	
	LDA !Freeram_SSP_PipeDir
	TAX
	LDA ReverseDirectionTable-1,x
return:
	RTL
	
	
ReverseDirectionTable:
	db #$03				;>From up to down
	db #$04				;>From right to left
	db #$01				;>From down to up
if !Setting_SSP_Description != 0
print "Reverses the player's pipe direction if the on/off switch is OFF."
endif