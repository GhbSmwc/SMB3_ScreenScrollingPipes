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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

No: ;Branch out of bounds
	RTL
main:
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ No
	CMP #$09			;\If already in warp/drag mode, skip
	BEQ No				;/
	CMP #$05
	BCC .NormalDirections
	SEC
	SBC #$04
		.NormalDirections
	STA $02				;>$01 = directions.
	.VerticalWrap
		..GetWrapHeight
			;Pixel Y position range: $0000~$01B0 in vanilla,
			;otherwise $0000~Value_In_RAM_13D7
			wdm
			LDA $1412|!addr
			BEQ ...WrapBasedByScreen
			
			...WrapBasedByLevel
				REP #$20
				if !EXLEVEL == 0
					LDA.w #($01B0+!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset)-!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
				else
					LDA $13D7|!addr
					CLC
					ADC.w #!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset-!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
				endif
				BRA ...SetHeight
			...WrapBasedByScreen
				REP #$20
				LDA #$00E0+!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset-!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
			...SetHeight
				STA $00
		..CheckIfAboveOrBelow
			LDA $1412|!addr
			AND #$00FF
			BNE ...CheckYpositionRelativeToLevel
			...CheckYpositionRelativeToScreen
				;I wouldn't use RAM $80 else the boundary essentially shakes during a screen shakes
				LDA $96
				SEC
				SBC $1464|!addr
				CMP.w #$00E0+!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset
				BPL ..WrapToTop
				CMP.w #!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
				BMI ..WrapToBottom
				BRA .HorizontalWrap
			...CheckYpositionRelativeToLevel
				LDA $96
				CMP.w #!Setting_SSP_WarpDragLevelWrap_TopTriggerYPosition
				BMI ..WrapToBottom
				if !EXLEVEL == 0
					CMP.w #$01B0+!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset
				else
					SEC
					SBC.w #!Setting_SSP_WarpDragLevelWrap_BottomTriggerYOffset
					CMP $13D7|!addr
				endif
				BPL ..WrapToTop
				BRA .HorizontalWrap
		..WrapToBottom
			SEP #$20
			LDA $02
			CMP #$01				;>Prevent potential softlock
			BNE .Done
			LDA !Freeram_SSP_PipeDir		;\Set prep direction to up
			AND.b #%00001111			;|
			ORA #$10				;|
			STA !Freeram_SSP_PipeDir		;/
			REP #$20
			LDA $96
			CLC
			ADC $00
			STA !Freeram_SSP_DragWarpPipeDestinationYPos
			LDA $94
			STA !Freeram_SSP_DragWarpPipeDestinationXPos
			BRA .SetDragMode
		..WrapToTop
			SEP #$20
			LDA $02
			CMP #$03				;>Prevent potential softlock
			BNE .Done
			LDA !Freeram_SSP_PipeDir		;\Set prep direction to down
			AND.b #%00001111			;|
			ORA #$30				;|
			STA !Freeram_SSP_PipeDir		;/
			REP #$20
			LDA $96
			SEC
			SBC $00
			STA !Freeram_SSP_DragWarpPipeDestinationYPos
			LDA $94
			STA !Freeram_SSP_DragWarpPipeDestinationXPos
			BRA .SetDragMode
	.HorizontalWrap
		;[...]
		BRA .Done
	.SetDragMode
		SEP #$30
		LDA !Freeram_SSP_PipeDir
		ASL #4				;\Copy directions to the prep directions
		ORA !Freeram_SSP_PipeDir	;/
		AND.b #%11110000		;\Set directions
		ORA.b #$09			;/
		STA !Freeram_SSP_PipeDir	;>And write
	.Done
	SEP #$30
	RTL
;EXLEVEL