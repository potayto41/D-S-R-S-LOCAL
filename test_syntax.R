#!/usr/bin/env Rscript

# Test script to validate app.R syntax

cat("Testing app.R syntax...\n")

tryCatch({
  source('DynamicRiskDashboard/app.R', echo=FALSE)
  cat("✓ PASS: app.R syntax is valid\n")
  quit(status=0)
}, error = function(e) {
  cat("✗ FAIL: Syntax error found:\n")
  cat("Error:", e$message, "\n")
  quit(status=1)
}, warning = function(w) {
  cat("⚠ WARNING:", w$message, "\n")
})
