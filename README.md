# Dynamic System Risk Simulator

This app is deployed as a single-file Shiny Web Service.

## Run locally

```bash
Rscript app.R
```

## Docker build/run

```bash
docker build -t dynamic-risk-simulator .
docker run --rm -e PORT=8080 -p 8080:8080 dynamic-risk-simulator
```

Open http://localhost:8080
