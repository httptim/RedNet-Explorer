# RedNet-Explorer Form Processing Documentation

## Overview

RedNet-Explorer provides comprehensive form processing capabilities, enabling interactive web applications within CC:Tweaked. The system includes form parsing, rendering, validation, server-side processing, and session management.

## Architecture

### Components

1. **Form Parser** (`src/forms/form_parser.lua`)
   - Parses form elements from RWML/HTML
   - Extracts form controls and attributes
   - Serializes form data for submission

2. **Form Renderer** (`src/forms/form_renderer.lua`)
   - Renders interactive form elements in terminal
   - Handles keyboard and mouse input
   - Provides real-time form interaction

3. **Form Validator** (`src/forms/form_validator.lua`)
   - Validates form data against rules
   - Sanitizes user input for security
   - Provides common validation schemas

4. **Form Processor** (`src/forms/form_processor.lua`)
   - Handles server-side form submissions
   - Implements CSRF protection
   - Manages rate limiting

5. **Session Manager** (`src/forms/session_manager.lua`)
   - Manages user sessions
   - Provides authentication helpers
   - Handles session persistence

## Form Definition

### Basic Form Structure

```html
<form id="loginForm" action="/login" method="POST">
  <input type="text" name="username" required="true" 
         minlength="3" maxlength="20" />
  
  <input type="password" name="password" required="true" 
         minlength="6" />
  
  <input type="checkbox" name="remember" value="yes" />
  
  <input type="submit" value="Login" />
</form>
```

### Supported Form Elements

#### Input Types
- `text` - Single-line text input
- `password` - Password field (masked)
- `email` - Email address validation
- `url` - URL validation
- `number` - Numeric input with min/max
- `checkbox` - Boolean checkbox
- `radio` - Radio button selection
- `submit` - Form submission button
- `reset` - Form reset button
- `button` - Generic button
- `hidden` - Hidden field
- `date` - Date input (YYYY-MM-DD)
- `time` - Time input (HH:MM)

#### Other Elements
- `textarea` - Multi-line text input
- `select` - Dropdown selection
- `button` - Button element
- `label` - Form label
- `fieldset` - Group related fields
- `legend` - Fieldset caption

### Form Attributes

```html
<form 
  id="formId"           <!-- Unique form identifier -->
  name="formName"       <!-- Form name -->
  action="/submit"      <!-- Submission URL -->
  method="POST"         <!-- HTTP method (GET/POST) -->
  enctype="..."         <!-- Encoding type -->
>
```

### Control Attributes

```html
<input
  type="text"           <!-- Input type -->
  name="fieldName"      <!-- Field name (required for submission) -->
  id="fieldId"          <!-- Unique identifier -->
  value="default"       <!-- Default value -->
  placeholder="hint"    <!-- Placeholder text -->
  required="true"       <!-- Required field -->
  disabled="true"       <!-- Disabled state -->
  readonly="true"       <!-- Read-only state -->
  minlength="3"         <!-- Minimum length -->
  maxlength="50"        <!-- Maximum length -->
  min="0"               <!-- Minimum value (number) -->
  max="100"             <!-- Maximum value (number) -->
  pattern="[A-Za-z]+"   <!-- Regex pattern -->
/>
```

## Client-Side Usage

### Rendering Forms

```lua
local formParser = require("src.forms.form_parser")
local formRenderer = require("src.forms.form_renderer")
local rwmlParser = require("src.content.rwml_parser")

-- Parse RWML content
local ast = rwmlParser.parse(rwmlContent)

-- Extract forms
local forms = formParser.parseForms(ast)

-- Initialize renderer
formRenderer.init()

-- Render first form
if #forms > 0 then
    formRenderer.renderForm(forms[1], 1, 3, 50, 16)
end

-- Handle events
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "key" then
        formRenderer.handleKey(p1)
    elseif event == "char" then
        formRenderer.handleChar(p1)
    elseif event == "mouse_click" then
        local handled, action, control = formRenderer.handleClick(p2, p3, p1)
        
        if action == "submit" then
            -- Submit form
            local formData = formRenderer.getFormData()
            -- Process submission...
        end
    end
end
```

### Form Interaction

#### Keyboard Navigation
- `Tab` / `Shift+Tab` - Navigate between fields
- `Enter` - Submit form (when focused on submit button)
- `Space` - Toggle checkbox, activate button
- `Arrow keys` - Navigate within fields and dropdowns
- `Escape` - Cancel input, close dropdowns

#### Mouse Interaction
- Click to focus fields
- Click checkboxes/radios to toggle
- Click dropdowns to expand
- Click buttons to activate

### Client-Side Validation

```lua
-- Validate before submission
local isValid, errors = formRenderer.validateForm()

if isValid then
    -- Submit form
    submitForm(formData)
else
    -- Display errors
    for _, error in ipairs(errors) do
        print("Error: " .. error)
    end
end
```

## Server-Side Processing

### Setting Up Form Processor

```lua
local formProcessor = require("src.forms.form_processor")
local sessionManager = require("src.forms.session_manager")

-- Initialize
sessionManager.init()
formProcessor.init({
    maxFormSize = 10240,
    rateLimitMax = 10,
    rateLimitWindow = 60000
})

-- Register custom handler
formProcessor.registerHandler("contact", function(formData, context)
    -- Validate data
    local isValid, sanitized, errors = validateContactForm(formData)
    
    if not isValid then
        return {
            success = false,
            errors = errors
        }
    end
    
    -- Process form
    saveContactMessage(sanitized)
    
    -- Return response
    return {
        success = true,
        data = {
            message = "Thank you for your message!"
        },
        redirect = "/contact/success"
    }
end)
```

### Processing Requests

```lua
-- In your server request handler
local response = formProcessor.processSubmission(request)

if response.success then
    if response.redirect then
        -- Redirect to new page
        return redirect(response.redirect)
    else
        -- Show success message
        return renderSuccess(response.data)
    end
else
    -- Show form with errors
    return renderForm(response.errors)
end
```

## Validation

### Defining Validation Rules

```lua
local formValidator = require("src.forms.form_validator")

-- Define schema
local schema = {
    username = {
        required = true,
        minLength = 3,
        maxLength = 20,
        alphanumeric = true,
        sanitize = {"trim", "lowercase"}
    },
    
    email = {
        required = true,
        email = true,
        sanitize = {"trim", "lowercase"}
    },
    
    age = {
        number = true,
        min = 18,
        max = 120,
        sanitize = {"toNumber"}
    },
    
    message = {
        required = true,
        maxLength = 1000,
        sanitize = {"trim", "escape", "normalizeWhitespace"}
    }
}

-- Validate form data
local isValid, errors = formValidator.validateForm(formData, schema)
```

### Built-in Validators

- `required` - Field must have a value
- `minLength` - Minimum string length
- `maxLength` - Maximum string length
- `pattern` - Regex pattern match
- `number` - Must be numeric
- `min` - Minimum numeric value
- `max` - Maximum numeric value
- `integer` - Must be whole number
- `email` - Valid email format
- `url` - Valid URL format
- `alphanumeric` - Letters and numbers only
- `alpha` - Letters only
- `date` - Valid date format
- `time` - Valid time format

### Built-in Sanitizers

- `trim` - Remove leading/trailing whitespace
- `lowercase` - Convert to lowercase
- `uppercase` - Convert to uppercase
- `stripTags` - Remove HTML/RWML tags
- `escape` - Escape special characters
- `toNumber` - Convert to number
- `toBoolean` - Convert to boolean
- `truncate` - Limit string length
- `alphanumericOnly` - Remove non-alphanumeric
- `normalizeWhitespace` - Collapse multiple spaces

### Custom Validators

```lua
-- Add custom validator
formValidator.addRule("phoneNumber", function(value, param)
    if type(value) ~= "string" then
        return false, "Invalid phone number"
    end
    
    local pattern = "^%+?%d{10,15}$"
    if value:match(pattern) then
        return true
    end
    
    return false, "Must be a valid phone number"
end)

-- Use in schema
local schema = {
    phone = {
        required = true,
        phoneNumber = true
    }
}
```

## Session Management

### Creating Sessions

```lua
local sessionManager = require("src.forms.session_manager")

-- Create new session
local sessionId, session = sessionManager.createSession({
    user = nil,
    preferences = {}
})

-- Session includes CSRF token
local csrfToken = session.csrfToken
```

### Using Sessions

```lua
-- Get session
local session = sessionManager.getSession(sessionId)

-- Update session data
sessionManager.updateSession(sessionId, {
    lastVisit = os.epoch("utc"),
    pageViews = (session.data.pageViews or 0) + 1
})

-- Set specific value
sessionManager.setSessionValue(sessionId, "theme", "dark")

-- Get specific value
local theme = sessionManager.getSessionValue(sessionId, "theme")
```

### Authentication

```lua
-- Login
sessionManager.helpers.login(sessionId, "username", {
    email = "user@example.com",
    role = "user"
})

-- Check login status
if sessionManager.helpers.isLoggedIn(sessionId) then
    local username = sessionManager.helpers.getUser(sessionId)
    -- Show user content
end

-- Logout
local newSessionId = sessionManager.helpers.logout(sessionId)
```

### Flash Messages

```lua
-- Set flash message
sessionManager.helpers.setFlash(sessionId, "success", "Form submitted!")

-- Get flash message (auto-removes)
local message = sessionManager.helpers.getFlash(sessionId, "success")
if message then
    displayMessage(message)
end
```

## Security

### CSRF Protection

All POST forms automatically include CSRF protection:

```lua
-- Server generates token
local csrfToken = session.csrfToken

-- Include in form
<input type="hidden" name="_csrf" value="{{csrfToken}}" />

-- Server validates on submission
if not formProcessor.validateCSRF(formData._csrf, session) then
    return error("Invalid CSRF token")
end
```

### Rate Limiting

Prevents form spam:

```lua
-- Configure limits
formProcessor.init({
    rateLimitMax = 10,        -- Max 10 submissions
    rateLimitWindow = 60000   -- Per minute
})

-- Automatic enforcement
-- Returns error if limit exceeded
```

### Input Sanitization

All form data is sanitized:

```lua
-- Automatic security checks
local secure, issues = formValidator.checkSecurity(formData)

-- Detects:
-- - Script injection attempts
-- - SQL injection patterns  
-- - Path traversal attempts
-- - Excessive data sizes
```

### Secure Password Handling

```lua
-- Never store plain passwords
local hashedPassword = hashPassword(password)

-- In production, use proper hashing:
-- - bcrypt
-- - scrypt
-- - argon2
```

## Examples

### Login Form

```html
<form id="login" action="/login" method="POST">
  <label for="username">Username:</label>
  <input type="text" id="username" name="username" 
         required="true" minlength="3" />
  
  <label for="password">Password:</label>
  <input type="password" id="password" name="password" 
         required="true" minlength="6" />
  
  <input type="checkbox" name="remember" value="yes" />
  <label for="remember">Remember me</label>
  
  <input type="submit" value="Login" />
</form>
```

### Contact Form

```html
<form id="contact" action="/contact" method="POST">
  <input type="text" name="name" placeholder="Your Name" 
         required="true" />
  
  <input type="email" name="email" placeholder="Your Email" 
         required="true" />
  
  <select name="subject" required="true">
    <option value="">Select Subject</option>
    <option value="general">General Inquiry</option>
    <option value="support">Technical Support</option>
    <option value="feedback">Feedback</option>
  </select>
  
  <textarea name="message" rows="5" cols="40" 
            placeholder="Your message..." 
            required="true" minlength="10"></textarea>
  
  <input type="submit" value="Send Message" />
</form>
```

### Registration Form

```html
<form id="register" action="/register" method="POST">
  <fieldset>
    <legend>Account Information</legend>
    
    <input type="text" name="username" 
           placeholder="Choose username" 
           required="true" minlength="3" maxlength="20" 
           pattern="[a-zA-Z0-9]+" />
    
    <input type="email" name="email" 
           placeholder="Email address" 
           required="true" />
    
    <input type="password" name="password" 
           placeholder="Password" 
           required="true" minlength="8" />
    
    <input type="password" name="confirm" 
           placeholder="Confirm password" 
           required="true" />
  </fieldset>
  
  <fieldset>
    <legend>Profile Information</legend>
    
    <input type="text" name="fullname" 
           placeholder="Full name" />
    
    <input type="date" name="birthdate" />
    
    <select name="country">
      <option value="">Select Country</option>
      <option value="us">United States</option>
      <option value="uk">United Kingdom</option>
      <option value="ca">Canada</option>
    </select>
  </fieldset>
  
  <input type="checkbox" name="terms" value="yes" 
         required="true" />
  <label for="terms">I agree to the terms of service</label>
  
  <input type="submit" value="Create Account" />
</form>
```

## Best Practices

### Form Design
1. **Clear Labels** - Every input should have a descriptive label
2. **Logical Grouping** - Use fieldsets for related fields
3. **Validation Feedback** - Show errors near relevant fields
4. **Progress Indication** - Show steps for multi-page forms
5. **Accessible** - Support keyboard navigation

### Security
1. **Always Validate** - Never trust client-side validation alone
2. **Sanitize Input** - Clean all user input before processing
3. **Use CSRF Tokens** - Protect against cross-site attacks
4. **Rate Limit** - Prevent spam and abuse
5. **Secure Sessions** - Regenerate IDs after login

### Performance
1. **Minimize Fields** - Only ask for necessary information
2. **Async Validation** - Validate fields as user types
3. **Cache Form State** - Preserve input on errors
4. **Optimize Rendering** - Only redraw changed elements

### User Experience
1. **Clear Instructions** - Explain requirements upfront
2. **Smart Defaults** - Pre-fill where appropriate
3. **Error Recovery** - Don't lose user input on errors
4. **Success Feedback** - Confirm successful submission
5. **Mobile Friendly** - Work well on pocket computers

## Troubleshooting

### Common Issues

**Forms not rendering:**
- Check form structure in AST
- Verify renderer initialization
- Ensure proper window dimensions

**Validation failing:**
- Check validation schema syntax
- Verify field names match
- Test with minimal rules first

**Sessions not persisting:**
- Check file system permissions
- Verify session timeout settings
- Ensure cleanup isn't too aggressive

**CSRF errors:**
- Include CSRF token in form
- Check session validity
- Verify token field name

### Debug Mode

Enable debug output:

```lua
-- In form components
local DEBUG = true

local function debug(message)
    if DEBUG then
        print("[Forms] " .. message)
    end
end
```

## Summary

RedNet-Explorer's form processing system provides:
- Complete form lifecycle management
- Client and server-side validation
- Secure session handling
- CSRF and rate limit protection
- Flexible form rendering
- Comprehensive input handling

This enables building interactive web applications with proper data handling and security within the CC:Tweaked environment.