incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Drag mario mode handler.
;;
;;When hitting [DragToDestination.asm], it will execute this
;;code to set the player's destination position.
;;
;;Each warp to a specific point is each index ID.
;;
;;Output:
;;-Carry: Set if no warp index found.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PHB							;>Preserve bank
	PHK							;\Adjust bank for any $xxxx,y
	PLB							;/
	PHY							;>Preserve block behaver
	REP #$10
	;Start at the highest valid index:
		LDX.w #((?CorrectDirection_End-?CorrectDirection)-1*2)		;>For 16-bit table array
		LDY.w #(?CorrectDirection_End-?CorrectDirection)-1		;>For 8-bit table array
	?Loop
		;Which warp to use:
			;Check if the player is going in the correct direction into the warp:
				?.CorrectDirectionCheck
					LDA !Freeram_SSP_PipeDir
					AND.b #%00001111
					CMP #$05
					BCC ?.AlreadyConvertedDirection
					SEC
					SBC #$04
				?.AlreadyConvertedDirection
					CMP ?CorrectDirection,y
					BNE ?.Next
			;Find if current level matches
				REP #$20
				LDA $010B|!addr
				CMP ?LevelNumberTable,x
				SEP #$20
				BNE ?.Next
			;Level matched, now check the XY start position
				;Is Xposition matched?
					REP #$20
					LDA $9A
					LSR #4			;>Convert pixel coordinates to 16x16 block coordinate
					CMP ?StartPositionX,x
					SEP #$20
					BNE ?.Next
				;What about Y?
					REP #$20
					LDA $98
					LSR #4			;>Convert pixel coordinates to 16x16 block coordinate
					CMP ?StartPositionY,x
					SEP #$20
					BNE ?.Next
		;With the XY start position matched, now take the destination position, write it to
		;!Freeram_SSP_DragWarpPipeDestinationXPos and !Freeram_SSP_DragWarpPipeDestinationYPos
			REP #$20
			LDA ?EndPositionX,x
			STA !Freeram_SSP_DragWarpPipeDestinationXPos
			LDA ?EndPositionY,x
			STA !Freeram_SSP_DragWarpPipeDestinationYPos
			SEP #$20
		;State and prep direction
			LDA #$09			;>$09 = %00001001
			ORA ?DestinationDirection,y	;>%XXXX1001
			STA !Freeram_SSP_PipeDir
		;Done.
			CLC
			BRA ?Done
	?.Next
		DEY
		DEX #2
		BPL ?Loop
		SEC
		BRA ?Done
	?Done
		SEP #$30
		PLY				;>Restore block behaver
		PLB
		RTL
;These are tables containing the warps (each warp is 1 entry, therefore 2-way takes 1 entry from point A to B
;and another from point B back to point A).
;
;Due to signed 16-bit limitations, you can have up to 32768 ($8000 in hex, index numbers from $0000-$7FFF)
;warp entries in your entire game. Highly unlikely you would even get close to that number.
;
;Also note that if you have a huge number of entries here, and you placed a [DragPlayer.asm] with no
;matching ?StartPositionX and ?StartPositionY, the game will lag and this block will do nothing. Reason
;of the lag is because this code checks every single entry in these tables. The game will also lag
;if you have lots of entries but trigger this block in the wrong direction (such as hitting [DragPlayer.asm]
;traveling rightwards when he supposed to travel downwards onto it).

	;These determine which warp the player will take:
		;Direction to enter warp mode (traveling in other directions into
		;the warp will do nothing). Only use values $01-$04:
		;-$01 = Up
		;-$02 = Right
		;-$03 = Down
		;-$04 = Left
			?CorrectDirection
				db $03			;>Index 0
				db $03			;>Index 1
				db $02
				?.End			;>Keep this here, and make sure all numbers in the table are after label [?LevelNumberTable] and [?.End]!
					;^This table uses math on the labels to assume how many entries on each table. Make sure all the number of entries matches!
					; (I use the term “entries” to refer each number or unit as 1 entry, regardless if the value is 8 or 16-bit)
		;Level the start wrap points are in.
			?LevelNumberTable
				dw $0105		;>Index 0 (Index 0 * 2)
				dw $0105		;>Index 2 (Index 1 * 2)
				dw $0105		;>Index 4 (Index 2 * 2)
		
		;These is the current block position (block coordinates, in units of 16x16, not pixels)
		;where Mario comes from.
			?StartPositionX
				dw $00A2		;>Index 0 (Index 0 * 2)
				dw $0094		;>Index 2 (Index 1 * 2)
				dw $00A9		;>Index 4 (Index 2 * 2)
			?StartPositionY
				dw $0007		;>Index 0 (Index 0 * 2)
				dw $0015		;>Index 2 (Index 1 * 2)
				dw $0020		;>Index 4 (Index 2 * 2)
	;These are the destination positions, in pixels (why not block positions, then LSR #4?,
	;well, because it is possible that the player must be centered horizontally between 2 blocks
	;than 16x16 grid-aligned as in the case with traveling through normal-sized vertical pipes).
	;
	;You can easily convert them into pixel coordinate via this formula:
	;	dw (BlockPos*$10)+HalfBlock
	;	
	;	-BlockPos = the X or Y position, in units of 16x16 (the coordinates of the block seen in Lunar Magic).
	;	-HalfBlock = $00 (16x16 aligned) or $08 (half-block aligned, with vertical normal-sized pipes, you
	;	 normally do this for X position though).

	;These positions are “feet” position of the player, rather than the head position.
	;When riding on yoshi, it is the position of Yoshi's saddle part, not the player's.
	;Therefore, to get the correct position in a pipe:
	;
	;-For Small horizontal pipes, it is the tile of the stem part, nuff said, same goes with vertical small pipe.
	;-For regular sized horizontal pipes, it is the bottom half of the stem.
	;-For regular sized vertical pipes, it is the bottom-left tile of the 2x2 16x16 block space the player is at least
	; touching, assuming you are using the [(BlockPos*$10)+HalfBlock] formula.


		?EndPositionX
			dw ($0094*$10)+$08	;>Index 0 (Index 0 * 2)
			dw ($00A2*$10)+$08	;>Index 2 (Index 1 * 2)
			dw ($00AC*$10)+$00	;>Index 4 (Index 2 * 2)
		?EndPositionY
			dw ($0015*$10)		;>Index 0 (Index 0 * 2)
			dw ($0007*$10)		;>Index 2 (Index 1 * 2)
			dw ($0019*$10)		;>Index 4 (Index 2 * 2)
	;This is the prep direction to set to that the player will start moving in that direction
	;upon reaching his destination.
	;Only use these values
	;-$00 = Revert to normal mode (“exit” the pipe with no animation nor sound)
	;-$10 = up
	;-$20 = right
	;-$30 = down
	;-$40 = left
		?DestinationDirection
			db $10			;>Index 0
			db $10			;>Index 1
			db $20			;>Index 2