# 09 — Software Engineering, SDLC & Agile Methodologies

---

## 🔄 SDLC & Agile Engineering Practices in LEO OPUS

During the internship at **The Shinnovation Co.**, LEO OPUS was built following an **Agile Scrum framework** across fast-paced development sessions, focusing on iterative delivery, feature increments, and continuous refactoring.

```
+-------------------------------------------------------------------------+
|                          AGILE SCRUM LIFECYCLE                          |
|                                                                         |
|  [ Sprint Planning ] ---> [ Daily Engineering / Coding ]                |
|           ^                                    |                        |
|           |                                    v                        |
|  [ Sprint Retrospective ] <--- [ Code Review & Testing (Mockito) ]      |
+-------------------------------------------------------------------------+
```

---

## ❓ Category 9 Interview Questions: Software Engineering & SDLC

### Q28: How did you apply Agile and Scrum methodologies during your internship on LEO OPUS?
- **Interviewer Focus:** Team collaboration, sprint management, ticket estimation, and pragmatic software delivery.
- **Answer A (Concise):**  
  We worked in two-week iterative sprints. Each sprint began with backlog grooming and story point estimation, breaking features into actionable user stories (e.g., *"As an employer, I want to post a job opening so candidates can apply"*). We maintained modular Git branches, conducted code reviews, and held retrospective sessions to identify technical bottlenecks (such as diagnosing Firebase index issues and Flutter test deprecations).
- **Answer B (Technical Deep-Dive):**  
  **Sprint Architecture across the Internship:**
  1. **Sprint 1 — Core Auth & Architecture:** Establishing the layered Flutter project structure, configuring Firebase Authentication, and structuring role-based routing in `main.dart`.
  2. **Sprint 2 — Hiring Module & Database Schemas:** Implementing `EmployerJobsProvider`, `EmployeeJobsProvider`, job creation forms, and establishing compound indexes in `firestore.indexes.json` to optimize queries.
  3. **Sprint 3 — Maintenance Contracts & Reactive State:** Creating service catalogs (`mc_services`), booking requests (`mc_requests`), and reviews for technicians.
  4. **Sprint 4 — AI Pipeline & Monetization:** Integrating `syncfusion_flutter_pdf` for local text extraction, Google Gemini AI prompt flows, Razorpay SDK checkouts, and Node.js HMAC verification.
  5. **Sprint 5 — Hardening, Testing & Store Release:** Authoring Mockito unit tests, writing `fix_tests.dart` to resolve Flutter 3.10+ deprecations, and building release APK/AAB bundles.
- **Verified Evidence:** Documented in [`INTERNSHIP_REPORT.md`](file:///d:/Shinnovation/leox/INTERNSHIP_REPORT.md); [`PROJECT_STATUS.md`](file:///d:/Shinnovation/leox/PROJECT_STATUS.md).
- **Likely Follow-up:** *"What is the difference between a Functional Requirement and a Non-Functional Requirement?"*
- **Follow-up Answer:** *"A Functional Requirement defines what the system does (e.g., 'An employee can submit a PDF resume for a job'). A Non-Functional Requirement defines how well the system performs (e.g., 'Cold start time must be under 2 seconds; database queries must complete within 200ms; payments must be cryptographically verified')."*
- **Common Mistakes to Avoid:** Don't invent formal corporate ceremonies you didn't attend. Keep it grounded in your genuine Shinnovation internship experience.

---

### Q29: What is Technical Debt, and how did you manage it in this project?
- **Interviewer Focus:** Code maintainability, pragmatic trade-offs, refactoring discipline, and engineering maturity.
- **Answer A (Concise):**  
  **Technical debt** is the implied cost of future rework incurred by choosing an expedient, quick solution now instead of a better, extensible approach that would take longer. In LEO OPUS, we accrued technical debt during early prototypes by mixing `SharedPreferences` with `FirebaseAuth` and hardcoding mock fallback data. In later sprints, I paid down this technical debt by eliminating dummy data, standardizing on Firebase Auth as the single source of truth, and deploying strict security rules.
- **Answer B (Technical Deep-Dive):**  
  Evidence of technical debt management from [`PROJECT_STATUS.md`](file:///d:/Shinnovation/leox/PROJECT_STATUS.md#L3-L27) and [`FIXES_NEEDED.md`](file:///d:/Shinnovation/leox/FIXES_NEEDED.md):
  1. **Removing Dummy / Hardcoded Data:** Early versions used fallback mock job lists in providers. I removed all dummy data from `EmployeeJobsProvider` and `EmployerJobsProvider`, ensuring UI states reflect genuine Firestore database records with proper empty-state UI widgets.
  2. **Resolving State Conflicts:** Early code used both `SharedPreferences` auth flags and Firebase Auth, causing desynchronization bugs upon logout. I refactored `SessionService` to use Firebase Auth as the primary authority with an in-memory cache.
  3. **Silent Failure Elimination:** Early code in `EmployerJobsProvider.addJob` caught exceptions and swallowed them without alerting the user. I added `rethrow` and error UI feedback so users receive immediate, descriptive alerts upon failure.
- **Verified Evidence:** `PROJECT_STATUS.md` lines 3–27; `FIXES_NEEDED.md` lines 30–39.
- **Likely Follow-up:** *"Is technical debt always bad?"*
- **Follow-up Answer:** *"No. Strategic technical debt is often necessary in early startup phases to validate product-market fit quickly. The key is tracking it transparently and scheduling dedicated refactoring sprints to pay it down before scaling."*
- **Common Mistakes to Avoid:** Don't claim your code had zero technical debt. Acknowledge real engineering trade-offs and explain how you refactored them.
