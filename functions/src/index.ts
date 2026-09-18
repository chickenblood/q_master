/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { setGlobalOptions } from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
// import {onRequest} from "firebase-functions/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

const f3ApiKey = defineSecret("F3_NATION_API_KEY");

// Call any of the F3 Nation API GET endpoints by providing the correct URL.
// https://api.f3nation.com/docs
export const getEventData = onCall(
  { secrets: [f3ApiKey] },
  async (request) => {
    let url = request.data?.url;
    if (!url) {
      throw new HttpsError("invalid-argument", "URL must be provided.");
    }

    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Client": "q_master",
        "Authorization": `Bearer ${f3ApiKey.value()}`,
      },
    });

    if (!response.ok) {
      throw new HttpsError("unavailable", `API returned ${response.status}`);
    }

    return await response.json();
  }
);

// Call the F3 Nation API POST endpoint by providing the correct URL.
// https://api.f3nation.com/docs
export const postEventData = onCall(
  { secrets: [f3ApiKey] },
  async (request) => {
    let url = request.data?.url;
    if (!url) {
      throw new HttpsError("invalid-argument", "URL must be provided.");
    }

    let payload = request.data?.payload;
    if (!payload) {
      throw new HttpsError("invalid-argument", "Payload must be provided.");
    }

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Client": "q_master",
        "Authorization": `Bearer ${f3ApiKey.value()}`,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new HttpsError("unavailable", `API returned ${response.status}`);
    }

    return await response.json();
  }
);

