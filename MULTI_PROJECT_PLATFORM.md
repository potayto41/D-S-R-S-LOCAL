# Multi-Project Analytics Platform - Phase 5

## Overview

**Phase 5** transforms the application into a production-grade **multi-project analytics platform** enabling organizations to manage multiple datasets, generate persistent reports, connect to various data sources, and export insights in multiple formats.

**Status**: ✅ Complete and Ready for Production  
**New Tabs**: Projects (new), Analytics, Dashboards, Reports (new)  
**Core Features**: Project management, Data connectors, Report storage, Multi-format exports

---

## 🏢 Task 1: Dataset Projects

### What It Does

Users can organize analytics work into **Projects** - each project contains:
- Multiple datasets
- Multiple dashboards
- Multiple saved reports
- Project metadata (creation date, statistics)

### Project Structure

```
Project
├── Datasets (CSV, Google Sheets, PostgreSQL)
├── Dashboards (saved custom views)
├── Reports (AI-generated with insights)
└── Settings (project info, sharing)
```

### How to Use

#### Create a New Project
1. Click **"New Project"** in sidebar under PROJECT MANAGEMENT
2. System creates project with default name "Project 1", "Project 2", etc.
3. Project automatically selected as current project

#### Switch Between Projects
1. Select project from **"Current Project"** dropdown
2. Active project highlighted in blue
3. All analytics/dashboards/reports scoped to current project

#### View Project Info
Cards display for current project:
- **Project name**
- **Creation date/time**
- **Number of datasets**
- **Number of dashboards**
- **Number of reports**

### Backend Structure

**Reactive Storage**:
```r
all_projects <- reactiveVal(list(
  list(
    id = 1,
    name = "Project Name",
    created = Sys.time(),
    datasets = list(...),      # Stored datasets in this project
    dashboards = list(...),    # Saved dashboards
    reports = list(...)        # Generated reports
  )
))
```

**Project Lifecycle**:
- Create: Generate new project with unique ID
- Select: Switch current_project_id to selected project
- Update: Add datasets/dashboards/reports to project
- Delete: Archive or remove entire project

---

## 🔗 Task 2: Saved Reports

### What It Does

System now **generates and stores** reports with:
- AI insights (Top 5 ranked)
- Detected risks & warnings
- Recommendations
- Dataset summary

### Generate a Report

1. Go to **Reports** tab
2. Enter **Report Name** (e.g., "March 2024 Analysis")
3. Select **Export Format** (PDF, CSV Summary, JSON Insights, All Formats)
4. Click **"Generate Report"**
- System generates report metadata
- Captures current insights, risks, recommendations
- Saves to project

5. Report appears in **"Saved Reports"** section

### Saved Reports Display

Each report shows:
- **Report name**
- **Created date/time**
- **Format**
- **Dataset metrics** (rows, columns)
- **Action buttons**:
  - View: Display full report
  - Delete: Remove from storage

### Report Metadata Captured

When you generate a report, system saves:

```r
new_report <- list(
  id = unique_id,
  name = "Report Name",
  created = timestamp,
  project_id = current_project,
  format = "PDF|CSV|JSON",
  insights = top_insights_ranked(),           # Top 5 insights at time of generation
  risks = detected_risks(),                    # Risks detected
  recommendations = recommendations_list(),   # AI recommendations
  data_summary = list(
    rows = row_count,
    columns = column_count,
    missing_pct = missing_percentage
  ),
  forecast = forecast_results(),              # Trend predictions
  health = dataset_health()                   # Data quality score
)
```

### Storage Mechanism

- **Session storage** (current implementation)
- Stored in `stored_reports` reactive
- Persists for duration of session
- Can be extended to database/file storage

**Future Enhancement**: Export reports to JSON file for external storage

---

## 📊 Task 3: Data Connectors

### What It Does

Users can load data from **multiple sources** instead of just CSV files.

### Supported Connectors

#### 1. CSV File (Existing)
```
Data Source: CSV File
├─ Upload file (.csv)
└─ Auto-detect columns & types
```

**How to Use**:
1. Select "CSV File" from "Data Source" dropdown
2. Choose .csv file to upload
3. File processes automatically

#### 2. Google Sheets (New)
```
Data Source: Google Sheets
├─ Input sheet URL
├─ Extract sheet ID
└─ Download as CSV
```

**Prerequisites**:
- Google Sheets must be publicly shared
- URL must be standard Google Sheets link format

**How to Use**:
1. Select "Google Sheets" from "Data Source" dropdown
2. Paste Google Sheets URL
3. Click "Load Sheet"
4. System downloads and processes data

**Example URL**:
```
https://docs.google.com/spreadsheets/d/SHEET_ID/edit#gid=0
```

#### 3. PostgreSQL (New - Placeholder)
```
Data Source: PostgreSQL
├─ Host: database server
├─ Username: credentials
├─ Password: secure
├─ Database: target DB
└─ SQL Query: custom query
```

**How to Use**:
1. Select "PostgreSQL" from "Data Source" dropdown
2. Enter connection details
3. Write SQL query to extract data
4. Click "Load Data"

**Status**: Requires `RPostgres` or `DBI` packages (not yet installed)

### Connector Selection UI

```
Data Source: [CSV File v]

IF CSV File:
├─ File upload button
└─ [Upload file]

IF Google Sheets:
├─ URL input: https://...
└─ [Load Sheet] button

IF PostgreSQL:
├─ Host input: localhost
├─ Username input: user
├─ Password input: [hidden]
├─ Database input: dbname
├─ Query input: SELECT...
└─ [Load Data] button
```

### Error Handling

Each connector includes error handling:

**CSV Errors**:
- File format errors
- Encoding issues
- Missing required columns

**Google Sheets Errors**:
- Invalid URL format
- Sheet not publicly shared
- Network connection issues

**PostgreSQL Errors**:
- Connection refused
- Authentication failed
- Query syntax errors

All errors displayed as notifications to user.

---

## 💾 Task 4: Report Export Formats

### What It Does

Reports can be exported in **multiple formats** optimized for different use cases.

### Format Options

#### 1. PDF (Existing)
Complete executive report with:
- Dataset overview
- Analysis sections
- Visualizations
- Insights, risks, recommendations
- Professional formatting

**File size**: 50-500 KB depending on data
**Best for**: Executive presentations, archives, sharing

**Content**:
```
INSIGHTFORGE AI REPORT
├─ Generated timestamp
├─ Dataset Overview (rows, columns, missing)
├─ Correlation Intelligence
├─ Variance Analysis
├─ Anomaly Detection
├─ Dataset Health Score
├─ Time-Series Forecasting
├─ TOP 5 RANKED INSIGHTS
├─ DETECTED RISKS & WARNINGS
├─ AI-GENERATED RECOMMENDATIONS
└─ END OF REPORT
```

#### 2. CSV Summary (New)
Tabular summary of key metrics:

```csv
Metric,Value
Rows,500
Columns,12
Missing %,3.5
Health Score,78
Trend,Upward
Anomalies,5
Clusters,3
Dataset,Sample Data
Generated,2024-03-13 14:30
```

**File size**: 1-5 KB
**Best for**: Data warehouses, dashboards, analysis tools
**Format**: Standard CSV (Excel compatible)

#### 3. JSON Insights (New)
Structured insights for programmatic access:

```json
{
  "report_name": "March Analysis",
  "created": "2024-03-13 14:30:00",
  "data_summary": {
    "rows": 500,
    "columns": 12,
    "missing_pct": 3.5
  },
  "top_insights": [
    {
      "rank": 1,
      "title": "Study Hours ↔ Score (r=0.71)",
      "description": "Strong positive relationship...",
      "score": 71,
      "category": "Relationship"
    }
  ],
  "detected_risks": [
    {
      "severity": "HIGH",
      "title": "High Anomaly Rate",
      "description": "Dataset contains 12% anomalies..."
    }
  ],
  "recommendations": [
    {
      "priority": "P1",
      "title": "Increase Study Hours",
      "description": "Focus on 5+ hours daily...",
      "impact": "High"
    }
  ]
}
```

**File size**: 10-50 KB
**Best for**: APIs, integrations, automated workflows
**Format**: Standard JSON (all major languages support)

#### 4. All Formats (Future)
Exports everything as a ZIP archive containing:
- `report.pdf` - PDF version
- `report.csv` - CSV summary
- `insights.json` - JSON insights
- `metadata.txt` - Generation details

**Status**: Placeholder (requires ZIP library)

### How to Export

1. **Generate Report**:
   - Go to Reports tab
   - Enter report name
   - Select desired format
   - Click "Generate"
   - System saves report

2. **Download Report**:
   - Click "Download" button
   - Browser downloads file with appropriate extension
   - `.pdf` for PDF format
   - `.csv` for CSV format
   - `.json` for JSON insights

### Format Comparison

| Feature | PDF | CSV | JSON |
|---|---|---|---|
| **Readability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **File Size** | Large | Small | Medium |
| **Programmatic Access** | ❌ | ⚠️ | ✅ |
| **Excel Compatible** | ❌ | ✅ | ❌ |
| **API Compatible** | ❌ | ⚠️ | ✅ |
| **Best For** | Presentations | Data import | Automation |
| **Human Readable** | ✅ | ✅ | ⚠️ |

---

## 🎨 New UI Components

### Projects Tab

```
┌─ YOUR PROJECTS (Full Screen)
│
├─ [Project 1] ⭐ Current (highlighted blue)
│  Created: 2024-03-10
│  3 datasets | 5 dashboards | 8 reports
│  [Select] [Archive] [Settings]
│
├─ [Project 2]
│  Created: 2024-03-05
│  1 dataset | 2 dashboards | 1 report
│  [Select] [Archive] [Settings]
│
└──────────────────────

[PROJECT DATASETS (Full Screen)]

├─ [Sales Data.csv] ⭐ Current
│  500 rows × 12 columns | Uploaded: 2024-03-13
│  [Load] [Delete] [Analyze]
│
├─ [Customer List]
│  1200 rows × 8 columns | Uploaded: 2024-03-12
│  [Load] [Delete] [Analyze]
```

### Reports Tab

```
┌─ GENERATE & SAVE REPORT
│  Report Name: [March 2024 Analysis   ]
│  Format: [PDF                         v]
│  [Generate] [Download]
│
├─ Status: Ready
└─────────────────────

[SAVED REPORTS]

├─ March 2024 Analysis
│  Created: 2024-03-13 14:30
│  Format: PDF | 500 rows | 12 columns
│  [View] [Delete]
│
├─ February Analysis
│  Created: 2024-02-28 10:15
│  Format: JSON | 450 rows | 12 columns
│  [View] [Delete]
```

### Sidebar Updates

```
PROJECT MANAGEMENT (NEW)
├─ Current Project: [Select Project v]
├─ [New Project] [Settings]
│
└─ Project Details
   ├─ Project: Sales Q1
   ├─ Created: 2024-03-10
   ├─ Datasets: 3
   ├─ Dashboards: 5
   └─ Reports: 8

DATA UPLOAD & CONNECTORS (ENHANCED)
├─ Data Source: [CSV File      v]
│
├─ IF CSV: [Choose File]
├─ IF Google Sheets: 
│  └─ URL: [https://...]
│     [Load Sheet]
├─ IF PostgreSQL:
│  ├─ Host: [localhost]
│  ├─ User: [user]
│  ├─ Pass: [••••••••••]
│  ├─ DB: [dbname]
│  ├─ Query: [SELECT...]
│  └─ [Load Data]
```

---

## 🔄 System Architecture

### Data Flow

```
┌─────────────────────────────────────────┐
│ Multiple Data Sources                   │
│ ├─ CSV Files                            │
│ ├─ Google Sheets                        │
│ └─ PostgreSQL                           │
└──────────┬──────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Load Data (Via Connectors)              │
├─ CSV Loader                             │
├─ Google Sheets Loader                   │
└─ PostgreSQL Loader (Future)             │
└──────────┬──────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Current Project Context                 │
│ ├─ Add to Project Datasets              │
│ └─ Link to Project Metadata             │
└──────────┬──────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Analytics Engine                        │
│ ├─ Generate Insights                    │
│ ├─ Detect Risks                         │
│ └─ Create Recommendations               │
└──────────┬──────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Report Generation                       │
│ ├─ PDF Format                           │
│ ├─ CSV Format                           │
│ └─ JSON Format                          │
└──────────┬──────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Report Storage                          │
│ ├─ Session Memory (Current)             │
│ ├─ Database (Future)                    │
│ └─ File System (Future)                 │
└─────────────────────────────────────────┘
```

### Storage Layers

**Tier 1: Session Memory (Current)**
- Projects stored in `all_projects` reactive
- Reports stored in `stored_reports` reactive
- Persists for duration of user session
- Lost when session ends

**Tier 2: Database (Future)**
- Projects in projects table
- Datasets in datasets table
- Reports in reports table
- Persistent across sessions
- Enable user accounts and sharing

**Tier 3: File System (Future)**
- Export projects to JSON files
- Download/import projects
- Archive historical reports
- External backup

---

## 📋 Feature Matrix

| Feature | Before | After | Status |
|---|---|---|---|
| Single Dataset | ✅ | ✅ (in project) | Complete |
| Multiple Projects | ❌ | ✅ | New |
| Project Management | ❌ | ✅ | New |
| CSV Upload | ✅ | ✅ | Enhanced |
| Google Sheets | ❌ | ✅ | New |
| PostgreSQL | ❌ | ⚠️ | Placeholder |
| PDF Export | ✅ | ✅ | Existing |
| CSV Export | ❌ | ✅ | New |
| JSON Export | ❌ | ✅ | New |
| Report Storage | ❌ | ✅ | New |
| Report Management | ❌ | ✅ | New |
| Dashboards | ✅ | ✅ (per project) | Enhanced |
| Analytics | ✅ | ✅ (per project) | Existing |
| AI Intelligence | ✅ | ✅ | Existing |

---

## 🚀 Usage Scenarios

### Scenario 1: Multi-Team Analysis
```
Organization: University
├─ Project: School of Engineering
│  ├─ Dataset: Engineering Grades 2024
│  ├─ Dashboard: Performance Overview
│  └─ Reports: 3 generated
│
├─ Project: School of Business
│  ├─ Dataset: Business School Metrics
│  ├─ Dashboard: Student Success
│  └─ Reports: 5 generated
│
└─ Project: School of Arts & Sciences
   ├─ Dataset: Liberal Arts Performance
   ├─ Dashboard: Academic Analytics
   └─ Reports: 4 generated
```

### Scenario 2: Ongoing Sales Analysis
```
Project: Sales Q1 2024
├─ Dataset 1: January Sales (loaded from CSV)
├─ Dataset 2: February Sales (loaded from Google Sheets)
├─ Dataset 3: March Sales (loaded from PostgreSQL)
│
├─ Dashboard: Sales Trends
├─ Dashboard: Regional Performance
├─ Dashboard: Product Analysis
│
├─ Report: Executive Summary (PDF)
├─ Report: Detailed Metrics (CSV + JSON)
└─ Report: Risk Assessment (PDF)
```

### Scenario 3: Research Project
```
Project: Machine Learning Study
├─ Dataset: Raw Experimental Data (CSV)
├─ Dataset: Processed Data (Google Sheets)
│
├─ Dashboard: Results Overview
├─ Dashboard: Statistical Analysis
│
├─ Report: Findings (PDF for paper)
├─ Report: Data Export (JSON for archive)
└─ Report: Summary Stats (CSV for databases)
```

---

## 🔧 Configuration & Customization

### Add New Data Connector

To add a new connector (e.g., SQL Server, MySQL):

1. **Create loader function**:
```r
load_sqlserver_data <- function(server, user, pass, database, query) {
  tryCatch({
    # Implementation
  }, error = function(e) {
    showNotification(paste("SQL Server Error:", e$message), type = "error")
    NULL
  })
}
```

2. **Add to connector selector**:
```r
selectInput("data_connector_type", "Data Source",
  choices = c("CSV File", "Google Sheets", "PostgreSQL", 
              "SQL Server"))  # NEW
```

3. **Add conditional panel**:
```r
conditionalPanel(
  condition = "input.data_connector_type === 'SQL Server'",
  textInput("sqlserver_server", "Server", placeholder = "server.db.com"),
  # ... other inputs
  actionButton("load_sqlserver", "Load Data", class = "btn-info btn-sm")
)
```

4. **Add event handler**:
```r
observeEvent(input$load_sqlserver, {
  # Call load_sqlserver_data()
})
```

---

## 📱 UI/UX Guidelines

### Color Scheme
- **Projects Tab**: Blue accents (#007bff)
- **Reports Tab**: Green accents (#28a745)
- **Current Project**: Highlighted with blue border
- **Active Report**: Highlighted background

### Responsive Design
- Sidebar cards adapt to width (330px fixed)
- Main tabs use full width
- Cards use layout_column_wrap for responsive grid
- Mobile: Single column layout

### Accessibility
- Color not only indicator (Current projects also highlighted)
- Clear action buttons with descriptive labels
- Status messages for all operations
- Error notifications for failures

---

## 🎓 Examples

### Example 1: Create Multi-Dataset Project
```
1. Click "New Project"
   → "Project 1" created

2. Select "CSV File" connector
   → Upload students.csv (500 rows)

3. Select "Google Sheets" connector
   → Load Attendance Sheet (450 rows)

4. Select "PostgreSQL" connector
   → Query Grades Table (select * from grades)

5. Now have 3 datasets in one project
   → Single unified analysis
   → Multiple perspectives on same cohort
```

### Example 2: Generate Multi-Format Reports
```
1. Go to Reports tab

2. Generate "Executive Summary"
   → Format: PDF
   → Save
   → Download executive_summary.pdf

3. Generate "Data Export"
   → Format: JSON
   → Save
   → Download data_export.json

4. Generate "Quick Stats"
   → Format: CSV
   → Save
   → Download quick_stats.csv

5. Now have 3 versions of same analysis
   → Each format for different use
```

---

## 🔮 Next Phase: Natural Language Chat

**Phase 6** will add **Natural Language Queries**:

Users ask questions like:
- "Why are scores dropping?"
- "Which students are at risk?"
- "What's the trend in engagement?"

System automatically:
- Interprets question
- Analyzes data
- Generates insights
- Returns answer in natural language

---

## 📞 Support & Documentation

**For Project Management**:
- Create/switch/view projects in sidebar
- Project info auto-updates when changed
- All data stays scoped to current project

**For Data Connectors**:
- CSV: Select file, auto-loads
- Google Sheets: Share publicly, paste URL
- PostgreSQL: Coming soon (requires setup)

**For Reports**:
- Generate by selecting format and clicking "Generate"
- Download from saved reports list
- Each format has specific use case

**For Export Formats**:
- PDF: Best for presentations and archival
- CSV: Best for data import and dashboards
- JSON: Best for APIs and automation

---

**Status**: ✅ Phase 5 Complete
**Next**: Phase 6 - Natural Language Data Chat
