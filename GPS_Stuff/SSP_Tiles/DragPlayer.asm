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
	LDA !Freeram_SSP_PipeDir	;\Pipe state
	AND.b #%00001111		;/
	BNE +
	;BEQ Done			;>If outside the pipe, do nothing
	RTL
	+
	LDY #$00			;\Become passable when in pipe.
	LDX #$25			;|
	STX $1693|!addr			;/
	CMP #$09			;\Just in case for some reason you managed to interact with this block
	;BCS Done			;/while in drag mode (for 1-frame), so this is a failsafe.
	BCC +
	RTL
	+
	REP #$20					;\Check if player is lined up with the blocks
	LDA #$FFFE					;|
	STA $00						;|
	STZ $02						;|
	SEP #$20					;|
	%CheckIfPlayerBottom16x16CenterIsInBlock()	;/
	BCS +
	RTL
	+
	;Note to developers here: Yes, this looks like "SSPChangeDirection.asm",
	;But there's one problem, this ASM file is a block, not a routine, that is used by both
	;regular and small vertical pipes, thus, we have 2 separate horizontal centering positions:
	;Centered between 2 blocks for regular-sized vertical pipes, and centered within a
	;block for small pipes. Thus we are better off not messing with the X position for vertical
	;traveling.
	LDA !Freeram_SSP_PipeDir	;\Pipe state
	AND.b #%00001111		;/
	CMP #$05			;\States 5-8 becomes 1-4
	BCC .StemSpeeds			;/
	.CapSpeeds
		SEC				;\convert states to 1-4 (corresponding directions)
		SBC #$04			;/
	.StemSpeeds
		ASL
		TAX
		JMP (.SSPDirectionPointers-2,x)
		
	.SSPDirectionPointers
		dw .Up
		dw .Right
		dw .Down
		dw .Left
	.Up
		%Get_Player_XPosition_RelativeToBlock()		;\Vertically-traveling Mario must be either be block-centered (small pipe) or 8 pixels to the right (regular-sized pipe) of the block to trigger.
		BMI Done					;|
		CMP #$09					;|
		BPL Done					;/
		JSR CompareYPositionToCheck
		BEQ .VerticalEntering
		BMI .VerticalEntering
		RTL
	.Right
		%Get_Player_XPosition_RelativeToBlock()
		BPL .HorizontalEntering
		RTL
	.Down
		%Get_Player_XPosition_RelativeToBlock()		;\Vertically-traveling Mario must be either be block-centered (small pipe) or 8 pixels to the right (regular-sized pipe) of the block to trigger.
		BMI Done					;|
		CMP #$09					;|
		BPL Done					;/
		JSR CompareYPositionToCheck
		BPL .VerticalEntering
		RTL
	.Left
		%Get_Player_XPosition_RelativeToBlock()
		BEQ .HorizontalEntering
		BMI .HorizontalEntering
		RTL

	.HorizontalEntering
		%SSPDragMarioMode()
		BCS Done
		LDA $9A							;\Center horizontally
		AND #$F0						;|
		STA $94							;|
		if !Setting_SSP_SetXYFractionBits			;|
			LDA.b #!Setting_SSP_XPositionFractionSetTo	;|
			STA $13DA|!addr					;|
		endif							;/
		RTL
	.VerticalEntering
		%SSPDragMarioMode()
		BCS Done
		%Set_Player_YPosition_LowerHalf()			;\Center vertically
		if !Setting_SSP_YPositionOffset != 0			;|
			REP #$20					;|
			LDA $96						;|
			CLC						;|
			ADC.w #!Setting_SSP_YPositionOffset		;|
			STA $96						;|
			SEP #$20					;|
		endif							;|
		if !Setting_SSP_SetXYFractionBits			;|
			LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
			STA $13DC|!addr					;|
		endif							;/
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Done:
	RTL
CompareYPositionToCheck:
	REP #$20
	LDA $98
	AND #$FFF0
	if !Setting_SSP_YPositionOffset != 0
		CLC
		ADC.w #!Setting_SSP_YPositionOffset
	endif
	STA $00
	SEP #$20
	%Get_Player_YPosition_LowerHalf()
	REP #$20
	CMP $00
	SEP #$20
	RTS
if !Setting_SSP_Description != 0
	print "Causes the player to enter warp pipe mode and drags the player to his destination."
endif