Locales = {}

function translate(str, ...)  -- Translate string
    local locale = Config.Locale or 'en'
    local langTable = Locales[locale] or Locales['en']
    if langTable and langTable[str] ~= nil then
        if select('#', ...) > 0 then
            return string.format(langTable[str], ...)
        else
            return langTable[str]
        end
    end

    if Locales['en'] and Locales['en'][str] ~= nil then
        if select('#', ...) > 0 then
            return string.format(Locales['en'][str], ...)
        else
            return Locales['en'][str]
        end
    end

    return 'Translation [' .. tostring(locale) .. '][' .. tostring(str) .. '] does not exist'
end

function _U(str, ...) -- Translate string first char uppercase
    local text = translate(str, ...)
    if type(text) == 'string' and #text > 0 then
        return text:gsub("^%l", string.upper)
    end
    return tostring(text)
end
