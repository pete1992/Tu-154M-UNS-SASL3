-- creator_script.lua
-- Development utility that generates custom DataRef declarations from a tab-separated file.

-- Escape sequences used by the code generator:
-- "\040" = (
-- "\041" = )
-- " \" " = "
-- ' " ' = "

-- Input columns are separated by tabs:
-- DataRef name [TAB] type [TAB] description [TAB] initial value
-- like this:
-- tu154/custom/anim/cargo_1	float	Cargo door opening ratio	0

-- panelDir = path to your aircraft

print("panel dir = ", panelDir)

local dataref_filename = panelDir .. "/Custom Avionics/DataRefsTu154_int.txt" -- path for source file
local save_filename = panelDir .. "/Custom Avionics/dataref_creator_2.lua" -- path for output files

--local save_filename = panelDir .. "/Custom Avionics/smart_copilot_datarefs_2.txt" -- path for output files

-- Open the source first so a missing input cannot truncate an existing output.
local dataref_file, input_error = io.open(dataref_filename, "r")
if not dataref_file then
    print("Cannot open DataRef input: " .. tostring(input_error))
    return
end
local save_file, output_error = io.open(save_filename, "w")
if not save_file then
    dataref_file:close()
    print("Cannot open DataRef output: " .. tostring(output_error))
    return
end

-- Always close both files, including malformed rows and failed reads/writes.
local ok, generation_error = pcall(function()
    while true do
        local line, read_error = dataref_file:read("*line") -- read file line by line
        if read_error then
            error(read_error)
        end
        if line == nil then
            break
        end

        local a = 0
        local b = string.find(line, "\t", a) -- find next tab
        if b ~= nil and b > 9 then -- if we found an actual line with DataRef
            local dataref_name = string.sub(line, a, b - 1)

            a = b
            b = string.find(line, "\t", a + 1) -- find next tab
            local dataref_type = string.sub(line, a + 1, b - 1)
            -- convert type to one letter
            if dataref_type == "float" then
                dataref_type = "f"
            elseif dataref_type == "int" then
                dataref_type = "i"
            elseif dataref_type == "string" then
                dataref_type = "s"
            elseif dataref_type == "double" then
                dataref_type = "d"
            end

            a = b
            b = string.find(line, "\t", a + 1) -- find next tab
            dataref_descr = string.sub(line, a + 1, b - 1)

            dataref_value = string.sub(line, b + 1) -- find everything to the end of the line
            if not dataref_value or dataref_value == nil then
                dataref_value = "0"
            end

            --local save_text = dataref_name.." = "..dataref_value.."\n" -- for Smart Copilot
            local save_text = "createGlobalProperty"
                .. dataref_type
                .. '\040"'
                .. dataref_name
                .. '", '
                .. dataref_value
                .. "\041"
                .. " -- "
                .. dataref_descr
                .. "\n" -- for regular use

            assert(save_file:write(save_text)) -- Report write failures before closing both files.
        end
    end
end)
local input_closed, input_close_error = dataref_file:close()
local output_closed, output_close_error = save_file:close()
if not ok or not input_closed or not output_closed then
    print("DataRef generation failed: " .. tostring(generation_error or input_close_error or output_close_error))
    return
end

print("DataRefs created")
