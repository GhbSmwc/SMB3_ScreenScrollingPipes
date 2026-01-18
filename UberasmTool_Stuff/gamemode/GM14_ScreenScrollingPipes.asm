;Put this in uberasm tool's gamemode file. Note: This code COULD be not to be run on certain levels, but fixes.asm will still be used for all levels so if the
;freeram is set, would causes glitches. Therefore the freeram is constantly used during levels.

incsrc "../SSPDef/Defines.asm"

macro GetAbsoluteDifference16Bit(a_RAM, b_RAM)
	LDA <b_RAM>
	SEC
	SBC <a_RAM>
	BPL ?Positive
	EOR #$FFFF
	INC
	?Positive
endmacro

main:
	if !sa1
		%invoke_sa1(SSPMaincode)
		RTL
	endif
SSPMaincode:
	PHB					;\Setup banks
	PHK					;|
	PLB					;/
	.DeathAnimationCheck
		;If Mario is inside a pipe AND dying, reset all his status for 1 frame.
		LDA !Freeram_SSP_PipeDir	;
		AND.b #%00001111		;>After this, A register = Pipe state
		BNE ..InPipe			;>If in pipe, execute (also check needed that if the player is already outside the pipe, not to run this code again, to ensure a execute-once for the reset when dying inside pipe).
		JMP .PipeCodeReturn
		
		..InPipe
		LDX $71					;\Prevent potential glitch that the player enters pipe and dies (often by level timer)
		CPX #$09				;|during travel (if freezing enabled, at the same frame the players interacts a pipe cap).
		BNE .PipeStateCheck			;/
		..MarioDiedReset
			LDA #$00				;\Reset all things.
			STA !Freeram_SSP_PipeDir		;|>Reset pipe state to ensure that [ResetStatus] is executed only once as the check before this code will assume player out of pipe on the next game loop.
			STA !Freeram_SSP_EntrExtFlg		;|
			STA !Freeram_SSP_PipeTmr		;/
			JMP .InPipeTraveling_ResetStatus	;>Bring mario back to the foreground, amoung other things.
	
	.PipeStateCheck
		CMP #$00				;\>This is needed so it wouldn't use the processor flags from the CPX.
		BNE .InPipeTraveling			;|
		JMP .PipeCodeReturn			;/>If pipe state == 0, end.

	.InPipeTraveling
		..FreezeCheck
			LDA $13D4|!addr				;>$13D4 - pause flag.
			if !Setting_SSP_FreezeTime == 0
				ORA $9D				;>Prevent glitches in which !Freeram_SSP_PipeTmr still decrements during freezes like baby yoshi growing when the user disable pipe freezing.
			endif
			ORA $1426|!addr				;>Don't lock controls on message boxes.
			ORA $13FB|!addr				;>Player frozen (such as yoshi growing animation).
			;ORA <address>				;>Other RAM to disable running pipe code.
			BEQ ..GameNotPaused
			JMP ..Pose				;>While the pipe-related code should stop running during a freeze, the pose should still be running (during freeze, he reverts to his normal pose).
	
		..GameNotPaused
		if and(!Setting_SSP_FreezeTime, !Setting_SSP_AllowCameraPanningWhenFrozen)
			..HandleCameraOrientation
				;This makes the camera face ahead of the player much like how vanilla SMW handles L/R scrolling (including adjusting the panning based on player's facing direction, which is at $00CDDD)
				;The problem is that this code only runs when PlayerStatus (RAM $71) is set to #$00. We need to set RAM $71 to #$0B so that $00CDE8 does not clear $9D and overrides this code of freezing
				;the level, and make the camera consistently pan over as if $71 == #$00.
				PHB
				LDA.b #$00|!bank8			;\Switch data bank so that 2-byte addressing tables use bank $00 and not the bank of here.
				PHA				;|
				PLB				;/
				LDY $1400|!addr
				PHK				;>Push current program bank
				PEA ...JSLRTSReturn-1		;>Push a return address so when the subroutine finishes, jumps to after the JML (PHK and first PEA forms the destination of the RTL)
				PEA.w $00D033-1|!bank		;>Push the RTL location (minus 1 because program counter takes the return addresses, add 1, then jump)
				JML $00CE49|!bank		;>Jump to code that ends with RTS (once RTS encountered, jumps to an RTL, then jumps to an instruction after here)
				...JSLRTSReturn
				PLB
		endif
		..ForceControlsSetAndClear
			LDA $15					;\
			ORA.b #%01000000			;|>Force X and Y on controller to be set for carrying sprites.
			AND.b #%01010000			;|>Clear out other than XY and START.
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
			CMP #$01			;|
			BEQ ...NoHide			;|
			LDA !Freeram_SSP_PipeTmr	;|\If timer == 0, make player invisible.
			BNE ...NoHide			;|/Carried sprites turning invisible is handled by Fixes.asm
			...StemHide
				if !Setting_SSP_HideDuringPipeStemTravel == 0
					LDA !Freeram_SSP_InvisbleFlag
					BEQ ...NoHide
				endif
			...Hide
				if !Setting_SSP_PipeDebug == 0
					;LDA #$EF			;>%11101111
					;LDY $187A|!addr			;>Riding yoshi
					;BEQ +
					;LDY $19
					;CPY #$02
					;BNE +
					;LDA #$FF
					;+
					;STA $78				;>Make player invisible
					
					LDA $187A|!addr
					BNE ....FullyInvisible
					LDA $19
					CMP #$02
					BEQ ....FullyInvisible
					....DontHideYoshi
						LDA #$EF			;>%11101111
						BRA ....WriteHideFlag
					....FullyInvisible
						LDA #$FF
					....WriteHideFlag
						STA $78
				endif
			...NoHide
		..YoshiImage
			LDA $187A|!addr		;\if on yoshi, then use yoshi poses
			BNE ...OnYoshi		;/NOTE: $1419 must still be written in any case of entering pipes to prevent accidental item dropping.
			
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
			LDA #$03			;\Some sprites ignore the $13F9, such as boo ring.
			STA $1497|!addr			;/
			LDA #$01			;\allow vertical scroll up.
			STA $1404|!addr			;/
			STZ $14A6|!addr			;>no spinning.
			STZ $1407|!addr			;>so mario cannot fly out of the cap
			STZ $72				;>zero air flag.
			STZ $14A3|!addr			;>no yoshi tongue
		..DirectionalSpeed
			LDA !Freeram_SSP_PipeDir	;\set player speed within pipe (use transfer commands
			AND.b #%00001111		;|>Only read the low 4 bits (nibble)
			CMP #$09			;|\If directional bits not using the normal 8 statuses, skip all and end (treat it as a non-transition between entering and exiting)
			BEQ ...DragWarpMode
			
			...NormalPipeMode
				....NormalPipeStates
					TAY
					LDA !Freeram_SSP_EntrExtFlg
					CMP #$04
					BEQ ....CannonExit
					LDA.w SSP_PipeXSpeed-1,y
					STA $7B
					LDA.w SSP_PipeYSpeed-1,y
					STA $7D
				....StopPotentialIssues
					STZ $185C|!addr			;Must interact with layers
				....HandleFacingDirections
					JSR CorrectFacing
					JMP ..EnterExitTransition
				
				....CannonExit
					TYA
					CMP #$05
					BCC .....AlreadyLessThan5
					SEC
					SBC #$04
					.....AlreadyLessThan5
						TAY
					
					LDA.w SSP_CannonExitXSpeed-1,y
					STA $7B
					LDA.w SSP_CannonExitYSpeed-1,y
					STA $7D
					BRA ....StopPotentialIssues
			
			...DragWarpMode
				....SetSeveralStatesForDragMode
					LDA #$00			;\Prevent a minor glitch that causes carried sprites in pipe failing to turn invisible
					STA !Freeram_SSP_PipeTmr	;/if the player enters a cap and immediately hits DragPlayer.asm before the timer hits 0.
				....CheckIfMarioArrivedDestination
					;Again, using the pseudo collision point, reason not to use the player's
					;AABB-collision is because it has a risk of snapping the player XY pos from the
					;very edges of the boxes at such a long distance that could risk layer 1/2 graphic loading
					;glitches. He should not snap more than 8 pixels in any direction.
					.....GetXPositionPoint
						REP #$20
						LDA $94
						CLC
						ADC #$0008
						STA $00
						SEP #$20
					.....GetYPositionPoint
						LDA $187A|!addr
						ASL
						TAY
						REP #$20
						LDA $96
						CLC
						ADC SSP_YoshiCollisionPoint,y
						STA $02
						SEP #$20
					.....CheckIfPointIsInDestinationHitBox
						JSL CheckPlayerBottomCollisionPointIsInDestinationHitBox
						BCC ....DragMarioXYSpeed
					.....MarioReachDestination
						;Go from state $09 to states $01-$08.
						LDA !Freeram_SSP_PipeDir			;\Switch player state to whatever was his prep direction
						LSR #4						;|
						STA $00						;|
						LDA !Freeram_SSP_PipeDir			;|
						AND.b #%11110000				;|
						ORA $00						;|
						STA !Freeram_SSP_PipeDir			;/
						REP #$20					;\Snap player XY position
						LDA !Freeram_SSP_DragWarpPipeDestinationXPos	;|
						STA $94						;|
						LDA !Freeram_SSP_DragWarpPipeDestinationYPos	;|
						SEC						;|
						SBC SSP_DragWarpDestinationYOffsetYoshi,y	;|
						STA $96						;|
						SEP #$20					;/
						STZ $7B						;\Just in case if the speed routine at $00DC4F is processed AFTER
						STZ $7D						;/this here is done setting XY position.
						LDA !Freeram_SSP_PipeDir			;\If the high nybble was 0 and got written to his pipe status, cancel all pipe states.
						AND.b #%00001111				;|
						BNE ..EnterExitTransition			;|
						LDA #$09					;|\Exiting door when door is a warp/drag mode
						STA $1DFC|!addr					;|/
						JMP ..ResetStatus				;/
				....DragMarioXYSpeed
					;This aiming code has to run every frame as mario goes towards his warp destination
					;as although it doesn't glitch out due to an overflow, an extreme distance
					;between the player and "target" can cause imprecise direction and may miss.
					REP #$20
					.....XPos
						LDA $94
						SEC
						SBC !Freeram_SSP_DragWarpPipeDestinationXPos
						STA $00
					.....YPos
						SEP #$20
						LDA $187A|!addr
						ASL
						TAY
						REP #$20
						LDA $96						;\Get the approximate vector of movement from the player/yoshi's feet
						CLC						;|to the block.
						ADC SSP_DragWarpDestinationYOffsetYoshi,y	;/
						SEC
						SBC !Freeram_SSP_DragWarpPipeDestinationYPos
						STA $02
						SEP #$20
					.....Aim
						if !Setting_SSP_DragModeSpeedUpLongDistance == 0
							LDA.b #!SSP_DragSpd
						else
							;Calculate taxicab distance:
							;DistanceTaxicab = abs(B_XPos - A_Xpos) + abs(B_YPos - A_YPos)
							;
							;Forms a circle where player moves at a lower speed when within.
							;asdf
							LDX #$00
							REP #$20
							%GetAbsoluteDifference16Bit(!Freeram_SSP_DragWarpPipeDestinationXPos, $94)
							STA $04
							%GetAbsoluteDifference16Bit(!Freeram_SSP_DragWarpPipeDestinationYPos, $96)
							CLC
							ADC $04
							CMP.w #!Setting_SSP_DragModeSpeedUpLongDistance
							SEP #$20
							BCC ......Close
							......Far
								INX
							......Close
							LDA SSPWarpDragSpeed,x
						endif
						%UberRoutine(Aiming)
						LDA $00
						STA $7B
						LDA $02
						STA $7D
				....StopPotentialIssues
					LDA #$01		;\Disable interaction with layers.
					STA $185C|!addr		;/
					JMP .PipeCodeReturn ;>And done.

		..EnterExitTransition
			;This should ONLY be executed when Mario's state is $01-$08.
			LDA !Freeram_SSP_EntrExtFlg	;\If mario is transitioning between in and out of pipe state, branch to handle entering and exiting code
			BNE ...InPipe			;/
			JMP .PipeCodeReturn		;>Otherwise do nothing and player will continue pipe movement.
	
			...InPipe
				CMP.b #((....PipeTravelStates_PointerTableEnd-....PipeTravelStates+2)/2)		;>Failsafe so the game doesn't crash
				BCC ....Valid
				....Invalid
					JMP .PipeCodeReturn
				....Valid
				ASL
				TAX
				JMP (....PipeTravelStates-2,x)

				....PipeTravelStates
					dw ....entering_pipe		;>State $01 (X=$02) Entering via pipe cap
					dw ..Pose			;>State $02 (X=$04) Pipe stem travel
					dw ....ExitingPipe		;>State $03 (X=$06) Exiting normally
					dw ....ExitingPipe		;>State $04 (X=$08) Exiting cannon out
					.....PointerTableEnd ;>This needed to mark the end of the table, to calculate the lowest index that points to invalid location.

	
				....entering_pipe		;
					LDA !Freeram_SSP_PipeTmr	;\If timer isn't 0, set pose
					BNE .....DecrementTimer
					JMP ..Pose			;/
					.....DecrementTimer
						DEC A				;\Otherwise decrement it
						STA !Freeram_SSP_PipeTmr	;/
					BEQ .....StemSpeed		;>If decremented from 1 to 0, accelerate for stem speed (1 frame only)
					JMP ..Pose			;>Otherwise still set pose (cap speed).
	
					.....StemSpeed
						;Switches Mario to stem speed
						LDA #$02			;\#$02 == stem speed
						STA !Freeram_SSP_EntrExtFlg	;/
						LDA !Freeram_SSP_PipeDir	;\Switch to stem speed keeping the same direction.
						AND.b #%00001111		;|>Check only bits 0-3 (normal direction bits)
						CMP #$05			;|\If already at stem speed, don't subtract again.
						BCC ......StemSpeedDone		;|/(It shouldn't land on #$00 or underflow, stay within #$01-#$08)
						CMP #$09			;|\If state $09-$0F, this is not the cap transition at all, so don't subtract by 4
						BCS ......StemSpeedDone		;|/(a failsafe, $09-$04=$05, which leads to the player going upwards at pipe cap speed when he shouldn't).
						LDA !Freeram_SSP_PipeDir	;|>Reload because we want to retain bits 4-7 (planned direction bits).
						SEC				;|
						SBC #$04			;/
						STA !Freeram_SSP_PipeDir	;>And set pipe direction from cap to stem speed with the same direction.
		
						......StemSpeedDone
							JMP ..Pose
	
				....ExitingPipe			;
					LDA !Freeram_SSP_PipeTmr	;\if timer already = 0, then skip the reset (so it does it once).
					BEQ ..Pose			;/
					DEC A				;\otherwise decrement timer.
					STA !Freeram_SSP_PipeTmr	;/
					BEQ ..ResetStatus		;>Reset status if timer hits zero (happens once after -1 to 0, again, a 1-frame action).
					
					.....CapSpeed
						;Switches Mario to cap speed
						LDA !Freeram_SSP_PipeDir	;\Switch to cap speed keeping the same direction.
						AND.b #%00001111		;|>Check only bits 0-3 (normal direction bits)
						CMP #$05			;|\If already at pipe cap speed, don't add again.
						BCS ..Pose			;|/
						LDA !Freeram_SSP_PipeDir	;|>Reload because we want to retain bits 4-7 (planned direction bits).
						CLC				;|
						ADC #$04			;/
						STA !Freeram_SSP_PipeDir	;>Set direction
						BRA ..Pose			;>and skip the reset routine
;---------------------------------
;This resets mario's status.
;It must be exceuted for one frame
;(or bugs will occur if executed every frame)
;the player exits a pipe.
;---------------------------------
		..ResetStatus
			...HandleCarryingSprites
				if !Setting_SSP_CarryAllowed != 0
					LDA $1470|!addr			;\Holding sprites routine
					ORA $148F|!addr			;|
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
					LDA $71				;\Prevent abrupt fade-out during death sequence.
					CMP #$09			;|
					BEQ ....DontReset9D		;/
					STZ $9D			;>back in motion
					....DontReset9D
				endif
				STZ $1497|!addr		;>make vulnerable
				STZ $13F9|!addr			;>go in front
				....RestorePlayerStateIfNotDying
					LDX $71				;\If player dying, don't restore his state
					CPX #$09			;|of not in his dying phase.
					BEQ .....NoRevive		;/
					STZ $71				;>mario can move
					
					.....NoRevive
				STZ $73				;>stop crouching (when going exiting down on yoshi)
				STZ $140D|!addr			;>no spinjump out the pipe (possable if both enter and exit caps are bottoms)
				LDA !Freeram_SSP_EntrExtFlg	;\Don't cancel speed if in cannon mode.
				CMP #$04			;|
				BEQ ....FireOut			;/
				
				....CancelSpeed
					STZ $7B				;cancel speed
					.....NoResetYSpeedDeath
						CPX #$09		;\Check mario animation again to see if dying to not zero out the Y speed
						BEQ ......Death		;/(which disables the "jump" on his death animation).
						STZ $7D
						
						......Death
				....FireOut
				
				STZ $1419|!addr			;>revert yoshi
				STZ $149F|!addr			;>zero cape "rise up timer"
				STZ $185C|!addr			;>Reenable block interaction, just in case...
				LDA $16				;\Prevent fireballs and cape action.
				AND.b #%00010000		;|While enabling only the pause button.
				STA $16				;/
				LDA #$00			;\reset freeram flags
				STA !Freeram_SSP_PipeTmr	;|
				STA !Freeram_SSP_EntrExtFlg	;/>Make code assume mario is out of the pipe.
				LDA !Freeram_SSP_PipeDir	;\Clear direction bits (resets the pipe state).
				AND.b #%11110000		;|
				STA !Freeram_SSP_PipeDir	;/
				JMP .PipeCodeReturn
;-----------------------------------------
;code that controls mario's pose
;-----------------------------------------
		..Pose
			STZ $1499|!addr		;>Make mario not have his  turning around pose with an item on his hands when entering/exiting pipe caps
			LDA !Freeram_SSP_PipeDir
			AND.b #%00001111
			CMP #$09
			BCS ...Skip
			AND #$01
			BEQ ...Horiz		;>If even number (bit 0 is clear), branch to Horizontal
	
			...Vert
				STZ $73			;>Clear ducking flag
				LDA $187A|!addr		;\if mario is riding yoshi, then
				BNE ....YoshiFaceScrn	;/use face screen instead
				LDA #$0F		;>vertical pipe pose (without regard to powerup status)
				BRA ...SetPose
		
				....YoshiFaceScrn
					LDA #$21		;>pose that mario turns around partially face the screen
					BRA ...SetPose
	
			...Horiz
				;Most of the handling of animations here are by Fixes.asm's hijack at $00CEB9 and $00CF9D. They will
				;make mario act as if he's on the ground.
				if !Setting_SSP_FreezeTime
					....CapeAniTimerCount
						;Similarly to $00D1F4 (specifically at $00D1F9, which runs when entering horizontal pipe caps) we
						;need to decrement the timer despite $9D set, $14A2 doesn't automatically decrement (there's a
						;check at $00C500 that makes it not decrement during a freeze).
						LDA $14A2|!addr
						BEQ .....Zero
						DEC
						STA $14A2|!addr
						.....Zero
					....WalkAniTimerCount
						;Yep, same as above, with decrement during a freeze at $00D13C.
						LDA $1496|!addr
						BEQ .....Zero
						DEC
						STA $1496|!addr
						.....Zero
				endif
				LDA $187A|!addr		;\if mario is riding yoshi, then
				BNE ....YoshiFaceHoriz	;/use "ride yoshi" pose
				LDA !Freeram_SSP_EntrExtFlg
				CMP #$02
				BEQ ....StemPose
				
				....Walking
					BRA ...Skip
				....StemPose
;					LDA $1470|!addr
;					ORA $148F|!addr
;					BEQ ....NotCarry
;					....Carry
;						LDA #$07
;						BRA ...SetPose
;					....NotCarry
						LDA #$0C		;\Long jump pose
						STA $72			;/
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
;Cap and stem speeds:
	SSP_PipeXSpeed:
		;X speed table
		db $00                            ;>$01 = Stem upwards
		db !SSP_HorizontalSpd             ;>$02 = Stem rightwards
		db $00                            ;>$03 = Stem downwards
		db $100-!SSP_HorizontalSpd        ;>$04 = Sten leftwards
		db $00                            ;>$05 = Pipe cap upwards
		db !SSP_HorizontalSpdPipeCap      ;>$06 = Pipe cap rightwards
		db $00                            ;>$07 = Pipe cap downwards
		db $100-!SSP_HorizontalSpdPipeCap ;>$08 = Pipe cap leftwards
	SSP_PipeYSpeed:
		;Y speed table
		db $100-!SSP_VerticalSpd          ;>$01 = Stem upwards
		db $00                            ;>$02 = Stem rightwards
		db !SSP_VerticalSpd               ;>$03 = Stem downwards
		db $00                            ;>$04 = Stem leftwards
		db $100-!SSP_VerticalSpdPipeCap   ;>$05 = Pipe cap upwards
		db $00                            ;>$06 = Pipe cap rightwards
		db !SSP_VerticalSpdPipeCap        ;>$07 = Pipe cap downwards
		db $00                            ;>$08 = Pipe cap leftwards
	SSPWarpDragSpeed:
		db !SSP_DragSpd              ;>When close
		db !SSP_DragSpdFastFar       ;>When far
;Cannon fire exit speeds:
	SSP_CannonExitXSpeed:
		db $00					;>$01 = upwards
		db !SSP_Cannon_HorizontalSpd		;>$02 = rightwards
		db $00					;>$03 = downwards
		db $100-!SSP_Cannon_HorizontalSpd	;>$04 = leftwards
	SSP_CannonExitYSpeed:
		db !SSP_Cannon_UpwardsSpd		;>$01 = upwards
		db $00					;>$02 = rightwards
		db !SSP_Cannon_DownwardsSpd		;>$03 = downwards
		db $00					;>$04 = leftwards
; first number = force button held when not carrying sprites, second is when carrying.
; a set bit here means a bit is forced to be enabled (button will be held down):
	SSP_CarryControlsForceSet:
		db %00000000, %01000000
; Same format as above, but fores a button to not be pressed.
; a bit clear here means the button will be forced to be cleared.
	SSP_CarryControlsForceClear:
		db %00010000, %01010000

;Don't touch these:
	SSP_DragWarpDestinationYOffsetYoshi:
		dw $0010
		dw $0020
		dw $0020

	SSP_YoshiCollisionPoint:
		dw $0018
		dw $0028
		dw $0028
;-------------------------------------------------------
;Other routines
;-------------------------------------------------------


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Check if a given pixel at the player's (or yoshi's if riding yoshi)
;;feet is close enough (within 4 pixels in any direction) to his destination
;position.
;Input:
; - $00~$01: Feet position point X pos
; - $02~$03: Feet position point Y pos
;Output:
; - Carry: 0 = too far, 1 = close enough.
;Destroyed values:
; - $04~$05: Offset of destination point X and Y pos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckPlayerBottomCollisionPointIsInDestinationHitBox:
	REP #$20
	.XAxis
		LDA !Freeram_SSP_DragWarpPipeDestinationXPos
		CLC
		ADC #$0008
		STA $04
		LDA $00
		SEC
		SBC $04
		BPL ..Positive
		
		..Negative
			EOR #$FFFF
			INC
		..Positive
			CMP #$0004
			BCS .NoCollision
	.YAxis
		LDA !Freeram_SSP_DragWarpPipeDestinationYPos
		CLC
		ADC #$0008
		STA $04
		LDA $02
		SEC
		SBC $04
		BPL ..Positive
		
		..Negative
			EOR #$FFFF
			INC
		..Positive
			CMP #$0004
			BCS .NoCollision
	.Collision
		SEP #$21					;>M and C flags set.
		RTL
	.NoCollision
		SEP #$20
		CLC
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Correct facing direction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CorrectFacing:
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	TAX
	LDA.l .PipeDirectionToFacing-1,x
	BMI .Done				;>For vertical movements, don't set direction.
	STA $76					;>Set player facing direction
	EOR #$01				;\RAM $157C's directions are opposite of RAM $76.
	STA $00					;/
	LDA $187A|!addr				;\Don't flip yoshi if yoshi is not ridden during pipe travel
	BEQ .Done				;/
	.YoshiFacing
		;Yes, this loops ALL 12 or 22 slots, even when yoshi is found. This is a failsafe
		;when there is a double-/multiple yoshis (from a glitch or placed directly in LM), it wouldn't
		;pick only the yoshi at the highest slot
		LDX.b #!sprite_slots-1
		..Loop
			if !Setting_SSP_UsingCustomSprites != 0
				LDA !7FAB10,x	;\If custom sprite, next slot
				AND #$08	;|
				BNE ..Next	;/
			endif
			LDA !9E,x	;\If other than yoshi, next slot
			CMP #$35	;|
			BNE ..Next	;/
			...IsYoshi
				LDa $00
				STA !157C,x
		..Next
			DEX
			BPL ..Loop
	.Done
		RTS
	.PipeDirectionToFacing
		;$80~$FF = don't set, $00 = left, $01 = right
		db $FF		;>$01 = Up (stem)
		db $01		;>$02 = Right (stem)
		db $FF		;>$03 = Down (stem)
		db $00		;>$04 = Left (stem)
		db $FF		;>$05 = Up (Pipe cap)
		db $01		;>$06 = Right (Pipe cap)
		db $FF		;>$07 = Down (Pipe cap)
		db $00		;>$08 = Left (Pipe cap)