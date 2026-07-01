' String utility functions

function StringContains(haystack as String, needle as String) as Boolean
    return haystack.inStr(needle) >= 0
end function

function StringTrim(s as String) as String
    regex = CreateObject("roRegex", "^\s+|\s+$", "")
    return regex.replaceAll(s, "")
end function

function StringSplit(s as String, delimiter as String) as Object
    parts = []
    regex = CreateObject("roRegex", delimiter, "")
    return regex.split(s)
end function

function ExtractQuotedAttribute(line as String, attrName as String) as String
    pattern = attrName + "=""([^""]*)"""
    regex = CreateObject("roRegex", pattern, "i")
    match = regex.match(line)
    if match <> invalid and match.count() > 1
        return match[1]
    end if
    return ""
end function

function FormatCount(count as Integer) as String
    if count >= 1000
        k = count / 1000.0
        if count mod 1000 = 0
            return Str(Int(k)).trim() + "K"
        else
            return Left(Str(k), 4).trim() + "K"
        end if
    end if
    return Str(count).trim()
end function
