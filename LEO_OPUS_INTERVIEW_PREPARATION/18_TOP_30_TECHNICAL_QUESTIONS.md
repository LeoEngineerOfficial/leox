# 18 — Top 30 Technical Questions Ranked by Priority (P1 / P2 / P3)

---

## 🎯 Priority-Ranked Technical Master Question Bank

- **P1 (Must Prepare):** Core architectural, framework, and security questions that every interviewer is guaranteed to ask.
- **P2 (Important):** Deep-dive implementation, database, and algorithmic trade-off questions.
- **P3 (Advanced Follow-up):** System design scalability and edge-case failure recovery questions.

---

### 📌 P1: Must Prepare (Questions 1–10)

1. **[P1] Explain the high-level architecture of LEO OPUS in 60 seconds.**  
   *(Answer in `00_PROJECT_OVERVIEW.md` Q1 & `01_ARCHITECTURE_AND_DATA_FLOW.md`)*
2. **[P1] Why did you choose Provider over BLoC or GetX for state management?**  
   *(Answer in `02_FLUTTER_AND_DART.md` Q9)*
3. **[P1] How do you prevent unauthorized users from posting jobs or modifying payments?**  
   *(Answer in `11_AUTHENTICATION_AND_SECURITY_AUDIT.md` Q31)*
4. **[P1] Explain how Razorpay payment verification works on your server using HMAC SHA-256.**  
   *(Answer in `13_RAZORPAY_AND_SUBSCRIPTIONS.md` Q33)*
5. **[P1] How does your app extract text from PDF resumes without passing files to external servers?**  
   *(Answer in `05_DSA_AND_ALGORITHMS.md` Section 2 & `12_GEMINI_AI_AND_RESUME_MATCHING.md`)*
6. **[P1] What is the difference between `StatelessWidget` and `StatefulWidget`?**  
   *(Answer in `02_FLUTTER_AND_DART.md` Q6)*
7. **[P1] How does Cloud Firestore differ from MySQL, and why was NoSQL appropriate here?**  
   *(Answer in `04_DATABASES_AND_DBMS.md` Q19)*
8. **[P1] What is the difference between `context.watch<T>()` and `context.read<T>()` in Provider?**  
   *(Answer in `02_FLUTTER_AND_DART.md` Q9)*
9. **[P1] Explain the most challenging bug you diagnosed in this project.**  
   *(Answer in `00_PROJECT_OVERVIEW.md` Q3 & `15_TESTING_AND_DEBUGGING.md` Scenario 1)*
10. **[P1] How do you handle Google Gemini API rate limiting (HTTP 429)?**  
    *(Answer in `03_BACKEND_AND_REST_APIS.md` Q16)*

---

### 📌 P2: Important Deep-Dive (Questions 11–20)

11. **[P2] How do compound indexes work in Firestore, and why did they improve query speed?**  
    *(Answer in `04_DATABASES_AND_DBMS.md` Q20)*
12. **[P2] What is Idempotency in payment processing, and how is it implemented?**  
    *(Answer in `03_BACKEND_AND_REST_APIS.md` Q18)*
13. **[P2] Explain the StatefulWidget lifecycle from `createState` to `dispose`.**  
    *(Answer in `02_FLUTTER_AND_DART.md` Q7)*
14. **[P2] How does Dart's single-threaded Event Loop handle asynchronous concurrency?**  
    *(Answer in `02_FLUTTER_AND_DART.md` Q11)*
15. **[P2] How do you prevent memory leaks in Flutter when working with streams and controllers?**  
    *(Answer in `02_FLUTTER_AND_DART.md` Q7 & Q10)*
16. **[P2] Explain how Firebase ID tokens and Custom Claims implement Role-Based Access Control.**  
    *(Answer in `03_BACKEND_AND_REST_APIS.md` Q15)*
17. **[P2] What is Sizer, and why is viewport proportional scaling better than fixed pixels?**  
    *(Answer in `02_FLUTTER_AND_DART.md` Q12)*
18. **[P2] How did you test your codebase using Mockito, and what did `fix_tests.dart` solve?**  
    *(Answer in `02_FLUTTER_AND_DART.md` Q13)*
19. **[P2] What is the difference between TCP and UDP, and why does LEO OPUS use TCP?**  
    *(Answer in `08_COMPUTER_NETWORKS_AND_SECURITY.md` Q26)*
20. **[P2] Explain the SOLID principles with concrete examples from your codebase.**  
    *(Answer in `06_OOP_AND_JAVA.md` Q23)*

---

### 📌 P3: Advanced Follow-up & System Design (Questions 21–30)

21. **[P3] How would you scale this architecture to handle 1,000,000 users?**  
    *(Answer in `10_SYSTEM_DESIGN.md` Q30)*
22. **[P3] What are the Coffman conditions for Deadlock, and how are deadlocks avoided?**  
    *(Answer in `07_OPERATING_SYSTEMS.md` Q25)*
23. **[P3] Compare client-initiated payment verification with server-to-server webhook verification.**  
    *(Answer in `03_BACKEND_AND_REST_APIS.md` Q17)*
24. **[P3] What is the difference between a Process and a Thread in modern operating systems?**  
    *(Answer in `07_OPERATING_SYSTEMS.md` Q24)*
25. **[P3] Explain the TLS 1.3 handshake and how it protects mobile API calls.**  
    *(Answer in `08_COMPUTER_NETWORKS_AND_SECURITY.md` Q27)*
26. **[P3] How do you handle LLM hallucinations in automated recruitment workflows?**  
    *(Answer in `12_GEMINI_AI_AND_RESUME_MATCHING.md` Q32)*
27. **[P3] How would you handle database contention if 10,000 candidates apply for 1 job simultaneously?**  
    *(Answer in `10_SYSTEM_DESIGN.md` Q30)*
28. **[P3] What is Technical Debt, and what technical debt did you pay down in LEO OPUS?**  
    *(Answer in `09_SOFTWARE_ENGINEERING_AND_SDLC.md` Q29)*
29. **[P3] What happens during an Android App Bundle (.aab) build compared to a universal APK?**  
    *(Answer in `14_DEPLOYMENT_DEVOPS_AND_MAINTENANCE.md` Q34)*
30. **[P3] How do you ensure offline resilience when a technician loses mobile connectivity on-site?**  
    *(Answer in `02_FLUTTER_AND_DART.md` & `04_DATABASES_AND_DBMS.md`)*
