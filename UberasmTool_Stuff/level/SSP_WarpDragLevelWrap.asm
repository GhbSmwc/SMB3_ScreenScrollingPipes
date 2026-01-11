;>bytes 1

incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Run this ASM file as level as "level"
;
;When Mario goes to the edge of the level during a pipe
;travel, would activate warp/drag mode to the opposite edge of
;the level, effectively having a wraparound effect.
;
;Works both horizontally and vertical, including the level
;format.
;
;Note that the triggers for left and right edges of the level
;are, by default, set at X=$0008 for left edge and X=-$0018
;for the right edge. Which means that placing pipe triggers
;(such as turn corners) at the leftmost or rightmost column of
;the level may have no effect and have this ASM wraparound
;effect take precedence instead.
;
;
;Extra bytes settings:
;EXB1: Wrap option: %000000VH:
; - H = Invert wraparound for left and right edges (hitting
;   left/right edges also inverts Y position): 0 = no, 1 =
;   yes.
; - V = Invert wraparound for top and bottom (hitting
;   top/bottom also inverts X position): 0 = no, 1 = yes.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

No: ;Branch out of bounds
	RTL
main:
	REP #$20
	LDA $00
	STA $8A				;>$8A~$8B = address of extra byte.
	SEP #$20
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ No
	CMP #$09			;\If already in warp/drag mode, skip
	BEQ No				;/
	CMP #$05
	.GetDirectionsOnly
		BCC ..NormalDirections
		..CapDirections
			SEC
			SBC #$04
		..NormalDirections
			STA $00				;>$00 = directions (ranges from #$01~#$04).
	.GetLeftAndRightEdges
		;After this:
		; - $01~$02: contains the left edge for the trigger
		; - $03~$04: contains the right edge for the trigger
		LDA $1411|!addr
		BEQ ..ScreenBasedWrap
		REP #$20
		LDA.w #!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset
		STA $01
		LDA $5B
		LSR
		BCS ..VerticalLevel
		..HorizontalLevel
			LDA.b $5E-1
			AND #$FF00
			SEC
			SBC.w #($00F0-!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset)
			BRA ..SetRightEdgeXPos
		..VerticalLevel
			LDA.w #($01F0-!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset)
			BRA ..SetRightEdgeXPos
		..ScreenBasedWrap
			LDA $1462|!addr
			CLC
			ADC.w #!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset
			STA $01
			LDA $1462|!addr
			CLC
			ADC.w #($00F0-!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset)
		..SetRightEdgeXPos
			STA $03
	.GetTopAndBottom
		;After this:
		; - $05~$06: contains the top for the trigger
		; - $07~$08: contains the bottom for the trigger
		LDA $1412|!addr
		BEQ ..ScreenBasedWrap
		REP #$20
		LDA.w #!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
		STA $05
		LDA $5B
		LSR
		BCS ..VerticalLevel
		..HorizontalLevel
			if !EXLEVEL == 0
				LDA.w #($01B0+!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset)
			else
				LDA $13D7|!addr
				CLC
				ADC.w !Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset
			endif
			BRA ..SetBottom
		..VerticalLevel
			;Note that the bottom two rows of blocks in a 32x16 block screen area
			;are not visible since the screen stops where its top is on the level's
			;screen boundary
			LDA.b $5F-1
			AND #$FF00
			SEC
			SBC.w #($0020-!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset)
			BRA ..SetBottom
		..ScreenBasedWrap
			;224 ($00E0) is the height of the screen
			LDA $1464|!addr
			CLC
			ADC.w #!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
			STA $05
			LDA $1464|!addr
			CLC
			ADC.w #($00E0+!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset)
		..SetBottom
			STA $07
	.CheckHeadingBoundary
		SEP #$20
		LDA $00
		ASL
		TAX
		REP #$20
		JMP (..DirectionsToWrapCheck-2,x)
		
		..DirectionsToWrapCheck
			dw ...Up
			dw ...Right
			dw ...Down
			dw ...Left
		...Up
			LDA $96
			CMP $05
			;BPL .Done
			BMI +
			JMP .Done
			+
			SEP #$20
			LDA ($8A)
			AND.b #%0000001
			REP #$20
			BNE ....Invert
			....Normal
				LDA $94
				STA !Freeram_SSP_DragWarpPipeDestinationXPos
				BRA ....SetYPosition
			....Invert
				JSR InvertXPosition
			....SetYPosition
				LDA $07
				STA !Freeram_SSP_DragWarpPipeDestinationYPos
			BRA ...SetWarpDrag
		...Right
			LDA $94
			CMP $03
			BMI .Done
			LDA $01
			STA !Freeram_SSP_DragWarpPipeDestinationXPos
			SEP #$20
			LDA ($8A)
			AND.b #%00000010
			REP #$20
			BNE ....Invert
			....Normal
				LDA $96
				STA $09
				JSR CalculateYPositionDestination
				BRA ...SetWarpDrag
			....Invert
				JSR InvertYPosition
				BRA ...SetWarpDrag
		...Down
			LDA $96
			CMP $07
			BMI .Done
			SEP #$20
			LDA ($8A)
			AND.b #%00000001
			REP #$20
			BNE ....Invert
			....Normal
				LDA $94
				STA !Freeram_SSP_DragWarpPipeDestinationXPos
				BRA ....SetYPosition
			....Invert
				JSR InvertXPosition
			....SetYPosition
				LDA $05
				STA !Freeram_SSP_DragWarpPipeDestinationYPos
			BRA ...SetWarpDrag
		...Left
			LDA $94
			CMP $01
			BPL .Done
			LDA $03
			STA !Freeram_SSP_DragWarpPipeDestinationXPos
			SEP #$20
			LDA ($8A)
			AND.b #%00000010
			REP #$20
			BNE ....Invert
			....Normal
				LDA $96
				STA $09
				JSR CalculateYPositionDestination
				BRA ...SetWarpDrag
			BRA ...SetWarpDrag
			....Invert
				JSR InvertYPosition
		...SetWarpDrag
			SEP #$20
			LDA $00				;\Get direction into the prep
			ASL #4				;/(will be #%XXXX0000)
			ORA #$09			;>set direction to warp/drag
			STA !Freeram_SSP_PipeDir	;>Set pipe state
	.Done
		SEP #$30
		RTL
CalculateYPositionDestination:
	;Input: $09~$0A: Y Position destination of the player's lowest 16x16 position
	LDA $187A|!addr
	AND #$00FF
	ASL
	TAX
	LDA $09
	CLC
	ADC YoshiYOffset,x
	STA !Freeram_SSP_DragWarpPipeDestinationYPos
	RTS
YoshiYOffset:
	dw $0010
	dw $0020
	dw $0020
InvertXPosition:
	;XPositionFlipped = RightEdge - (MarioXPos - LeftEdgeXPos)
	;Simplified to XPositionFlipped = RightEdge - MarioXPos + LeftEdgeXPos
	LDA $03
	SEC
	SBC $94
	CLC
	ADC $01
	STA !Freeram_SSP_DragWarpPipeDestinationXPos
	RTS
InvertYPosition:
	;YPositionFlipped = Bottom - (MarioYPos - Top)
	;Simplified to YPositionFlipped = Bottom - MarioYPos + Top
	LdA $187A|!addr
	AND #$00FF
	ASL
	TAX
	LDA $07
	SEC
	SBC $96
	CLC
	ADC $05
	CLC
	ADC YoshiYOffsetInvert,x
	STA !Freeram_SSP_DragWarpPipeDestinationYPos
	RTS
YoshiYOffsetInvert:
	dw $0040
	dw $0030
	dw $0030
;EXLEVEL