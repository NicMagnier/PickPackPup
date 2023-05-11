
function string:split(delimiter)
    if not delimiter then delimiter = ' ' end
    local result = {}
    local string_index = 1

    local found_start, found_end = string.find( self, delimiter, string_index)
    while found_start do
        table.insert(result, string.sub( self, string_index , found_start-1 ) )
        string_index = found_end + 1
        found_start, found_end = string.find( self, delimiter, string_index)
    end

    table.insert( result, string.sub( self, string_index) )

    return result
end

