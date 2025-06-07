-- RedNet-Explorer Form Parser
-- Parses form elements from RWML/HTML content

local formParser = {}

-- Form element types
local FORM_ELEMENTS = {
    "form", "input", "textarea", "select", "option", 
    "button", "label", "fieldset", "legend"
}

-- Input types
local INPUT_TYPES = {
    "text", "password", "number", "email", "url",
    "checkbox", "radio", "submit", "reset", "button",
    "hidden", "file", "date", "time", "color"
}

-- Parse form elements from AST
function formParser.parseForms(ast)
    local forms = {}
    
    -- Recursively find all form elements
    local function findForms(node, parentForm)
        if type(node) ~= "table" then
            return
        end
        
        -- Check if this is a form element
        if node.type == "element" and node.tag == "form" then
            local form = formParser.parseFormElement(node)
            table.insert(forms, form)
            parentForm = form
        end
        
        -- Check if this is a form control inside a form
        if parentForm and node.type == "element" and 
           formParser.isFormControl(node.tag) then
            local control = formParser.parseFormControl(node)
            table.insert(parentForm.controls, control)
        end
        
        -- Recurse into children
        if node.children then
            for _, child in ipairs(node.children) do
                findForms(child, parentForm)
            end
        end
    end
    
    findForms(ast, nil)
    return forms
end

-- Parse a form element
function formParser.parseFormElement(node)
    local form = {
        id = node.attrs and node.attrs.id,
        name = node.attrs and node.attrs.name,
        action = node.attrs and node.attrs.action or "",
        method = node.attrs and node.attrs.method or "GET",
        enctype = node.attrs and node.attrs.enctype or "application/x-www-form-urlencoded",
        controls = {},
        attrs = node.attrs or {}
    }
    
    -- Validate method
    form.method = form.method:upper()
    if form.method ~= "GET" and form.method ~= "POST" then
        form.method = "GET"
    end
    
    return form
end

-- Check if element is a form control
function formParser.isFormControl(tag)
    return tag == "input" or tag == "textarea" or 
           tag == "select" or tag == "button"
end

-- Parse a form control element
function formParser.parseFormControl(node)
    local control = {
        tag = node.tag,
        type = "text",
        name = node.attrs and node.attrs.name,
        id = node.attrs and node.attrs.id,
        value = node.attrs and node.attrs.value,
        attrs = node.attrs or {},
        children = node.children or {}
    }
    
    -- Handle specific control types
    if node.tag == "input" then
        control.type = node.attrs.type or "text"
        
        -- Validate input type
        local validType = false
        for _, itype in ipairs(INPUT_TYPES) do
            if control.type == itype then
                validType = true
                break
            end
        end
        if not validType then
            control.type = "text"
        end
        
        -- Handle special attributes
        control.checked = node.attrs.checked == "true" or 
                         node.attrs.checked == "checked"
        control.disabled = node.attrs.disabled == "true" or 
                          node.attrs.disabled == "disabled"
        control.readonly = node.attrs.readonly == "true" or 
                          node.attrs.readonly == "readonly"
        control.required = node.attrs.required == "true" or 
                          node.attrs.required == "required"
        control.placeholder = node.attrs.placeholder
        control.pattern = node.attrs.pattern
        control.min = node.attrs.min
        control.max = node.attrs.max
        control.minlength = tonumber(node.attrs.minlength)
        control.maxlength = tonumber(node.attrs.maxlength)
        
    elseif node.tag == "textarea" then
        control.type = "textarea"
        control.rows = tonumber(node.attrs.rows) or 4
        control.cols = tonumber(node.attrs.cols) or 20
        control.placeholder = node.attrs.placeholder
        control.disabled = node.attrs.disabled == "true"
        control.readonly = node.attrs.readonly == "true"
        control.required = node.attrs.required == "true"
        
        -- Get text content
        control.value = formParser.extractText(node)
        
    elseif node.tag == "select" then
        control.type = "select"
        control.multiple = node.attrs.multiple == "true"
        control.disabled = node.attrs.disabled == "true"
        control.required = node.attrs.required == "true"
        control.options = {}
        
        -- Parse options
        formParser.parseSelectOptions(node, control.options)
        
    elseif node.tag == "button" then
        control.type = node.attrs.type or "submit"
        control.disabled = node.attrs.disabled == "true"
        control.label = formParser.extractText(node)
    end
    
    return control
end

-- Parse select options
function formParser.parseSelectOptions(node, options)
    if node.children then
        for _, child in ipairs(node.children) do
            if child.type == "element" then
                if child.tag == "option" then
                    local option = {
                        value = child.attrs and child.attrs.value,
                        label = formParser.extractText(child),
                        selected = child.attrs and 
                                 (child.attrs.selected == "true" or
                                  child.attrs.selected == "selected"),
                        disabled = child.attrs and 
                                 (child.attrs.disabled == "true" or
                                  child.attrs.disabled == "disabled")
                    }
                    
                    -- If no value, use label
                    if not option.value then
                        option.value = option.label
                    end
                    
                    table.insert(options, option)
                    
                elseif child.tag == "optgroup" then
                    -- Handle option groups
                    local group = {
                        label = child.attrs and child.attrs.label,
                        disabled = child.attrs and child.attrs.disabled == "true",
                        options = {}
                    }
                    
                    formParser.parseSelectOptions(child, group.options)
                    table.insert(options, group)
                end
            end
        end
    end
end

-- Extract text content from node
function formParser.extractText(node)
    local text = ""
    
    if type(node) == "string" then
        return node
    elseif type(node) == "table" then
        if node.type == "text" then
            return node.content or ""
        elseif node.children then
            for _, child in ipairs(node.children) do
                text = text .. formParser.extractText(child)
            end
        end
    end
    
    return text
end

-- Find form by ID or name
function formParser.findForm(forms, idOrName)
    for _, form in ipairs(forms) do
        if form.id == idOrName or form.name == idOrName then
            return form
        end
    end
    return nil
end

-- Find control by name in form
function formParser.findControl(form, name)
    for _, control in ipairs(form.controls) do
        if control.name == name then
            return control
        end
    end
    return nil
end

-- Get all controls with same name (for radio/checkbox groups)
function formParser.findControlGroup(form, name)
    local group = {}
    for _, control in ipairs(form.controls) do
        if control.name == name then
            table.insert(group, control)
        end
    end
    return group
end

-- Serialize form data for submission
function formParser.serializeFormData(form, formData)
    local data = {}
    
    for _, control in ipairs(form.controls) do
        if control.name and not control.disabled then
            local value = formData[control.name] or control.value
            
            -- Handle different control types
            if control.type == "checkbox" then
                if formData[control.name] ~= nil then
                    if formData[control.name] then
                        data[control.name] = control.value or "on"
                    end
                elseif control.checked then
                    data[control.name] = control.value or "on"
                end
                
            elseif control.type == "radio" then
                -- Only include if this radio is selected
                local selected = formData[control.name] == control.value
                if selected or (control.checked and formData[control.name] == nil) then
                    data[control.name] = control.value
                end
                
            elseif control.type == "select" then
                if control.multiple then
                    -- Handle multiple selection
                    data[control.name] = formData[control.name] or {}
                else
                    -- Single selection
                    data[control.name] = value
                end
                
            elseif control.type ~= "submit" and control.type ~= "reset" and 
                   control.type ~= "button" then
                -- Regular inputs
                data[control.name] = value or ""
            end
        end
    end
    
    return data
end

-- URL encode form data
function formParser.urlEncodeFormData(data)
    local encoded = {}
    
    for key, value in pairs(data) do
        if type(value) == "table" then
            -- Handle arrays (multiple values)
            for _, v in ipairs(value) do
                table.insert(encoded, 
                    textutils.urlEncode(key) .. "=" .. 
                    textutils.urlEncode(tostring(v)))
            end
        else
            table.insert(encoded, 
                textutils.urlEncode(key) .. "=" .. 
                textutils.urlEncode(tostring(value)))
        end
    end
    
    return table.concat(encoded, "&")
end

-- Create form data structure from control values
function formParser.createFormData(form, values)
    local formData = {}
    
    for _, control in ipairs(form.controls) do
        if control.name then
            if values and values[control.name] ~= nil then
                formData[control.name] = values[control.name]
            else
                -- Set default values
                if control.type == "checkbox" then
                    formData[control.name] = control.checked
                elseif control.type == "radio" then
                    if control.checked then
                        formData[control.name] = control.value
                    end
                elseif control.type == "select" then
                    -- Find default selected option
                    for _, option in ipairs(control.options or {}) do
                        if option.selected then
                            if control.multiple then
                                formData[control.name] = formData[control.name] or {}
                                table.insert(formData[control.name], option.value)
                            else
                                formData[control.name] = option.value
                                break
                            end
                        end
                    end
                else
                    formData[control.name] = control.value or ""
                end
            end
        end
    end
    
    return formData
end

return formParser