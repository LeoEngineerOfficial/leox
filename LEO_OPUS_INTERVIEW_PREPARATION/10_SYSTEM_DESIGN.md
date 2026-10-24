# 10 — System Design & Scalability Roadmap (10k to 1M Users)

---

## 📈 Scalability Evolution Roadmap

This chapter explores how the current architecture of LEO OPUS would evolve from an initial deployment (1,000 users) to 10,000, 100,000, and 1,000,000 active users.

```
+-------------------------------------------------------------------------+
|                        SYSTEM SCALING EVOLUTION                         |
|                                                                         |
|  PHASE 1: Monolith + Firebase (Current MVP / 1k–10k Users)               |
|  - Cloud Firestore + Node.js Express on Render + Flutter Client          |
|                                                                         |
|  PHASE 2: Scaled Modular Monolith (100k Users)                          |
|  - Redis Caching Layer + Cloud Tasks / BullMQ Worker Queues             |
|  - CDN Edge Caching (Cloudflare) + Firestore Read Replicas              |
|                                                                         |
|  PHASE 3: Distributed Microservices (1M+ Users)                         |
|  - Microservices: Auth Service, Jobs Service, Payment Service, AI Worker|
|  - PostgreSQL with Read Replicas + Redis Cluster + Kafka Event Bus      |
+-------------------------------------------------------------------------+
```

---

## ❓ Category 10 Interview Questions: System Design

### Q30: How would you scale LEO OPUS from 10,000 to 1,000,000 users? When would you transition from a modular monolith to microservices?
- **Interviewer Focus:** System design principles, caching strategies, database bottlenecks, asynchronous queues, and avoiding premature microservice complexity.
- **Answer A (Concise):**  
  At 10,000 users, our current modular monolith with Cloud Firestore and Express is more than sufficient. To scale to 100,000 users, we would introduce **Redis** for caching hot job listings, implement **BullMQ / Cloud Tasks** for background AI processing, and add a CDN for static assets. We would only transition to microservices at 1,000,000 users if separate business domains (e.g., Payments vs AI Matching) experience independent scaling bottlenecks or require separate engineering deployment teams.
- **Answer B (Technical Deep-Dive):**  
  **Stage 1: Scaling to 10,000 Users (Current Architecture Optimization)**
  - *Database:* Rely on Firestore's native auto-scaling. Enforce compound indexes to prevent unindexed query table scans.
  - *Caching:* Implement HTTP caching headers (`Cache-Control: public, max-age=300`) on static job catalogs and subscription plan definitions.
  
  **Stage 2: Scaling to 100,000 Users (Bottleneck Elimination)**
  - *AI Processing:* Direct synchronous calls to Gemini API will exhaust rate limits and cause timeouts. Transition to an asynchronous message queue (e.g., **Redis + BullMQ** or **Google Cloud Tasks**). The client receives an immediate job application ID; background workers process resumes against Gemini with rate-limit throttling and write scores back asynchronously.
  - *Hot Reads Caching:* Popular job listings (e.g., top software engineering roles) are read thousands of times. Cache them in **Redis** with a 10-minute TTL, offloading 80% of read traffic from Firestore.
  - *Backend Horizontal Scaling:* Run multiple stateless Express instances behind a Cloud Load Balancer (Render Auto-Scaling or Google Cloud Run).
  
  **Stage 3: Scaling to 1,000,000+ Users (Domain Separation)**
  - *Why Split to Microservices?* Do NOT split prematurely. Microservices introduce distributed transaction overhead (Saga pattern), network latency, and operational complexity. Split only when:
    1. *Independent Scaling:* The AI Matching Service requires high CPU/GPU resources and long timeouts, whereas the Auth Service requires sub-50ms lightweight responses.
    2. *Team Autonomy:* Multiple independent engineering teams need to deploy without stepping on each other's code.
  - *Target Microservices:*
    - `Auth & User Service` (Handles profiles, roles, custom claims)
    - `Job Marketplace Service` (Postings, applications, search via Elasticsearch / MeiliSearch)
    - `Maintenance Service` (Service catalogs, technician bookings)
    - `Payment & Billing Service` (Razorpay orders, webhooks, subscriptions)
    - `AI Worker Service` (GPU/LLM processing consumed via Apache Kafka)
- **Verified Evidence:** `backend/server.js`; `firestore.rules`; `firestore.indexes.json`.
- **Likely Follow-up:** *"How would you handle database contention if 10,000 candidates apply for 1 job posting simultaneously?"*
- **Follow-up Answer:** *"Updating `applicationCount` directly on a single Firestore document at 10,000 writes/sec will exceed Firestore's limit of 1 write/sec per document. We would implement **Distributed Counters** (sharding the counter across 10–20 sub-documents and summing them on read) or offload count increments to a Redis buffer that flushes to Firestore in periodic batches."*
- **Common Mistakes to Avoid:** Don't recommend Kubernetes and microservices for 5,000 users. Real architects explain why a modular monolith is preferable first and justify microservices based on measurable constraints.
