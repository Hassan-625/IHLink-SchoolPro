# Application call-site manifest index — 2026-10-17

Repository: Hassan-625/IHLink-SchoolPro
Branch: migration/mysql-schoolpro-foundation
Source scope: 190 src/**/*.{ts,tsx,js,jsx} files in the branch tree at scan time.
Method: static line scan for Supabase client references, table/RPC calls, Auth, Storage and Edge Function invocation patterns. JSONL rows include source path, line, operation category, first recognized object name or dynamic, and a source-line snippet.

## Machine-readable shards

- [Part 01](application-callsite-manifest-part-01.jsonl)
- [Part 02](application-callsite-manifest-part-02.jsonl)
- [Part 03](application-callsite-manifest-part-03.jsonl)
- [Part 04](application-callsite-manifest-part-04.jsonl)
- [Part 05](application-callsite-manifest-part-05.jsonl)
- [Part 06](application-callsite-manifest-part-06.jsonl)
- [Part 07](application-callsite-manifest-part-07.jsonl)
- [Part 08](application-callsite-manifest-part-08.jsonl)
- [Part 09](application-callsite-manifest-part-09.jsonl)
- [Part 10](application-callsite-manifest-part-10.jsonl)
- [Part 11](application-callsite-manifest-part-11.jsonl)
- [Part 12](application-callsite-manifest-part-12.jsonl)
- [Part 13](application-callsite-manifest-part-13.jsonl)

## Limitations and required review

This is a static candidate manifest, not a validated AST or runtime call graph. It may include client references that are not calls, miss indirect wrappers/aliased clients/computed names, and miss multiline arguments whose literal name is not on the same line. When a line contains multiple calls, the record stores the first recognized literal name. Do not treat the row count as unique calls or assume the scan is exhaustive.

Next review: resolve dynamic and aliased calls, shared wrappers, Auth context, storage helpers, Edge Function callers, and reconcile each object with the live catalog/deployed function inventory. Supplement the static scan with AST-aware or manual review before redirecting/removing any production calls.

No source code, production configuration, database records or deployments were changed by generating the manifest.
