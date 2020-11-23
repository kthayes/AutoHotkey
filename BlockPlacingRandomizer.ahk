#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

distributionMapping := Array()
finalActiveSlots := Array()
 
; Create gui that shows the check boxes and sliders for the user to select their desired hotbar slot usage
Gui, Add, Text, x12 y9 w298 h80 , Select which hotbar slots to randomly pick blocks from. The sliders allow you to specify the weight (frequency) for each selected hotbar slot. The percent is the actual distribution for each active hotbar slot.`nNote: The 'X' terminates the script, 'Apply' saves the changes and minimizes the GUI. Use CTRL-ALT-B to pull it back up.
yCoord := 100
Loop 9{
	isActive%A_index% := 0
	weight%A_index% := 0
	percent%A_index% := 0

	Gui, Add, CheckBox, x12 y%yCoord% w50 h30 visActive%A_index% gManageBox, Slot %A_index%
	yCoord += 3
	Gui, Add, Slider, x72 y%yCoord% w200 h30 Range0-100 TickInterval10 ToolTip vweight%A_index% gManageSlider AltSubmit
	GuiControl, Disable, weight%A_index%
	yCoord += 3
	Gui, Add, Text, x275 y%yCoord% w30 h15 vpercentStr%A_index%, % percent%A_index% `%
	yCoord += 25
}
; The following 3 lines are for middle-clicking to refil blocks, but it does not work consistently. If enabled,
; you must also enable the extra code in the *RButton: label, near the bottom
/*
yCoord += 20
midClick := 0
Gui, Add, CheckBox, x12 y%yCoord% w160 h30 vmidClick, Select to enable auto-refill (will middle-click for you)
*/
yCoord += 3
Gui, Add, Button, x200 y%yCoord% w100 h30 + gApply, Apply
yCoord += 40
Gui, Show, x682 y316 h%yCoord% w310, Block Placing Randomizer

; Key command to open the gui, (^!b) == (CTRL ALT B)
^!b::
	Gui, Show
Return

; Manager for each checkbox
ManageBox:
	Gui, Submit, NoHide
	StringRight, boxID, A_GuiControl, 1

	if(isActive%boxID%){
		GuiControl, Enable, weight%boxID%
		GuiControl, , weight%boxID%, 100
	}else{
		GuiControl, , weight%boxID%, 0
		percent%boxID% := 0
		GuiControl, , percentStr%boxID%, % percent%boxID% `%
		GuiControl, Disable, weight%boxID%
	}

	Gui, Submit, NoHide
	Updater()
Return

; Manager for each slider
ManageSlider:
	Gui, Submit, NoHide
	Updater()
Return

; Updates all active percent displays in accordance with the changes the user is making to any one slider
Updater(){
	; Make a list of all current active slots
	activeSlots := GetActiveSlots()
	; Calculate the percent for each active slot
	if(activeSlots.Length() > 0){
		for key, slot in activeSlots{
			percent%slot% := GetPercent(slot, activeSlots)
			toRound := 0
			if(percent%slot% > 0 and percent%slot% < 100){
				toRound := 1
			}
			GuiControl, , percentStr%slot%, % Round(percent%slot%, toRound) `%
		}
	}
	Gui, Submit, NoHide
}

; Returns an array of the hotbar indexes of each active hotbar
GetActiveSlots(){
	activeSlots := Array()
	Loop, 9{
		if(isActive%A_index% == 1){
			activeSlots.push(A_index)
		}
	}
	Return activeSlots
}

; Returns the percent for any currentID that is passed in
GetPercent(currentID, activeSlots){
	; Return 100 if only one slider is active and has a value above 0
	if(activeSlots.Length() == 1 and weight%currentID% > 0){
		return 100
	; Return 0 if the current slider is at 0, guarantees no divide by 0 in the final else
	}else if(weight%currentID% == 0){
		return 0
	; Retruns the weight of the current slider divided by the total combined weight of all active sliders, times 100 for %
	}else{
		totalWeight := 0
		for key, slot in activeSlots{
			totalWeight += weight%slot%
		}
		return Round((weight%currentID% / totalWeight) * 100, 3)
	}
}

; Clicking Apply will save the current setting for the checkboxes and sliders, and hide the GUI
Apply:
	Global finalActiveSlots, distributionMapping
	if(finalActiveSlots.MinIndex() != ""){
		finalActiveSlots.Delete(finalActiveSlots.MinIndex(), finalActiveSlots.MaxIndex())
	}
	finalActiveSlots := GetActiveSlots()

	if(distributionMapping.MinIndex() != ""){
		distributionMapping.Delete(distributionMapping.MinIndex(), distributionMapping.MaxIndex())
	}
	toPush := 0
	for index, eachSlot in finalActiveSlots{
		if(percent%eachSlot% > 0){
			toPush += percent%eachSlot%
			distributionMapping.push(toPush * 1000)
		}else{
			distributionMapping.push(0)
		}
	}
	Gui, Submit, Hide
Return


; Every time you right-click, this will place the block you are currently holding, then select the next hotbar slot
*RButton::
	IfWinActive , Minecraft
	{
		Global finalActiveSlots, distributionMapping
		Click, Right
		KeyWait, RButton
		
		; The middle-click functionality is hit and miss. It works fine if you're going slow, but as soon as you start 
		; spamming blocks, it breaks down. The sleep is necessary, otherwise the slot picking process below works faster
		; than Minecraft can pick-block, and you end up selecting a new slot, then picking the block you just placed,
		; leaving you with the same block you just placed
		/*
		if(midClick){
			Click, Middle
		}
		Sleep, 50
		*/
		if(finalActiveSlots.Length() > 0){
			Random, rand, 1, 100000
			for index, eachSlot in finalActiveSlots{
				if(rand <= distributionMapping[index]){
					Send, {Blind}%eachSlot%
					Break
				}
			}
		}
	}else{
		Click Down Right
		KeyWait, RButton
		Click Up Right
	}
Return

; Clicking the red X will terminate the script
GuiClose:
	ExitApp
Return
