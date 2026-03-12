# Dynamic System Risk Simulator - Advanced Analytics Engine

A comprehensive Shiny web application with AI-powered analytics, interactive dashboards, and forecasting capabilities.

## Features

### Core Analytics
- CSV upload and data ingestion
- Interactive visualizations with filters
- K-means clustering analysis
- Z-score anomaly detection
- Correlation matrix analysis
- Dataset health scoring

### Advanced Analytics
- **Dataset Profiling**: Automatic analysis of rows, columns, data types, missing values, and numeric summaries
- **Time-Series Forecasting**: Linear regression-based forecasting with confidence intervals and trend detection
- **AI Insights**: Automatic detection of correlations, anomalies, and forecasted trends with natural language summaries

### Interactive Dashboard System (NEW)
- **Dashboard Builder**: Create custom analytical dashboards with Chart, KPI Card, Table, and AI Insight components
- **Cross-Filtering**: All dashboard components update automatically when filters are applied
- **KPI Cards**: Automatic calculation and display of key metrics (average, median, min/max, counts)
- **Save/Load Dashboards**: Persist dashboard layouts and filter settings for reuse
- **Responsive Layout**: Dynamic grid layout that adapts to screen size

### AI Decision Intelligence Layer (NEW)
- **Automatic Insight Ranking**: Top 5 insights ranked by statistical significance
  - Strongest correlations with impact scores
  - Largest variances and spreads
  - Anomalies and outlier patterns
  - Cluster distributions and segments
  - Trend analysis and forecasts
- **Automated Risk Detection**: Real-time warning system
  - High anomaly rate alerts
  - Cluster imbalance warnings
  - Rapid trend detection (downward/upward)
  - Data quality health warnings
  - Missing data threshold alerts
- **AI-Generated Recommendations**: Actionable suggestions
  - Relationship optimization
  - Targeted interventions
  - Trend reversal strategies
  - Anomaly protocols
  - Monitoring dashboards

### Reports & Exports
- Interactive plots with zoom and pan
- Filtered data CSV export
- Plot PNG export
- AI-generated PDF reports with profiling, forecasting, and dashboard insights

## Quick Start

### Run Locally

```bash
cd DynamicRiskDashboard
Rscript app.R
```

Opens at `http://localhost:3838`

### Docker Deployment

```bash
docker build -t dynamic-risk-simulator .
docker run --rm -e PORT=8080 -p 8080:8080 dynamic-risk-simulator
```

Opens at `http://localhost:8080`

### Render/Cloud Deployment

```bash
# Automatically handles PORT environment variable
docker run --rm -e PORT=3838 -p 3838:3838 dynamic-risk-simulator
```

## Usage Guide

### Tab 1: Analytics (Original)

Original analytics features including visualizations, clustering, anomaly detection, and AI insights.

**Key Sections**:
- **Visualization**: Interactive plot with filtering, clustering, anomalies, and regression
- **Dataset Profile**: Data types, rows, columns, missing values analysis
- **Forecast Visualization**: Time-series forecasts and trend analysis
- **TOP 5 RANKED INSIGHTS**: Automatically ranked insights by importance (NEW)
  - Correlations, variances, anomalies, clusters, and trends
  - Scored and sorted by statistical significance
  - Executive summaries for each insight
- **DETECTED RISKS & WARNINGS**: Real-time risk alerts (NEW)
  - High anomaly rates, cluster imbalances, trend warnings
  - Severity levels (Critical, High, Medium, Low)
  - Specific recommended actions
- **AI RECOMMENDATIONS**: AI-generated suggestions (NEW)
  - Relationship optimization strategies
  - Targeted interventions
  - Data quality improvements
- **Summary Statistics**: Table of descriptive statistics
- **Table Preview**: First 10 filtered rows
- **AI Insights**: Detailed narrative analysis
- **Download Options**: CSV, PNG, PDF reports

### Tab 2: Dashboard (New)

Create interactive custom dashboards without coding.

**Steps**:
1. **Add Components**: Select type (Chart, KPI, Table, AI Insight) and click "Add to Dashboard"
2. **Apply Filters**: Use sidebar filters - all dashboard components update automatically
3. **Save Dashboard**: Enter dashboard name and click "Save Current"
4. **Load Dashboard**: Select from dropdown and click "Load"
5. **Delete Dashboard**: Select and click "Delete Selected"

**Dashboard Components**:

- **Chart**: Scatter plot with clusters and regression line
- **KPI Card**: Key metrics (average, range, count, missing values) with gradient styling
- **Table**: First 20 filtered rows
- **AI Insight**: Correlation, variance, anomaly, and forecast analysis

## Component Types

### Chart Component
- Scatter plot of selected X/Y columns
- Color-coded by cluster membership
- Black rings for anomalies
- Green regression line
- Real-time updates with filters

### KPI Card Component
- Automatically calculates metrics for all numeric columns
- Shows average (prominent), range, count, and missing values
- Gradient card design for easy scanning
- Updates dynamically with filtered data

Example:
```
┌─────────────────────────────┐
│ Age                          │
│ 38.5                         │
│ Avg | Range: 18-65           │
│ n = 1500 | Missing: 3        │
└─────────────────────────────┘
```

### Table Component
- Displays first 20 rows of filtered data
- All columns shown
- Striped, bordered format
- Updates with filters

### AI Insight Component
- Correlation analysis (strongest relationships)
- Variance assessment (variability patterns)
- Outlier detection (anomalies)
- Dataset health score (0-100)
- Trend analysis and forecasting
- Cluster summaries
- Anomaly counts

## Advanced Features

### Cross-Filtering

All dashboard components automatically update when you:
- Change X/Y axis columns
- Adjust numeric filter ranges
- Select/deselect categorical values

No need to refresh - changes apply instantly!

### Dashboard State Management

**Save** your custom dashboards including:
- All components (type, name, configuration)
- Current filter settings (columns and ranges)
- Timestamp of creation

**Load** previously saved dashboards to restore:
- Component layout
- Filter settings
- All visualizations

### KPI Calculation

Automatically generates metrics for each numeric column:
- **Average**: Mean value (prominently displayed)
- **Median**: Middle value
- **Min/Max**: Range boundaries
- **Count**: Non-missing values
- **Missing**: Count of missing values

Special formatting for large numbers:
- 1,000,000+ → "1.5M"
- 1,000-999,999 → "5.2K"
- Otherwise → 2 decimal places

## Dashboard Examples

### Sales Performance Dashboard

Components:
1. Chart: Revenue vs Units Sold
2. KPI: Sales Metrics
3. Table: Top 20 Sales Records
4. AI Insight: Sales Analysis

Filters:
- Region = North America
- Time Period = Last 30 days

Result: Focused view of high-value sales in specific region

### Employee Analytics Dashboard

Components:
1. Chart: Age vs Salary
2. KPI: HR Metrics
3. Table: Employee Data
4. AI Insight: Salary Distribution

Filters:
- Department = Engineering
- Tenure >= 2 years

Result: Engineering compensation and performance analysis

## Technical Stack

- **R 4.3.1+**
- **Shiny**: Web framework for interactive analytics
- **bslib**: Bootstrap theme styling
- **ggplot2 & plotly**: Visualization
- **tidyverse**: Data manipulation
- **jsonlite**: Dashboard state serialization
- **Base stats**: Statistical analysis and forecasting

## Requirements

### System Dependencies
- R 4.3.1 or later
- libcurl, libssl, libxml2, libcairo2, libpng (for graphical rendering)

### R Packages
- shiny
- bslib
- ggplot2
- plotly
- tidyverse
- jsonlite

## Deployment Notes

### Docker
- Automatically handles PORT environment variable
- Sets SHINY_HOST to 0.0.0.0 for proper networking
- Compatible with Render, Heroku, and other cloud platforms

### Render
- Set PORT environment variable (e.g., 3838)
- App automatically binds to 0.0.0.0:$PORT
- No additional configuration needed

### Local Development
```bash
cd DynamicRiskDashboard
Rscript app.R
# Opens on http://localhost:3838
```

## Performance

- Handles datasets up to 5 MB
- Real-time filtering and analysis
- Linear regression forecasting optimized for <10,000 observations
- Dashboard responsive with up to 10,000 rows × 50 columns
- Multiple components (3-5 recommended for optimal performance)

## Documentation

### User Guides
- **[DASHBOARD_GUIDE.md](DASHBOARD_GUIDE.md)** - Complete dashboard usage tutorial and examples
- **[INTELLIGENCE_LAYER.md](INTELLIGENCE_LAYER.md)** - AI Decision Intelligence system (NEW)
  - Top 5 insight ranking explained
  - Risk detection and warning system
  - AI-generated recommendations
  - PDF report structure
- **[README.md](README.md)** - This file (getting started)
- **[IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)** - Forecasting & profiling details

### Technical Documentation
- **[DASHBOARD_TECHNICAL.md](DASHBOARD_TECHNICAL.md)** - Dashboard architecture guide
- Inline code comments in `DynamicRiskDashboard/app.R`

### For AI Intelligence Features (NEW)
- Automatic insight ranking using statistical metrics
- Risk thresholds and severity levels
- Recommendation generation logic
- See [INTELLIGENCE_LAYER.md](INTELLIGENCE_LAYER.md) for full details

## Troubleshooting

### Dashboard Components Not Updating

**Problem**: Dashboard elements don't refresh after filtering
**Solution**: 
- Check that component is marked as "Active" (has Remove button)
- Verify filter values are actually set
- Try removing and re-adding component

### KPI Cards Show Warning

**Problem**: "No numeric columns available for KPI calculation"
**Solution**:
- Upload CSV with at least one numeric column
- Check data types in Dataset Profile tab
- Non-numeric columns can't be included in KPIs

### Performance Issues

**Problem**: Dashboard loads slowly
**Solution**:
- Filter data to smaller subset
- Remove unused components
- Keep 3-5 components active
- Close other browser tabs

### Saved Dashboard Won't Load

**Problem**: Dashboard list empty or dashboards clear after refresh
**Solution**:
- Dashboards are stored in-session (browser refresh clears them)
- Future version will add persistent storage
- Save important dashboards as JSON exports

## API Customization

### Adding Custom Component Types

Edit `DynamicRiskDashboard/app.R`:

```r
# 1. Add to UI selector
selectInput("dashboard_component_type", choices = c(..., "MyType"))

# 2. Add rendering case
if (comp$type == "MyType") {
  uiOutput(paste0("dashboard_mytype_", comp$id))
}

# 3. Create output handler
output$dashboard_mytype_* <- renderUI({
  df <- filtered_data()  # Must use filtered_data()!
  # Your component code here
})
```

### Custom Metrics in KPI Cards

Modify `calculate_kpis()` function in server.R to add:
- Quartiles
- Standard deviation indicators
- Outlier counts
- Custom thresholds

## Limitations & Future Enhancements

### Current Limitations
- Session-only storage (dashboards clear on refresh)
- Linear regression forecasting only
- Static component positions
- PDF export only

### Planned Enhancements
- [ ] Persistent dashboard storage (file/database)
- [ ] Drag-and-drop layout editor
- [ ] Advanced forecasting (ARIMA, exponential smoothing)
- [ ] More chart types (heatmaps, treemaps, histograms)
- [ ] Dashboard sharing and collaboration
- [ ] Mobile-optimized layouts
- [ ] Custom color themes
- [ ] Scheduled report generation
- [ ] Real-time data updates

## Support

For issues or feature requests:
1. Check the troubleshooting section above
2. Review documentation in [DASHBOARD_GUIDE.md](DASHBOARD_GUIDE.md)
3. See technical details in [DASHBOARD_TECHNICAL.md](DASHBOARD_TECHNICAL.md)
4. Consult inline code comments

## License

MIT

## Contributors

AI-powered analytics engine with dataset profiling, forecasting, and interactive dashboard system.

