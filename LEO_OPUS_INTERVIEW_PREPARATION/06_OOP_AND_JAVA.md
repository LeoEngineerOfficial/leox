# 06 — Object-Oriented Programming (OOP) & Java Knowledge Transfer

---

## 🏛️ The Four Pillars of OOP in LEO OPUS & Java

Although the mobile frontend is written in **Dart**, all core Object-Oriented principles apply directly to the design of LEO OPUS and map cleanly to **Java** software engineering standards expected by enterprise recruiters like LTIMindtree.

```
+-------------------------------------------------------------------------+
|                         FOUR PILLARS OF OOP                             |
|                                                                         |
|  +--------------------+  +--------------------+  +-------------------+  |
|  |   ENCAPSULATION    |  |    ABSTRACTION     |  |    INHERITANCE    |  |
|  | Private fields     |  | Abstract classes   |  | Extends base      |  |
|  | Getters / Setters  |  | Interfaces         |  | Code reuse        |  |
|  +--------------------+  +--------------------+  +-------------------+  |
|                                                                         |
|                         +---------------------+                         |
|                         |    POLYMORPHISM     |                         |
|                         | Overriding / Loading|                         |
|                         | Dynamic dispatch    |                         |
|                         +---------------------+                         |
+-------------------------------------------------------------------------+
```

---

## ❓ Category 6 Interview Questions: OOP & Java

### Q22: Explain Encapsulation, and identify where it is implemented in LEO OPUS. Provide a Java equivalent.
- **Interviewer Focus:** Data hiding, access specifiers, state mutation control, and class invariants.
- **Answer A (Concise):**  
  **Encapsulation** is the bundling of data (fields) and the methods that operate on that data into a single unit, while restricting direct external access to mutable state through access specifiers (private fields and public getters/setters). In LEO OPUS, all providers (such as [`EmployerJobsProvider`](file:///d:/Shinnovation/leox/lib/providers/employer_jobs_provider.dart#L9-L20)) maintain private state variables (e.g., `List<JobModel> _jobs = []; bool _isLoading = false;`), exposing only read-only getters (`List<JobModel> get jobs => _jobs;`). External widgets cannot mutate `_jobs` directly; they must call controlled methods like `addJob()`.
- **Answer B (Technical Deep-Dive):**  
  **Dart Implementation in LEO OPUS:**
  ```dart
  class EmployerJobsProvider extends ChangeNotifier {
    // Private state hidden behind underscore prefix
    List<JobModel> _jobs = [];
    bool _isLoading = false;
    String? _errorMessage;

    // Public read-only unmodifiable getters
    List<JobModel> get jobs => _jobs;
    bool get isLoading => _isLoading;

    // Controlled mutation method enforcing business invariants
    void _setLoading(bool value) {
      _isLoading = value;
      notifyListeners();
    }
  }
  ```
  **Java Production Equivalent:**
  ```java
  public class JobService {
      // Encapsulated private field
      private final List<Job> jobs = new ArrayList<>();
      private boolean loading;

      // Defensive copy / unmodifiable view prevents external tampering
      public List<Job> getJobs() {
          return Collections.unmodifiableList(this.jobs);
      }

      public boolean isLoading() {
          return this.loading;
      }

      public synchronized void addJob(Job job) {
          Objects.requireNonNull(job, "Job cannot be null");
          this.jobs.add(job);
      }
  }
  ```
- **Verified Evidence:** `lib/providers/employer_jobs_provider.dart` lines 9–20; `lib/providers/subscription_provider.dart` lines 14–26.
- **Likely Follow-up:** *"Why should a getter return an unmodifiable list in Java rather than the direct list reference?"*
- **Follow-up Answer:** *"If a getter returns a direct reference to an internal mutable collection (`return this.jobs;`), external code can execute `getJobs().clear()`, corrupting internal state and bypassing all class validation logic. Returning `Collections.unmodifiableList()` enforces true encapsulation."*
- **Common Mistakes to Avoid:** Don't just say "encapsulation is getters and setters." Explain that it protects data integrity and business invariants.

---

### Q23: How are the SOLID principles demonstrated in LEO OPUS and enterprise Java?
- **Interviewer Focus:** Software architecture quality, maintainability, design patterns, and clean code.
- **Answer A (Concise):**  
  SOLID is a mnemonic for five clean object-oriented design principles: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion. In LEO OPUS, we follow Single Responsibility by separating UI views from business logic providers and low-level API services. We follow Dependency Inversion by using constructor injection in providers so services can be substituted with mocks during unit testing.
- **Answer B (Technical Deep-Dive):**  
  1. **S — Single Responsibility Principle (SRP):**  
     A class should have one, and only one, reason to change.
     - *LEO OPUS:* [`EmployeeProfileModel`](file:///d:/Shinnovation/leox/lib/models/employee_profile_model.dart) is purely responsible for data representation and JSON serialization. [`ProfileService`](file:///d:/Shinnovation/leox/lib/services/profile_service.dart) is responsible for network persistence. [`EmployeeProfileProvider`](file:///d:/Shinnovation/leox/lib/providers/employee_providers/employee_profile_provider.dart) is responsible for UI presentation state.
  2. **O — Open/Closed Principle (OCP):**  
     Software entities should be open for extension, but closed for modification.
     - *LEO OPUS / Java:* In [`SubscriptionProvider.hasFeature(featureKey)`](file:///d:/Shinnovation/leox/lib/providers/subscription_provider.dart#L132), features are evaluated against dynamic plan feature maps (`features: Map<String, dynamic>`). Adding a new premium feature (e.g., `'bulk_export'`) requires zero code changes to the provider logic; we simply add the key to the Firestore plan document.
  3. **L — Liskov Substitution Principle (LSP):**  
     Subtypes must be substitutable for their base types without altering program correctness.
     - *LEO OPUS:* Every provider extends `ChangeNotifier`. Any widget expecting `ChangeNotifier` or using `ChangeNotifierProvider` can treat `EmployerJobsProvider` or `SubscriptionProvider` polymorphically.
  4. **I — Interface Segregation Principle (ISP):**  
     Clients should not be forced to depend on methods they do not use.
     - *LEO OPUS:* In Maintenance Contracts, we segregated Provider functionality (`mc_provider_auth_controller.dart`) from Seeker functionality (`mc_seeker_auth_controller.dart`) instead of creating a bloated `MaintenanceUserController`.
  5. **D — Dependency Inversion Principle (DIP):**  
     High-level modules should not depend on low-level modules; both should depend on abstractions.
     - *LEO OPUS:* [`EmployerJobsProvider({FirebaseService? firebaseService})`](file:///d:/Shinnovation/leox/lib/providers/employer_jobs_provider.dart#L21) accepts `FirebaseService` via constructor injection. In unit tests, we inject a `MockFirebaseService`, decoupling the provider from concrete cloud infrastructure.
- **Verified Evidence:** `lib/providers/employer_jobs_provider.dart` lines 21–23; `lib/models/employee_profile_model.dart`.
- **Likely Follow-up:** *"What is the difference between an Abstract Class and an Interface in Java?"*
- **Follow-up Answer:** *"An abstract class can contain instance variables, constructors, and implemented methods, used when classes share common code and identity (`is-a` relationship). An interface specifies a contract of capabilities (`can-do` relationship) without state. A Java class can implement multiple interfaces, but extend only one class."*
- **Common Mistakes to Avoid:** Don't just list the acronym letters. Provide concrete examples from the project or Java.
