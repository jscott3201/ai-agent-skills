# Secret Detection Patterns

Regex patterns for detecting hardcoded secrets in source code. Use during
manual audits and when reviewing code that handles credentials.

## Cloud provider keys

| Secret Type | Pattern |
|-------------|---------|
| AWS Access Key ID | `AKIA[0-9A-Z]{16}` |
| AWS MWS Auth Token | `amzn\.mws\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` |
| Google API Key | `AIza[0-9A-Za-z\-_]{35}` |
| GCP Service Account | `"type": "service_account"` |
| Azure Storage Key | `DefaultEndpointsProtocol=https;AccountName=` |

## API and service keys

| Secret Type | Pattern |
|-------------|---------|
| GitHub Token | `(ghp\|gho\|ghu\|ghs\|ghr)_[A-Za-z0-9_]{36}` |
| Stripe Live Key | `sk_live_[0-9a-zA-Z]{24}` |
| Stripe Publishable | `pk_live_[0-9a-zA-Z]{24}` |
| Slack Token | `xox[pboa]-[0-9]{12}-[0-9]{12}-[0-9]{12}-[a-z0-9]{32}` |
| Slack Webhook | `https://hooks\.slack\.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}` |
| Twilio API Key | `SK[0-9a-fA-F]{32}` |
| Mailgun API Key | `key-[0-9a-zA-Z]{32}` |
| MailChimp API Key | `[0-9a-f]{32}-us[0-9]{1,2}` |
| SendGrid API Key | `SG\.[0-9A-Za-z\-_]{22}\.[0-9A-Za-z\-_]{43}` |
| Facebook Token | `EAACEdEose0cBA[0-9A-Za-z]+` |

## Private keys

| Secret Type | Pattern |
|-------------|---------|
| RSA Private Key | `-----BEGIN RSA PRIVATE KEY-----` |
| EC Private Key | `-----BEGIN EC PRIVATE KEY-----` |
| PGP Private Key | `-----BEGIN PGP PRIVATE KEY BLOCK-----` |
| SSH Private Key | `-----BEGIN OPENSSH PRIVATE KEY-----` |
| Generic Private Key | `-----BEGIN PRIVATE KEY-----` |

## Generic patterns

| Secret Type | Pattern |
|-------------|---------|
| Password in URL | `[a-zA-Z]{3,10}://[^/\s:@]{3,20}:[^/\s:@]{3,20}@.{1,100}` |
| API Key assignment | `[aA][pP][iI][_-]?[kK][eE][yY].*['"][0-9a-zA-Z]{32,45}['"]` |
| Secret assignment | `[sS][eE][cC][rR][eE][tT].*['"][0-9a-zA-Z]{32,45}['"]` |
| Password assignment | `[pP][aA][sS][sS][wW][oO][rR][dD].*['"][^'"]{8,}['"]` |
| Connection string | `(mongodb\|postgres\|mysql\|redis)://[^/\s]+:[^/\s]+@` |
| Bearer token | `[Bb]earer\s+[A-Za-z0-9\-._~+/]+=*` |

## Common false positives

These patterns frequently match non-secrets. Verify with surrounding context:

- Example/placeholder keys in documentation (`AKIAIOSFODNN7EXAMPLE`)
- Test fixtures with dummy values (check file path for `test`, `mock`, `fixture`)
- Base64-encoded non-secret data matching entropy thresholds
- Package version strings matching key-length patterns
- Documentation URLs with embedded example tokens
- Environment variable NAMES (without values): `API_KEY=` in `.env.example`

## Detection strategy

1. Run regex patterns against all source files (not just code - check
   configs, docs, scripts, CI files)
2. Exclude known false positive paths: `test/`, `mock/`, `fixture/`,
   `example/`, `*.md` (but still check docs for real leaked keys)
3. Check `.env` files are in `.gitignore`
4. Check git history for previously committed secrets (they remain in history
   even after removal): `git log -p --all -S 'AKIA'`
5. Flag any match that appears in a non-test, non-example context for human
   review
