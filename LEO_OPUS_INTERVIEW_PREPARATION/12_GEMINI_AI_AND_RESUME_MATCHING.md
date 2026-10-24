# 12 — Google Gemini AI Integration & Resume Matching Engine

---

## 🤖 AI Workflow Architecture & Prompt Engineering

LEO OPUS integrates **Google Gemini 3.6 Flash** (with automatic fallback to **Gemini 2.0 Flash**) to provide objective, semantic candidate-job matching.

```
+-------------------------------------------------------------------------+
|                        AI RESUME MATCHING PIPELINE                      |
|                                                                         |
|  [ Candidate PDF Resume ]                                               |
|             |                                                           |
|             v                                                           |
|  [ Syncfusion Flutter PDF ] ---> Extracts clean text in-memory          |
|             |                                                           |
|             v                                                           |
|  [ Backend API Call ] ---------> POST /api/subscription/ai/match-resume |
|             |                    (Bearer Auth Token + Sanitized Text)   |
|             v                                                           |
|  [ Gemini 3.6 Flash ] ---------> Structured JSON Prompt Schema          |
|             |                    (responseMimeType: 'application/json') |
|             v                                                           |
|  [ Regex & JSON Parsing ] -----> Normalizes scores & recommendations    |
|             |                                                           |
|             v                                                           |
|  [ Graceful Fallback ] --------> If 429: Queue in Firestore             |
|                                  If Offline: Client-side GeminiService  |
+-------------------------------------------------------------------------+
```

---

## ❓ Category 12 Interview Questions: Gemini AI & Resume Matching

### Q32: Explain the exact prompt and JSON output schema used for Gemini AI in LEO OPUS. How do you prevent LLM hallucinations?
- **Interviewer Focus:** Prompt engineering, structured outputs, JSON validation, and mitigating hallucinations.
- **Answer A (Concise):**  
  We enforce structured JSON generation by passing `responseMimeType: 'application/json'` in Gemini's `generationConfig`. The prompt instructs the model to act as an objective HR Recruiter, compare the resume text against the job description, and output strict keys including `overallScore`, `skillsMatch`, `experienceMatch`, `educationMatch`, `analysis`, `strengths`, `gaps`, `recommendations`, `matchedSkills`, and `missingSkills`. To mitigate hallucinations, we instruct the model to return empty arrays if skills are not explicitly stated in the input texts.
- **Answer B (Technical Deep-Dive):**  
  In [`backend/routes/subscription.js`](file:///d:/Shinnovation/leox/backend/routes/subscription.js#L970-L991) and [`GeminiService`](file:///d:/Shinnovation/leox/lib/services/gemini_service.dart#L115-L136):
  ```
  Act as an AI Recruiter. Compare the provided resume against the job description.
  Return a detailed analysis in JSON format with the following keys:
  - overallScore: A matching percentage (0.0 to 100.0)
  - skillsMatch: Percentage for skills only (0.0 to 100.0)
  - experienceMatch: Percentage for experience only (0.0 to 100.0)
  - educationMatch: Percentage for education only (0.0 to 100.0)
  - analysis: A high-level summary of the match (2-3 sentences)
  - strengths: Array of 3-5 specific strengths the candidate has for this role
  - gaps: Array of 3-5 specific areas where the candidate is lacking or could improve
  - recommendations: Array of 3-5 actionable steps the candidate should take
  - matchedSkills: Array of skills found in both resume and job description
  - missingSkills: Array of high-priority skills in job description missing from resume

  Return pure JSON object only, no markdown formatting.
  ```
  **Mitigating Hallucinations & Output Parsing:**
  1. **Schema Constraining:** `responseMimeType: 'application/json'` activates Gemini's internal grammar-constrained decoding, preventing conversational filler (e.g., *"Sure, here is your analysis:"*).
  2. **Defensive Parsing:** In [`GeminiService._extractJson()`](file:///d:/Shinnovation/leox/lib/services/gemini_service.dart#L29-L49), if `jsonDecode()` fails due to markdown fences, a regex extractor `RegExp(r'\{[\s\S]*\}')` extracts the balanced JSON object.
  3. **Distinguishing Fact from AI Estimation:** In the UI, the score is explicitly presented as an "AI Match Indicator" with clear disclaimers that it is an automated semantic compatibility score, not an objective hiring endorsement.
- **Verified Evidence:** `backend/routes/subscription.js` lines 970–1008; `lib/services/gemini_service.dart` lines 115–146.
- **Likely Follow-up:** *"What are the bias and fairness risks of using AI in candidate screening?"*
- **Follow-up Answer:** *"LLMs can inadvertently favor specific phrasing, prestigious institutions, or gendered keywords present in their pre-training data. In LEO OPUS, we mitigate this by using AI purely as a decision-support tool: candidates are NEVER automatically rejected based on score, and human recruiters retain full authority to review applications."*
- **Common Mistakes to Avoid:** Don't say "the AI decides who gets hired." Emphasize that it is an assistive matching tool with human-in-the-loop oversight.
