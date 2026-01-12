;>bytes 1
%require_uber_ver(2, 0)

incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Run this ASM file as level as "level"
;
;When Mario goes to the edge of the level during a pipe
;travel, would automatically activate warp/drag mode to the
;opposite edge of the level, effectively having a wraparound
;effect.
;
;Works for both horizontal and VerticalLevel, as well as LM's
;custom level dimensions, as well as when horizontal and/or
;vertical scrolling is disabled.
;
;Notes:
; - Triggers for left and right edges of the level
;   are, by default, set at X=$0008 for left edge and X=-$0018
;   from the right edge. Which means that placing pipe
;   triggers (such as turn corners) at the leftmost or
;   rightmost column of the level may have no effect and have
;   this ASM wraparound effect take precedence instead.
; - If you have trouble knowing where the player is going, I
;   would recommend having !Setting_SSP_PipeDebug set to 1 and
;   re-run uberasm tool, and test to see the player's actual
;   position.
; - Use Lunar Magic's XY position and
;   "Selection <BlockWidth>X<BlockHeight>" (when clicking on
;   nothing and dragging) on the bottom status bar to know if
;   you have positioned the blocks correctly.
; - If you have horizontal and/or vertical scrolling disabled
;   (RAM $1411/$1412 set to #$00), this ASM code will adopt to
;   camera-based edges on what's disabled instead of level
;   edges.
; -- With vertical scrolling disabled, the bottom of where the
;    warp trigger would be at would be at ScreenY+$00E0, not
;    ScreenY+$0100. This means you shouldn't count the blocks
;    on where the LM's screen exit/subscreen boundaries are
;    at, rather you should use the "Game View Screen" (Menu
;    bar -> View -> Game View Screen, or F3) instead.
;
;Extra bytes settings:
;EXB1: Wrap option: %000000VH:
; - H = Invert wraparound for left and right edges (hitting
;   left/right edges also inverts Y position): 0 = no, 1 =
;   yes.
; - V = Invert wraparound for top and bottom (hitting
;   top/bottom also inverts X position): 0 = no, 1 = yes.
;
;   To get the inverted X position, count how many blocks
;   between the left pipe and the left edge of the level, that
;   amount would be the amount of blocks between the right
;   pipe and the right edge where the screen stops scrolling
;   past.
;
;   For inverted Y position, it would be similar. Except that
;   if vertical scrolling is disabled, then you would count
;   the number of blocks from the bottom of the viewable game
;   screen rather than the bottom edge of a screen boundary or
;   bottom of the level.
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
			SBC.w #(!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset+$0010) ;#$00E8 is the rightmost position within a screen the player cannot move further to the right without being pushed into.
			BRA ..SetRightEdgeXPos
		..VerticalLevel
			LDA.w #($01F0-!Setting_SSP_WarpDragLevelWrap_LevelEdgeTriggerOffset)
			BRA ..SetRightEdgeXPos
		..ScreenBasedWrap
			REP #$20
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
		AND #$00FF
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
				ADC.w #!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset
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
			AND.b #%0000010
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
			AND.b #%00000001
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
			AND.b #%00000010
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
			AND.b #%00000001
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
	;XPositionFlipped = LevelWidth - MarioXPosition - #$0010
	LDA $1411|!addr
	AND #$00FF
	BEQ .ScreenBasedWrap
	.Normal
		LDA $5B
		LSR
		BCS ..VerticalLevel
		..HorizontalLevel
			LDA $5E-1
			AND #$FF00
			BRA .SetXPos
		..VerticalLevel
			LDA #$0200
			BRA .SetXPos
	.ScreenBasedWrap
		;XPositionFlipped = (ScreenXPos + #$0100) - (MarioXPos - ScreenXPos) - #$0010
		;Becomes: XPositionFlipped = ScreenXPos + #$0100 - MarioXPos + ScreenXPos - #$0010
		LDA $1462|!addr
		CLC
		ADC.w #$0100
		SEC
		SBC $94
		CLC
		ADC $1462|!addr
		SEC
		SBC #$0010
		STA !Freeram_SSP_DragWarpPipeDestinationXPos
		RTS
	.SetXPos
		SEC
		SBC $94
		SEC
		SBC #$0010
		STA !Freeram_SSP_DragWarpPipeDestinationXPos
		RTS
InvertYPosition:
	;We don't use $05 and $07 here because then it's possible at certain Y position settings
	;would calculate incorrectly.
	LdA $187A|!addr
	AND #$00FF
	ASL
	TAX
	
	LDA $1412|!addr
	AND #$00FF
	BEQ .ScreenBasedWrap
	;$09~$0A = Top Y position (different from $05~$06 since we do not want offsets.)
	;$0B~$0C = bottom Y position (different from $07~$08, same as above)
	.Normal
		STZ $09
		LDA $5B
		LSR
		BCS ..VerticalLevel
		
		..HorizontalLevel
			if !EXLEVEL == 0
				LDA #$01B0
			else
				LDA $13D7|!addr
			endif
			BRA .SetBottom
		..VerticalLevel
			LDA $5F-1
			AND #$FF00
			BRA .SetBottom
	.ScreenBasedWrap
		LDA $1464|!addr
		STA $09
		CLC
		ADC.w #$00E0			;>Height of the screen
	.SetBottom
		STA $0B
	.Invert
		;YInverted = BottomY - (YPos - Top) + YoshiOffset
		;Simplified to YInverted = BottomY - YPos + Top + YoshiOffset
		LDA $0B
		SEC
		SBC $96
		CLC
		ADC $09
		CLC
		ADC YoshiYOffsetInvert,x
		wdm
		if !Setting_SSP_YPositionOffset != 0
			CLC
			ADC.w #(!Setting_SSP_YPositionOffset*2)
			;^Now, why is this doubled? Well, when mario's Y position is block-centered plus !Setting_SSP_YPositionOffset
			;(1 pixel up from block-centered by default), but then this inverter happens, that also gets inverted
			;(so now he's 1 pixel lower (in the opposite direction) from that default setting). This means simply adding
			;by !Setting_SSP_YPositionOffset afterwards would just cancel and now he's block centered rather than offset
			;by !Setting_SSP_YPositionOffset.
		endif
		STA !Freeram_SSP_DragWarpPipeDestinationYPos
	.Done
		RTS
YoshiYOffsetInvert:
	dw -$0010
	dw -$0020
	dw -$0020
;EXLEVEL