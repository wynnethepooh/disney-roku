' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of GridScreen
' Note that we need to import this file in GridScreen.xml using relative path.
sub Init()
    m.rowList = m.top.FindNode("rowList")
    m.rowList.SetFocus(true)
    ' label with item description
    m.descriptionLabel = m.top.FindNode("descriptionLabel")
    ' label with item title
    m.titleLabel = m.top.FindNode("titleLabel")
    ' observe rowItemFocused so we can know when another item of rowList will be focused
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
end sub

' invoked when another item is focused
sub OnItemFocused()
    focusedIndex = m.rowList.rowItemFocused ' get position of focused item
    row = m.rowList.content.GetChild(focusedIndex[0]) ' get all items of row
    nextRow = m.rowList.content.GetChild(focusedIndex[0] + 1)
    if nextRow <> invalid and nextRow.type = "SetRef" and not nextRow.alreadyloaded
        ' if focused item is a ref set, we need to fetch its content
        ' and add new content to rowList
        m.loaderTask = m.top.FindNode("MainLoaderTask")
        m.loaderTask.refId = nextRow.refId
        m.loaderTask.ObserveField("nextRowContent", "OnSetContentLoaded")
        m.loaderTask.control = "run"
        nextRow.alreadyloaded = true        
    end if
    item = row.GetChild(focusedIndex[1]) ' get focused item
    ' update description label with description of focused item
    m.descriptionLabel.text = item.description
    ' update title label with title of focused item
    m.titleLabel.text = item.title
    ' adding length of playback to the title if item length field was populated
    if item.length <> invalid
        m.titleLabel.text += " | " + GetTime(item.length)
    end if
end sub

' invoked when ref set content is loaded and 
' adds the items to the row
sub OnSetContentLoaded()
    setContent = m.loaderTask.nextRowContent
    if setContent <> invalid
        focusedIndex = m.rowList.rowItemFocused
        row = m.rowList.content.GetChild(focusedIndex[0] + 1)
        for i = 0 to setContent.GetChildCount() - 1
            row.AppendChild(setContent.GetChild(i))
        end for
        m.rowList.content = m.rowList.content ' trigger UI refresh
        m.loaderTask.nextRowContent = invalid
        m.rowList.jumpToRowItem = [focusedIndex[0], 0] ' restore focus to current row

    end if
end sub

' this method convert seconds to mm:ss format
' getTime(138) returns 2:18
function GetTime(length as Integer) as String
    minutes = (length \ 60).ToStr()
    seconds = length MOD 60
    if seconds < 10
       seconds = "0" + seconds.ToStr()
    else
       seconds = seconds.ToStr()
    end if
    return minutes + ":" + seconds
end function
