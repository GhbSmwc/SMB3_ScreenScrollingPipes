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
	;Carry: Clear if outside pipe, Set if inside pipe. This will determine should
	;the sprite being carried turn invisible with the player traveling through SSP.
	?.PlayerPipeStatus
		LDA !Freeram_SSP_PipeDir	;\Get player pipe direction
		AND.b #%00001111		;/
		BEQ ?.Visible			;>If player is outside...
		XBA				;>Move the pipe directions to A's high byte for later
		LDA !14C8,x			;\...or if sprite not carried
		CMP #$0B			;|then make sprite visible.
		BNE ?.Visible			;/
		if !Setting_SSP_HideDuringPipeStemTravel
			LDA !Freeram_SSP_EntrExtFlg	;\If transitioning between pipe and outside-of-pipe state, or just outside the pipe,
			CMP #$02			;|draw.
			BNE ?.Visible			;/
		endif
	?.CarriedAndTraveling
		if !Setting_SSP_HideDuringPipeStemTravel == 0
			XBA				
			CMP #$09			;\
			BNE ?.CheckIfDoorPassing	;/>Not in drag mode
			BRA ?.Invisible			;>Regardless if door or not, if dragmode is on, don't render the sprite.
		endif
	?.CheckIfDoorPassing
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