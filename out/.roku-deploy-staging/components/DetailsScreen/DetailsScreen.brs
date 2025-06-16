' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

 ' entry point of detailsScreen
function Init()
    ' observe "visible" so we can know when DetailsScreen change visibility
    m.top.ObserveField("visible", "OnVisibleChange")
    ' observe "itemFocused" so we can know when another item gets in focus
    m.top.ObserveField("itemFocused", "OnItemFocusedChanged")
    ' save a reference to the DetailsScreen child components in the m variable
    ' so we can access them easily from other functions
    m.buttons = m.top.FindNode("buttons")
    m.description = m.top.FindNode("descriptionLabel")
    m.timeLabel = m.top.FindNode("timeLabel")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.titlePoster = m.top.FindNode("titlePoster")
    m.titlePoster.visible = false
    m.titlePoster.observeField("loadStatus", "OnTitlePosterLoadStatusChanged")
    m.metadataLabel = m.top.FindNode("metadataLabel")
    m.backgroundImage = m.top.FindNode("backgroundImage") 

    ' set background image size to fit screen
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    m.backgroundImage.width = displaySize.w
    m.backgroundImage.height = displaySize.h
    
    ' create buttons
    result = []
    for each button in ["Play"] ' buttons list contains only "Play" button for now
        result.Push({title : button})
    end for
    m.buttons.content = ContentListToSimpleNode(result)
end function

' invoked when DetailsScreen visibility is changed
sub OnVisibleChange()
    ' set focus for buttons list when DetailsScreen become visible
    if m.top.visible = true
        m.buttons.SetFocus(true)
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

' Populate content details information
sub SetDetailsContent(content as Object)
    m.description.text = content.description
    m.titleLabel.text = content.title
    if content.backgroundImageUri <> invalid
        m.backgroundImage.uri = content.backgroundImageUri
    end if
    if content.titleTreatmentImageUri <> invalid
        m.titlePoster.uri = content.titleTreatmentImageUri
    end if
    
    if content.releaseYear <> invalid and content.tags <> invalid
        m.metadataLabel.text = content.rating + " • " + strI(content.releaseYear) + " • " + GetTags(content.tags)
    end if
end sub

' invoked when titlePoster load status is changed
' if titlePoster load status is "failed", we hide it and show titleLabel instead.
' TODO: add a loading spinner if the status is "loading"
sub OnTitlePosterLoadStatusChanged()
    if m.titlePoster.loadStatus = "failed"
        ShowTitleLabel()
    else
        ShowTitlePoster()
    end if
end sub

' Show title image instead of text
sub ShowTitlePoster()
    m.titlePoster.visible = true
    m.titleLabel.visible = false
end sub

' Show title text instead of image
sub ShowTitleLabel()
    m.titlePoster.visible = false
    m.titleLabel.visible = true
end sub

' returns a string with all tags separated by ", " 
' TODO: convert tags to presentable string (currently returns tags like "disneyPlusOriginal")
function GetTags(tags as Object) as String
    ' this function returns a string with all tags separated by ", "
    result = ""
    if tags <> invalid
        for each tag in tags
            if result <> "" then result += ", "
            result += tag.type
        end for
    end if
    return result
end function

' invoked when jumpToItem field is populated
sub OnJumpToItem()
    content = m.top.content
    ' check if jumpToItem field has valid value
    ' it should be set within interval from 0 to content.Getchildcount()
    if content <> invalid and m.top.jumpToItem >= 0 and content.GetChildCount() > m.top.jumpToItem
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

' invoked when another item is focused
sub OnItemFocusedChanged(event as Object)
    focusedItem = event.GetData()
    content = m.top.content.GetChild(focusedItem) ' get metadata of focused item
    SetDetailsContent(content) ' populate DetailsScreen with item metadata
end sub

' The OnKeyEvent() function receives remote control key events
function OnKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        currentItem = m.top.itemFocused
        if key = "left"
            ' navigate to the left item in case of "left" keypress
            m.top.jumpToItem = currentItem - 1 
            result = true
        else if key = "right" 
            ' navigate to the right item in case of "right" keypress
            m.top.jumpToItem = currentItem + 1 
            result = true
        end if
    end if
    return result
end function