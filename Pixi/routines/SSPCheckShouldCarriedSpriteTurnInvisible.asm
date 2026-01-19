incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Check should a sprite be hidden when dragged through a screen scrolling pipe. With
;!Setting_SSP_HideDuringPipeStemTravel == 0, it shall only turn invisible during warp/drag mode or when traveling
;through doors. Otherwise it shall turn invisible during mid-stem travel, wrap/drag mode, and door traveling.
;Output:
; Carry: Set = Turn invisible, Clear = Remain visible.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?SSPCheckShouldCarriedSpriteTurnInvisible:
		;Determines should a carried sprite skip drawing during pipe travel (through stem) should draw to OAM or not:
		;Carry clear = No, Set = yes.
		?.PlayerPipeStatus
			LDA !14C8,x			;\If not carried, always be visible, regardless of !Freeram_SSP_InvisbleFlag
			CMP #$0B			;|
			BNE ?.Visible			;/
			?..Carried
				LDA !Freeram_SSP_PipeDir		;\If during warp/drag mode, always be invisible, regardless of !Freeram_SSP_InvisbleFlag
				AND.b #%00001111			;|
				CMP #$09				;|
				BEQ ?.Invisible				;/
				?...NotWarpDragMode
					LDA !Freeram_SSP_EntrExtFlg	;\If during entering/exiting animation (non-stem animation), always be visible, regardless of !Freeram_SSP_InvisbleFlag
					CMP #$02			;|
					BNE ?.Visible			;/
					?....InStemTraveling
						;While carried, not in warp/drag mode, and in-stem animation, now we do regard with !Freeram_SSP_InvisbleFlag if configured to disable hiding.
						if !Setting_SSP_HideDuringPipeStemTravel == 0
							LDA !Freeram_SSP_InvisbleFlag
							BEQ ?.Visible
						endif
		?.Invisible
			SEC
			RTL
		?.Visible
			CLC
			RTL