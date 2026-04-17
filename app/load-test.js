// ============================================================
// k6 Load Test — 2048 App
// Tests both EKS (automated) and EC2 (manual) environments.
//
// Usage:
//   k6 run --env TARGET_URL=http://YOUR_URL load-test.js
//
// Install k6: https://k6.io/docs/getting-started/installation/
// ============================================================

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ── Custom metrics ──────────────────────────────────────────
const errorRate = new Rate('error_rate');
const responseTime = new Trend('response_time', true);

// ── Target URL (pass via --env or hardcode below) ───────────
const BASE_URL = __ENV.TARGET_URL || 'http://YOUR_APP_URL_HERE';

// ── Test stages ─────────────────────────────────────────────
// This ramp pattern is designed to:
//   1. Warm up gently
//   2. Spike to trigger HPA on EKS
//   3. Hold at peak to observe sustained scaling
//   4. Ramp down to observe recovery
export const options = {
  stages: [
    { duration: '1m',  target: 10  },  // Warm-up: 10 virtual users
    { duration: '2m',  target: 50  },  // Ramp up: 50 VUs
    { duration: '3m',  target: 200 },  // Spike: 200 VUs — should trigger HPA
    { duration: '3m',  target: 200 },  // Hold at peak
    { duration: '2m',  target: 50  },  // Ramp down
    { duration: '1m',  target: 0   },  // Cool down
  ],
  thresholds: {
    // Fail the test if >5% of requests error
    'error_rate': ['rate<0.05'],
    // 95% of requests should complete under 500ms
    'http_req_duration': ['p(95)<500'],
  },
};

// ── Main test function ───────────────────────────────────────
export default function () {
  // Request 1: Homepage (index.html)
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    'homepage status 200': (r) => r.status === 200,
    'homepage <500ms':     (r) => r.timings.duration < 500,
  });
  errorRate.add(homeRes.status !== 200);
  responseTime.add(homeRes.timings.duration);

  sleep(0.5);

  // Request 2: Main CSS
  const cssRes = http.get(`${BASE_URL}/style/main.css`);
  check(cssRes, {
    'CSS status 200': (r) => r.status === 200,
  });

  sleep(0.5);

  // Request 3: Core JS file
  const jsRes = http.get(`${BASE_URL}/js/game_manager.js`);
  check(jsRes, {
    'JS status 200': (r) => r.status === 200,
  });

  sleep(1);
}

// ── Summary output ───────────────────────────────────────────
export function handleSummary(data) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  return {
    // Save JSON results for later analysis
    [`results-${timestamp}.json`]: JSON.stringify(data, null, 2),
    // Also print to stdout
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const d = data.metrics;
  return `
========================================
  k6 Load Test Summary
========================================
  URL Tested:       ${BASE_URL}
  Total Requests:   ${d.http_reqs?.values?.count ?? 'N/A'}
  Error Rate:       ${((d.error_rate?.values?.rate ?? 0) * 100).toFixed(2)}%
  
  Response Times:
    Avg:  ${(d.http_req_duration?.values?.avg ?? 0).toFixed(2)}ms
    p95:  ${(d.http_req_duration?.values?.['p(95)'] ?? 0).toFixed(2)}ms
    p99:  ${(d.http_req_duration?.values?.['p(99)'] ?? 0).toFixed(2)}ms
    Max:  ${(d.http_req_duration?.values?.max ?? 0).toFixed(2)}ms
========================================
`;
}
