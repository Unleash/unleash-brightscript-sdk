#!/usr/bin/env node
"use strict";

/**
 * Seed a local Unleash instance so its Frontend API returns exactly the toggles
 * used by the parity fixture (test/fixtures/frontend-response.json). Running the
 * Roku demo against this instance therefore exercises the *same* scenarios the
 * off-device parity suite checks — closing the loop between Layer 2 (parity) and
 * Layer 3 (live integration) of the alpha validation plan.
 *
 * Prereq: `docker compose -f test/integration/docker-compose.yml up -d`
 * Usage:  node scripts/seed-unleash.js
 * Env:    UNLEASH_URL   (default http://localhost:4242)
 *         ADMIN_TOKEN   (default *:*.unleash-insecure-admin-api-token)
 */

const fs = require("fs");
const path = require("path");

const base = (process.env.UNLEASH_URL || "http://localhost:4242").replace(/\/+$/, "");
const adminToken = process.env.ADMIN_TOKEN || "*:*.unleash-insecure-admin-api-token";
const project = "default";
const environment = "development";

const fixture = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, "..", "test", "fixtures", "frontend-response.json"), "utf8")
);

async function api(method, pathname, body) {
    const res = await fetch(`${base}${pathname}`, {
        method,
        headers: { Authorization: adminToken, "Content-Type": "application/json" },
        body: body === undefined ? undefined : JSON.stringify(body),
    });
    // 409 = already exists; treat as idempotent success.
    if (!res.ok && res.status !== 409) {
        const text = await res.text();
        throw new Error(`${method} ${pathname} -> ${res.status} ${text}`);
    }
    return res;
}

async function seedToggle(toggle) {
    const name = toggle.name;
    const hasRealVariant = toggle.variant && toggle.variant.name !== "disabled";

    await api("POST", `/api/admin/projects/${project}/features`, {
        name,
        type: "release",
        description: "BrightScript SDK integration fixture",
    });

    if (toggle.enabled) {
        // Variants live on the strategy (environment-level variants are
        // deprecated). Attach them to a 100%-rollout strategy.
        const strategy = {
            name: "flexibleRollout",
            parameters: { rollout: "100", stickiness: "default", groupId: name },
        };
        if (hasRealVariant) {
            const v = toggle.variant;
            strategy.variants = [
                {
                    name: v.name,
                    weight: 1000,
                    weightType: "variable",
                    stickiness: "default",
                    payload: v.payload ? { type: v.payload.type, value: v.payload.value } : undefined,
                },
            ];
        }
        await api(
            "POST",
            `/api/admin/projects/${project}/features/${name}/environments/${environment}/strategies`,
            strategy
        );
        await api(
            "POST",
            `/api/admin/projects/${project}/features/${name}/environments/${environment}/on`
        );
    }

    console.log(`seeded ${name} (enabled=${toggle.enabled}, variant=${hasRealVariant ? toggle.variant.name : "none"})`);
}

(async () => {
    for (const toggle of fixture.toggles) {
        await seedToggle(toggle);
    }
    console.log(
        `\ndone. Frontend API: ${base}/api/frontend` +
            `\nFrontend token:    default:development.unleash-insecure-frontend-api-token`
    );
})().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
});
