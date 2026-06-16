#!/usr/bin/env node
"use strict";

/**
 * Behavioral-parity baseline capture.
 *
 * This is the source of truth for the parity tests: it loads the shared
 * Frontend API response fixture, feeds it (via `bootstrap`) to the *official*
 * Unleash JavaScript frontend SDK (`unleash-proxy-client`), and records what
 * that SDK returns from `isEnabled` / `getVariant` for each queried toggle.
 *
 * The BrightScript SDK is then asserted (off-device, see scripts/run-tests.js
 * + test/UnleashTests.brs) to produce the same answers for the same response.
 * Because evaluation in a frontend SDK is just interpreting the `/api/frontend`
 * JSON, identical input must yield identical output across runtimes.
 *
 * Output: test/fixtures/expected.json (committed, human-reviewable).
 * Run via `make baseline` (requires `unleash-proxy-client`, a devDependency).
 */

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const fixturesDir = path.join(root, "test", "fixtures");
const responsePath = path.join(fixturesDir, "frontend-response.json");
const queriesPath = path.join(fixturesDir, "queries.json");
const expectedPath = path.join(fixturesDir, "expected.json");

let UnleashClient, InMemoryStorageProvider;
try {
    ({ UnleashClient, InMemoryStorageProvider } = require("unleash-proxy-client"));
} catch (err) {
    console.error(
        "missing dependency `unleash-proxy-client` — run `pnpm install` first.\n" +
            "It is the official Unleash JS frontend SDK and the parity baseline source of truth."
    );
    process.exit(2);
}

const response = JSON.parse(fs.readFileSync(responsePath, "utf8"));
const queries = JSON.parse(fs.readFileSync(queriesPath, "utf8"));

// Bootstrap the JS SDK with the fixture toggles. No network, timers or metrics:
// `toggles` is populated from `bootstrap` synchronously in the constructor, so
// isEnabled/getVariant are answerable without ever calling start().
const client = new UnleashClient({
    url: "http://localhost:4242/api/frontend",
    clientKey: "baseline-not-used",
    appName: "parity-baseline",
    bootstrap: response.toggles,
    bootstrapOverride: true,
    disableRefresh: true,
    disableMetrics: true,
    storageProvider: new InMemoryStorageProvider(),
});

const expected = queries.map((name) => {
    const variant = client.getVariant(name);
    const record = {
        name,
        isEnabled: client.isEnabled(name),
        variant: {
            name: variant.name,
            enabled: variant.enabled === true,
            feature_enabled: variant.feature_enabled === true,
        },
    };
    if (variant.payload) {
        record.variant.payload = {
            type: variant.payload.type,
            value: variant.payload.value,
        };
    }
    return record;
});

fs.writeFileSync(expectedPath, JSON.stringify(expected, null, 2) + "\n", "utf8");
console.log(
    `captured ${expected.length} baseline evaluations from unleash-proxy-client -> ${path.relative(root, expectedPath)}`
);
