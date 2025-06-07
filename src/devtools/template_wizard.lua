-- Template Wizard for RedNet-Explorer
-- Interactive UI for customizing and generating projects from templates

local templateWizard = {}

-- Load dependencies
local templates = require("src.devtools.templates")
local colors = colors or colours
local keys = keys

-- Wizard state
local state = {
    -- Current step
    step = "category",  -- category, template, variables, generate
    
    -- Selection
    selectedCategory = nil,
    selectedTemplate = nil,
    
    -- Variables
    variables = {},
    currentVarIndex = 1,
    
    -- Project
    projectName = "",
    projectPath = "/websites/",
    
    -- Display
    width = 0,
    height = 0,
    scrollOffset = 0,
    
    -- Message
    message = "",
    messageType = "info"
}

-- Initialize wizard
function templateWizard.init()
    state.width, state.height = term.getSize()
    state.step = "category"
    state.selectedCategory = nil
    state.selectedTemplate = nil
    state.variables = {}
    state.currentVarIndex = 1
    state.projectName = ""
    state.message = ""
    
    term.clear()
    term.setCursorPos(1, 1)
end

-- Render header
function templateWizard.renderHeader()
    -- Title
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" Template Wizard - Create New Project")
    
    -- Progress bar
    term.setCursorPos(1, 2)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    
    local steps = {"Category", "Template", "Customize", "Generate"}
    local currentStep = 1
    if state.step == "template" then currentStep = 2
    elseif state.step == "variables" then currentStep = 3
    elseif state.step == "generate" then currentStep = 4
    end
    
    local stepWidth = math.floor(state.width / #steps)
    for i, stepName in ipairs(steps) do
        local x = (i - 1) * stepWidth + 1
        term.setCursorPos(x, 2)
        
        if i == currentStep then
            term.setBackgroundColor(colors.green)
            term.setTextColor(colors.white)
        elseif i < currentStep then
            term.setBackgroundColor(colors.lime)
            term.setTextColor(colors.black)
        else
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.white)
        end
        
        local text = " " .. stepName .. " "
        if #text < stepWidth then
            text = text .. string.rep(" ", stepWidth - #text)
        end
        term.write(text:sub(1, stepWidth))
    end
    
    -- Reset colors
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

-- Render category selection
function templateWizard.renderCategoryStep()
    term.setCursorPos(1, 4)
    term.setTextColor(colors.yellow)
    print("Step 1: Choose a Template Category")
    print("")
    term.setTextColor(colors.white)
    
    local categories = templates.categories
    for i, category in ipairs(categories) do
        term.setCursorPos(3, 6 + i)
        
        if state.selectedCategory == category then
            term.setBackgroundColor(colors.blue)
            term.setTextColor(colors.white)
            term.write("> ")
        else
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.write("  ")
        end
        
        -- Category name with description
        local displayName = category:sub(1, 1):upper() .. category:sub(2)
        term.write(displayName)
        
        -- Category description
        term.setTextColor(colors.gray)
        local descriptions = {
            basic = " - Simple starter templates",
            business = " - Professional business sites",
            personal = " - Blogs and personal pages",
            documentation = " - Technical documentation",
            application = " - Interactive web apps",
            api = " - REST APIs and services"
        }
        term.write(descriptions[category] or "")
        
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
    end
    
    -- Instructions
    term.setCursorPos(1, state.height - 3)
    term.setTextColor(colors.gray)
    print("Use arrow keys to select, Enter to continue, Q to quit")
end

-- Render template selection
function templateWizard.renderTemplateStep()
    term.setCursorPos(1, 4)
    term.setTextColor(colors.yellow)
    print("Step 2: Choose a Template")
    print("")
    term.setTextColor(colors.white)
    
    local categoryTemplates = templates.getByCategory(state.selectedCategory)
    local templateList = {}
    for id, template in pairs(categoryTemplates) do
        table.insert(templateList, {id = id, template = template})
    end
    
    -- Sort by name
    table.sort(templateList, function(a, b)
        return a.template.name < b.template.name
    end)
    
    local y = 7
    for i, item in ipairs(templateList) do
        if y + 2 <= state.height - 4 then
            term.setCursorPos(3, y)
            
            if state.selectedTemplate == item.id then
                term.setBackgroundColor(colors.blue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            end
            
            -- Template name
            term.write(item.template.name)
            term.setBackgroundColor(colors.black)
            
            -- Description
            term.setCursorPos(5, y + 1)
            term.setTextColor(colors.gray)
            term.write(item.template.description:sub(1, state.width - 6))
            
            y = y + 3
        end
    end
    
    -- Instructions
    term.setCursorPos(1, state.height - 3)
    term.setTextColor(colors.gray)
    print("Use arrow keys to select, Enter to continue, Backspace to go back")
end

-- Render variable customization
function templateWizard.renderVariablesStep()
    term.setCursorPos(1, 4)
    term.setTextColor(colors.yellow)
    print("Step 3: Customize Your Project")
    print("")
    
    local template = templates.getTemplate(state.selectedTemplate)
    if not template then return end
    
    -- Project name input
    term.setCursorPos(3, 7)
    term.setTextColor(colors.white)
    term.write("Project Name: ")
    
    if state.currentVarIndex == 0 then
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.black)
    end
    term.write(state.projectName == "" and "[Enter name]" or state.projectName)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.write("  ")
    
    -- Variable inputs
    local varList = {}
    for name, def in pairs(template.variables) do
        table.insert(varList, {name = name, def = def})
    end
    table.sort(varList, function(a, b) return a.name < b.name end)
    
    local y = 9
    local visibleVars = math.min(#varList, math.floor((state.height - 12) / 3))
    local startIdx = math.max(1, state.currentVarIndex - math.floor(visibleVars / 2))
    local endIdx = math.min(#varList, startIdx + visibleVars - 1)
    
    if endIdx - startIdx + 1 < visibleVars then
        startIdx = math.max(1, endIdx - visibleVars + 1)
    end
    
    for i = startIdx, endIdx do
        local var = varList[i]
        if not var then break end
        
        term.setCursorPos(3, y)
        
        -- Variable name
        if state.currentVarIndex == i then
            term.setTextColor(colors.yellow)
            term.write("> ")
        else
            term.setTextColor(colors.white)
            term.write("  ")
        end
        
        local displayName = var.name:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
        term.write(displayName .. ": ")
        
        -- Variable value
        if state.currentVarIndex == i then
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.black)
        else
            term.setTextColor(colors.lightGray)
        end
        
        local value = state.variables[var.name] or var.def.default
        term.write(tostring(value):sub(1, state.width - #displayName - 10))
        
        term.setBackgroundColor(colors.black)
        
        -- Description
        term.setCursorPos(5, y + 1)
        term.setTextColor(colors.gray)
        term.write(var.def.description:sub(1, state.width - 6))
        
        y = y + 3
    end
    
    -- Scroll indicator
    if #varList > visibleVars then
        term.setCursorPos(state.width - 2, 9)
        term.setTextColor(colors.gray)
        term.write(string.format("%d/%d", state.currentVarIndex, #varList))
    end
    
    -- Instructions
    term.setCursorPos(1, state.height - 3)
    term.setTextColor(colors.gray)
    print("Arrow keys to navigate, Enter to edit, Tab to continue, Backspace to go back")
end

-- Render generation step
function templateWizard.renderGenerateStep()
    term.setCursorPos(1, 4)
    term.setTextColor(colors.yellow)
    print("Step 4: Generate Project")
    print("")
    
    local template = templates.getTemplate(state.selectedTemplate)
    if not template then return end
    
    -- Summary
    term.setTextColor(colors.white)
    term.setCursorPos(3, 7)
    print("Project Summary:")
    
    term.setCursorPos(5, 9)
    term.setTextColor(colors.lightGray)
    print("Template: " .. template.name)
    
    term.setCursorPos(5, 10)
    print("Location: " .. fs.combine(state.projectPath, state.projectName))
    
    term.setCursorPos(5, 11)
    print("Files: " .. #table.keys(template.files))
    
    -- File list
    term.setCursorPos(3, 13)
    term.setTextColor(colors.white)
    print("Files to generate:")
    
    local y = 14
    for filename, _ in pairs(template.files) do
        if y < state.height - 4 then
            term.setCursorPos(5, y)
            term.setTextColor(colors.gray)
            term.write("• " .. filename)
            y = y + 1
        end
    end
    
    -- Action buttons
    term.setCursorPos(3, state.height - 5)
    term.setBackgroundColor(colors.green)
    term.setTextColor(colors.white)
    term.write(" Generate Project ")
    
    term.setCursorPos(25, state.height - 5)
    term.setBackgroundColor(colors.red)
    term.write(" Cancel ")
    
    term.setBackgroundColor(colors.black)
    
    -- Instructions
    term.setCursorPos(1, state.height - 3)
    term.setTextColor(colors.gray)
    print("Press G to generate, C to cancel, Backspace to go back")
end

-- Edit variable value
function templateWizard.editVariable(varName, currentValue)
    term.setCursorPos(1, state.height - 1)
    term.clearLine()
    term.setTextColor(colors.yellow)
    term.write("New value: ")
    term.setTextColor(colors.white)
    term.setCursorBlink(true)
    
    local newValue = read(nil, nil, function(text)
        return {currentValue}
    end)
    
    term.setCursorBlink(false)
    
    if newValue and newValue ~= "" then
        state.variables[varName] = newValue
    end
end

-- Edit project name
function templateWizard.editProjectName()
    term.setCursorPos(1, state.height - 1)
    term.clearLine()
    term.setTextColor(colors.yellow)
    term.write("Project name: ")
    term.setTextColor(colors.white)
    term.setCursorBlink(true)
    
    local name = read(nil, nil, function(text)
        return {state.projectName}
    end)
    
    term.setCursorBlink(false)
    
    if name and name ~= "" then
        -- Sanitize name
        name = name:gsub("[^%w%-_]", "")
        state.projectName = name
    end
end

-- Generate project
function templateWizard.generateProject()
    if state.projectName == "" then
        state.message = "Please enter a project name"
        state.messageType = "error"
        return false
    end
    
    local projectPath = fs.combine(state.projectPath, state.projectName)
    
    -- Check if directory exists
    if fs.exists(projectPath) then
        state.message = "Project directory already exists"
        state.messageType = "error"
        return false
    end
    
    -- Generate the project
    local success, message = templates.generateProject(
        state.selectedTemplate,
        projectPath,
        state.variables
    )
    
    if success then
        state.message = "Project generated successfully!"
        state.messageType = "success"
        return true
    else
        state.message = message
        state.messageType = "error"
        return false
    end
end

-- Render the wizard
function templateWizard.render()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    templateWizard.renderHeader()
    
    if state.step == "category" then
        templateWizard.renderCategoryStep()
    elseif state.step == "template" then
        templateWizard.renderTemplateStep()
    elseif state.step == "variables" then
        templateWizard.renderVariablesStep()
    elseif state.step == "generate" then
        templateWizard.renderGenerateStep()
    end
    
    -- Show message if any
    if state.message ~= "" then
        term.setCursorPos(1, state.height - 1)
        if state.messageType == "error" then
            term.setTextColor(colors.red)
        elseif state.messageType == "success" then
            term.setTextColor(colors.green)
        else
            term.setTextColor(colors.white)
        end
        term.clearLine()
        term.write(" " .. state.message)
        term.setTextColor(colors.white)
    end
end

-- Handle input
function templateWizard.handleInput()
    while true do
        templateWizard.render()
        
        local event, p1, p2, p3 = os.pullEvent()
        state.message = ""  -- Clear message on any input
        
        if event == "key" then
            local key = p1
            
            -- Common keys
            if key == keys.q then
                return "quit"
            elseif key == keys.backspace then
                -- Go back
                if state.step == "template" then
                    state.step = "category"
                    state.selectedTemplate = nil
                elseif state.step == "variables" then
                    state.step = "template"
                    state.variables = {}
                    state.currentVarIndex = 1
                elseif state.step == "generate" then
                    state.step = "variables"
                end
            end
            
            -- Step-specific keys
            if state.step == "category" then
                if key == keys.up then
                    local cats = templates.categories
                    local idx = 1
                    for i, cat in ipairs(cats) do
                        if cat == state.selectedCategory then idx = i break end
                    end
                    idx = math.max(1, idx - 1)
                    state.selectedCategory = cats[idx]
                    
                elseif key == keys.down then
                    local cats = templates.categories
                    local idx = 1
                    for i, cat in ipairs(cats) do
                        if cat == state.selectedCategory then idx = i break end
                    end
                    idx = math.min(#cats, idx + 1)
                    state.selectedCategory = cats[idx]
                    
                elseif key == keys.enter and state.selectedCategory then
                    state.step = "template"
                end
                
                -- Initialize selection if none
                if not state.selectedCategory and #templates.categories > 0 then
                    state.selectedCategory = templates.categories[1]
                end
                
            elseif state.step == "template" then
                local categoryTemplates = templates.getByCategory(state.selectedCategory)
                local templateList = {}
                for id, _ in pairs(categoryTemplates) do
                    table.insert(templateList, id)
                end
                table.sort(templateList)
                
                if key == keys.up then
                    local idx = 1
                    for i, id in ipairs(templateList) do
                        if id == state.selectedTemplate then idx = i break end
                    end
                    idx = math.max(1, idx - 1)
                    state.selectedTemplate = templateList[idx]
                    
                elseif key == keys.down then
                    local idx = 1
                    for i, id in ipairs(templateList) do
                        if id == state.selectedTemplate then idx = i break end
                    end
                    idx = math.min(#templateList, idx + 1)
                    state.selectedTemplate = templateList[idx]
                    
                elseif key == keys.enter and state.selectedTemplate then
                    state.step = "variables"
                    state.currentVarIndex = 0  -- Start with project name
                end
                
                -- Initialize selection if none
                if not state.selectedTemplate and #templateList > 0 then
                    state.selectedTemplate = templateList[1]
                end
                
            elseif state.step == "variables" then
                local template = templates.getTemplate(state.selectedTemplate)
                local varCount = 0
                for _ in pairs(template.variables) do
                    varCount = varCount + 1
                end
                
                if key == keys.up then
                    state.currentVarIndex = math.max(0, state.currentVarIndex - 1)
                    
                elseif key == keys.down then
                    state.currentVarIndex = math.min(varCount, state.currentVarIndex + 1)
                    
                elseif key == keys.enter then
                    if state.currentVarIndex == 0 then
                        -- Edit project name
                        templateWizard.editProjectName()
                    else
                        -- Edit variable
                        local varList = {}
                        for name, def in pairs(template.variables) do
                            table.insert(varList, {name = name, def = def})
                        end
                        table.sort(varList, function(a, b) return a.name < b.name end)
                        
                        local var = varList[state.currentVarIndex]
                        if var then
                            local currentValue = state.variables[var.name] or var.def.default
                            templateWizard.editVariable(var.name, currentValue)
                        end
                    end
                    
                elseif key == keys.tab then
                    -- Continue to next step
                    if state.projectName ~= "" then
                        state.step = "generate"
                    else
                        state.message = "Please enter a project name"
                        state.messageType = "error"
                    end
                end
                
            elseif state.step == "generate" then
                if key == keys.g then
                    -- Generate project
                    if templateWizard.generateProject() then
                        sleep(2)  -- Show success message
                        return "success", fs.combine(state.projectPath, state.projectName)
                    end
                    
                elseif key == keys.c then
                    -- Cancel
                    return "cancelled"
                end
            end
            
        elseif event == "mouse_click" then
            -- Handle mouse clicks on generate step
            if state.step == "generate" then
                local x, y = p2, p3
                
                -- Check if clicked on Generate button
                if y == state.height - 5 and x >= 3 and x <= 20 then
                    if templateWizard.generateProject() then
                        sleep(2)
                        return "success", fs.combine(state.projectPath, state.projectName)
                    end
                    
                -- Check if clicked on Cancel button
                elseif y == state.height - 5 and x >= 25 and x <= 33 then
                    return "cancelled"
                end
            end
            
        elseif event == "term_resize" then
            state.width, state.height = term.getSize()
        end
    end
end

-- Utility function to get table keys
function table.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

-- Run the wizard
function templateWizard.run()
    templateWizard.init()
    return templateWizard.handleInput()
end

return templateWizard