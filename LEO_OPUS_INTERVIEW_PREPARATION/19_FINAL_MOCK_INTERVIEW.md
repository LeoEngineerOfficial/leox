# 19 — Final Full-Length Technical & Managerial Mock Interview

---

## 🎭 Simulated Technical Interview Transcript

**Setting:** LTIMindtree Technical Specialist Round  
**Interviewer:** Senior Software Architect  
**Candidate:** Akash Sanjay More  

---

**Interviewer:** *"Hello Akash. I see on your resume that you built a project called LEO OPUS during your internship at The Shinnovation Co. Can you walk me through what you built and why?"*

**Akash (Candidate):**  
*"Thank you, sir. During my internship at The Shinnovation Co., I architected and developed LEO OPUS, a cross-platform mobile ecosystem built with Flutter, backed by Cloud Firestore and a dedicated Node.js microservice. In the current market, hiring platforms and on-demand maintenance services are completely fragmented—users have to maintain separate profiles, isolated reputations, and navigate high commission fees.  
I engineered LEO OPUS to bridge both domains into a single ecosystem with four user personas: Employers, Candidates, Maintenance Service Providers, and Service Seekers. A key highlight is our AI Resume Matcher: we extract text locally from candidate PDF resumes on the mobile device and query Google's Gemini AI to compute objective compatibility scores, skill matches, and gap analyses. I also integrated Razorpay for role-based subscriptions with secure server-side HMAC-SHA256 signature verification."*

---

**Interviewer:** *"Interesting. You mentioned extracting PDF text locally on the device. Why didn't you just upload the PDF file directly to your backend and extract it there?"*

**Akash (Candidate):**  
*"That was an intentional architectural decision based on mobile performance and bandwidth constraints. A multi-page candidate resume in PDF format can easily be 3 to 10 megabytes. Uploading heavy binary files over unstable 3G/4G cellular networks in India causes latency, network timeouts, and drains device battery.  
By using `syncfusion_flutter_pdf` directly in Flutter, we parse the PDF byte stream in-memory on the device and extract the raw text, which is typically under 5 kilobytes—a 99% reduction in payload size. We upload the original PDF asynchronously to Firebase Storage once for the employer's records, but our API calls to the AI engine transmit only sanitized text, resulting in sub-second API round-trips."*

---

**Interviewer:** *"Good. Now let's talk about state management. I noticed you used Provider. Why Provider instead of BLoC or GetX?"*

**Akash (Candidate):**  
*"We evaluated all three. BLoC is very robust for complex enterprise state machines, but it introduces significant boilerplate—events, states, and streams for every single feature—which would have slowed down our development cycle. On the other hand, GetX bypasses Flutter's native element tree and introduces global mutable singletons, making automated testing and mocking with Mockito very difficult.  
Provider is Flutter's officially recommended state management solution. It operates natively with Flutter's `InheritedWidget`, uses `ChangeNotifier` for clean observer-pattern reactivity, and supports constructor dependency injection. This allowed us to write clean unit tests with Mockito while maintaining fast feature velocity."*

---

**Interviewer:** *"Let's look at your backend. You integrated Razorpay. Walk me through what happens when a user pays for a subscription. How do you prevent a malicious user from spoofing a payment?"*

**Akash (Candidate):**  
*"We never trust the client-side callback alone. When a user completes a transaction on Razorpay's checkout modal, the Razorpay SDK returns three parameters to our mobile app: `razorpay_order_id`, `razorpay_payment_id`, and `razorpay_signature`.  
Our Flutter app sends these three values along with the plan details to our Express.js backend at `POST /api/subscription/verify-payment`. The backend uses Node.js's native `crypto` module to compute an HMAC-SHA256 hash by taking `orderId + '|' + paymentId` and hashing it with our private `RAZORPAY_KEY_SECRET`. If the computed signature matches the incoming signature, we write the payment record to Firestore with status `'captured'` and activate the subscription. If the signature does not match, the request is rejected with HTTP 400. Because our secret key is never exposed on the mobile device, a malicious user cannot forge a valid signature."*

---

**Interviewer:** *"What if Razorpay's rate limits hit, or Gemini AI returns HTTP 429 when many candidates apply simultaneously?"*

**Akash (Candidate):**  
*"We implemented graceful degradation on our Express backend. When Gemini returns HTTP 429, our catch block intercepts the status code, generates a unique queue ID, writes the resume text and job description into a Firestore collection called `pending_matches`, and returns HTTP 202 Accepted. The mobile app receives a user-friendly message explaining that the AI service is busy and that their application has been queued. Furthermore, on the client side, if the backend is unreachable, our service automatically falls back to secondary model `gemini-2.0-flash`."*

---

**Interviewer:** *"Very well explained, Akash. You clearly understand both the high-level architecture and low-level implementation details of your project."*
