' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

 ' entry point of detailsScreen
function Init()
    ' observe "visible" so we can know when DetailsScreen change visibility
    m.top.ObserveField("visible", "OnVisibleChange")
    ' observe "itemFocused" so we can know when another item gets in focus
    m.top.ObserveField("itemFocused", "OnItemFocusedChanged")
    ' save a references to the DetailsScreen child components in the m variable
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
    m.buttons.content = ContentListToSimpleNode(result) ' set list of buttons for DetailsScreen
end function

sub OnVisibleChange() ' invoked when DetailsScreen visibility is changed
    ' set focus for buttons list when DetailsScreen become visible
    if m.top.visible = true
        m.buttons.SetFocus(true)
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

' Populate content details information
sub SetDetailsContent(content as Object)
    m.description.text = content.description ' set description of content
    m.backgroundImage.uri = content.backgroundImageUri ' set url of content poster
    ' m.timeLabel.text = GetTime(content.length) ' set length of content
    m.titleLabel.text = content.title ' set title of content
    m.titlePoster.uri = content.titleTreatmentImageUri
    ' ' If there is no title image, show text
    ' if m.titlePoster.uri = invalid or m.titlePoster.loadStatus = "loading" or m.titlePoster.loadStatus = "failed"
    '     ShowTitleLabel()
    ' else
    '     ShowTitlePoster()
    ' end if
    m.titlePoster.uri = content.titleTreatmentImageUri
    
    if content.releaseYear <> invalid and content.tags <> invalid
        m.metadataLabel.text = content.rating + " • " + strI(content.releaseYear) + " • " + GetTags(content.tags)
    end if
end sub

sub OnTitlePosterLoadStatusChanged(event as Object)
    ' invoked when titlePoster load status is changed
    ' if titlePoster load status is "failed", we hide it and show titleLabel instead.
    ' I would add a loading spinner if the status was still "loading" though.
    if m.titlePoster.loadStatus = "failed"
        ShowTitleLabel()
    else
        ShowTitlePoster()
    end if
end sub

sub ShowTitlePoster()
    m.titlePoster.visible = true
    m.titleLabel.visible = false
end sub

sub ShowTitleLabel()
    m.titlePoster.visible = false
    m.titleLabel.visible = true
end sub

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

sub OnJumpToItem() ' invoked when jumpToItem field is populated
    content = m.top.content
    ' check if jumpToItem field has valid value
    ' it should be set within interval from 0 to content.Getchildcount()
    if content <> invalid and m.top.jumpToItem >= 0 and content.GetChildCount() > m.top.jumpToItem
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

sub OnItemFocusedChanged(event as Object)' invoked when another item is focused
    focusedItem = event.GetData() ' get position of focused item
    content = m.top.content.GetChild(focusedItem) ' get metadata of focused item
    SetDetailsContent(content) ' populate DetailsScreen with item metadata
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        currentItem = m.top.itemFocused ' position of currently focused item
        ' handle "left" button keypress
        if key = "left"
            ' navigate to the left item in case of "left" keypress
            m.top.jumpToItem = currentItem - 1 
            result = true
        ' handle "right" button keypress
        else if key = "right" 
            ' navigate to the right item in case of "right" keypress
            m.top.jumpToItem = currentItem + 1 
            result = true
        end if
    end if
    return result
end function