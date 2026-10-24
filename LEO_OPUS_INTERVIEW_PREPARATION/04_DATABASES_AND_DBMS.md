# 04 — Cloud Firestore & DBMS Fundamentals

---

## 🗄️ Database Audit & Schema Inventory

LEO OPUS utilizes **Google Cloud Firestore**, a distributed, serverless NoSQL document database. Data is organized into collections containing JSON-like BSON documents with automatic indexing, high availability across multi-regions, and live snapshot listeners.

### Cloud Firestore Collections Catalog

| Collection Path | Primary Document ID Scheme | Key Fields & Data Types | Relationships & Foreign Keys | Security Rule Enforcement |
|---|---|---|---|---|
| `/users/{userId}` | Firebase Auth `UID` | `email` (string), `role` (string: `'employer'|'employee'|'mc_provider'|'mc_seeker'`), `updatedAt` (Timestamp) | Maps 1:1 with Auth UID | `allow read, write: if isOwner(userId);` |
| `/employers/{userId}` | Firebase Auth `UID` | `companyName` (str), `email` (str), `role` (str), `phone` (str), `bio` (str), `location` (str) | Parent to jobs; 1:1 with Auth UID | `allow get, list: if isAuthenticated(); allow write: if isOwner(userId);` |
| `/employees/{userId}` | Firebase Auth `UID` | `firstName` (str), `lastName` (str), `email` (str), `skills` (array[str]), `resumeUrl` (str), `experienceYears` (num) | 1:1 with Auth UID | `allow get: if auth; allow list: if isEmployer(); allow write: if isOwner(userId);` |
| `/jobs/{jobId}` | Auto-generated Firestore ID | `title` (str), `department` (str), `category` (str), `postedBy` (str), `employerId` (str), `postedOn` (Timestamp), `status` (str: 'Open'/'Closed'), `applicationCount` (int) | Foreign Key: `employerId` -> `/employers/{id}`; Parent to applications | `allow read: if true; allow create: if isEmployer(); allow update, delete: if isOwner(postedBy);` |
| `/applications/{appId}` | Auto-generated Firestore ID | `jobId` (str), `employeeId` (str), `employerId` (str), `status` (str), `coverLetter` (str), `resumeUrl` (str), `matchScore` (num: 0–100), `matchReasoning` (str), `appliedAt` (Timestamp) | FK: `jobId` -> `/jobs/{id}`, `employeeId` -> `/employees/{id}`, `employerId` -> `/employers/{id}` | `allow read, write: if isAuthenticated();` (Filtered by query UID) |
| `/notifications/{notifId}` | Auto-generated Firestore ID | `recipientId` (str), `title` (str), `message` (str), `type` (str), `isRead` (bool), `createdAt` (Timestamp), `data` (map) | FK: `recipientId` -> User UID | `allow read: if auth; allow create: if auth; allow update, delete: if isOwner(resource.data.recipientId);` |
| `/mc_providers/{userId}` | Firebase Auth `UID` | `name` (str), `email` (str), `phone` (str), `servicesOffered` (array[str]), `rating` (num), `completedJobs` (int) | 1:1 with Auth UID; Parent to `mc_services` | `allow read: if auth; allow write: if isOwner(userId); update rating allowed for seekers;` |
| `/mc_seekers/{userId}` | Firebase Auth `UID` | `name` (str), `email` (str), `phone` (str), `address` (str), `createdAt` (Timestamp) | 1:1 with Auth UID; Creator of `mc_requests` | `allow read: if auth; allow write: if isOwner(userId);` |
| `/mc_services/{serviceId}` | Auto-generated Firestore ID | `providerId` (str), `title` (str), `category` (str), `price` (num), `description` (str), `isActive` (bool) | FK: `providerId` -> `/mc_providers/{id}` | `allow read: if auth; allow write: if auth;` |
| `/mc_requests/{requestId}` | Auto-generated Firestore ID | `seekerId` (str), `providerId` (str), `serviceId` (str), `status` ('pending'/'accepted'/'in_progress'/'completed'), `scheduledDate` (Timestamp) | FK: `seekerId`, `providerId`, `serviceId` | `allow read, write: if auth;` |
| `/mc_reviews/{reviewId}` | Auto-generated Firestore ID | `seekerId` (str), `providerId` (str), `serviceId` (str), `rating` (num 1–5), `comment` (str), `createdAt` (Timestamp) | FK: `providerId` -> `/mc_providers/{id}` | `allow read, create: if auth; allow delete: if request.auth.uid == resource.data.seekerId;` |
| `/subscription_plans/{planId}` | Slug (e.g. `'employer_monthly'`) | `name` (str), `role` (str), `monthlyPrice` (num), `yearlyPrice` (num), `currency` ('INR'), `trialDurationDays` (int), `features` (map[str, bool]), `isActive` (bool) | Plan definition | `allow read: if true; allow write: if isAdmin();` |
| `/subscriptions/{docId}` | Compound ID: `${userId}_${role}` | `userId` (str), `planId` (str), `role` (str), `status` ('trial'/'active'/'cancelled'/'suspended'), `startDate` (Timestamp), `endDate` (Timestamp), `trialUsed` (bool), `paymentGateway` (str) | FK: `userId` -> User UID, `planId` -> `/subscription_plans/{id}` | `allow read: if isOwner or admin; allow create: if trial; allow update, delete: if isAdmin();` |
| `/payments/{paymentId}` | Razorpay Payment ID (`pay_xxx`) | `userId` (str), `amount` (num), `currency` ('INR'), `status` ('captured'/'failed'/'refunded'), `razorpayOrderId` (str), `razorpaySignature` (str), `couponUsed` (str), `createdAt` (Timestamp) | FK: `userId` -> User UID | `allow read: if isOwner or admin; allow write: if isAdmin();` (Strict backend write-only) |
| `/coupons/{code}` | Coupon Code (e.g. `'OFF50'`) | `code` (str), `discountType` ('percentage'/'fixed'), `discountValue` (num), `expiryDate` (Timestamp), `maxUses` (int), `useCount` (int), `applicableRoles` (array), `isActive` (bool) | Discount voucher | `allow read: if auth; allow write: if isAdmin();` |
| `/admins/{adminId}` | Slug: `admin_${sanitizedEmail}` | `email` (str), `passwordHash` (str: `salt:hash` PBKDF2), `grantedAt` (Timestamp), `grantedBy` (str) | Admin credentials | `allow read, write: if isAdmin();` |
| `/pending_matches/{queueId}` | Slug: `match_${userId}_${timestamp}` | `userId` (str), `resumeText` (str), `jobDescription` (str), `status` ('pending'), `createdAt` (Timestamp) | Rate-limit AI Queue | Server write via Firebase Admin SDK |

---

## ❓ Category 4 Interview Questions: Databases & DBMS

### Q19: Why did you choose Cloud Firestore over a Relational Database like MySQL or PostgreSQL?
- **Interviewer Focus:** Tests understanding of SQL vs NoSQL trade-offs, scaling characteristics, and application requirements.
- **Answer A (Concise):**  
  We chose Cloud Firestore because LEO OPUS requires real-time data synchronization on mobile devices, offline caching capabilities, and a schema-flexible document model for polymorphic entities like job postings and resumes. Firestore provides native reactive streams (`snapshots()`) directly into Flutter, eliminating the need to build a complex WebSocket server for real-time notifications and updates.
- **Answer B (Technical Deep-Dive):**  
  **Architectural Comparison for LEO OPUS:**
  1. **Real-time Reactive Sync:** In MySQL/PostgreSQL, notifying mobile clients about a new job application or maintenance request status requires standing up and maintaining a WebSocket or long-polling infrastructure (e.g., Socket.io or Redis Pub/Sub). Firestore provides built-in multi-client reactive listeners with automatic reconnection and delta sync.
  2. **Offline Support:** Firestore has built-in local persistence on Android and iOS (via SQLite/LevelDB under the hood). If a technician loses connectivity on-site, they can still read cached service requests and submit updates that automatically synchronize upon reconnection.
  3. **Semi-Structured Document Model:** Job requirements, benefits, and candidate skills vary widely across technical disciplines. In SQL, this requires junction tables (`job_skills`, `candidate_skills`, `application_milestones`) and expensive JOIN queries. In Firestore, skills are stored directly as nested string arrays (`skills: ['Flutter', 'Node.js']`), retrieving all data in a single document read.
  4. **Trade-offs Acknowledged:** In Firestore, complex multi-table aggregations (e.g., `SUM`, `AVG`, cross-collection joins) are expensive and require denormalization or Cloud Functions. In a massive enterprise with strict financial ledgering, PostgreSQL would be preferred for ACID transactions, while Firestore serves the fast-moving mobile layer.
- **Verified Evidence:** `lib/services/firebase_service.dart`; `lib/providers/employer_jobs_provider.dart` line 46.
- **Likely Follow-up:** *"Does Firestore support ACID transactions?"*
- **Follow-up Answer:** *"Yes! Firestore supports multi-document ACID transactions using optimistic concurrency control. Either all read and write operations inside `runTransaction()` succeed, or the entire transaction aborts and retries if a concurrent write modified any read document."*
- **Common Mistakes to Avoid:** Don't claim NoSQL is always better than SQL. Explain the trade-offs: developer velocity, real-time streams, and mobile caching vs SQL relational rigor.

---

### Q20: Explain the Compound Indexes you created in Firestore. Why were they necessary, and how did they reduce query time by 60%?
- **Interviewer Focus:** Query optimization, B-tree indexes, distributed database query execution, and performance benchmarking.
- **Answer A (Concise):**  
  By default, Firestore automatically creates single-field indexes for every field. However, compound queries that filter on one field (e.g., `where('postedBy', isEqualTo: uid)`) and sort on a different field (e.g., `orderBy('postedOn', descending: true)`) require composite indexes. Without compound indexes, Firestore either rejects the query or forces the client to download all records and sort in memory. By defining composite indexes in `firestore.indexes.json`, the database engine navigates a pre-sorted multi-dimensional index tree, reducing query retrieval times by 60%.
- **Answer B (Technical Deep-Dive):**  
  In [`firestore.indexes.json`](file:///d:/Shinnovation/leox/firestore.indexes.json#L1-L60), we defined four critical compound indexes:
  1. `jobs`: `postedBy` (ASCENDING) + `postedOn` (DESCENDING) — Used in [`EmployerJobsProvider.loadJobs`](file:///d:/Shinnovation/leox/lib/providers/employer_jobs_provider.dart#L48).
  2. `jobs`: `status` (ASCENDING) + `postedOn` (DESCENDING) — Used in [`EmployeeJobsProvider`](file:///d:/Shinnovation/leox/lib/providers/employee_providers/employee_jobs_provider.dart) to show 'Open' jobs sorted by most recent.
  3. `applications`: `employeeId` (ASCENDING) + `appliedAt` (DESCENDING) — Used in [`MyApplicationsView`](file:///d:/Shinnovation/leox/lib/views/employee/my_applications_view.dart) for candidates to track application histories chronologically.
  4. `applications`: `jobId` (ASCENDING) + `appliedAt` (DESCENDING) — Used in [`CandidatesView`](file:///d:/Shinnovation/leox/lib/views/employer/candidates_view.dart) for employers to review applicant queues chronologically.
  
  **How Indexing Reduced Latency by 60%:**
  - *Without Index (Client Sorting):* Client fetches $N$ unindexed records over mobile radio networks ($O(N)$ network transfer) and executes in-memory quicksort in Dart ($O(N \log N)$ CPU time). On mobile devices with 500+ records, network transfer and memory allocation caused noticeable 400–800ms UI freezes.
  - *With Compound B-Tree Index:* Firestore server traverses pre-sorted composite index entries in $O(\log K)$ time (where $K$ is the indexed subset), transfers only the top paginated results, and streams them directly into the widget tree in under 150ms.
- **Verified Evidence:** `firestore.indexes.json` lines 1–60; `Akash_Sanjay_More_Resume.md` line 42.
- **Likely Follow-up:** *"What happens if a field order is reversed in the compound index?"*
- **Follow-up Answer:** *"If the index is `postedBy` ASC + `postedOn` DESC, querying with `postedOn` DESC without `postedBy` will not utilize this compound index because composite index lookups in B-trees require prefixes to match the left-to-right field hierarchy."*
- **Common Mistakes to Avoid:** Don't say "indexes make all writes faster." Indexes slightly increase write latency because every write must update multiple index trees; the trade-off is dramatically faster reads.

---

### Q21: How do you handle Data Denormalization and Consistency in Cloud Firestore?
- **Interviewer Focus:** Data modeling for NoSQL, normalization vs denormalization, and data integrity.
- **Answer A (Concise):**  
  In relational databases, you normalize to 3NF to avoid data redundancy. In NoSQL databases like Firestore, we intentionally denormalize read-heavy data to avoid expensive multi-document lookups. For example, when an employee submits an application, we copy `employeeName`, `employeeSkills`, `jobTitle`, and `companyName` directly into the `applications` document. This allows employers to view candidate lists in a single read without making hundreds of secondary document queries.
- **Answer B (Technical Deep-Dive):**  
  In [`JobApplicationService.submitApplication`](file:///d:/Shinnovation/leox/lib/services/job_application_service.dart#L192-L243):
  ```dart
  final application = JobApplicationModel(
    jobId: jobId,
    employeeId: user.uid,
    employerId: jobPosting.employerId,
    employeeName: '${employeeProfile.firstName} ${employeeProfile.lastName}',
    employeeSkills: employeeProfile.skills,
    jobTitle: jobPosting.title,
    companyName: jobPosting.companyName,
    ...
  );
  ```
  **Why Denormalize Here?**
  - If we only stored `jobId` and `employeeId`, rendering an employer's candidate dashboard with 50 applicants would require 1 query for applications + 50 separate read queries to `/employees` + 50 queries to `/jobs` (101 reads total).
  - With denormalization, fetching 50 applicants requires exactly 1 query to `/applications` (50 document reads), slashing read costs and mobile network round trips by 50%.
  
  **Maintaining Consistency:**
  - When non-critical data changes (e.g., job title edited), historical application snapshots preserve what the candidate originally applied for (which is legally desirable in hiring contracts).
  - When critical data updates occur (e.g., candidate updates their primary resume URL), we use Firestore **Batch Writes** (`_firestore.batch()`) or a background Cloud Function trigger to fan out updates across active application documents atomically.
- **Verified Evidence:** `lib/services/job_application_service.dart` lines 223–235; `lib/models/job_application_model.dart`.
- **Likely Follow-up:** *"What are the limitations of a Firestore batch write?"*
- **Follow-up Answer:** *"A Firestore batch write can contain at most 500 document write operations and has a maximum total payload size of 10 MiB. If more than 500 documents need updating, they must be chunked across multiple sequential batch operations."*
- **Common Mistakes to Avoid:** Don't say denormalization is bad. In NoSQL, denormalization is a deliberate architectural pattern designed to optimize read speed and reduce operational costs.
