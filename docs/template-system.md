# RedNet-Explorer Template System Documentation

## Overview

The RedNet-Explorer Template System provides a comprehensive solution for quickly creating professional websites with pre-built templates, customization tools, and a complete project workflow. Whether you're building a simple static site or a complex web application, our templates help you get started quickly while maintaining full control over customization.

## Features

### 1. **Pre-built Templates**
- **6 Categories**: Basic, Business, Personal, Documentation, Application, API
- **10+ Templates**: Ready-to-use designs for various purposes
- **Fully Customizable**: Every template can be tailored to your needs
- **Best Practices**: Built with security and performance in mind

### 2. **Template Wizard**
- **Interactive UI**: Step-by-step project creation
- **Variable Customization**: Modify colors, text, and settings
- **Live Preview**: See changes before generating
- **Smart Defaults**: Sensible starting values for all options

### 3. **Asset Management**
- **Image Support**: NFP format for CC:Tweaked
- **Configuration Files**: Structured project settings
- **Data Files**: JSON support for dynamic content
- **Automatic Organization**: Assets sorted by type

### 4. **Site Generator**
- **Complete Workflow**: From creation to deployment
- **Project Management**: Open, edit, and organize projects
- **Build Tools**: Package and deploy your sites
- **Integrated Editor**: Syntax highlighting and validation

## Getting Started

### Using the Site Generator

The Site Generator is your central hub for all template operations:

```bash
# Launch the Site Generator
dev-portal generator

# Or access via browser
Visit: rdnt://dev-portal/generator
```

### Quick Start with Templates

1. **Launch Site Generator**
   ```bash
   dev-portal generator
   ```

2. **Select "Create New Project"**

3. **Choose a Template Category**:
   - Basic - Simple starter templates
   - Business - Professional sites
   - Personal - Blogs and portfolios
   - Documentation - Technical docs
   - Application - Interactive apps
   - API - REST services

4. **Select a Specific Template**

5. **Customize Variables**:
   - Project name
   - Site title
   - Colors and themes
   - Content placeholders

6. **Generate Project**

## Available Templates

### Basic Templates

#### Basic Static Website
```
Template ID: basic-static
Files: index.rwml, about.rwml, contact.rwml, contact-handler.lua
```

Perfect for simple informational websites with:
- Navigation menu
- Contact form
- About page
- Customizable colors and content

**Variables:**
- `site_name` - Your website name
- `author_name` - Your name
- `welcome_message` - Homepage greeting
- `bg_color`, `text_color` - Theme colors

### Business Templates

#### Corporate Website
```
Template ID: business-corporate
Files: index.lua, services.lua, config.json
```

Professional business website featuring:
- Dynamic homepage
- Services showcase
- Company information
- Call-to-action sections

**Key Variables:**
- `company_name` - Business name
- `company_tagline` - Slogan
- `primary_color` - Brand color
- `service1_name`, `service2_name`, etc. - Service details

### Personal Templates

#### Personal Blog
```
Template ID: personal-blog
Files: index.lua, post.lua, admin.lua
```

Full-featured blog system with:
- Post management
- Categories
- Admin panel
- Archive page

**Variables:**
- `blog_title` - Blog name
- `blog_subtitle` - Tagline
- `author_name` - Your name
- `accent_color` - Theme accent

### Documentation Templates

#### Documentation Site
```
Template ID: docs-manual
Files: index.rwml, getting-started.rwml
```

Technical documentation layout with:
- Sidebar navigation
- Code examples
- Quick start guide
- Version information

**Variables:**
- `project_name` - Project being documented
- `version` - Current version
- `installation_command` - Install instructions

### Application Templates

#### Web Application Dashboard
```
Template ID: app-dashboard
Files: index.lua, api/status.lua
```

Interactive dashboard featuring:
- Real-time statistics
- Auto-refresh
- API endpoints
- Widget layout

**Variables:**
- `app_name` - Application name
- `primary_color` - UI theme

### API Templates

#### RESTful API
```
Template ID: api-rest
Files: index.lua, api/items.lua
```

Complete REST API with:
- CRUD operations
- JSON responses
- Documentation page
- Error handling

**Variables:**
- `api_name` - API name
- `base_url` - API base URL
- `auth_description` - Authentication info

## Template Customization

### Variable System

Each template includes customizable variables:

```lua
variables = {
    site_name = {
        default = "My Website",
        description = "Your website name"
    },
    primary_color = {
        default = "blue",
        description = "Primary theme color"
    }
}
```

### Customization Process

1. **During Creation**: Modify variables in the Template Wizard
2. **After Creation**: Edit files directly or modify `config.cfg`
3. **Dynamic Values**: Use Lua for computed values

### Adding Custom Variables

In your template files, use the `{{variable_name}}` syntax:

```html
<h1>Welcome to {{site_name}}</h1>
<p>Created by {{author_name}} in {{year}}</p>
```

## Asset Management

### Project Structure

Templates automatically create this structure:

```
/your-project/
├── index.rwml          # Main page
├── config.cfg          # Site configuration
├── README.txt          # Project documentation
└── assets/
    ├── images/         # NFP image files
    ├── styles/         # Style configurations
    └── data/           # JSON data files
```

### Working with Assets

#### Adding Images

1. Create NFP images using the `paint` program
2. Add to project:
   ```bash
   # In Site Generator
   Select "Manage Assets" > "Add new asset"
   ```

3. Reference in RWML:
   ```xml
   <image src="/assets/images/logo.nfp" />
   ```

#### Configuration Files

Edit `config.cfg` to modify site settings:

```ini
[site]
name = "My Website"
version = "1.0"

[theme]
primary_color = "blue"
background = "black"

[features]
enable_search = false
enable_analytics = true
```

#### Data Files

Store dynamic data in JSON:

```json
{
    "products": [
        {"id": 1, "name": "Item 1", "price": 100},
        {"id": 2, "name": "Item 2", "price": 200}
    ]
}
```

Load in Lua:
```lua
local data = json.decode(fs.open("/assets/data/products.json", "r").readAll())
```

## Site Generation Workflow

### Complete Workflow

1. **Create Project**
   - Choose template
   - Customize variables
   - Generate files

2. **Develop**
   - Edit pages
   - Add assets
   - Test locally

3. **Build**
   - Validate files
   - Optimize assets
   - Create package

4. **Deploy**
   - Copy to server
   - Start server
   - Test live site

### Deployment Options

#### Local Deployment
```bash
# In Site Generator
Select "Deploy to Server" > "Copy to server directory"
```

#### Package Creation
Create a distributable package:
```bash
# Creates projectname.pkg file
Select "Deploy to Server" > "Create deployment package"
```

#### Remote Deployment
Upload to remote server (requires HTTP API):
```bash
Select "Deploy to Server" > "Upload to remote server"
```

## Advanced Features

### Custom Templates

Create your own templates:

1. **Define Template Structure**:
   ```lua
   templates.definitions["my-template"] = {
       name = "My Custom Template",
       category = "custom",
       description = "My template description",
       files = {
           ["index.rwml"] = "template content..."
       },
       variables = {
           custom_var = {default = "value", description = "desc"}
       }
   }
   ```

2. **Add to Category**:
   ```lua
   table.insert(templates.categories, "custom")
   ```

### Template Inheritance

Build templates based on existing ones:

```lua
local baseTemplate = templates.getTemplate("basic-static")
local myTemplate = table.deepcopy(baseTemplate)
myTemplate.name = "Extended Template"
myTemplate.files["extra.rwml"] = "additional content"
```

### Dynamic Template Generation

Generate template content programmatically:

```lua
function generateDynamicTemplate(options)
    local template = {
        name = options.name,
        files = {}
    }
    
    -- Generate files based on options
    for i = 1, options.pageCount do
        template.files["page" .. i .. ".rwml"] = generatePage(i)
    end
    
    return template
end
```

## Best Practices

### 1. **Choose the Right Template**
- Static sites: Use RWML templates
- Dynamic content: Use Lua templates
- APIs: Start with api-rest template

### 2. **Customize Thoughtfully**
- Keep variable names descriptive
- Use consistent color schemes
- Don't over-customize initially

### 3. **Organize Assets**
- Use proper directories
- Name files clearly
- Keep images optimized

### 4. **Test Before Deployment**
- Preview all pages
- Test forms and interactions
- Verify responsive design

### 5. **Document Your Changes**
- Update README.txt
- Comment custom code
- Document API endpoints

## Troubleshooting

### Common Issues

**Template not generating:**
- Check project name (no special characters)
- Ensure target directory doesn't exist
- Verify disk space

**Variables not replacing:**
- Check syntax: `{{variable_name}}`
- Ensure variable is defined
- Look for typos in variable names

**Assets not loading:**
- Verify file paths
- Check file extensions
- Ensure assets directory exists

**Deployment failures:**
- Check server directory permissions
- Verify no conflicting files
- Ensure server is running

### Debug Mode

Enable detailed logging:

```lua
-- In your project
_G.DEBUG = true

-- Will show detailed error messages
```

## Examples

### Creating a Portfolio Site

```bash
1. Launch: dev-portal generator
2. Select: Create New Project
3. Category: Personal
4. Template: Personal Blog
5. Customize:
   - blog_title: "John's Portfolio"
   - blog_subtitle: "Web Developer"
   - accent_color: "cyan"
6. Generate project
7. Edit pages to show projects instead of blog posts
8. Add portfolio images to assets/images/
9. Deploy
```

### Building an API Service

```bash
1. Launch: dev-portal generator
2. Select: Create New Project
3. Category: API
4. Template: RESTful API
5. Customize:
   - api_name: "Task Manager API"
   - base_url: "http://tasks.comp1234.rednet"
6. Generate project
7. Modify api/items.lua for task management
8. Add authentication logic
9. Test with preview
10. Deploy and document
```

## Next Steps

1. **Explore Templates**: Try different templates to find your style
2. **Learn RWML**: Master the markup language for better designs
3. **Study Lua Patterns**: Understand dynamic website creation
4. **Share Templates**: Create and share your own templates
5. **Join Community**: Get help and share experiences

For more information:
- Development Tools: `/docs/development-tools.md`
- RWML Reference: `/docs/rwml-reference.md`
- Security Guide: `/docs/security.md`

Happy building with RedNet-Explorer Templates!