FROM rocker/r-ver:4.3.1

# Install system dependencies required for shiny + httpuv + graphics
RUN apt-get update && apt-get install -y \
    build-essential \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libcairo2-dev \
    libxt-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# Install shiny, bslib, and other required dependencies
RUN R -e "install.packages(c('shiny', 'bslib', 'ggplot2', 'plotly', 'tidyverse'), repos='https://cloud.r-project.org/')"

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Expose port (default 3838 for Shiny, can be overridden by PORT env var)
EXPOSE 3838

# Set environment variable for Shiny host
ENV SHINY_HOST=0.0.0.0

# Run the app with proper port binding via PORT environment variable
CMD ["Rscript", "-e", "port <- as.numeric(Sys.getenv('PORT', '3838')); shiny::runApp('DynamicRiskDashboard', host='0.0.0.0', port=port)"]
