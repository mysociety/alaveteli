# Product Guidelines - Alaveteli

## 1. UX & UI Principles
*   **Simplicity First:** The primary action (making a request) must be prominent and self-explanatory. Hide advanced options (like batching or developer tools) under submenus or separate paths.
*   **Accessibility (WCAG 2.1 AA):** Ensure proper contrast, screen-reader friendly markup, and full keyboard navigability. Alaveteli sites are often used by diverse user groups with varying technical skills.
*   **Transparency of Action:** Users must always understand when their actions are public vs. private. Clear warning banners must precede any public request submission.
*   **Mobile-First Design:** All user-facing pages, especially request writing and public body browsing, must scale gracefully onto mobile devices.

## 2. Prose & Tone of Voice
*   **Empowering & Supportive:** Use encouraging and clear language during the request-making flow. Avoid overly technical or dense legal jargon where possible.
*   **Neutral & Objective:** Maintain a strictly neutral and non-partisan tone throughout the platform. Alaveteli is an infrastructure tool, not a political advocacy group.
*   **Clear Warnings:** Clearly explain the permanent nature of public archiving to users before they post sensitive or personal information.

## 3. Localization & Internationalization
*   **Translation-Ready:** All user-facing strings must utilize translation helpers (`_()` or Rails `I18n.t`).
*   **Jurisdiction Flexibility:** Ensure the application accommodates different country models, FOI laws, response timelines (e.g., working days vs. calendar days), and terminology.

## 4. Development & Code Quality Guidelines
*   **Test-Driven Development:** Write unit tests for models and feature/system tests for critical user journeys (request writing, response parsing).
*   **Semantic HTML:** Use native elements (`<main>`, `<nav>`, `<article>`, `<header>`) to preserve structural hierarchy.
*   **Clean Upgrade Path:** Avoid modifying core Rails classes directly. Follow clean rails patterns and utilize the plugin extension system for country-specific overrides.
*   **No Accepted Known Risk:** Do not accept known security, privacy, accessibility, data-integrity, availability, correctness, or quality risks as "low risk." If a risk is found, remove it, add a verified mitigation, block the track, or keep the risky path disabled by default with a dated Conductor follow-up.
*   **Harness Engineering:** Design the repository so humans and coding agents are steered by explicit guides and corrected by fast sensors. Every new feature or operational control should have feedforward guidance in specs, style guides, contracts, or runbooks and feedback sensors in tests, linters, scanners, type checks, benchmarks, logs, or CI.
*   **Quality Left:** Put cheap deterministic checks close to the change: local commands, task verification, and pre-merge CI. Use slower semantic review, mutation testing, profiling, and E2E suites as additional gates, not replacements for fast computational checks.
