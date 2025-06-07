-- RedNet-Explorer Form Renderer
-- Renders interactive form elements in terminal

local formRenderer = {}

-- Load dependencies
local colors = colors or colours
local keys = keys

-- Form rendering state
local state = {
    activeForm = nil,
    focusedControl = nil,
    controlPositions = {},  -- Maps controls to screen positions
    formData = {},         -- Current form values
    cursorPos = 1,         -- Text cursor position
    scrollY = 0            -- Form scroll offset
}

-- Initialize form renderer
function formRenderer.init()
    state.activeForm = nil
    state.focusedControl = nil
    state.controlPositions = {}
    state.formData = {}
    state.cursorPos = 1
    state.scrollY = 0
end

-- Render a form
function formRenderer.renderForm(form, x, y, width, height, formData)
    state.activeForm = form
    state.formData = formData or {}
    state.controlPositions = {}
    
    local currentY = y - state.scrollY
    
    -- Render form title if available
    if form.name or form.id then
        term.setCursorPos(x, currentY)
        term.setTextColor(colors.lightBlue)
        term.write("Form: " .. (form.name or form.id))
        currentY = currentY + 2
    end
    
    -- Render each control
    for i, control in ipairs(form.controls) do
        if currentY >= y and currentY < y + height then
            currentY = formRenderer.renderControl(control, x, currentY, width, i)
        else
            -- Still track position even if not visible
            state.controlPositions[i] = {
                x = x,
                y = currentY,
                width = width,
                control = control
            }
            currentY = currentY + formRenderer.getControlHeight(control)
        end
        currentY = currentY + 1  -- Spacing between controls
    end
    
    return currentY
end

-- Render individual control
function formRenderer.renderControl(control, x, y, width, index)
    -- Store position for click handling
    state.controlPositions[index] = {
        x = x,
        y = y,
        width = width,
        control = control
    }
    
    -- Render based on control type
    if control.tag == "input" then
        return formRenderer.renderInput(control, x, y, width, index)
    elseif control.tag == "textarea" then
        return formRenderer.renderTextarea(control, x, y, width, index)
    elseif control.tag == "select" then
        return formRenderer.renderSelect(control, x, y, width, index)
    elseif control.tag == "button" then
        return formRenderer.renderButton(control, x, y, width, index)
    end
    
    return y
end

-- Render input element
function formRenderer.renderInput(control, x, y, width, index)
    local value = state.formData[control.name] or control.value or ""
    local isFocused = state.focusedControl == index
    
    -- Render label if available
    if control.name then
        term.setCursorPos(x, y)
        term.setTextColor(colors.white)
        term.write(control.name .. ":")
        y = y + 1
    end
    
    -- Render based on input type
    if control.type == "text" or control.type == "password" or 
       control.type == "email" or control.type == "url" or 
       control.type == "number" then
        -- Text input box
        term.setCursorPos(x, y)
        
        if isFocused then
            term.setBackgroundColor(colors.white)
            term.setTextColor(colors.black)
        else
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.white)
        end
        
        -- Calculate display value
        local displayValue = value
        if control.type == "password" then
            displayValue = string.rep("*", #value)
        end
        
        -- Truncate if too long
        local inputWidth = math.min(width - 2, 30)
        if #displayValue > inputWidth then
            if isFocused then
                -- Show end of string when focused
                displayValue = displayValue:sub(-inputWidth + 1)
            else
                displayValue = displayValue:sub(1, inputWidth - 3) .. "..."
            end
        end
        
        -- Draw input box
        term.write(" " .. displayValue .. string.rep(" ", inputWidth - #displayValue) .. " ")
        
        -- Show cursor if focused
        if isFocused then
            local cursorX = x + 1 + math.min(state.cursorPos - 1, inputWidth - 1)
            term.setCursorPos(cursorX, y)
            term.setCursorBlink(true)
        end
        
        term.setBackgroundColor(colors.black)
        
    elseif control.type == "checkbox" then
        -- Checkbox
        term.setCursorPos(x, y)
        term.setTextColor(colors.white)
        
        local checked = state.formData[control.name]
        if checked == nil then
            checked = control.checked
        end
        
        if isFocused then
            term.setBackgroundColor(colors.gray)
        end
        
        term.write(checked and "[X] " or "[ ] ")
        term.write(control.value or control.name or "")
        
        term.setBackgroundColor(colors.black)
        
    elseif control.type == "radio" then
        -- Radio button
        term.setCursorPos(x, y)
        term.setTextColor(colors.white)
        
        local selectedValue = state.formData[control.name]
        local checked = selectedValue == control.value or 
                       (selectedValue == nil and control.checked)
        
        if isFocused then
            term.setBackgroundColor(colors.gray)
        end
        
        term.write(checked and "(o) " or "( ) ")
        term.write(control.value or "")
        
        term.setBackgroundColor(colors.black)
        
    elseif control.type == "submit" or control.type == "reset" then
        -- Submit/Reset button
        formRenderer.renderButton(control, x, y, width, index)
    end
    
    return y
end

-- Render textarea element
function formRenderer.renderTextarea(control, x, y, width, index)
    local value = state.formData[control.name] or control.value or ""
    local isFocused = state.focusedControl == index
    
    -- Render label
    if control.name then
        term.setCursorPos(x, y)
        term.setTextColor(colors.white)
        term.write(control.name .. ":")
        y = y + 1
    end
    
    -- Calculate dimensions
    local rows = math.min(control.rows or 4, 8)
    local cols = math.min(control.cols or 20, width - 2)
    
    -- Set colors
    if isFocused then
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
    else
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
    end
    
    -- Split value into lines
    local lines = {}
    for line in (value .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line)
    end
    
    -- Render textarea box
    for row = 1, rows do
        term.setCursorPos(x, y + row - 1)
        local line = lines[row] or ""
        
        -- Truncate line if needed
        if #line > cols then
            line = line:sub(1, cols)
        end
        
        term.write(line .. string.rep(" ", cols - #line))
    end
    
    term.setBackgroundColor(colors.black)
    
    return y + rows - 1
end

-- Render select element
function formRenderer.renderSelect(control, x, y, width, index)
    local isFocused = state.focusedControl == index
    
    -- Render label
    if control.name then
        term.setCursorPos(x, y)
        term.setTextColor(colors.white)
        term.write(control.name .. ":")
        y = y + 1
    end
    
    -- Get selected value
    local selectedValue = state.formData[control.name]
    local selectedLabel = ""
    
    -- Find selected option label
    for _, option in ipairs(control.options or {}) do
        if type(option.value) == "string" then
            if option.value == selectedValue or 
               (selectedValue == nil and option.selected) then
                selectedLabel = option.label or option.value
                break
            end
        elseif option.options then
            -- Option group
            for _, subOption in ipairs(option.options) do
                if subOption.value == selectedValue or 
                   (selectedValue == nil and subOption.selected) then
                    selectedLabel = subOption.label or subOption.value
                    break
                end
            end
        end
    end
    
    -- Render select box
    term.setCursorPos(x, y)
    
    if isFocused then
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
    else
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
    end
    
    local selectWidth = math.min(width - 4, 25)
    if #selectedLabel > selectWidth - 3 then
        selectedLabel = selectedLabel:sub(1, selectWidth - 6) .. "..."
    end
    
    term.write(" " .. selectedLabel .. string.rep(" ", selectWidth - #selectedLabel - 2) .. " v ")
    
    term.setBackgroundColor(colors.black)
    
    -- If focused and expanded, show options
    if isFocused and control.expanded then
        y = y + 1
        term.setBackgroundColor(colors.gray)
        
        local optionY = y
        for i, option in ipairs(control.options or {}) do
            if optionY - y < 5 then  -- Limit dropdown height
                term.setCursorPos(x + 1, optionY)
                
                if type(option.value) == "string" then
                    -- Regular option
                    if i == control.highlightedOption then
                        term.setBackgroundColor(colors.lightGray)
                    end
                    
                    local optionText = option.label or option.value
                    if #optionText > selectWidth - 1 then
                        optionText = optionText:sub(1, selectWidth - 4) .. "..."
                    end
                    
                    term.write(optionText .. string.rep(" ", selectWidth - #optionText))
                    
                    if i == control.highlightedOption then
                        term.setBackgroundColor(colors.gray)
                    end
                    
                    optionY = optionY + 1
                end
            end
        end
        
        term.setBackgroundColor(colors.black)
        y = optionY - 1
    end
    
    return y
end

-- Render button element
function formRenderer.renderButton(control, x, y, width, index)
    local isFocused = state.focusedControl == index
    local label = control.label or control.value or control.type
    
    -- Center button
    local buttonWidth = #label + 4
    local buttonX = x + math.floor((width - buttonWidth) / 2)
    
    term.setCursorPos(buttonX, y)
    
    if isFocused then
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.black)
    else
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
    end
    
    term.write("[ " .. label .. " ]")
    
    term.setBackgroundColor(colors.black)
    
    return y
end

-- Get control height
function formRenderer.getControlHeight(control)
    local height = 1  -- Base height
    
    if control.name then
        height = height + 1  -- Label
    end
    
    if control.tag == "textarea" then
        height = height + math.min(control.rows or 4, 8) - 1
    elseif control.tag == "select" and control.expanded then
        height = height + math.min(#(control.options or {}), 5)
    end
    
    return height
end

-- Handle keyboard input
function formRenderer.handleKey(key)
    if not state.activeForm or not state.focusedControl then
        return false
    end
    
    local control = state.controlPositions[state.focusedControl].control
    
    if control.tag == "input" and 
       (control.type == "text" or control.type == "password" or
        control.type == "email" or control.type == "url" or
        control.type == "number") then
        -- Text input handling
        local value = state.formData[control.name] or ""
        
        if key == keys.backspace then
            if state.cursorPos > 1 then
                value = value:sub(1, state.cursorPos - 2) .. 
                        value:sub(state.cursorPos)
                state.cursorPos = state.cursorPos - 1
                state.formData[control.name] = value
                return true
            end
            
        elseif key == keys.delete then
            if state.cursorPos <= #value then
                value = value:sub(1, state.cursorPos - 1) .. 
                        value:sub(state.cursorPos + 1)
                state.formData[control.name] = value
                return true
            end
            
        elseif key == keys.left then
            if state.cursorPos > 1 then
                state.cursorPos = state.cursorPos - 1
                return true
            end
            
        elseif key == keys.right then
            if state.cursorPos <= #value then
                state.cursorPos = state.cursorPos + 1
                return true
            end
            
        elseif key == keys.home then
            state.cursorPos = 1
            return true
            
        elseif key == keys["end"] then
            state.cursorPos = #value + 1
            return true
        end
        
    elseif control.tag == "select" then
        -- Select handling
        if key == keys.enter or key == keys.space then
            control.expanded = not control.expanded
            if control.expanded then
                control.highlightedOption = 1
            end
            return true
            
        elseif control.expanded then
            if key == keys.up then
                if control.highlightedOption > 1 then
                    control.highlightedOption = control.highlightedOption - 1
                end
                return true
                
            elseif key == keys.down then
                if control.highlightedOption < #(control.options or {}) then
                    control.highlightedOption = control.highlightedOption + 1
                end
                return true
                
            elseif key == keys.enter then
                -- Select highlighted option
                local option = control.options[control.highlightedOption]
                if option and option.value then
                    state.formData[control.name] = option.value
                end
                control.expanded = false
                return true
                
            elseif key == keys.escape then
                control.expanded = false
                return true
            end
        end
    end
    
    -- Tab navigation
    if key == keys.tab then
        formRenderer.focusNext(keys.isHeld(keys.leftShift))
        return true
    end
    
    return false
end

-- Handle character input
function formRenderer.handleChar(char)
    if not state.activeForm or not state.focusedControl then
        return false
    end
    
    local control = state.controlPositions[state.focusedControl].control
    
    if control.tag == "input" and 
       (control.type == "text" or control.type == "password" or
        control.type == "email" or control.type == "url") then
        -- Text input
        local value = state.formData[control.name] or ""
        
        -- Check maxlength
        if control.maxlength and #value >= control.maxlength then
            return false
        end
        
        -- Insert character
        value = value:sub(1, state.cursorPos - 1) .. char .. 
                value:sub(state.cursorPos)
        state.cursorPos = state.cursorPos + 1
        state.formData[control.name] = value
        
        return true
        
    elseif control.tag == "input" and control.type == "number" then
        -- Number input - only allow digits and minus
        if char:match("[0-9%-]") then
            local value = state.formData[control.name] or ""
            value = value:sub(1, state.cursorPos - 1) .. char .. 
                    value:sub(state.cursorPos)
            state.cursorPos = state.cursorPos + 1
            state.formData[control.name] = value
            return true
        end
    end
    
    return false
end

-- Handle mouse click
function formRenderer.handleClick(x, y, button)
    if not state.activeForm then
        return false
    end
    
    -- Check each control position
    for index, pos in pairs(state.controlPositions) do
        if y >= pos.y and y < pos.y + formRenderer.getControlHeight(pos.control) and
           x >= pos.x and x < pos.x + pos.width then
            
            -- Focus the control
            state.focusedControl = index
            
            local control = pos.control
            
            -- Handle specific control types
            if control.tag == "input" then
                if control.type == "checkbox" then
                    -- Toggle checkbox
                    local current = state.formData[control.name]
                    if current == nil then
                        current = control.checked
                    end
                    state.formData[control.name] = not current
                    return true
                    
                elseif control.type == "radio" then
                    -- Select radio
                    state.formData[control.name] = control.value
                    return true
                    
                elseif control.type == "text" or control.type == "password" then
                    -- Position cursor in text field
                    local relX = x - pos.x - 1
                    local value = state.formData[control.name] or ""
                    state.cursorPos = math.min(relX + 1, #value + 1)
                    return true
                end
                
            elseif control.tag == "button" or 
                   (control.tag == "input" and 
                    (control.type == "submit" or control.type == "reset")) then
                -- Button click
                return true, control.type, control
                
            elseif control.tag == "select" then
                -- Toggle dropdown
                control.expanded = not control.expanded
                if control.expanded then
                    control.highlightedOption = 1
                end
                return true
            end
            
            return true
        end
    end
    
    return false
end

-- Focus next/previous control
function formRenderer.focusNext(reverse)
    if not state.activeForm then
        return
    end
    
    local controlCount = #state.activeForm.controls
    if controlCount == 0 then
        return
    end
    
    if not state.focusedControl then
        state.focusedControl = reverse and controlCount or 1
    else
        if reverse then
            state.focusedControl = state.focusedControl - 1
            if state.focusedControl < 1 then
                state.focusedControl = controlCount
            end
        else
            state.focusedControl = state.focusedControl + 1
            if state.focusedControl > controlCount then
                state.focusedControl = 1
            end
        end
    end
    
    -- Reset cursor position for text inputs
    local control = state.controlPositions[state.focusedControl].control
    if control.tag == "input" then
        local value = state.formData[control.name] or control.value or ""
        state.cursorPos = #value + 1
    end
end

-- Get current form data
function formRenderer.getFormData()
    return state.formData
end

-- Set form data
function formRenderer.setFormData(data)
    state.formData = data or {}
end

-- Check if form is valid
function formRenderer.validateForm()
    if not state.activeForm then
        return false, "No active form"
    end
    
    local errors = {}
    
    for _, control in ipairs(state.activeForm.controls) do
        if control.required and control.name then
            local value = state.formData[control.name]
            
            if not value or value == "" or 
               (type(value) == "boolean" and not value) then
                table.insert(errors, control.name .. " is required")
            end
        end
        
        -- Additional validation based on type
        if control.tag == "input" and control.name then
            local value = state.formData[control.name] or ""
            
            if control.type == "email" and value ~= "" then
                if not value:match("^[^@]+@[^@]+%.[^@]+$") then
                    table.insert(errors, control.name .. " must be a valid email")
                end
                
            elseif control.type == "url" and value ~= "" then
                if not value:match("^https?://") then
                    table.insert(errors, control.name .. " must be a valid URL")
                end
                
            elseif control.type == "number" and value ~= "" then
                local num = tonumber(value)
                if not num then
                    table.insert(errors, control.name .. " must be a number")
                else
                    if control.min and num < tonumber(control.min) then
                        table.insert(errors, control.name .. " must be at least " .. control.min)
                    end
                    if control.max and num > tonumber(control.max) then
                        table.insert(errors, control.name .. " must be at most " .. control.max)
                    end
                end
            end
            
            -- Pattern validation
            if control.pattern and value ~= "" then
                if not value:match(control.pattern) then
                    table.insert(errors, control.name .. " format is invalid")
                end
            end
            
            -- Length validation
            if control.minlength and #value < control.minlength then
                table.insert(errors, control.name .. " must be at least " .. 
                                   control.minlength .. " characters")
            end
            if control.maxlength and #value > control.maxlength then
                table.insert(errors, control.name .. " must be at most " .. 
                                   control.maxlength .. " characters")
            end
        end
    end
    
    if #errors > 0 then
        return false, errors
    end
    
    return true
end

return formRenderer