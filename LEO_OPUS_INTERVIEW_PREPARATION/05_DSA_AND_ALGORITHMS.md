# 05 — Data Structures & Algorithms in LEO OPUS and Core DSA Revision

---

## 🔍 Verified Algorithmic Logic in the Repository

While LEO OPUS is a product-grade mobile application rather than a competitive programming library, several concrete algorithms, data structures, and optimization routines are genuinely implemented in the source code.

### 1. In-Memory Chronological Sorting Algorithm
- **Use Case:** Ordering job listings and application histories chronologically when query parameters or local cache results require date ordering.
- **File & Function:** [`FirebaseService.getEmployerJobs()`](file:///d:/Shinnovation/leox/lib/services/firebase_service.dart#L93), [`EmployerJobsProvider.loadJobs()`](file:///d:/Shinnovation/leox/lib/providers/employer_jobs_provider.dart#L77)
- **Algorithm:** Dual-Pivot Quicksort / TimSort (Dart's native `List.sort`).
  ```dart
  list.sort((a, b) => b.postedOn.compareTo(a.postedOn));
  ```
- **Time Complexity:** $O(N \log N)$ average and worst case.
- **Space Complexity:** $O(\log N)$ auxiliary recursion stack space.
- **Intuition:** Compares timestamp integers (`DateTime.compareTo`) in descending order ($b$ compared to $a$) to present newest opportunities first.
- **Edge Cases:** Identical timestamps (stable order maintained); empty lists (bypassed immediately in $O(1)$); null timestamps defaulted to `DateTime.now()`.

### 2. PDF Binary Stream Text Extraction & String Sanitization
- **Use Case:** Extracting raw textual content from uploaded PDF resumes on the mobile device before sending to the Gemini AI API.
- **File & Function:** [`AIResumeMatcherProvider.pickResumeFile()`](file:///d:/Shinnovation/leox/lib/providers/ai_resume_matcher_provider.dart#L69-L82), [`JobApplicationService.submitApplication()`](file:///d:/Shinnovation/leox/lib/services/job_application_service.dart#L159-L185)
- **Algorithm:** Linear token parsing and byte stream traversal via `PdfDocument` and `PdfTextExtractor`.
- **Time Complexity:** $O(P \cdot L)$ where $P$ is page count and $L$ is average character length per page (linear in file size).
- **Space Complexity:** $O(M)$ where $M$ is total extracted character buffer length.
- **Edge Cases:** Password-protected PDFs (handled via catch block); image-only/scanned PDFs with zero text (detected via `text.isEmpty`, prompting user to paste text); corrupt PDF magic headers (`%PDF-`).

### 3. Regex JSON Token Recovery & Fallback Parsing
- **Use Case:** LLMs often wrap JSON output in markdown code fences (` ```json `) or conversational prefixes. This algorithm cleans and isolates the JSON payload.
- **File & Function:** [`GeminiService._extractJson()`](file:///d:/Shinnovation/leox/lib/services/gemini_service.dart#L29-L49), [`backend/routes/subscription.js`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L995-L1008)
- **Algorithm:** Regular expression pattern matching with greedy brace boundary isolation:
  ```dart
  final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
  ```
- **Time Complexity:** $O(K)$ where $K$ is response string length.
- **Space Complexity:** $O(K)$ for string slicing.
- **Intuition:** Finds the first `{` and the last `}` in the string, stripping markdown fences, leading/trailing whitespace, and conversational preambles.

### 4. Exponential Backoff & Retry with Collection Fallbacks
- **Use Case:** Resolving user roles during registration across multiple distributed Firestore collections.
- **File & Function:** [`_getUserRole()`](file:///d:/Shinnovation/leox/lib/main.dart#L319-L407)
- **Algorithm:** Bounded iterative retry loop with constant sleep intervals ($N=10$ attempts, $\Delta t = 2000\text{ms}$) across 5 candidate collections.
- **Time Complexity:** $O(A \cdot C)$ where $A$ is maximum attempts (10) and $C$ is number of candidate collections (5).
- **Space Complexity:** $O(1)$ constant auxiliary memory.

---

## 📚 Core DSA Technical Interview Revision

### Arrays & Strings
- **Key Concepts:** Contiguous memory allocation, cache locality, amortized $O(1)$ dynamic array resizing, two-pointer techniques, sliding window.
- **Project Application:** Resume skill array deduplication: converting `List<String>` to `Set<String>` in $O(N)$ time.
- **Typical Interview Question:** *"How does a dynamic array double its capacity, and why is insertion amortized $O(1)$?"*
  - **Answer:** When the underlying array fills up, a new array of size $2N$ is allocated in memory and all $N$ elements are copied over ($O(N)$ cost). However, since this doubling only occurs after $N$ insertions, the total cost for $N$ insertions is $N + N/2 + N/4 + \dots = 2N$. Spreading $2N$ across $N$ insertions yields an amortized time of $O(1)$ per insertion.

### Hash Tables & Hash Maps
- **Key Concepts:** Hash functions, collision resolution (separate chaining vs open addressing with linear/quadratic probing), load factor (typically 0.75), rehashing.
- **Project Application:** `SessionService` in-memory key-value lookups; Firestore document field mapping via Dart `Map<String, dynamic>` ($O(1)$ average lookup and insertion).
- **Typical Interview Question:** *"What happens when two keys hash to the same index in a hash map?"*
  - **Answer:** A hash collision occurs. In separate chaining, entries at that bucket index are stored in a linked list or self-balancing Red-Black tree (as in Java 8+ when bucket length exceeds 8). In open addressing, the algorithm probes adjacent slots until an empty slot is found.

### Stacks & Queues
- **Key Concepts:** LIFO (Last In First Out) vs FIFO (First In First Out), monotonic stacks, circular queues, deque.
- **Project Application:** Flutter's `Navigator` operates as a route stack (`push` adds a route to the top; `pop` removes the top route; `popUntil` unwinds the stack to the root route). Express background rate-limit queueing (`pending_matches`).
- **Typical Interview Question:** *"How would you implement a Queue using two Stacks?"*
  - **Answer:** Use `stackIn` and `stackOut`. Enqueue pushes onto `stackIn` in $O(1)$. Dequeue checks `stackOut`; if empty, it pops all elements from `stackIn` and pushes them onto `stackOut`, reversing their order. Popping from `stackOut` yields FIFO order in amortized $O(1)$ time.

### Linked Lists
- **Key Concepts:** Singly vs doubly linked lists, pointer manipulation, detecting cycles (Floyd's Tortoise and Hare algorithm), reversing in-place.
- **Project Application:** In Dart's event loop, microtask and event queues are internally implemented as linked node queues.
- **Typical Interview Question:** *"How do you detect a cycle in a linked list in $O(N)$ time and $O(1)$ memory?"*
  - **Answer:** Use Floyd's Cycle Detection algorithm with two pointers: a `slow` pointer moving 1 step at a time and a `fast` pointer moving 2 steps. If a cycle exists, the fast pointer will eventually lap and meet the slow pointer. If `fast` or `fast.next` reaches `null`, the list has no cycle.

### Trees & Binary Search Trees (BST)
- **Key Concepts:** Tree traversals (Inorder, Preorder, Postorder, Level-order/BFS), BST invariants (Left < Root < Right), AVL Trees & Red-Black Trees (self-balancing with height $O(\log N)$), B-Trees.
- **Project Application:** Cloud Firestore uses distributed B-Trees to index fields, enabling compound range and equality queries in $O(\log N)$ disk seek time. Flutter's Widget Tree and RenderObject Tree.
- **Typical Interview Question:** *"Why do databases like MySQL and Firestore use B-Trees instead of Binary Search Trees for indexes?"*
  - **Answer:** Binary Search Trees have at most 2 children per node, resulting in deep trees that require many disk I/O operations. B-Trees have a high branching factor ($M$ children per node), meaning tree height is shallow (typically 3–4 levels for millions of rows), minimizing disk head seeks.

### Graphs & Traversal Algorithms
- **Key Concepts:** Graph representations (Adjacency Matrix $O(V^2)$ vs Adjacency List $O(V+E)$), Breadth-First Search (BFS via Queue), Depth-First Search (DFS via Stack/Recursion), Dijkstra's Shortest Path, Topological Sort.
- **Project Application:** Flutter's Element Tree layout and render pipeline performs Depth-First traversal during the layout pass to measure constraints from parent to child, and synthesizes sizes from child to parent.
- **Typical Interview Question:** *"What is the time complexity of BFS and DFS on an adjacency list?"*
  - **Answer:** Both BFS and DFS run in $O(V + E)$ time, where $V$ is the number of vertices and $E$ is the number of edges, because each vertex is visited once and each edge is examined once.

### Searching & Sorting Complexity Summary
| Algorithm | Best Time | Average Time | Worst Time | Space Complexity | Stable? |
|---|---|---|---|---|---|
| **Binary Search** | $O(1)$ | $O(\log N)$ | $O(\log N)$ | $O(1)$ | N/A |
| **Quicksort** | $O(N \log N)$ | $O(N \log N)$ | $O(N^2)$ | $O(\log N)$ | No |
| **Mergesort** | $O(N \log N)$ | $O(N \log N)$ | $O(N \log N)$ | $O(N)$ | Yes |
| **TimSort (Dart native)** | $O(N)$ | $O(N \log N)$ | $O(N \log N)$ | $O(N)$ | Yes |
| **HeapSort** | $O(N \log N)$ | $O(N \log N)$ | $O(N \log N)$ | $O(1)$ | No |
