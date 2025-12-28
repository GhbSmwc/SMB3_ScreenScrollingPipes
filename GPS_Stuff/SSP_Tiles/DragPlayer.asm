;~@sa1
;This is the stem part of the pipe that makes Mario
;goes in “drag mode”. For normal-sized pipes, it is
;the left side of vertical pipes or bottom for
;horizontal stems. Small pipes, should be obvious.
;
;To edit the warp destinations, it is located in
;BlockRoutines/SSPDragMarioMode.asm.
;Behaves $25 or $130

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
SSPWarpmode:
	;Check
		LDA !Freeram_SSP_PipeDir	;\Pipe state
		AND.b #%00001111		;/
		BNE +
		;BEQ Done			;>If outside the pipe, do nothing
		RTL
		+
	;Render passable
		LDY #$00			;\Become passable when in pipe.
		LDX #$25			;|
		STX $1693|!addr			;/
	;Failsafe
		CMP #$09			;\Just in case for some reason you managed to interact with this block
		;BCS Done			;/while in drag mode (for 1-frame), so this is a failsafe.
		BCC +
		RTL
		+
	;Check if the player's position point at his feet is “mostly in this block”.
		REP #$20
		LDA #$FFFE
		STA $00
		STZ $02
		SEP #$20
		%CheckIfPlayerBottom16x16CenterIsInBlock()
		;BCC Done
		BCS +
		RTL
		+
	;Check directions to determine a XY position threshold the player goes to state $09:
		LDA !Freeram_SSP_PipeDir	;\Pipe state
		AND.b #%00001111		;/
		;Merge duplicate directions (caps and stems) so that the table is much smaller
			CMP #$05			;\States 5-8 becomes 1-4
			BCC .AlreadyLessThan5		;/
			
			.SwitchToLessThan5
				SEC				;\convert states to 1-4
				SBC #$04			;/
			.AlreadyLessThan5
		;Determine direction
			CMP #$01
			BEQ .Up
			CMP #$02
			BEQ .Right
			CMP #$03
			BEQ .Down
			CMP #$04
			BEQ .Left
			RTL			;>Failsafe
	;Player XY position threshold to enter state $09 (waits till the player is “centered”, then enter such state).
	;Note that snapping the player XY coordinate is unnecessary when reaching this threshold, since the player will
	;not interact with objects at this point, and there is no way a problem can happen if he is off-center. What matters
	;is precise positioning upon reaching his destination.
		.Up
			LDA $187A|!addr
			ASL
			TAX
			REP #$20
			LDA $98					;\Block Y position
			AND #$FFF0				;/
			SEC					;\1 or 2 blocks up
			SBC.l YoshiYPositionThresholdOffset,x	;/
			CMP $96					;>Compare with player's Y position
			SEP #$20
			BPL .VertEnterState9			;>If block Y pos is >= player's (or playerY is <= BlockY), enter state 9
			RTL
		.Right
			REP #$20
			LDA $9A					;\Block X position
			AND #$FFF0				;/
			CMP $94					;>Compare with Player's X
			SEP #$20
			BEQ .HorizEnterState9
			BMI .HorizEnterState9			;>If block X =< Player X (or Player X >= Block X), state 9.
			RTL
		.Down
			LDA $187A|!addr
			ASL
			TAX
			REP #$20
			LDA $98					;\Block Y position
			AND #$FFF0				;/
			SEC					;\1 or 2 blocks up
			SBC.l YoshiYPositionThresholdOffset,x	;/
			CMP $96					;>Compare with player's Y position
			SEP #$20
			BEQ .VertEnterState9
			BMI .VertEnterState9			;>If block Y pos is <= player's (or playerY is >= BlockY), enter state 9
			RTL
		.Left
			REP #$20
			LDA $9A					;\Block X position
			AND #$FFF0				;/
			CMP $94					;>Compare with Player's X
			SEP #$20
			BPL .HorizEnterState9			;>If block X >= Player X (or Player X <= Block X), state 9.
			RTL
		;These prevent the player potentially going past the block by a few pixel after entering warp mode.
		;This is to prevent a potential bug in which non-SSP-related blocks placed next to this block
		;can be interacted with. Note they do not center both X and Y, it only centers the player's X
		;position when traveling horizontally and Y position when vertically to address that the player
		;is not always centered-horizontally given that normal-sized vertical pipes is centered within
		;2 blocks while small vertical pipes is within a single block.
			.HorizEnterState9
				%SSPDragMarioMode()
				BCS Done
				REP #$20
				LDA $9A
				AND #$FFF0
				STA $94
				SEP #$20
				RTL
			.VertEnterState9
				PHX
				%SSPDragMarioMode()
				PLX
				BCS Done
				REP #$20
				LDA $98
				AND #$FFF0
				SEC
				SBC.l YoshiYPositionThresholdOffset,x
				STA $96
				SEP #$20
				RTL
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Done:
	RTL
YoshiYPositionThresholdOffset:
	;In units of blocks, plus 1 to avoid potential interaction with blocks place below this.
		dw $0011
		dw $0021
		dw $0021

if !Setting_SSP_Description != 0
	print "Causes the player to enter warp pipe mode and drags the player to his destination"
endif