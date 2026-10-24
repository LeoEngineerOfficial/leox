# 17 — Computer Engineering Fundamentals to Project Mapping

---

## 🎓 Complete Cross-Reference Matrix

This matrix maps foundational Computer Engineering academic subjects directly to verified components in the LEO OPUS repository, providing ready-to-use answers for technical viva and interview questions.

| Core Subject | Relevant LEO OPUS Component | Actual Code Evidence | Sample Interview Question | Key Fundamental Concept |
|---|---|---|---|---|
| **Data Structures** | In-memory job sorting & candidate queues | `lib/services/firebase_service.dart` line 93 (`list.sort`) | *"How do you sort items in memory and what is its time complexity?"* | TimSort / Dual-Pivot Quicksort, $O(N \log N)$, Space $O(\log N)$ |
| **Data Structures** | In-memory session cache | `lib/services/session_service.dart` lines 19–25 | *"How does a Hash Table achieve $O(1)$ lookups?"* | Hash functions, bucket arrays, collision resolution via chaining |
| **Algorithms** | Regex JSON recovery & text extraction | `lib/services/gemini_service.dart` line 34; `syncfusion_flutter_pdf` | *"How do you parse structured data from unstructured LLM output?"* | Pattern matching, greedy boundary search, linear stream parsing |
| **DBMS** | Cloud Firestore NoSQL schema | `firestore.rules`, `lib/models/job_model.dart` | *"Explain the difference between SQL 3NF and NoSQL Denormalization."* | ACID vs BASE, document stores, read optimization vs write redundancy |
| **DBMS** | Compound Composite Indexes | `firestore.indexes.json` lines 1–60 | *"How do B-Trees optimize composite range and equality queries?"* | Multi-attribute B-Trees, prefix matching, eliminating $O(N)$ table scans |
| **Operating Systems** | Flutter event loop & async Dart | `lib/main.dart` line 133; `lib/services/connectivity_service.dart` | *"How does single-threaded non-blocking I/O work in an event loop?"* | Microtask queue, Event queue, FIFO scheduling, non-blocking sockets |
| **Operating Systems** | Process isolation & mobile lifecycle | `android/app/build.gradle.kts`, `lib/widgets/premium_paywall.dart` | *"What causes memory leaks in mobile applications and how do you prevent them?"* | Garbage collection roots, uncancelled stream subscriptions, resource disposal |
| **Computer Networks** | HTTPS REST communication | `lib/services/api_service.dart` line 21 | *"Explain the OSI layers traversed during an HTTPS POST request."* | 7-layer OSI model, TCP 3-way handshake, TLS 1.3 key exchange, DNS resolution |
| **Computer Networks** | Rate limiting & network timeouts | `backend/routes/subscription.js` line 1018; `api_service.dart` | *"Why is HTTP 202 Accepted used for rate-limited requests?"* | RFC 7231 status codes, asynchronous request acceptance, network timeouts |
| **Cybersecurity** | HMAC-SHA256 signature verification | `backend/routes/subscription.js` line 306 | *"Why is HMAC more secure than a simple hash for payment verification?"* | Secret-key cryptography, collision resistance, preventing payload tampering |
| **Cybersecurity** | Firebase Custom Claims & RBAC | `backend/grant-admin.js` line 29; `firestore.rules` line 138 | *"Explain the difference between Authentication and Authorization."* | Principle of Least Privilege, stateless JWT claims, server-side rule enforcement |
| **Software Engineering** | Layered Clean Architecture | `MultiProvider` in `lib/main.dart` lines 79–115 | *"How does Dependency Inversion benefit automated testing?"* | SOLID principles, separation of concerns, decoupling presentation from persistence |
| **Software Engineering** | Automated testing pyramid | `test/unit/`, `test/widget/`, `fix_tests.dart` | *"Explain the difference between Unit, Widget, and Integration tests."* | Mockito mocking, virtual frame pumping (`pumpAndSettle`), regression testing |
