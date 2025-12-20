# Hardcoded Secrets Report for nexo-1.16.1.jar

## Summary
Extracted and scanned nexo-1.16.1.jar (Minecraft plugin) for hardcoded secrets using `grep_search` (system-wide regex grep), `read_file`, and manual inspection.

**Critical Findings:**
- Cloud object storage access/secret keys
- GitHub Personal Access Tokens (PATs, base64-encoded)
- Polymart marketplace license token

No passwords, AWS/Stripe keys, or other API keys found.

## Extraction & Analysis
- Copied `/root/context/nexo-1.16.1.jar` to `temp/nexo-1.16.1.jar`
- Unzipped to `temp/extracted/`
- Scanned all files with regex patterns for keywords (api_key, secret, token, password, private_key, auth, bearer) and formats (long base64, AWS prefixes)
- Read suspicious files directly

**Directories scanned:** `temp/extracted/` (JAR contents: classes, YAML configs, resources)

## Discovered Secrets

### 1. Cloud Object Storage Credentials
**File:** `temp/extracted/cred.secret`
```json
{
  \"url\": \"https://fsn1.your-objectstorage.com\",
  \"bucket\": \"nexo-storage\",
  \"access\": \"OGW86KJE9YMELF54B6DB\",
  \"secret\": \"GC3ZjskMihXoDbNDVQ3PdITts7QbVAMuW9Lgzph6\"
}
```
**Type:** Likely Oracle Cloud Infrastructure (OCI) Object Storage (Frankfurt region `fsn1`).
**Risk:** **HIGH** - Direct access to storage bucket possible.

### 2. GitHub Personal Access Tokens
**File:** `temp/extracted/token.secret`
```
# This is for accessing and downloading the default-pack
# Do not alter or share this file
token1: Z2l0aHViX3BhdF8xMUFPNUFBR1kwUlh0VW16OExJdHBPX1hBQWZXZTFQY
token2: m43YzI3amlTc0Y4dnNtSzNRaWZqZFNaa2ltOXA4eVVEd1lKMkxaNE9SSWtDeG16d0Qw
```
**Decoded token1:** `github_pat_11AO5AAGY0RXtUmz8LItpO_XAAfWe1P...` (GitHub PAT prefix `ghpat_` confirms)
**token2:** Appears base64 (possibly another PAT or asset token).
**Purpose:** Downloading default resource pack from private GitHub repo.
**Risk:** **MEDIUM** - Repo access; rotate if compromised.

### 3. Polymart Auto-Updater Token
**File:** `temp/extracted/polymart.yml`
```yaml
info:
  token: Xbmewm3HPuT_1vioTHUeVYwBJ_EfE54XlA5q65qpmMo
```
**Purpose:** License validation/auto-updates for Nexo plugin on Polymart.org.
**Risk:** **MEDIUM** - Product-specific; could allow unauthorized updates.

## False Positives / Non-Secrets
- `mp.secret`: Placeholder message templates (e.g., `{{USER_NAME}}`).
- ProGuard configs, pom.xml authors, decompiler comments.

## Additional Scans
| Pattern | Matches |
|---------|---------|
| `(?i)(api[_-]?key\\|secret\\|token\\|pass...` | Above secrets + noise (e.g., `TypeToken` in ProGuard) |
| `[A-Z0-9a-z+/]{40,}=?` (long Base64) | Confirmed secrets |
| `(?i)(sk_live_\\|ak[ia][0-9A-Z]{16}\\|Bearer...)` | None |
| `password\\|pwd\\|key=\\|:key` | None in `extracted/` |

No secrets in `.class` bytecode strings (via keyword grep).

## Verification Steps
```bash
# View secrets
cat /root/work/mission-34532a9c/temp/extracted/cred.secret
cat /root/work/mission-34532a9c/temp/extracted/token.secret
cat /root/work/mission-34532a9c/temp/extracted/polymart.yml

# Decode GitHub token1
echo 'Z2l0aHViX3BhdF8xMUFPNUFBR1kwUlh0VW16OExJdHBPX1hBQWZXZTFQY' | base64 -d
```

## Recommendations
1. **Rotate all keys/tokens immediately.**
2. **Externalize secrets:** Use environment vars, plugin config, or secure vault.
3. **Remove from repo:** Delete `.secret` files; use CI/CD secrets.
4. **Obfuscate/encrypt:** If must bundle, encrypt with runtime key derivation.
5. **Audit usage:** Check if storage keys allow public read/write.

## Files Created
- `temp/extracted/` (JAR contents)
- `output/secrets-report.md` (this report)