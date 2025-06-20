' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainLoaderTask.xml using relative path.
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "Run"
end sub

sub Run()
    if m.top.refId <> invalid and m.top.refId <> ""
        ' if refId is set, we need to fetch content of the ref set
        GetSetContent(m.top.refId)
    else
        GetContent()
    end if
end sub

sub GetContent()
    ' request the content feed from the API
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://cd-static.bamgrid.com/dp-117731241344/home.json")
    rsp = xfer.GetToString()
    if rsp = invalid or rsp = "" then
        print "Error: Failed to fetch data from server."
        m.top.content = invalid
        return
    end if
    rootChildren = []

    ' parse the feed and build a tree of ContentNodes to populate the GridView
    json = ParseJson(rsp)
    if json = invalid then
        print "Error: Failed to parse JSON."
        m.top.content = invalid
        return
    end if
    if json <> invalid
        containers = json.Lookup("data").Lookup("StandardCollection").Lookup("containers")
        if Type(containers) = "roArray" ' if container has other objects in it
            for each container in containers
                setData = container.Lookup("set")
                items = setData.Lookup("items")
                if items <> invalid and Type(items) = "roArray"
                    row = {}
                    row.title = setData.Lookup("text").Lookup("title").Lookup("full").Lookup("set").Lookup("default").Lookup("content")
                    row.children = []
                    items = setData.Lookup("items")
                    for each item in items
                        itemData = GetItemData(item)
                        if itemData <> invalid
                        row.children.Push(itemData)
                        end if
                    end for
                    rootChildren.Push(row)
                else if setData.type = "SetRef"
                    ' setContent = GetSetContent(setData.Lookup("refId"))
                    print setData.Lookup("text").Lookup("title").Lookup("full").Lookup("set").Lookup("default").Lookup("content")
                    row = {}
                    row.title = setData.Lookup("text").Lookup("title").Lookup("full").Lookup("set").Lookup("default").Lookup("content")
                    row.type = setData.type
                    row.refId = setData.refId
                    row.alreadyloaded = false
                    row.children = []
                    rootChildren.Push(row)
            end if
        end for
        end if
        ' set up a root ContentNode to represent rowList on the GridScreen
        contentNode = CreateObject("roSGNode", "ContentNode")
        contentNode.Update({
            children: rootChildren
        }, true)
        ' populate content field with root content node.
        ' Observer(see OnMainContentLoaded in MainScene.brs) is invoked at that moment
        m.top.content = contentNode
    end if
end sub

' fetches the content of a set by its refId 
' and populates the nextRowContent field
sub GetSetContent(refId as string) 
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL(Substitute("https://cd-static.bamgrid.com/dp-117731241344/sets/{0}.json", refId))
    rsp = xfer.GetToString()
    if rsp = invalid or rsp = "" then
        print "Error: Failed to fetch data from server."
        m.top.content = invalid
        return
    end if

    json = ParseJson(rsp)
    if json = invalid then
        print "Error: Failed to parse JSON."
        m.top.content = invalid
        return
    end if
    if json <> invalid
        data = json.Lookup("data")
        ' print data
        setData = invalid
        if data <> invalid
            for each key in data
                setData = data.Lookup(key)
                items = setData.Lookup("items")
                if items <> invalid and Type(items) = "roArray"
                    contentNode = CreateObject("roSGNode", "ContentNode")
                    for each item in items
                        itemData = GetItemData(item)
                        if itemData <> invalid
                            childNode = CreateObject("roSGNode", "ContentNode")
                            childNode.AddField("tileImageUri", "string", false)
                            childNode.AddField("backgroundImageUri", "string", false)
                            if itemData.title <> invalid then childNode.title = itemData.title
                            if itemData.tileImageUri <> invalid then childNode.tileImageUri = itemData.tileImageUri
                            if itemData.backgroundImageUri <> invalid then childNode.backgroundImageUri = itemData.backgroundImageUri
                            if itemData.description <> invalid then childNode.description = itemData.description
                            if itemData.length <> invalid then childNode.length = itemData.length
                            contentNode.AppendChild(childNode)
                        end if
                    end for
                    m.top.nextRowContent = contentNode
                end if
            end for
        end if
    end if    
end sub

function GetItemData(data as Object) as Object
    item = {}
    item.id = data.contentId

    if data.type = "DmcVideo"
        item.title = data.text.title.full.program.default.content
    else if data.type = "DmcSeries"
        item.title = data.text.title.full.series.default.content
    else if data.type = "StandardCollection"
        item.title = data.text.title.full.collection.default.content
    else if data.type = invalid
        return invalid
    else 
        print item.type
    end if

    item.description = "Description"

    GetItemImages(data, item)

    if data.releases <> invalid
        item.releaseYear = data.releases[0].releaseYear
    end if

    item.tags = data.tags
    if data.ratings <> invalid and data.ratings.Count() > 0
        item.rating = data.ratings[0].value
    end if
    
    item.length = 0
    return item
end function

function GetItemImages(data as Object, item) as Object
    tileImageUri = invalid
    if data.type = "DmcVideo"
        tileImageUri = data.image.Lookup("tile").Lookup("1.78").Lookup("program").default.url
        if data.image.Lookup("title_treatment") <> invalid
            item.titleTreatmentImageUri = data.image.Lookup("title_treatment").Lookup("1.78").Lookup("program").default.url
        end if
        if data.image.Lookup("background") <> invalid
            item.backgroundImageUri = data.image.Lookup("background").Lookup("1.78").Lookup("program").default.url
        end if
    else if data.type = "DmcSeries"
        tileImageUri = data.image.Lookup("tile").Lookup("1.78").Lookup("series").default.url
        if data.image.Lookup("title_treatment") <> invalid
            item.titleTreatmentImageUri = data.image.Lookup("title_treatment").Lookup("1.78").Lookup("series").default.url
        end if
        if data.image.Lookup("background") <> invalid
            item.backgroundImageUri = data.image.Lookup("background").Lookup("1.78").Lookup("series").default.url
        end if
    else if data.type = "StandardCollection"
        tileImageUri = data.image.Lookup("tile").Lookup("1.78").Lookup("default").default.url
        if data.image.Lookup("title_treatment") <> invalid
            item.titleTreatmentImageUri = data.image.Lookup("title_treatment").Lookup("1.78").Lookup("default").default.url
        end if
        if data.image.Lookup("background") <> invalid
            item.backgroundImageUri = data.image.Lookup("background").Lookup("1.78").Lookup("default").default.url
        end if
    end if
    if tileImageUri <> invalid
        item.tileImageUri = tileImageUri
    else
        item.tileImageUri = "pkg:/images/disney-plus-hulu-logo.jpg" ' use placeholder image if no image is available
    end if
end function