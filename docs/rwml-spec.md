# RWML (RedNet Website Markup Language) Specification v1.0

## Table of Contents
1. [Introduction](#introduction)
2. [Design Principles](#design-principles)
3. [Syntax Overview](#syntax-overview)
4. [Elements Reference](#elements-reference)
5. [Attributes](#attributes)
6. [Colors and Styling](#colors-and-styling)
7. [Forms and Input](#forms-and-input)
8. [Layout System](#layout-system)
9. [Security Considerations](#security-considerations)
10. [Examples](#examples)

## Introduction

RWML (RedNet Website Markup Language) is a markup language designed specifically for CC:Tweaked terminal displays. It provides a secure, HTML-like syntax for creating interactive web pages within the constraints of Minecraft's ComputerCraft environment.

### Key Features
- Terminal-optimized rendering
- 16-color palette support
- Form handling and user input
- Secure by design (no embedded scripts)
- Lightweight and efficient parsing
- Graceful degradation for unsupported features

### Constraints
- Text-only display (no graphics except NFP images)
- Limited to 16 colors
- Terminal width/height restrictions
- No JavaScript or dynamic scripting (use Lua server-side)
- Single-page rendering (no frames or iframes)

## Design Principles

1. **Security First**: No executable code within RWML
2. **Simplicity**: Easy to learn for HTML users
3. **Terminal Native**: Designed for text-mode displays
4. **Accessibility**: Clear structure and navigation
5. **Performance**: Efficient parsing and rendering
6. **Extensibility**: Room for future enhancements

## Syntax Overview

### Basic Structure
```rwml
<rwml version="1.0">
  <head>
    <title>Page Title</title>
    <meta name="description" content="Page description" />
    <meta name="author" content="Username" />
  </head>
  <body>
    <!-- Page content here -->
  </body>
</rwml>
```

### Comments
```rwml
<!-- This is a comment -->
```

### Self-closing Tags
```rwml
<br />
<hr />
<img src="logo.nfp" />
```

### Case Sensitivity
- Tag names are case-insensitive: `<P>` equals `<p>`
- Attribute names are case-insensitive
- Attribute values are case-sensitive

## Elements Reference

### Document Structure

#### `<rwml>`
Root element of every RWML document.
- **Attributes**: 
  - `version` (required): RWML version (currently "1.0")
  - `lang`: Language code (e.g., "en")

#### `<head>`
Contains metadata about the document.
- **Children**: `<title>`, `<meta>`, `<style>`

#### `<title>`
Sets the page title (displayed in browser tab/title bar).
- **Content**: Plain text only

#### `<meta>`
Provides metadata about the page.
- **Attributes**:
  - `name`: Metadata type ("description", "author", "keywords", etc.)
  - `content`: Metadata value

#### `<body>`
Contains the visible page content.
- **Attributes**:
  - `bgcolor`: Background color name
  - `color`: Default text color name

### Text Content

#### `<h1>` to `<h6>`
Heading elements (h1 largest, h6 smallest).
- **Attributes**:
  - `color`: Text color
  - `align`: Text alignment ("left", "center", "right")

#### `<p>`
Paragraph element.
- **Attributes**:
  - `color`: Text color
  - `align`: Text alignment

#### `<span>`
Inline text container.
- **Attributes**:
  - `color`: Text color
  - `bg`: Background color

#### `<br />`
Line break (self-closing).

#### `<hr />`
Horizontal rule (self-closing).
- **Attributes**:
  - `color`: Line color
  - `width`: Width in characters or percentage

### Formatting

#### `<b>` or `<strong>`
Bold text (rendered with emphasis character if available).

#### `<i>` or `<em>`
Italic text (rendered with emphasis character if available).

#### `<u>`
Underlined text.

#### `<code>`
Monospace code text.
- **Attributes**:
  - `lang`: Programming language for syntax hints

#### `<pre>`
Preformatted text (preserves whitespace).
- **Attributes**:
  - `color`: Text color
  - `bg`: Background color

### Lists

#### `<ul>`
Unordered list.
- **Attributes**:
  - `marker`: List marker character (default: "•")

#### `<ol>`
Ordered list.
- **Attributes**:
  - `start`: Starting number (default: 1)
  - `type`: Numbering type ("1", "a", "A", "i", "I")

#### `<li>`
List item.
- **Attributes**:
  - `color`: Text color

### Links and Navigation

#### `<a>` or `<link>`
Hyperlink element.
- **Attributes**:
  - `href` or `url`: Target URL (required)
  - `color`: Link color (default: blue)
  - `title`: Tooltip text
  - `target`: Target behavior ("_blank" for new tab)

Example:
```rwml
<a href="rdnt://home">Home</a>
<link url="/about.rwml">About Us</link>
```

### Media

#### `<img>`
Display NFP (Nitrogen Fingers Paint) image.
- **Attributes**:
  - `src`: Image file path (required)
  - `alt`: Alternative text
  - `width`: Display width
  - `height`: Display height
  - `align`: Alignment ("left", "center", "right")

### Tables

#### `<table>`
Table container.
- **Attributes**:
  - `border`: Show borders (0 or 1)
  - `width`: Table width
  - `align`: Table alignment

#### `<tr>`
Table row.
- **Attributes**:
  - `bgcolor`: Row background color

#### `<td>`
Table cell.
- **Attributes**:
  - `colspan`: Column span
  - `rowspan`: Row span
  - `align`: Cell alignment
  - `color`: Text color
  - `bgcolor`: Background color

#### `<th>`
Table header cell (same attributes as `<td>`).

### Layout

#### `<div>`
Block container element.
- **Attributes**:
  - `align`: Content alignment
  - `color`: Text color
  - `bgcolor`: Background color
  - `width`: Width in characters or percentage
  - `margin`: Margin in characters

#### `<center>`
Center-aligned content (deprecated, use `<div align="center">`).

## Attributes

### Global Attributes
These attributes can be used on any element:
- `id`: Unique identifier
- `class`: Space-separated class names
- `style`: Inline styles (limited set)
- `hidden`: Hide element from display

### Color Attributes
- `color`: Foreground/text color
- `bgcolor` or `bg`: Background color
- `bordercolor`: Border color

### Dimension Attributes
- `width`: Element width (number or percentage)
- `height`: Element height (number or percentage)
- `margin`: Spacing around element
- `padding`: Spacing inside element

## Colors and Styling

### Color Names
RWML supports the 16 CC:Tweaked colors:
- `white`
- `orange`
- `magenta`
- `lightblue`
- `yellow`
- `lime`
- `pink`
- `gray`
- `lightgray`
- `cyan`
- `purple`
- `blue`
- `brown`
- `green`
- `red`
- `black`

### Color Usage
```rwml
<p color="red">Error message</p>
<div bgcolor="lightblue" color="black">Info box</div>
<span bg="yellow" color="black">Highlighted text</span>
```

### Style Attribute
Limited inline styles are supported:
```rwml
<div style="color: red; bg: yellow; align: center">
  Styled content
</div>
```

## Forms and Input

### `<form>`
Form container.
- **Attributes**:
  - `action`: Form submission URL
  - `method`: HTTP method ("get" or "post")
  - `name`: Form name

### `<input>`
Input field.
- **Attributes**:
  - `type`: Input type (see below)
  - `name`: Field name (required)
  - `value`: Default value
  - `placeholder`: Placeholder text
  - `required`: Field is required
  - `readonly`: Field is read-only
  - `maxlength`: Maximum length
  - `size`: Display width

#### Input Types:
- `text`: Single-line text input (default)
- `password`: Password input (hidden characters)
- `number`: Numeric input
- `checkbox`: Checkbox
- `radio`: Radio button
- `submit`: Submit button
- `reset`: Reset button
- `button`: Generic button
- `hidden`: Hidden field

### `<textarea>`
Multi-line text input.
- **Attributes**:
  - `name`: Field name (required)
  - `rows`: Number of visible rows
  - `cols`: Number of visible columns
  - `placeholder`: Placeholder text
  - `required`: Field is required
  - `readonly`: Field is read-only
  - `maxlength`: Maximum length

### `<select>`
Dropdown selection.
- **Attributes**:
  - `name`: Field name (required)
  - `multiple`: Allow multiple selections
  - `size`: Number of visible options
  - `required`: Field is required

### `<option>`
Select option.
- **Attributes**:
  - `value`: Option value
  - `selected`: Option is selected
  - `disabled`: Option is disabled

### `<button>`
Button element.
- **Attributes**:
  - `type`: Button type ("submit", "reset", "button")
  - `name`: Button name
  - `value`: Button value
  - `disabled`: Button is disabled
  - `color`: Text color
  - `bgcolor`: Background color

### Form Example
```rwml
<form action="/login" method="post">
  <p>Username: <input type="text" name="username" required /></p>
  <p>Password: <input type="password" name="password" required /></p>
  <p>
    <input type="checkbox" name="remember" value="1" /> Remember me
  </p>
  <p>
    <button type="submit" bgcolor="green" color="white">Login</button>
    <button type="reset">Clear</button>
  </p>
</form>
```

## Layout System

### Block vs Inline Elements

#### Block Elements
Take full width, start on new line:
- `<div>`, `<p>`, `<h1>`-`<h6>`, `<ul>`, `<ol>`, `<table>`, `<form>`, `<hr>`, `<pre>`

#### Inline Elements
Flow with text, don't force line breaks:
- `<span>`, `<a>`, `<link>`, `<b>`, `<i>`, `<u>`, `<code>`, `<strong>`, `<em>`

### Alignment
```rwml
<div align="left">Left aligned</div>
<div align="center">Center aligned</div>
<div align="right">Right aligned</div>
```

### Spacing
```rwml
<div margin="2">2-character margin on all sides</div>
<div padding="1">1-character padding inside</div>
```

### Width Control
```rwml
<div width="50%">Half width</div>
<div width="20">20 characters wide</div>
<hr width="80%" />
```

## Security Considerations

### Prohibited Features
- No `<script>` tags or JavaScript
- No `<object>`, `<embed>`, or plugins
- No external resource loading (except images)
- No inline event handlers
- No `javascript:` URLs

### Safe Practices
1. All user input must be escaped
2. File paths are sandboxed to document root
3. No directory traversal allowed
4. URLs are validated and sanitized
5. Form submissions require CSRF protection

### Content Security Policy
RWML enforces these policies:
- No execution of arbitrary code
- Limited to predefined element behaviors
- Sandboxed file system access
- Network requests only through forms/links

## Examples

### Basic Page
```rwml
<rwml version="1.0">
  <head>
    <title>Welcome to RedNet</title>
    <meta name="description" content="A simple RWML page" />
  </head>
  <body bgcolor="black" color="white">
    <h1 color="lime">Welcome to RedNet-Explorer!</h1>
    <p>This is a simple RWML page demonstrating basic features.</p>
    <hr color="gray" />
    <p>Visit our <link url="/docs">documentation</link> to learn more.</p>
  </body>
</rwml>
```

### Navigation Menu
```rwml
<div bgcolor="blue" color="white" padding="1">
  <span>[</span>
  <link url="/" color="yellow">Home</link>
  <span>] [</span>
  <link url="/about" color="yellow">About</link>
  <span>] [</span>
  <link url="/contact" color="yellow">Contact</link>
  <span>]</span>
</div>
```

### Contact Form
```rwml
<h2>Contact Us</h2>
<form action="/contact" method="post">
  <table>
    <tr>
      <td>Name:</td>
      <td><input type="text" name="name" size="30" required /></td>
    </tr>
    <tr>
      <td>Email:</td>
      <td><input type="text" name="email" size="30" required /></td>
    </tr>
    <tr>
      <td>Message:</td>
      <td><textarea name="message" rows="5" cols="30" required></textarea></td>
    </tr>
    <tr>
      <td></td>
      <td>
        <button type="submit" bgcolor="green" color="white">Send</button>
        <button type="reset">Clear</button>
      </td>
    </tr>
  </table>
</form>
```

### Styled Content Box
```rwml
<div bgcolor="lightgray" color="black" padding="2" margin="1">
  <h3 color="blue">Information Box</h3>
  <p>This is an example of a styled content box with:</p>
  <ul>
    <li>Custom background color</li>
    <li>Padding for inner spacing</li>
    <li>Margin for outer spacing</li>
    <li>Nested elements with colors</li>
  </ul>
  <p align="right">
    <link url="/more" color="blue">Learn more →</link>
  </p>
</div>
```

### Table Layout
```rwml
<table border="1" width="100%">
  <tr bgcolor="blue" color="white">
    <th>Feature</th>
    <th>Status</th>
    <th>Notes</th>
  </tr>
  <tr>
    <td>Basic Rendering</td>
    <td color="green">Complete</td>
    <td>Fully functional</td>
  </tr>
  <tr bgcolor="lightgray">
    <td>Forms</td>
    <td color="yellow">In Progress</td>
    <td>90% complete</td>
  </tr>
  <tr>
    <td>Images</td>
    <td color="red">Planned</td>
    <td>NFP support coming</td>
  </tr>
</table>
```

## Future Enhancements

### Planned Features
1. **CSS-like Stylesheets**: `<style>` tag support
2. **Advanced Forms**: File uploads, date pickers
3. **Media**: Audio indicators, animations
4. **Interactivity**: Limited client-side behaviors
5. **Templates**: Include/import functionality

### Version History
- **v1.0** (Current): Initial specification
- **v1.1** (Planned): Stylesheet support
- **v1.2** (Planned): Enhanced forms
- **v1.3** (Planned): Media extensions

---

This specification is designed to evolve with the RedNet-Explorer project while maintaining backward compatibility. All parsers should gracefully handle unknown elements and attributes by ignoring them rather than failing.