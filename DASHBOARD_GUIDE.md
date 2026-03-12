# Dynamic Analytics Dashboard System

Complete guide to the new interactive dashboard functionality in the Dynamic System Risk Simulator.

## Overview

The dashboard system allows users to create custom, interactive analytics dashboards similar to Metabase or Tableau. Users can:

- **Build dashboards** with multiple component types
- **Visualize data** with charts, KPI cards, tables, and AI insights
- **Apply cross-filtering** - changes to filters update all dashboard components automatically
- **Save/load dashboards** - persist custom dashboards for reuse
- **Manage components** - add, remove, and configure dashboard elements

## Getting Started

### Accessing Dashboards

1. Upload a CSV file using the "Data Upload" card in the sidebar
2. Click the **"Dashboard"** tab at the top to enter Dashboard mode
3. Use the **"Dashboard Builder"** card in the sidebar to create components

## Building Your Dashboard

### Step 1: Add Components

In the Dashboard Builder sidebar:

1. **Select Component Type**: Choose from:
   - **Chart** - Scatter plot with regression line and clusters
   - **KPI Card** - Key Performance Indicator metrics
   - **Table** - Data table (first 20 rows)
   - **AI Insight** - Automated statistical insights

2. **Enter Component Name**: Give your component a descriptive name
   - Example: "Sales Trend", "Revenue Metrics", "Top Performers"

3. **Click "Add to Dashboard"**: The component appears in the dashboard grid

### Step 2: Apply Filters (Cross-Filtering)

In the "Filtering" card:

- **Numeric columns**: Use the range slider to filter by value range
- **Categorical columns**: Check/uncheck values to include
- **All dashboard components update automatically** with filters applied

Changes to filters are reflected instantly across:
- Charts (colored by cluster, respects anomalies)
- KPI cards (recalculated with filtered data)
- Tables (shows first 20 filtered rows)
- AI insights (updated statistics and analysis)

### Step 3: Remove Components

Click the **"Remove"** button on any dashboard card to delete that component from the dashboard.

## Component Types Explained

### 1. Chart Components

Displays a scatter plot of your selected X and Y columns.

**Features**:
- Points colored by cluster membership
- Black rings indicate z-score anomalies (|z| > 2)
- Green line shows linear regression trend
- Component title shown at the top
- Responds to all filtering changes

**Example**:
```
Chart: "Age vs Score"
- Shows relationship between Age (X) and Score (Y)
- Blue/green/orange points = different clusters
- Automatically updates with filter changes
```

### 2. KPI Card Components

Displays key metrics for all numeric columns in the dataset.

**Metrics Calculated**:
- **Average** - Mean value (prominently displayed)
- **Range** - Min to max values
- **Count & Missing** - Valid values and missing data count

**Design**:
- Large, colorful cards with gradient backgrounds
- Easy-to-read metrics summary
- Color-coded for quick visual scanning

**Example**:
```
KPI Card: "Key Metrics"
┌─────────────────────┐
│ Age                 │
│ 38.5                │
│ Avg | Range: 18-65  │
│ n = 1500 | Missing: 3 │
└─────────────────────┘
```

### 3. Table Components

Shows the first 20 rows of filtered data in a clean table format.

**Features**:
- Displays all columns from your dataset
- Sorted by default appearance order
- Striped rows for easy reading
- Shows filtered data in real-time
- Bordered cells for clarity

### 4. AI Insight Components

Displays AI-generated statistical insights about your data.

**Includes**:
- Strongest correlation relationships
- Variance analysis (variability patterns)
- Outlier and anomaly detection
- Dataset health score (0-100)
- Trend analysis and forecasting insights
- Cluster summaries
- Z-score anomaly counts

**Example**:
```
AI Insights:

Strongest Relationship Insight: Age and Score show a moderate positive
relationship (r = 0.456). As Age increases, Score tends to increase.

Variability Insight: Score exhibits high variability within the dataset.
This indicates a wide distribution of values...

Dataset Health Score: 78 / 100 (Good)
```

## Saving and Loading Dashboards

### Saving Your Dashboard

1. Enter a **Dashboard Name** in the "Dashboard Name" input field
   - Example: "Sales Overview Q1 2024"
2. Click **"Save Current"** button
3. Confirmation message appears: "Dashboard 'X' saved successfully!"

**What Gets Saved**:
- Dashboard name
- All components (type, name, configuration)
- Current filter settings (X/Y columns, filter ranges/selections)
- Timestamp of creation

**Storage**: Dashboards are saved in the current app session

### Loading a Saved Dashboard

1. Select a dashboard from the **"Load Dashboard"** dropdown
2. Click **"Load"** button
3. The dashboard layout, components, and filters are restored
4. Confirmation message: "Dashboard 'X' loaded!"

### Deleting a Dashboard

1. Select a dashboard from the **"Load Dashboard"** dropdown
2. Click **"Delete Selected"** button
3. Confirmation: Dashboard removed from available dashboards

## Cross-Filtering in Action

### How Cross-Filtering Works

All dashboard components are **reactive** - they automatically update when any filter changes:

```
User Action: Apply "Age 25-45" filter
         ↓
Dashboard Components Update:
  ├─ Charts: Show only points where Age is 25-45
  ├─ KPIs: Recalculate metrics for filtered data
  ├─ Tables: Display only rows matching filter
  └─ AI Insights: Re-analyze filtered dataset
```

### Example Scenario

**Initial Dashboard**:
- 1500 employees total
- Average salary: $52,000
- Highest anomalies in 3 columns

**Apply "Department = Sales" Filter**:
- 200 employees in sales
- Average salary: $48,500 (recalculated)
- Anomalies: 1 column (recalculated)
- Charts update to show sales-only data
- All KPI cards refresh with sales metrics

**Apply "Years of Service > 5" + "Department = Sales" Filters**:
- 85 employees (sales with 5+ years)
- Average salary: $54,200
- All components show only this segment

## Best Practices

### Dashboard Design

1. **Clear Naming**: Use descriptive component names
   - ✓ Good: "Employee Salary Distribution", "Top Performers Table"
   - ✗ Bad: "Chart 1", "Table"

2. **Balanced Layouts**: Mix component types for better insights
   - Combine charts with KPI cards
   - Add tables for detailed data
   - Include AI insights for analysis

3. **Logical Organization**: Group related components together
   - Sales metrics together
   - Performance indicators together
   - Demographic analysis together

4. **Filter Purpose**: Use filters to drill down into segments
   - Start with full dataset
   - Apply filters to focus on specific segments
   - Observe how metrics change

### Performance Tips

1. **Limit Active Components**: Keep 3-5 active components for responsiveness
2. **Filter Large Datasets**: Smaller filtered datasets render faster
3. **Save Frequently Used Dashboards**: Load pre-configured dashboards instead of recreating

## Advanced Features

### KPI Card Configuration

KPI cards automatically calculate for all numeric columns:
```r
for each numeric column:
  calculate: average, median, min, max
  count valid and missing values
  display in gradient card
```

### AI Insights Integration

Dashboard AI Insights include:
- Correlation analysis
- Variance assessment
- Outlier detection
- Dataset health scoring
- Forecasting insights
- Cluster information

### Dynamic Component Generation

Each dashboard component renders:
1. **Independently** - No cross-component conflicts
2. **Reactively** - Updates when data or filters change
3. **Efficiently** - Only recalculates what changed

## Troubleshooting

### Dashboard Won't Load

**Problem**: Saved dashboard doesn't load
**Solution**:
- Ensure file hasn't been closed
- Reopen and re-select the dashboard
- Dashboards are session-specific; refresh browser may clear them

### Components Not Updating

**Problem**: Dashboard components don't update after filtering
**Solution**:
- Check if component is marked "Active" (should have Remove button)
- Verify filter values are actually selected/entered
- Try removing and re-adding component

### KPI Cards Show "No numeric columns"

**Problem**: KPI component shows warning
**Solution**:
- Upload CSV with at least one numeric column (numbers, not text)
- Check data types in Dataset Profile
- Numeric columns needed for KPI calculation

### Performance Issues

**Problem**: Dashboard loads slowly
**Solution**:
- Filter data to smaller subset
- Remove unused components
- Close browser tabs if many are open

## Technical Details

### Reactive Data Flow

```
User Input (Filtering)
         ↓
filtered_data() reactive triggers
         ↓
All output handlers re-execute:
  ├─ output$dashboard_chart_*
  ├─ output$dashboard_kpi_*
  ├─ output$dashboard_table_*
  └─ output$dashboard_insight_*
         ↓
UI updates with new visualizations
```

### Component Architecture

Each dashboard component:
1. **ID**: Unique identifier (auto-incremented)
2. **Name**: User-provided display name
3. **Type**: Chart, KPI Card, Table, or AI Insight
4. **Active**: Boolean flag (active components render)
5. **Created_at**: Timestamp of creation

### Dashboard State Structure

```
all_dashboards = list(
  "Dashboard Name" = list(
    name = "Dashboard Name",
    created_at = Sys.time(),
    components = list(...),
    filters = list(
      xcol = "Age",
      ycol = "Score",
      x_numeric_filter = c(18, 65),
      x_categorical_filter = c("Sales", "Marketing")
    )
  )
)
```

## Limitations & Future Enhancements

### Current Limitations

1. **Session-only storage**: Dashboards clear on browser refresh
   - Future: Add database/file persistence

2. **Basic forecasting**: Linear regression only
   - Future: Advanced forecasting methods (ARIMA, Prophet)

3. **Static layout**: Components in single column wrap
   - Future: Drag-and-drop layout editor

4. **Export format**: PDF reports only
   - Future: Excel, PowerPoint exports

### Future Enhancements

- [ ] Drag-and-drop dashboard builder
- [ ] Custom color schemes per KPI
- [ ] Component-specific filter overrides
- [ ] Dashboard sharing capabilities
- [ ] Real-time collaboration
- [ ] Custom metrics support
- [ ] Scheduled dashboard emails
- [ ] Mobile-responsive layouts
- [ ] Advanced chart types (heatmaps, treemaps)
- [ ] Time-series dashboard components

## Examples

### Sales Performance Dashboard

**Components**:
1. Chart: "Revenue vs Units Sold"
2. KPI: "Sales Metrics"
3. Table: "Top 20 Sales Records"
4. AI Insight: "Sales Analysis"

**Filters**:
- Region = North America
- Time Period = Last 30 days
- Product > $1000

**Result**: Focused view of high-value sales in specific region

### Employee Analytics Dashboard

**Components**:
1. Chart: "Age vs Salary"
2. KPI: "HR Metrics"
3. Table: "Employee Data"
4. AI Insight: "Salary Analysis"

**Filters**:
- Department = Engineering
- Tenure >= 2 years

**Result**: Engineering department performance and compensation analysis

## Support & Documentation

For more information:
- **Analytics Tab**: Original analytics features remain unchanged
- **Forecasting**: See data profiling & forecasting documentation
- **AI Insights**: Detailed methodology in implementation notes

For issues or questions about the dashboard system, refer to the inline code comments in `DynamicRiskDashboard/app.R`.
