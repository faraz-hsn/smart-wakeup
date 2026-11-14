# Technical decisions log

Small technical choices made inside a layer. Product decisions are in PLAN.md section 5. Overrule anything here.

| # | Step | Decision | Why |
|---|---|---|---|
| 1 | 0 | One git repo at `Garmin/` (code, docs, reports, scripts, tools); SDK Manager and research notes excluded | Docs and reports are versioned with the code |
| 2 | 0 | Developer key stays at `%USERPROFILE%\.connectiq\developer_key.der`, never committed | Signing key must not leak |
| 3 | 0 | Unit tests in `Restwise/test/`, compiled only in the test build (`rw.ps1 test`) | Keeps tests out of the shipped app |
| 4 | 0 | `Background` permission removed until Feature 3 needs it | Avoids loading the whole app as a background process |
| 5 | 0 | Target device list: only `fenix7pro` for now | Hackathon device; others added later if wanted |
