;Put this in uberasm tool's library file. Note: This code COULD be not to be run on certain levels, but fixes.asm will still be used for all levels so if the
;freeram is set, would causes glitches. Therefore the freeram is constantly used during levels.

incsrc "../SSPDef/Defines.asm"

SSPMaincode:
	.DeathAnimationCheck
		LDA $71					;\Prevent potential glitch that the player enters pipe and dies (often by level timer)
		CMP #$09				;|during travel (if freezing enabled, at the same frame the players interacts a pipe cap).
		BNE .PipeStateCheck			;|
		RTL					;/
	
	.PipeStateCheck
		LDA !Freeram_SSP_PipeDir		;\don't do anything while outside the pipe.
		AND.b #%00001111			;|(this also should prevent running the reset pipe state every frame when the pipe state == 0)
		;ORA !Freeram_SSP_PipeTmr		;|
		BNE .InPipeTraveling			;/
		RTL

	.InPipeTraveling
		PHB					;\Setup banks
		PHK					;|
		PLB					;/
		..FreezeCheck
			LDA $13D4|!addr				;>$13D4 - pause flag.
			if !Setting_SSP_FreezeTime == 0
				ORA $9D				;>Prevent glitches in which !Freeram_SSP_PipeTmr still decrements during freezes like baby yoshi growing when the user disable pipe freezing.
			endif
			ORA $1426|!addr				;>Don't lock controls on message boxes.
			;ORA <address>				;>Other RAM to disable running pipe code.
			BEQ ..HandleCarryingSprites
			JMP ..pose				;>While the pipe-related code should stop running during a freeze, the pose should still be running (during freeze, he reverts to his normal pose).
	
		..HandleCarryingSprites
			if !Setting_SSP_CarryAllowed != 0
				...KeyGlitchFailsafe			;>A glitch that forces the player to drop the key upon exiting should the player enter and pick up the key the same frame.
					LDA $1470|!addr
					ORA $148F|!addr
					BEQ ....NoCarry
					LDA #$01			;\Set flag that the player is carrying sprites
					STA !Freeram_SSP_CarrySpr	;/
					;Y = index for carrying sprites or not.
					....NoCarry
						LDY #$00			;>Default Y as #$00 (later on, will remain #$00 if not carrying sprites) 
						LDA !Freeram_SSP_CarrySpr	;\fix automatic drop item when carrying (when freeze disabled, he shouldn't automatically
						BEQ ...NotCarrying		;/pick up sprites when the player didn't intend to do so.)
				
				...CarryingSprite
					INY
				
				...NotCarrying
			endif
		..ForceControlsSetAndClear
			LDA $15					;\
			ORA SSP_CarryControlsForceSet,y		;|>Force X and Y on controller to be set when carrying sprites.
			AND SSP_CarryControlsForceClear,y	;|>Clear out other than XY and START.
			STA $15					;|
			LDA $16					;|\Prevent fireballs and cape action.
			AND.b #%00010000			;||While enabling only the pause button.
			STA $16					;//

			...ResetControlsPBalloonStompCountAndFire
				STZ $17			;\Lock other controls.
				STZ $18			;/
				STZ $13F3|!addr		;\remove p-balloon
				STZ $1891|!addr		;/
				STZ $1697|!addr		;>remove consecutive stomps.
				STZ $140D|!addr		;>so fire mario cannot shoot fireballs in pipe

		..HidePlayer
			LDA !Freeram_SSP_PipeDir	;\If mario isn't one of the 8 main states, make him invisible.
			AND.b #%00001111		;|
			CMP #$09			;|
			BCS ...Hide			;/
			LDA !Freeram_SSP_EntrExtFlg	;\hide player if timer hits zero when entering.
			CMP #$02			;|
			BEQ ...NoHide			;|
			LDA !Freeram_SSP_PipeTmr	;|\If timer == 0, make player invisible.
			BNE ...NoHide			;|/Carried sprites turning invisible is handled by Fixes.asm
			
			...Hide
			if !Setting_SSP_PipeDebug == 0
				LDA #$FF		;|\Render player invisible
				STA $78			;//
			endif

			...NoHide
		..YoshiImage
			LDA $187A|!addr		;\if on yoshi, then use yoshi poses
			BNE ...OnYoshi		;/
			
			...OffYoshi
				STZ $73			;>so mario cannot remain ducking (unless on yoshi) as he exits.
		
			...OnYoshi
			...YoshiPipePose
				LDA !Freeram_SSP_PipeDir
				AND.b #%00000001		;
				BNE ....YoshiFaceScreen		;>Bit 0 clear = horizontal movement, set = vertical movement.
	
				....YoshiDuck			;>horizontal pipe
					LDA $187A|!addr			;\Do not duck if not riding yoshi.
					BEQ .....NoDuck			;/
					LDA #$04			;\crouch on yoshi
					STA $73				;/
	
					.....NoDuck
						LDA #$01			;\(this should make mario face left or right carrying sprites to the side)
						BRA ....SetYoshiPipePose		;/
	
				....YoshiFaceScreen		;\yoshi face the screen (vertical pipe, Nintendo did this so that yoshi's head
					LDA #$02			;/doesn't display a glitch graphic).
	
				....SetYoshiPipePose
					STA $1419|!addr			;>Even if you are not mounted on yoshi, you still have to write a value here, or carrying sprites don't work.

		..InPipeMode ;>Somewhat mimicks the way SMW handles pipes when entered.
			if !Setting_SSP_PipeDebug == 0
				LDA #$02		;\go behind layers
				STA $13F9|!addr		;/
			endif
			if !Setting_SSP_FreezeTime != 0
				LDA #$0B		;\freeze player (blame $00CDE8 for not allowing freezing), note that this also renders the plater invulnerable for most sprites.
				STA $71			;/
				STA $9D			;>Freeze time
			endif
			LDA #$01			;\allow vertical scroll up.
			STA $1404|!addr			;/
			STZ $14A6|!addr			;>no spinning.
			STZ $1407|!addr			;>so mario cannot fly out of the cap
			STZ $72				;>zero air flag.
			STZ $14A3|!addr			;>no yoshi tongue
			if !Setting_SSP_CarryAllowed != 0
				LDA !Freeram_SSP_CarrySpr	;\if mario not carrying anything, then skip
				BEQ ...NotCarry			;/
				LDA #$01			;\force keep carrying
				STA $1470|!addr			;|
				STA $148F|!addr			;/
		
				...NotCarry
			endif
		..DirectionalSpeed
			LDA !Freeram_SSP_PipeDir	;\set player speed within pipe (use transfer commands
			AND.b #%00001111		;|>Only read the low 4 bits (nibble)
			CMP #$09			;|\If directional bits not using the normal 8 statuses, skip all and end (treat it as a non-transition between entering and exiting)
			BEQ ...DragWarpMode
			
			...NormalPipeMode
				....NormalPipeStates
					TAY				;|so you can use long freeram address)
					LDA.w SSP_PipeXSpeed-1,y	;|
					STA $7B				;|
					LDA.w SSP_PipeYSpeed-1,y	;|
					STA $7D				;/
				....StopPotentialIssues
					STZ $185C|!addr
				BRA ..EnterExitTransition
			
			...DragWarpMode
				;This has to run every frame as mario goes towards his warp destination
				;as although it doesn't glitch out due to an overflow, an extreme distance
				;between the player and "target" can cause imprecise direction and may miss.
				
				....DragMarioXYSpeed
					REP #$20
					LDA $94
					SEC
					SBC !Freeram_SSP_DragWarpPipeDestinationXPos
					STA $00
					LDA $96
					SEC
					SBC !Freeram_SSP_DragWarpPipeDestinationYPos
					STA $02
					SEP #$20
					JSL Aiming
					LDA $00
					STA $7B
					LDA $02
					STA $7D
				....StopPotentialIssues
					LDA #$01
					STA $185C|!addr

		..EnterExitTransition
			LDA !Freeram_SSP_EntrExtFlg	;\If mario is transitioning between in and out of pipe state, branch to handle entering and exiting code
			BNE ...InPipe			;/
			JMP .PipeCodeReturn		;>Otherwise do nothing and player will continue pipe movement.
	
			...InPipe
				CMP #$01		;\If entering a pipe...
				BEQ ....entering_pipe	;/
				CMP #$02		;\If exiting a pipe...
				BEQ ....ExitingPipe	;/
				JMP .PipeCodeReturn
	
				....entering_pipe		;
					LDA !Freeram_SSP_PipeTmr	;\If timer isn't 0, set pose
					BNE +
					JMP ..pose			;/
					+
					DEC A				;\Otherwise decrement it
					STA !Freeram_SSP_PipeTmr	;/
					BEQ .....StemSpeed		;>If decremented from 1 to 0, accelerate for stem speed
					JMP ..pose			;>Otherwise still set pose (cap speed).
	
					.....StemSpeed
						LDA !Freeram_SSP_PipeDir	;\Switch to stem speed keeping the same direction.
						AND.b #%00001111		;|>Check only bits 0-3 (normal direction bits)
						CMP #$05			;|\If already at stem speed, don't subtract again.
						BCC ......StemSpeedDone		;|/(It shouldn't land on #$00 or underflow, stay within #$01-#$08)
						LDA !Freeram_SSP_PipeDir	;|>Reload because we want to retain bits 4-7 (planned direction bits).
						SEC				;|
						SBC #$04			;/
						STA !Freeram_SSP_PipeDir	;>And set pipe direction from cap to stem speed with the same direction.
		
						......StemSpeedDone
							BRA ..pose
	
				....ExitingPipe			;
					LDA !Freeram_SSP_PipeTmr	;\if timer already = 0, then skip the reset (so it does it once).
					BEQ ..pose			;/
					DEC A				;\otherwise decrement timer.
					STA !Freeram_SSP_PipeTmr	;/
					BEQ ..ResetStatus		;>Reset status if timer hits zero (happens once after -1 to 0).
					
					.....CapSpeed
						LDA !Freeram_SSP_PipeDir	;\Switch to cap speed keeping the same direction.
						AND.b #%00001111		;|>Check only bits 0-3 (normal direction bits)
						CMP #$05			;|\If already at pipe cap speed, don't add again.
						BCS ..pose			;|/
						LDA !Freeram_SSP_PipeDir	;|>Reload because we want to retain bits 4-7 (planned direction bits).
						CLC				;|
						ADC #$04			;/
						STA !Freeram_SSP_PipeDir	;>Set direction
						BRA ..pose			;>and skip the reset routine
;---------------------------------
;This resets mario's status.
;It must be exceuted for one frame
;the player exits a pipe.
;---------------------------------
		..ResetStatus
			...HandleCarryingSprites
				if !Setting_SSP_CarryAllowed != 0
					LDA !Freeram_SSP_CarrySpr	;\Holding sprites routine
					BEQ ....NotCarrySprite		;|
				
					....CarrySprite
					LDA #$40			;|
					BRA ....WriteXYBitController	;|
				endif
				....NotCarrySprite		;|
					LDA #$00			;|
	
				....WriteXYBitController		;|
					STA $15				;/
			...RevertPipeStatus
				if !Setting_SSP_FreezeTime != 0
					STZ $9D			;>back in motion
				endif
				STZ $13F9|!addr			;>go in front
				STZ $71				;>mario can move
				STZ $73				;>stop crouching (when going exiting down on yoshi)
				STZ $140D|!addr			;>no spinjump out the pipe (possable if both enter and exit caps are bottoms)
				STZ $7B				;\cancel speed
				STZ $7D				;/
				STZ $1419|!addr			;>revert yoshi
				STZ $149F|!addr			;>zero cape "rise up timer"
				LDA $16				;\Prevent fireballs and cape action.
				AND.b #%00010000		;|While enabling only the pause button.
				STA $16				;/
				LDA #$00			;\reset freeram flags
				STA !Freeram_SSP_PipeTmr	;|
				if !Setting_SSP_CarryAllowed != 0
					STA !Freeram_SSP_CarrySpr	;|
				endif
				STA !Freeram_SSP_EntrExtFlg	;/>Make code assume mario is out of the pipe.
				LDA !Freeram_SSP_PipeDir	;\Clear direction bits (resets the pipe state).
				AND.b #%11110000		;|
				STA !Freeram_SSP_PipeDir	;/
				JMP .PipeCodeReturn
;-----------------------------------------
;code that controls mario's pose
;-----------------------------------------
		..pose
			LDA !Freeram_SSP_PipeDir
			AND.b #%00001111
			CMP #$09
			BCS ...Skip
			AND #$01
			BEQ ...Horiz		;>If even number (bit 0 is clear), branch to Horizontal
	
			...Vert
				LDA $187A|!addr		;\if mario is riding yoshi, then
				BNE ....YoshiFaceScrn	;/use face screen instead
				LDA #$0F		;>vertical pipe pose (without regard to powerup status)
				BRA ...SetPose
		
				....YoshiFaceScrn
					LDA #$21		;>pose that mario turns around partially face the screen
					BRA ...SetPose
	
			...Horiz
				LDA $187A|!addr		;\if mario is riding yoshi, then
				BNE ....YoshiFaceHoriz	;/use "ride yoshi" pose
				LDA #$00
				BRA ...SetPose
	
				....YoshiFaceHoriz
					LDA #$1D		;>crouch as entering a horizontal pipe on yoshi.
	
			...SetPose
				STA $13E0|!addr		;>set player pose
			...Skip
	.PipeCodeReturn
		PLB
		RTL
;-------------------------------------------------------
;tables.
;-------------------------------------------------------

SSP_PipeXSpeed:
;X speed table
db $00                            ;>#$01 Stem upwards
db !SSP_HorizontalSpd             ;>#$02 Stem rightwards
db $00                            ;>#$03 Stem downwards
db $100-!SSP_HorizontalSpd        ;>#$04 Sten leftwards
db $00                            ;>#$05 Pipe cap upwards
db !SSP_HorizontalSpdPipeCap      ;>#$06 Pipe cap rightwards
db $00                            ;>#$07 Pipe cap downwards
db $100-!SSP_HorizontalSpdPipeCap ;>#$08 Pipe cap leftwards


SSP_PipeYSpeed:
;Y speed table
db $100-!SSP_VerticalSpd          ;>#$01 Stem upwards
db $00                            ;>#$02 Stem rightwards
db !SSP_VerticalSpd               ;>#$03 Stem downwards
db $00                            ;>#$04 Stem leftwards
db $100-!SSP_VerticalSpdPipeCap   ;>#$05 Pipe cap upwards
db $00                            ;>#$06 Pipe cap rightwards
db !SSP_VerticalSpdPipeCap        ;>#$07 Pipe cap downwards
db $00                            ;>#$08 Pipe cap leftwards

SSP_CarryControlsForceSet:
; first number = force button held when not carrying sprites, second is when carrying.
; a set bit here means a bit is forced to be enabled (button will be held down)
db %00000000, %01000000
SSP_CarryControlsForceClear:
; Same format as above, but fores a button to not be pressed.
; a bit clear here means the button will be forced to be cleared.
db %00010000, %01010000


;Don't touch these unless you remap the poses: [beta stuff]
;WalkingFrames:
;db $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02
;



;-------------------------------------------------------
;Other routines
;-------------------------------------------------------

;Aiming Routine by MarioE. Edited by Akaginite to enable
;unlimited distance.

;Input:  A   = 8 bit projectile speed
;        $00 = 16 bit (shooter x pos - target x pos)
;        $02 = 16 bit (shooter y pos - target y pos)
;
;Output: $00 = 8 bit X speed of projectile
;        $02 = 8 bit Y speed of projectile
Aiming:
.aiming
		PHX
		PHP
		SEP #$30
		STA $0F
		if !SA1
			STZ $2250
		endif
		LDX #$00
		REP #$30
		LDA $00
		BPL ..pos_dx
		EOR #$FFFF
		INC A
		STA $00
		LDX #$0002
		
..pos_dx	LDA $02
		BPL ..pos_dy
		EOR #$FFFF
		INC A
		STA $02
		INX
		
..pos_dy	STX $06
		ORA $00
		AND #$FF00
		BEQ +
		XBA
	-	LSR $00
		LSR $02
		LSR A
		BNE -
	+
		if !SA1
			LDA $00
			STA $2251
			STA $2253
			;NOP
			;BRA $00
			LDA $2306
			
			LDX $02
			STX $2251
			STX $2253
			;BRA $00
			CLC
			ADC $2306
		else
			SEP #$20
			LDA $00
			STA $4202
			STA $4203
			;NOP #4
			LDX $4216
			
			LDA $02
			STA $4202
			STA $4203
			;NOP
			REP #$21
			TXA
			ADC $4216
		endif
		
		BCS ..v10000
		CMP #$4000
		BCS ..v4000
		CMP #$1000
		BCS ..v1000
		CMP #$0400
		BCS ..v400
		CMP #$0100
		BCS ..v100
		ASL A
		TAX
		LDA.l ..recip_sqrt_lookup,x
		BRA ..s0
		
..v100		LSR A
		AND #$01FE
		TAX
		LDA.l ..recip_sqrt_lookup,x
		BRA ..s1
		
..v400		LSR #3
		AND #$01FE
		TAX
		LDA.l ..recip_sqrt_lookup,x
		BRA ..s2
		
..v1000		ASL #2
		XBA
		ASL A
		AND #$01FE
		TAX
		LDA.l ..recip_sqrt_lookup,x
		BRA ..s3
		
..v4000		XBA
		ASL A
		AND #$01FE
		TAX
		LDA.l ..recip_sqrt_lookup,x
		BRA ..s4

..v10000	ROR A
		XBA
		AND #$00FE
		TAX
		LDA.l ..recip_sqrt_lookup,x
..s5		LSR A
..s4		LSR A
..s3		LSR A
..s2		LSR A
..s1		LSR A
..s0
		if !SA1
			STA $2251
			ASL A
			LDA $0F
			AND #$00FF
			STA $2253
			BCC ..skip_conv
	..conv		XBA
			CLC
			ADC $2307
			BRA +
	..skip_conv	LDA $2307
	+		STA $2251
			LDA $02
			STA $2253
			SEP #$20
			LSR $06
			LDA $2307
			BCS ..y_plus
			EOR #$FF
			INC A
	..y_plus	STA $02
		
			LDX $00
			STX $2253
			;LSR $06
			;LDA $2307
			;BCS ..x_plus
			LDA $2307
			LDX $06
			BNE ..x_plus
			EOR #$FF
			INC A
	..x_plus	STA $00
		
		else
			SEP #$30
			LDX $0F
			STX $4202
			STA $4203
			;NOP #4
			LDX $4217
			XBA
			STA $4203
			
			;BRA $00
			REP #$21
			TXA
			ADC $4216
			STA $04
			SEP #$20
			
			LDX $02
			STX $4202
			STA $4203
			;NOP #4
			LDX $4217
			XBA
			STA $4203
			;BRA $00
			REP #$21
			TXA
			ADC $4216
			SEP #$20
			LSR $06
			BCS ..y_plus
			EOR #$FF
			INC A
	..y_plus	STA $02
		
			LDA $00
			STA $4202
			LDA $04
			STA $4203
			;NOP #4
			LDX $4217
			LDA $05
			STA $4203
			;BRA $00
			REP #$21
			TXA
			ADC $4216
			SEP #$20
			LDX $06
			BNE ..x_plus
			EOR #$FF
			INC A
	..x_plus	STA $00
		endif
		
		PLP
		PLX
		RTL
		
	
..recip_sqrt_lookup
		dw $FFFF,$FFFF,$B505,$93CD,$8000,$727D,$6883,$60C2
		dw $5A82,$5555,$50F4,$4D30,$49E7,$4700,$446B,$4219
		dw $4000,$3E17,$3C57,$3ABB,$393E,$37DD,$3694,$3561
		dw $3441,$3333,$3235,$3144,$3061,$2F8A,$2EBD,$2DFB
		dw $2D41,$2C90,$2BE7,$2B46,$2AAB,$2A16,$2987,$28FE
		dw $287A,$27FB,$2780,$270A,$2698,$262A,$25BF,$2557
		dw $24F3,$2492,$2434,$23D9,$2380,$232A,$22D6,$2285
		dw $2236,$21E8,$219D,$2154,$210D,$20C7,$2083,$2041
		dw $2000,$1FC1,$1F83,$1F46,$1F0B,$1ED2,$1E99,$1E62
		dw $1E2B,$1DF6,$1DC2,$1D8F,$1D5D,$1D2D,$1CFC,$1CCD
		dw $1C9F,$1C72,$1C45,$1C1A,$1BEF,$1BC4,$1B9B,$1B72
		dw $1B4A,$1B23,$1AFC,$1AD6,$1AB1,$1A8C,$1A68,$1A44
		dw $1A21,$19FE,$19DC,$19BB,$199A,$1979,$1959,$1939
		dw $191A,$18FC,$18DD,$18C0,$18A2,$1885,$1869,$184C
		dw $1831,$1815,$17FA,$17DF,$17C5,$17AB,$1791,$1778
		dw $175F,$1746,$172D,$1715,$16FD,$16E6,$16CE,$16B7
		dw $16A1,$168A,$1674,$165E,$1648,$1633,$161D,$1608
		dw $15F4,$15DF,$15CB,$15B7,$15A3,$158F,$157C,$1568
		dw $1555,$1542,$1530,$151D,$150B,$14F9,$14E7,$14D5
		dw $14C4,$14B2,$14A1,$1490,$147F,$146E,$145E,$144D
		dw $143D,$142D,$141D,$140D,$13FE,$13EE,$13DF,$13CF
		dw $13C0,$13B1,$13A2,$1394,$1385,$1377,$1368,$135A
		dw $134C,$133E,$1330,$1322,$1315,$1307,$12FA,$12ED
		dw $12DF,$12D2,$12C5,$12B8,$12AC,$129F,$1292,$1286
		dw $127A,$126D,$1261,$1255,$1249,$123D,$1231,$1226
		dw $121A,$120F,$1203,$11F8,$11EC,$11E1,$11D6,$11CB
		dw $11C0,$11B5,$11AA,$11A0,$1195,$118A,$1180,$1176
		dw $116B,$1161,$1157,$114D,$1142,$1138,$112E,$1125
		dw $111B,$1111,$1107,$10FE,$10F4,$10EB,$10E1,$10D8
		dw $10CF,$10C5,$10BC,$10B3,$10AA,$10A1,$1098,$108F
		dw $1086,$107E,$1075,$106C,$1064,$105B,$1052,$104A
		dw $1042,$1039,$1031,$1029,$1020,$1018,$1010,$1008