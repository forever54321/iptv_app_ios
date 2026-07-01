' M3U Playlist Parser
' Parses M3U content into an array of channel entries

function ParseM3u(content as String) as Object
    entries = []
    lines = content.split(chr(10))
    lineCount = lines.count()

    currentEntry = invalid

    for i = 0 to lineCount - 1
        line = StringTrim(lines[i])

        ' Skip empty lines
        if line <> ""

        if Left(line, 7) = "#EXTINF"
            ' Parse EXTINF line
            currentEntry = {}

            ' Extract duration
            colonPos = line.inStr(":")
            commaPos = line.inStr(",")

            if colonPos >= 0 and commaPos >= 0
                durStr = Mid(line, colonPos + 2, commaPos - colonPos - 1)
                ' Duration might have attributes after it, get just the number
                spacePos = durStr.inStr(" ")
                if spacePos >= 0
                    durStr = Left(durStr, spacePos)
                end if
                currentEntry.duration = Val(durStr)
            else
                currentEntry.duration = -1
            end if

            ' Extract attributes
            currentEntry.tvgName = ExtractQuotedAttribute(line, "tvg-name")
            currentEntry.groupTitle = ExtractQuotedAttribute(line, "group-title")
            currentEntry.tvgLogo = ExtractQuotedAttribute(line, "tvg-logo")
            currentEntry.tvgId = ExtractQuotedAttribute(line, "tvg-id")
            currentEntry.tvgLanguage = ExtractQuotedAttribute(line, "tvg-language")

            ' Extract title (text after last comma)
            if commaPos >= 0
                currentEntry.title = Mid(line, commaPos + 2)
            else
                currentEntry.title = "Unknown"
            end if

            if currentEntry.title = "" then currentEntry.title = currentEntry.tvgName
            if currentEntry.title = "" then currentEntry.title = "Unknown"

        else if Left(line, 1) <> "#"
            ' This is a URL line
            if currentEntry <> invalid
                currentEntry.url = line
                entries.push(currentEntry)
                currentEntry = invalid
            end if
        end if

        end if ' line <> ""
    end for

    return entries
end function

' Extract categories from parsed entries
function ExtractCategories(entries as Object) as Object
    groupCounts = {}
    langCounts = {}

    for each ch in entries
        group = ch.groupTitle
        if group = invalid or group = "" then group = "Uncategorized"
        if groupCounts[group] = invalid
            groupCounts[group] = 0
        end if
        groupCounts[group] = groupCounts[group] + 1

        lang = ch.tvgLanguage
        if lang <> invalid and lang <> ""
            if langCounts[lang] = invalid
                langCounts[lang] = 0
            end if
            langCounts[lang] = langCounts[lang] + 1
        end if
    end for

    categories = []
    for each name in groupCounts
        categories.push({ name: name, type: "group", channelCount: groupCounts[name] })
    end for
    for each name in langCounts
        categories.push({ name: name, type: "language", channelCount: langCounts[name] })
    end for

    ' Sort by name
    ' Sort categories by name (simple bubble sort)
    n = categories.count()
    for i = 0 to n - 2
        for j = 0 to n - 2 - i
            if categories[j].name > categories[j + 1].name
                temp = categories[j]
                categories[j] = categories[j + 1]
                categories[j + 1] = temp
            end if
        end for
    end for
    return categories
end function
