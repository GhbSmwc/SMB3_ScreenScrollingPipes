;If you make changes here, make sure you apply the changes to all the copies of this define files
;elsewhere by simply copying the folder containing this file.

;If you're using notepad++, the tab size is 8 in case if you don't like the text vertical misalignment.

;Places to put this define file to:
;-In GPS's main directory (same where the exe is in, not in the sub-folder/subdirectory)
;-In uberasm tool's main directory, same style as above.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA1 detector:
;Place this at the very top of gamemode_code.asm.
;Do not change anything here unless you know what are you doing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	!dp = $0000
;	!addr = $0000
;	!sa1 = 0
;	!gsu = 0
;
;if read1($00FFD6) == $15
;	sfxrom
;	!dp = $6000
;	!addr = !dp
;	!gsu = 1
;elseif read1($00FFD5) == $23
;	sa1rom
;	!dp = $3000
;	!addr = $6000
;	!sa1 = 1
;endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;uberasm code for GHB's screen scrolling pipes.
;Do not insert this as blocks, paste this code in "gamemode_code.asm"
;labeled "gamemode_14:" so blocks works in all levels.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;freeram addresses, you can use long address also.--------------------------
;Do note that these freerams above are not automatically converted to SA-1 addressing. Remember to use banks $40/41 if you
;use 3-byte addressing ($xxxxxx).

;Also be careful if you are using untouched RAM, as the game does not even reset them on level load, therefore the player
;will maintain his pipe state even after he dies and enters the level. You'll have to initialize them by resetting all these
;RAM address.

 if !sa1 == 0
  !Freeram_SSP_PipeDir		= $7E0060
 else
  !Freeram_SSP_PipeDir		= $60
 endif
  ;^[1 byte] this controls the directions within a pipe. Values stored on
  ;this RAM as follows:
  ;
  ; Bit format: PPPPDDDD
  ;
  ; DDDD bits (The stem and pipe cap directions):
  ;  #$00 = out of pipe (normal mode).
  ;  #$01-#$04 = travel up, right, down and left (in that order) for stem sections.
  ;  #$05-#$08 = same as above, but for cap speeds.
  ;
  ; PPPP bits (the planned direction for "special turning corners"):
  ;  #$00 = Keep going straight, don't change direction.
  ;  #$01-#$04 = travel up, right, down and left (in that order).

 if !sa1 == 0
  !Freeram_SSP_PipeTmr		= $7E0061
 else
  !Freeram_SSP_PipeTmr		= $61
 endif
  ;^[1 byte] for exiting and entering animations. Stored here is how
  ; long the player perform a cap entering and exiting, in frames.

 if !sa1 == 0
  !Freeram_SSP_EntrExtFlg	= $7E0062
 else
  !Freeram_SSP_EntrExtFlg	= $62
 endif
  ;^[1 byte] use to determine if mario's entering or
  ; exiting, stored values are:
  ; #$00 = outside the pipe
  ; #$01 = entering
  ; #$02 = exiting
  
 if !sa1 == 0
  !Freeram_SSP_CarrySpr		= $7E0063
 else
  !Freeram_SSP_CarrySpr		= $63
 endif
  ;^[BytesUsed = !Setting_SSP_CarryAllowed] used for if mario enters a
  ; pipe while holding a sprite. Will store a #$01 if you did carry a sprite though pipe.
  ; Not used should your entire hack doesn't allow entering SSP with a sprite, otherwise
  ; 1 byte taken.
  
 if !sa1 == 0
  !Freeram_BlockedStatBkp	= $7E0079
 else
  !Freeram_BlockedStatBkp	= $79
 endif
  ;^[1 byte] A backup of $77 to determine if mario is on the ground.

;Settings. NOTE: There are other defines settings in [SSP_Tiles\caps\enterable\*\cap_defines.asm] (* means any valid filename, including "default")
;so that you can multiple blocks with different variations (such as having some pipe caps that allow carrying sprites or allowing yoshi).
 !Setting_SSP_PipeDebug		= 0
  ;^This will make mario visible and in front of objects when enabled, set to 1 if you encounter issues and need to know where is Mario.
  
 ;SFX stuff for yoshi prohibited from entering pipes (only for normal-sized pipes, since you cannot enter small pipes on yoshi even as small Mario):
  !Setting_SSP_YoshiProhibitSFXNum	= $20
   ;^Set this to $00 for no sound (no worry, it won't cancel the SFX port of any current SFX.)
  !Setting_SSP_YoshiProhibitSFXPort	= $1DF9
   ;^The sound effect played when you tried to enter pipes on yoshi when yoshi is prohibited.
 
 !Setting_SSP_Description	= 0
  ;^0 = off, 1 = on. Due to a bug in GPS with blocks with the wrong description, I added an option just in case if GPS has that fixed in the future.
  
 !Setting_SSP_FreezeTime	= 0
  ;^0 = FuSoYa's pipe to not freeze stuff, 1 = freeze stuff.
  
 !Setting_SSP_FuSoYaSpd		= 1
  ;^0 = SMW styled speed (fast stem speed by default), 1 = fast FuSoYa speed.
 
;Pipe travel speeds:
;Use only values $01-$7F (negative speeds already calculated).
;
 if !Setting_SSP_FuSoYaSpd == 0		;>Don't change this if statement.
  ;SMW styled speed
  !SSP_HorizontalSpd		= $40 ;\Stem speed (changing this does not affect the timing of the entering/exiting)
  !SSP_VerticalSpd		= $40 ;/
  !SSP_HorizontalSpdPipeCap	= $08 ;\cap speed (if changed, you must change the timers below this section)
  !SSP_VerticalSpdPipeCap	= $10 ;/
 else
  ;FuSoYa styled speed.
  !SSP_HorizontalSpd		= $40 ;\Duplicate of above, but for fusoya style speeds.
  !SSP_VerticalSpd		= $40 ;|
  !SSP_HorizontalSpdPipeCap	= $40 ;|
  !SSP_VerticalSpdPipeCap	= $40 ;/
 endif

;Pipe exiting (and entering) timers (needed in case if you changed the cap speeds and have to fiddle to make
;sure the player exit the pipes properly, as well as the player hitbox to not exit while overlapping the pipes.)
;Numbers here are how long (in frames) before the player returns to normal when hitting pipe caps.
;The faster you set the pipe cap speed, the lower the values here should be.
;Hint: by using the scale by factor (Speed*X leads to Timer/X), it makes it much easier to work with this.
;
;Easiest to know is to test them, if the player exits the pipe further ahead of the cap past it, the timer is too long
;and needs to be a lower value, if the player exits the pipe while inside the cap (embedded inside the solid pipe, which
;may kill the player), the timer is too short and needs to be a higher value. For downwards facing pipes, shorter timers
;also enable entering back in them just after exiting it by holding up (you don't need to jump).

;Alternative way, have the timer be $FF. Then use a debugger and check out the RAM address "!Freeram_SSP_PipeTmr" is
;using, from the time the timer is $FF about to decrement to the time the value is at a certain number when the player's
;body (including yoshi when riding it) is at the position he should be freely be able to move, the difference is the
;correct amount of frames for the player to exit the pipe properly:
;
; CorrectTimerValue = $FF - <Timer value when the player is completely out of the pipe>
;
; Example:
;
; Right when mario exits the pipe leftwards, his time value was $C5, so [$FF - C5 = $3A]. That $3A is the correct time
; amount.

 if !Setting_SSP_FuSoYaSpd == 0
  ;Regular pipe timing
  !SSP_PipeTimer_Enter_Leftwards			= $3A
  !SSP_PipeTimer_Enter_Rightwards			= $3C
  !SSP_PipeTimer_Enter_Upwards_OffYoshi			= $1D
  !SSP_PipeTimer_Enter_Upwards_OnYoshi			= $27
  !SSP_PipeTimer_Enter_Downwards_OffYoshi		= $20
  !SSP_PipeTimer_Enter_Downwards_OnYoshi		= $30
  !SSP_PipeTimer_Enter_Downwards_SmallPipe		= $1D
  
  !SSP_PipeTimer_Exit_Leftwards				= $1B
  !SSP_PipeTimer_Exit_Rightwards			= $1B
  !SSP_PipeTimer_Exit_Upwards_OffYoshi			= $1D
  !SSP_PipeTimer_Exit_Upwards_OnYoshi			= $27
  !SSP_PipeTimer_Exit_Downwards_OffYoshi_SmallMario	= $0E
  !SSP_PipeTimer_Exit_Downwards_OffYoshi_BigMario	= $1B
  !SSP_PipeTimer_Exit_Downwards_OnYoshi_SmallMario	= $18
  !SSP_PipeTimer_Exit_Downwards_OnYoshi_BigMario	= $25
 else
  ;FuSoYa enter and exit timers.
  !SSP_PipeTimer_Enter_Leftwards			= $0A
  !SSP_PipeTimer_Enter_Rightwards			= $0A
  !SSP_PipeTimer_Enter_Upwards_OffYoshi			= $0A
  !SSP_PipeTimer_Enter_Upwards_OnYoshi			= $0A
  !SSP_PipeTimer_Enter_Downwards_OffYoshi		= $0A
  !SSP_PipeTimer_Enter_Downwards_OnYoshi		= $0A
  !SSP_PipeTimer_Enter_Downwards_SmallPipe		= $0A

  !SSP_PipeTimer_Exit_Leftwards				= $04
  !SSP_PipeTimer_Exit_Rightwards			= $04
  !SSP_PipeTimer_Exit_Upwards_OffYoshi			= $09
  !SSP_PipeTimer_Exit_Upwards_OnYoshi			= $0A
  !SSP_PipeTimer_Exit_Downwards_OffYoshi_SmallMario	= $06
  !SSP_PipeTimer_Exit_Downwards_OffYoshi_BigMario	= $08
  !SSP_PipeTimer_Exit_Downwards_OnYoshi_SmallMario	= $07
  !SSP_PipeTimer_Exit_Downwards_OnYoshi_BigMario	= $08
 endif