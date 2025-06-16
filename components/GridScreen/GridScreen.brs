' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of GridScreen
' Note that we need to import this file in GridScreen.xml using relative path.
sub Init()
    m.backgroundImage = m.top.FindNode("backgroundImage")

    m.rowList = m.top.FindNode("rowList")
    m.rowList.SetFocus(true)
    m.top.ObserveField("visible", "onVisibleChange")
    ' observe rowItemFocused so we can know when another item of rowList will be focused
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")

    ' offset of row to load when an empty row is at the bottom of the screen
    m.ROW_LOAD_OFFSET = 1
end sub

' invoked when GridScreen visibility is changed
sub OnVisibleChange()
    if m.top.visible = true
        ' set focus to rowList if GridScreen visible
        m.rowList.SetFocus(true)
    end if
end sub

' invoked when another item is focused
sub OnItemFocused()
    focusedIndex = m.rowList.rowItemFocused
    if focusedIndex[0] + m.ROW_LOAD_OFFSET < m.rowList.content.GetChildCount()
        bottomRow = m.rowList.content.GetChild(focusedIndex[0] + m.ROW_LOAD_OFFSET)
        if bottomRow <> invalid and bottomRow.type = "SetRef" and not bottomRow.alreadyloaded
            ' if focused item is a ref set, we need to fetch its content
            ' and add new content to rowList
            LoadSetContent(bottomRow.refId)
        end if
    else
        print "Warning: Attempted to access out-of-bounds row."
    end if
end sub

' invokes MainLoaderTask to load content of the ref set
sub LoadSetContent(refId as String)
    m.loaderTask = m.top.FindNode("MainLoaderTask")
    m.loaderTask.refId = refId
    m.loaderTask.ObserveField("nextRowContent", "OnSetContentLoaded")
    m.loaderTask.control = "run"
end sub

' invoked when ref set content is loaded and adds the items to the row
sub OnSetContentLoaded()
    setContent = m.loaderTask.nextRowContent
    if setContent <> invalid
        focusedIndex = m.rowList.rowItemFocused
        if focusedIndex[0] + m.ROW_LOAD_OFFSET < m.rowList.content.GetChildCount()
            row = m.rowList.content.GetChild(focusedIndex[0] + m.ROW_LOAD_OFFSET)
            if row <> invalid
                for i = 0 to setContent.GetChildCount() - 1
                    child = setContent.GetChild(i)
                    if child <> invalid
                        row.AppendChild(child)
                    end if
                end for
                m.rowList.content = m.rowList.content ' trigger UI refresh
                m.loaderTask.nextRowContent = invalid
                m.rowList.jumpToRowItem = focusedIndex ' restore focus to current row
                row.alreadyLoaded = true
            else
                print "Warning: Row is invalid."
            end if
        else
            print "Warning: Attempted to access out-of-bounds row."
        end if      
    end if
end sub
