' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of GridScreen
' Note that we need to import this file in GridScreen.xml using relative path.
sub Init()
    m.rowList = m.top.FindNode("rowList")
    m.rowList.SetFocus(true)
    m.top.ObserveField("visible", "onVisibleChange")
    ' observe rowItemFocused so we can know when another item of rowList will be focused
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
end sub

sub OnVisibleChange() ' invoked when GridScreen change visibility
    if m.top.visible = true
        m.rowList.SetFocus(true) ' set focus to rowList if GridScreen visible
    end if
end sub

sub OnItemFocused() ' invoked when another item is focused
    focusedIndex = m.rowList.rowItemFocused ' get position of focused item
    row = m.rowList.content.GetChild(focusedIndex[0]) ' get all items of row
    bottomRow = m.rowList.content.GetChild(focusedIndex[0] + 2)
    if bottomRow <> invalid and bottomRow.type = "SetRef" and not bottomRow.alreadyloaded
        ' if focused item is a ref set, we need to fetch its content
        ' and add new content to rowList
        m.loaderTask = m.top.FindNode("MainLoaderTask")
        m.loaderTask.refId = bottomRow.refId
        m.loaderTask.ObserveField("nextRowContent", "OnSetContentLoaded")
        m.loaderTask.control = "run"
        bottomRow.alreadyloaded = true        
    end if
end sub

' invoked when ref set content is loaded and 
' adds the items to the row
sub OnSetContentLoaded()
    setContent = m.loaderTask.nextRowContent
    if setContent <> invalid
        focusedIndex = m.rowList.rowItemFocused
        row = m.rowList.content.GetChild(focusedIndex[0] + 2)
        for i = 0 to setContent.GetChildCount() - 1
            row.AppendChild(setContent.GetChild(i))
        end for
        m.rowList.content = m.rowList.content ' trigger UI refresh
        m.loaderTask.nextRowContent = invalid
        m.rowList.jumpToRowItem = [focusedIndex[0], 0] ' restore focus to current row

    end if
end sub
