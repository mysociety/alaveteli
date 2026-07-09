# Bot Traffic Resilience Modernization - Harness Map

This document establishes the feedforward guides and feedback sensors that steer work and enforce quality within this repository.

## 1. Feedforward Guides
*   **Workflow Guidelines:** [conductor/workflow.md](file:///C:/Users/60217257/OneDrive%20-%20Flinders/repos/alaveteli/conductor/workflow.md)
*   **Product Principles:** [conductor/product-guidelines.md](file:///C:/Users/60217257/OneDrive%20-%20Flinders/repos/alaveteli/conductor/product-guidelines.md)
*   **Tech Stack Inventory:** [conductor/tech-stack.md](file:///C:/Users/60217257/OneDrive%20-%20Flinders/repos/alaveteli/conductor/tech-stack.md)
*   **PR Template:** [.github/PULL_REQUEST_TEMPLATE.md](file:///C:/Users/60217257/OneDrive%20-%20Flinders/repos/alaveteli/.github/PULL_REQUEST_TEMPLATE.md)

## 2. Feedback Sensors

| Control Category | Sensor Name | Type | Run Event |
| --- | --- | --- | --- |
| **Maintainability** | RuboCop | Computational | Local, Pull Request |
| **Maintainability** | RBS / Steep Type Checking | Computational | Local (when piloted) |
| **Maintainability** | Architecture & Design Review | Inferential | Pull Request, Review |
| **Architecture Fitness** | Brakeman | Computational | Local, Pull Request |
| **Architecture Fitness** | Bearer | Computational | Pull Request (SARIF) |
| **Architecture Fitness** | bundler-audit | Computational | Local, Pull Request |
| **Behaviour** | RSpec Test Suite | Computational | Local, Pull Request |
| **Behaviour** | Cuprite E2E tests | Computational | Pull Request |
| **Behaviour** | Property-Based Tests (PBT) | Computational | Local, Pull Request |
| **Behaviour** | Mutant Mutation Tests | Computational | Scheduled / Local |
| **Performance** | Vernier Profiling | Computational / Runtime | Manual profiling |
| **Performance** | Load Simulation Benchmarks | Computational | Local task execution |
