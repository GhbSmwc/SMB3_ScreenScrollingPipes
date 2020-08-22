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
	REP #$30
	LDX.w #(?LevelNumberTable_End-?LevelNumberTable)-2
	LDY.w #((?LevelNumberTable_End-?LevelNumberTable)/2)-1
	?Loop
		;Find if current level matches
			LDA $010B|!addr
			CMP ?LevelNumberTable,x
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
		PLB
		RTL
;Level the start wrap points are in.
	?LevelNumberTable
		dw $0105		;>Index 0 (Index 0 * 2)
		dw $0105		;>Index 2 (Index 1 * 2)
		?.End

;These is the current block position (block coordinates, in units of 16x16, not pixels)
;needed to determine which destination to drag Mario to.
	?StartPositionX
		dw $0005		;>Index 0 (Index 0 * 2)
		dw $000C		;>Index 2 (Index 1 * 2)
	?StartPositionY
		dw $0018		;>Index 0 (Index 0 * 2)
		dw $0010		;>Index 2 (Index 1 * 2)
;These are the destination positions, in pixels (why not block positions, then LSR #4?,
;well, because it is possible that the player must be centered horizontally between 2 blocks
;than 16x16 grid-aligned as in the case with traveling through normal-sized vertical pipes).

;You can easily convert them into pixel coordinate via this formula:
;	dw (BlockPos*$10)+HalfBlock
;	
;	-BlockPos = the X or Y position, in units of 16x16 (the coordinates of the block seen in Lunar Magic).
;	-HalfBlock = $00 (16x16 aligned) or $08 (half-block aligned, with vertical normal-sized pipes, you
;	 normally do this for X position though).
	?EndPositionX
		dw ($000C*$10)+$08	;>Index 0 (Index 0 * 2)
		dw ($0005*$10)+$08	;>Index 2 (Index 1 * 2)
	?EndPositionY
		dw ($000F*$10)		;>Index 0 (Index 0 * 2)
		dw ($0017*$10)		;>Index 2 (Index 1 * 2)
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