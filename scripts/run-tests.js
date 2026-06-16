#!/usr/bin/env node
"use strict";

/**
 * Off-device test runner.
 *
 * The Roku does not need to be involved to test the SDK's pure logic. This
 * script bundles the built library (src/main/source/Unleash.brs) together with
 * the BrightScript test files and executes them with the `brs` interpreter,
 * then inspects the output to set the process exit code.
 *
 * Only the device-free code paths are exercised here (encoding, parsing,
 * evaluation, metrics bucketing, config). Networking and SceneGraph threading
 * are verified on-device / via the demo channel.
 */

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const lib = path.join(root, "src/main/source/Unleash.brs");
const testDir = path.join(root, "test");
const fixturesDir = path.join(testDir, "fixtures");
const buildDir = path.join(root, "build");
const bundle = path.join(buildDir, "test-bundle.brs");

// Embed the parity fixtures as BrightScript string constants so the parity tests
// can compare without any on-device file I/O. Three fixtures are embedded:
//   - frontend-response.json : the shared /api/frontend response (toggle data)
//   - queries.json           : the toggle names to evaluate (the test contract)
//   - expected.json          : the committed JS-SDK baseline (the known truth,
//                              produced by scripts/capture-baseline.js)
// The parity test keys the baseline by toggle name and looks each query up, so
// the order of toggles in the response or rows in the baseline is irrelevant —
// no sorting is needed and reordering can't produce a false negative. JSON is
// compacted and `"` is doubled per BrightScript string-literal escaping. Missing
// files degrade to empty values so the rest of the suite still runs (the parity
// test fails loudly on an empty baseline rather than silently skipping).
function readJsonCompact(file) {
    if (!fs.existsSync(file)) {
        return null;
    }
    return JSON.stringify(JSON.parse(fs.readFileSync(file, "utf8")));
}

function brsStringLiteral(value) {
    return '"' + String(value).replace(/"/g, '""') + '"';
}

function parityDataModule() {
    const body = readJsonCompact(path.join(fixturesDir, "frontend-response.json")) || "{}";
    const queries = readJsonCompact(path.join(fixturesDir, "queries.json")) || "[]";
    const expected = readJsonCompact(path.join(fixturesDir, "expected.json")) || "[]";
    return [
        "function ParityResponseBody() as String",
        "    return " + brsStringLiteral(body),
        "end function",
        "function ParityQueries() as String",
        "    return " + brsStringLiteral(queries),
        "end function",
        "function ParityExpected() as String",
        "    return " + brsStringLiteral(expected),
        "end function",
    ].join("\n");
}

if (!fs.existsSync(lib)) {
    console.error(`missing built library at ${lib} — run \`make build\` first`);
    process.exit(2);
}

// Order matters only so that `main` (the runner) is present; definitions are
// resolved at runtime. Assert + test files are loaded before TestMain.
const testFiles = fs
    .readdirSync(testDir)
    .filter((f) => f.endsWith(".brs") && f !== "TestMain.brs")
    .sort()
    .map((f) => path.join(testDir, f));
testFiles.push(path.join(testDir, "TestMain.brs"));

const parts = [fs.readFileSync(lib, "utf8")];
parts.push("\n' ===== parity fixtures (generated) =====\n");
parts.push(parityDataModule());
for (const f of testFiles) {
    parts.push(`\n' ===== ${path.basename(f)} =====\n`);
    parts.push(fs.readFileSync(f, "utf8"));
}

fs.mkdirSync(buildDir, { recursive: true });
fs.writeFileSync(bundle, parts.join("\n"), "utf8");

// Run brs with --root pointing at build/ (which has no `components` dir) so the
// interpreter does not try to parse the channel's SceneGraph XML.
const brsBin = path.join(root, "node_modules/.bin/brs");

let output = "";
let failed = false;
try {
    output = execFileSync(brsBin, ["--root", buildDir, bundle], {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "pipe"],
    });
} catch (err) {
    output = `${err.stdout || ""}${err.stderr || ""}`;
    failed = true;
}

process.stdout.write(output);

if (failed || /not ok/.test(output) || /TEST FAILURE/.test(output) || !/ALL TESTS PASSED/.test(output)) {
    process.exit(1);
}
process.exit(0);
