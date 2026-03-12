# Quick Reference: Multi-Project Platform Implementation

## Core Features Implementation Map

### 1️⃣ Projects Tab (NEW)
**Files**: `ui.R` → `navbarPage()` tab  
**Business Logic**: `server.R` → `observeEvent(input$new_project)`

**Key Elements**:
- Project List (reactive: `all_projects`)
- Create/Select/Archive projects
- Project statistics card

### 2️⃣ Data Connectors (ENHANCED)
**Files**: `ui.R` → Input section  
**Logic**: `server.R` → `observeEvent(input$load_data)`

**Types Implemented**:
1. CSV File (existing)
2. Google Sheets (new)
3. PostgreSQL (placeholder)

### 3️⃣ Reports Tab (NEW)
**Files**: `ui.R` → `navbarPage()` tab  
**Logic**: `server.R` → Report generation functions

**Features**:
- Report generation
- Multi-format export
- Report storage & retrieval

### 4️⃣ Export Formats (NEW)
**Formats**:
- PDF (existing system)
- CSV Summary (new)
- JSON Insights (new)

---

## Data Structure

### Projects
```r
all_projects <- reactiveVal(list(
  list(id=1, name="Project 1", datasets=..., dashboards=..., reports=...),
  list(id=2, name="Project 2", datasets=..., dashboards=..., reports=...)
))
```

### Reports
```r
stored_reports <- reactiveVal(list(
  list(
    id=1,
    name="Report Name",
    format="PDF|CSV|JSON",
    content=...,
    created=Sys.time()
  )
))
```

---

## Key Functions

### Project Management
- `create_project()` - Create new project
- `select_project(id)` - Switch active project
- `delete_project(id)` - Remove project
- `get_current_project()` - Get active project data

### Data Connectors
- `load_csv_data(file)` - Load CSV
- `load_google_sheets(url)` - Load Google Sheets
- `load_postgresql_data(...)` - Load PostgreSQL (placeholder)

### Report Generation
- `generate_report(name, format)` - Create report
- `export_pdf_report(data)` - PDF export
- `export_csv_report(data)` - CSV export
- `export_json_report(data)` - JSON export

---

## Common Tasks

### Add a New Data Connector
1. Create UI input panel (conditional)
2. Create loader function
3. Add observer for load button
4. Add error handling

### Add Export Format
1. Create export function
2. Add format option to UI dropdown
3. Update generate_report() logic
4. Update download handler

### Add Project Metadata
1. Update project structure
2. Add to project info card
3. Update project summary display

---

## Testing Checklist

- [ ] Create new project
- [ ] Switch between projects
- [ ] Load CSV data
- [ ] Load Google Sheets
- [ ] Generate PDF report
- [ ] Generate CSV report
- [ ] Generate JSON report
- [ ] View saved reports
- [ ] Delete report
- [ ] View project statistics
- [ ] All data scoped to project

---

## References

- **Full Documentation**: MULTI_PROJECT_PLATFORM.md
- **User Guide**: See README.md
- **Architecture**: See ARCHITECTURE.md
