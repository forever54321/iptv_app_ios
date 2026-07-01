sub init()
    m.top.functionName = "parseContent"
end sub

sub parseContent()
    m.top.status = "loading"

    content = m.top.rawContent
    if content = invalid or content = ""
        m.top.status = "error"
        return
    end if

    entries = ParseM3u(content)
    categories = ExtractCategories(entries)

    m.top.parsedEntries = { entries: entries }
    m.top.categories = { categories: categories }
    m.top.status = "success"
end sub
