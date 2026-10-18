import test from "node:test";
import assert from "node:assert/strict";
import { readBearerToken, isPlatformAdmin } from "../auth.mjs";

test("accepts a single bearer token", () => {
  assert.equal(readBearerToken("Bearer abc.def"), "abc.def");
});

test("rejects missing, malformed, or multi-value authorization headers", () => {
  assert.equal(readBearerToken(undefined), null);
  assert.equal(readBearerToken("Basic abc"), null);
  assert.equal(readBearerToken("Bearer "), null);
  assert.equal(readBearerToken("Bearer one two"), null);
});

test("platform admin is an exact server-configured UUID allowlist match", () => {
  assert.equal(isPlatformAdmin("ABC-123", "abc-123,def-456"), true);
  assert.equal(isPlatformAdmin("abc-1234", "abc-123"), false);
  assert.equal(isPlatformAdmin("abc-123", ""), false);
  assert.equal(isPlatformAdmin("", "abc-123"), false);
});
