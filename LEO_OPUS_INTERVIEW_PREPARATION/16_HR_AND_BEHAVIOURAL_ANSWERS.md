# 16 — HR & Behavioural Interview Question Bank (STAR Method)

---

## 🌟 Candidate Profile Context: Akash Sanjay More
- **Background:** B.E. in Computer Engineering from Sinhgad College of Engineering (SCOE), SPPU (CGPA: 8.54/10). Schooling at **Sainik School Satara** (disciplined boarding school background, NCC 'A' and 'B' certificates).
- **Internship:** Mobile Application Developer Intern at **The Shinnovation Co.** (Jan 2025 – Present) building LEO OPUS.
- **Competitions:** 2nd Runner-up at Yukti Innovation Challenge 2.0; 1st Rank at Ideaspark PBL Competition; Finalist at Innerve 2025 Hackathon (Army Institute of Technology).

---

## ❓ 16 Highest-Priority HR Questions with Two Answer Styles

### Q35: Tell me about yourself.
- **Style A (Concise Spoken Pitch — 60s):**  
  *"I'm Akash More, a final-year Computer Engineering student at Sinhgad College of Engineering, Pune, with a CGPA of 8.54. I specialize in cross-platform mobile development with Flutter, full-stack backend engineering with Node.js, and cloud databases like Cloud Firestore. Over the past several months, I've worked as a Mobile Application Developer Intern at The Shinnovation Co., where I developed LEO OPUS—a cross-platform mobile ecosystem combining recruitment and maintenance contracting, integrated with Google Gemini AI and Razorpay. Coming from a disciplined background at Sainik School Satara with NCC certification, I bring a strong work ethic, structured problem-solving, and passion for building reliable software. I'm excited about this opportunity at LTIMindtree to contribute to high-impact enterprise projects."*
- **Style B (Deeper Background & Achievements):**  
  Focus on technical journey, transitioning from academic problem-solving to production engineering at Shinnovation, hackathon achievements (Ideaspark 1st rank, Yukti Challenge runner-up), and commitment to continuous learning.

---

### Q36: Why do you want to join LTIMindtree?
- **Style A (Concise):**  
  *"LTIMindtree stands out to me because of its strong culture of technological innovation and large-scale digital transformation. As a fresher who has built full-stack applications with AI and fintech integrations, I want to work in an environment where engineering rigor, scalable architectures, and continuous learning are prioritized. LTIMindtree's diverse domain footprint across cloud, banking, and enterprise mobility offers the perfect platform for me to apply my skills and grow as a software engineer."*
- **Style B (Company Culture & Alignment):**  
  Connect personal values of discipline and craftsmanship to LTIMindtree's reputation for delivery excellence and graduate training programs.

---

### Q37: Describe a difficult technical problem you faced and how you solved it. (STAR Method)
- **Situation:** During my internship at The Shinnovation Co., newly registered users on LEO OPUS were experiencing intermittent permission crashes immediately after sign-up.
- **Task:** I needed to diagnose and resolve this issue to ensure a smooth, zero-failure onboarding experience across Android and iOS.
- **Action:** I traced the root cause to an asynchronous race condition between Firebase Authentication state changes and Firestore document writes, compounded by a mismatch in our security rules. I designed an in-memory session cache in `SessionService` to preserve the user's intended role pre-login, implemented an exponential retry loop with backoff in our root routing layer, and updated our Firestore security rules to check both candidate collections.
- **Result:** We eliminated 100% of registration routing failures, reduced support tickets, and established an automated unit test suite to prevent regressions.

---

### Q38: What are your greatest strengths and weaknesses?
- **Strength:** *Disciplined execution and fast learning.* Built through years at Sainik School Satara and demonstrated by delivering a full-stack production mobile app with AI and payment integrations during a fast-paced internship.
- **Weakness:** *Tendency to over-engineer early prototypes.* In early sprints of LEO OPUS, I spent time building custom sorting algorithms when built-in framework methods were sufficient. I've learned to practice the YAGNI principle (You Aren't Gonna Need It)—delivering the simplest working solution first, and refactoring only when profiling proves it necessary.

---

### Q39–Q50 (Summary Guidelines for Remaining HR Questions)
- **Handling Pressure:** Relate to disciplined boarding school routines at Sainik School Satara and tight internship release deadlines.
- **Handling Disagreements:** Focus on data-driven discussions, code reviews, and listening to senior architectural feedback.
- **Where do you see yourself in 5 years?** Evolving from a strong software development engineer into a technical lead/architect who designs resilient distributed systems and mentors junior engineers.
- **Why should we hire you?** Rare combination of solid computer science fundamentals (CGPA 8.54), proven production project delivery (LEO OPUS live on app stores), and a disciplined, dependable mindset.
