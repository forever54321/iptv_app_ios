' Group Classifier — classifies groups into Live, Movies, or Shows
' Mirrors the Flutter/Swift classification logic exactly

function ClassifyGroup(name as String, groupChannels as Object) as String
    lower = LCase(name)

    isMovieName = StringContains(lower, "movie") or StringContains(lower, "film") or StringContains(lower, "cinema")
    isSeriesName = StringContains(lower, "series") or StringContains(lower, "show") or StringContains(lower, "episode") or StringContains(lower, "season")
    isVodName = StringContains(lower, "vod") or StringContains(lower, "on demand") or StringContains(lower, "ondemand")

    ' Clear name match
    if isMovieName and not isSeriesName then return "movies"
    if isSeriesName and not isMovieName then return "shows"

    ' VOD or ambiguous — analyze channels
    if isVodName or (isMovieName and isSeriesName)
        if HasRepeatedNames(groupChannels) then return "shows"
        return "movies"
    end if

    ' No name keywords — check if VOD content
    if groupChannels.count() > 0 and IsVodContent(groupChannels)
        if HasRepeatedNames(groupChannels) then return "shows"
        return "movies"
    end if

    return "live"
end function

function ExtractBaseName(title as String) as String
    lower = LCase(title)
    ' Strip S01E01 patterns
    regex1 = CreateObject("roRegex", "[Ss]\d{1,2}\s?[Ee]\d{1,3}", "i")
    lower = regex1.replaceAll(lower, "")
    ' Strip Ep patterns
    regex2 = CreateObject("roRegex", "[Ee]p\.?\s?\d+", "i")
    lower = regex2.replaceAll(lower, "")
    ' Strip Episode patterns
    regex3 = CreateObject("roRegex", "[Ee]pisode\s?\d+", "i")
    lower = regex3.replaceAll(lower, "")
    ' Strip Season patterns
    regex4 = CreateObject("roRegex", "[Ss]eason\s?\d+", "i")
    lower = regex4.replaceAll(lower, "")
    ' Strip trailing separators
    regex5 = CreateObject("roRegex", "\s*[-|:]\s*$", "")
    lower = regex5.replaceAll(lower, "")
    ' Collapse whitespace
    regex6 = CreateObject("roRegex", "\s+", "")
    lower = regex6.replaceAll(lower, " ")

    return StringTrim(lower)
end function

function HasRepeatedNames(channels as Object) as Boolean
    if channels.count() < 3 then return false

    baseCounts = {}
    for each ch in channels
        base = ExtractBaseName(ch.title)
        if base <> ""
            if baseCounts[base] = invalid
                baseCounts[base] = 0
            end if
            baseCounts[base] = baseCounts[base] + 1
        end if
    end for

    repeatedCount = 0
    for each base in baseCounts
        if baseCounts[base] >= 2
            repeatedCount = repeatedCount + baseCounts[base]
        end if
    end for

    return (repeatedCount / channels.count()) > 0.4
end function

function IsVodContent(channels as Object) as Boolean
    if channels.count() = 0 then return false

    vodExtensions = [".mp4", ".mkv", ".avi", ".mov", ".flv", ".wmv", ".m4v", ".mpg", ".mpeg", ".webm"]
    vodCount = 0

    for each ch in channels
        if ch.duration <> invalid and ch.duration > 0
            vodCount = vodCount + 1
        end if

        urlLower = LCase(ch.url)
        qPos = urlLower.inStr("?")
        if qPos >= 0 then urlLower = Left(urlLower, qPos)

        for each ext in vodExtensions
            if Right(urlLower, Len(ext)) = ext
                vodCount = vodCount + 1
                exit for
            end if
        end for
    end for

    return (vodCount / channels.count()) > 0.4
end function
