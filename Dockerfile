FROM rocker/r-ver:4.3.1

# Install system dependencies required for shiny + httpuv
RUN apt-get update && apt-get install -y \
    build-essential \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libcairo2-dev \
    libxt-dev \
    && rm -rf /var/lib/apt/lists/*

# Install shiny and dependencies
RUN R -e "install.packages('shiny', repos='https://cloud.r-project.org/')"

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Run the app
CMD ["Rscript", "app.R"]
