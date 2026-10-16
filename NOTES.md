## 1. Starting Repository & How to Run

- **Repository Branch:** The fixed code is located in the `main` branch.
- **How to Run (via Docker):**
  1. Clone the repository and navigate to the project directory.
  2. Set up Docker.
  3. Start the service and database:
     ```bash
     docker compose up --build
     ```
  4. The service will be available at `http://localhost:8080` (refer to `README.md` for API `curl` examples).
- **Running Tests:**
  Execute the verification scripts against the running service:
  ```bash
  ./scripts/burst_test.sh
  ./scripts/leak_test.sh
  ./scripts/consistency_check.sh
  
## 2. Problems Found, Priorities, and Root Causes

After getting acquainted with the code, the feedback from the team, and the test results, two major issues were identified:

1. **Race Condition / Data Loss (High Priority):**
   The most critical problem was related to data loss. Due to a race condition between concurrent requests, information was lost or updated incorrectly in the database because two requests were working on the same piece of data at the same time. 

   *Fix:* This problem was resolved by adding `FOR UPDATE`. This locks the specific piece of data, preventing multiple requests from working on it simultaneously and introducing errors while another request is already processing it.

2. **Unclosed Database Connections on Errors - High Priority:**
   The second identified problem was the incorrect handling of POST request errors. If an error occurred during a request—such as when a request was invalid—our system returned an error, but the database connection slot was not closed and remained active. 

   Before the fix, all available database slots would get clogged, and subsequent requests waiting in queue would eventually time out and throw errors.

   *Fix:* This problem was resolved by wrapping the request logic in a `try` block and adding a `finally` block at the end that guarantees the connection is returned or closed. This ensures that no matter what the outcome is, whether success or error, the connection slot is always released properly.

## 3. Reproduction Steps and Tests

To reproduce the issues and verify the fixes, I executed the provided verification scripts against the running service:

1. **Burst Test (`./scripts/burst_test.sh`):**
   - *Purpose:* Checks for race conditions and concurrent transfer handling by sending 100 requests (20 at a time).
   - *Result:* All 100 requests completed with HTTP `200` status codes. 

2. **Leak Test (`./scripts/leak_test.sh`):**
   - *Purpose:* Verifies connection pool stability under invalid requests.
   - *Result:* All 10 failing requests returned proper `400` and `404` errors. The connection pool status before, during, and after remained clean (`active: 0, idle: 5`), confirming that connections are properly returned to the pool without leaks.

3. **Consistency Check (`./scripts/consistency_check.sh`):**
   - *Purpose:* Verifies that inventory counts across warehouses remain consistent after heavy load.
   - *Result:* All inventory balances matched perfectly without any data loss or discrepancies.

## 4. Assumptions & Rejected Alternatives

- **Debugging & Troubleshooting:** When I encountered the issue, it was clear that the error handling of the request was at fault, but at first glance, everything looked fine. However, after noticing that database requests remained active even after completing, I identified that connection slots were not closing properly.
- **Alternatives Considered & Decision:** I had the idea to completely rewrite the code for this request. However, I decided to keep the original code as intact as possible while fixing the issue. Since the problem was that connection closure wasn't being invoked, I simply added a `try...finally` block, which fixed the connection leak without making unnecessary code changes.
- **Next Steps (with extra time):
  - **Pipeline Automation:** Set up CI/CD pipelines to run tests automatically on every commit/push so that issues or failures are immediately visible.
  - **Expanded Test Coverage:** Add more tests covering additional edge cases and potential error scenarios.

## 5. Time Spent & Thinking Log

**Time spent:** 2 hours in total.
  - *Preparation (1 hour):* Setting up the environment, installing Docker and tools, and thoroughly exploring the project structure, codebase, and rules.
  - *Refactoring & Testing (1 hour):* Identifying root causes, implementing fixes, and running verification scripts.
**AI Usage:** I used AI while getting acquainted with the project's code, specifically for the parts that were not entirely clear to me.