' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainLoaderTask.xml using relative path.
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    ' request the content feed from the API
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://cd-static.bamgrid.com/dp-117731241344/home.json")
    rsp = xfer.GetToString()
    rootChildren = []

    ' parse the feed and build a tree of ContentNodes to populate the GridView
    json = ParseJson(rsp)
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
                    setContent = GetSetContent(setData.Lookup("refId"))
                    print setData.Lookup("text").Lookup("title").Lookup("full").Lookup("set").Lookup("default").Lookup("content")
                    rootChildren.Push(setContent)
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

function GetSetContent(refId) 
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL(Substitute("https://cd-static.bamgrid.com/dp-117731241344/sets/{0}.json", refId))
    rsp = xfer.GetToString()

    json = ParseJson(rsp)
    if json <> invalid
        data = json.Lookup("data")
        ' print data
        setData = invalid
        if data <> invalid
            for each key in data
                setData = data.Lookup(key)
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
                    return row
                end if
            end for
        end if
    end if
    
end function

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

    item.description = "test"

    imageUrl = invalid
    if data.type = "DmcVideo"
        imageUrl = data.image.Lookup("tile").Lookup("1.78").Lookup("program").default.url
    else if data.type = "DmcSeries"
        imageUrl = data.image.Lookup("tile").Lookup("1.78").Lookup("series").default.url
    else if data.type = "StandardCollection"
        imageUrl = data.image.Lookup("tile").Lookup("1.78").Lookup("default").default.url
    end if
    if imageUrl <> invalid
        item.hdPosterURL = imageUrl
    else
        item.hdPosterURL = "pkg:/images/disney-plus-hulu-logo.jpg" ' use placeholder image if no image is available
    end if

    if data.releases <> invalid
        item.releaseDate = data.releases[0].releaseDate
    end if
    
    item.length = 0
    return item
end function

function isImageAvailable(url as String) as boolean
    request = CreateObject("roUrlTransfer")
    request.setUrl(url)
    request.SetRequest("HEAD") ' use HEAD request to avoid downloading the image
    request.InitClientCertificates()
    response = request.GetToString()
    code = request.GetResponseCode()
    return code = 200
end function
