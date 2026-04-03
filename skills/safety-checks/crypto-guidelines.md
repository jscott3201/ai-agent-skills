# Cryptographic Algorithm Guidelines

## Deprecated - flag immediately

| Algorithm/Mode | Issue |
|---------------|-------|
| MD5 | Practical collision attacks. Never use for integrity or signatures. |
| SHA-1 | Collision attacks demonstrated. Retired by NIST 2022. |
| DES | 56-bit key, brute-forceable in hours. |
| 3DES (Triple DES) | Deprecated by NIST. Sweet32 attack on 64-bit block. |
| RC4 / ARC4 | Keystream biases. Prohibited for TLS. |
| ECB mode | Identical plaintext blocks produce identical ciphertext. Leaks patterns. |
| Blowfish cipher | 64-bit block size vulnerability. (Note: bcrypt for password hashing is still fine.) |
| RSA < 2048 bits | Factorable with current hardware. |
| DSA | Nonce reuse is catastrophic and common in implementations. Use Ed25519. |

## Approved algorithms

### Symmetric encryption

| Algorithm | Key Size | Notes |
|-----------|----------|-------|
| AES-256-GCM | 256-bit | Preferred. AEAD (authenticated encryption). |
| ChaCha20-Poly1305 | 256-bit | Preferred where AES-NI hardware is unavailable. AEAD. |
| AES-128-GCM | 128-bit | Acceptable. AEAD. |
| XChaCha20-Poly1305 | 256-bit | Extended nonce (192-bit) reduces nonce collision risk. |

Always use AEAD modes (GCM, Poly1305). Never use CBC without a separate HMAC
(Encrypt-then-MAC). Never use ECB for any purpose.

### Password hashing

| Algorithm | Notes |
|-----------|-------|
| Argon2id | Preferred. Memory-hard, resists GPU/ASIC attacks. |
| bcrypt | Widely supported. Work factor 12+ for new deployments. |
| scrypt | Memory-hard alternative. Less common than Argon2id. |
| PBKDF2-SHA256 | Acceptable with 600,000+ iterations (NIST 2023 guidance). |

Never use raw SHA-256/SHA-512/BLAKE for password hashing. These are fast
hashes, not password KDFs.

### General hashing (integrity, checksums)

| Algorithm | Output Size | Notes |
|-----------|-------------|-------|
| SHA-256 | 256-bit | Standard choice. |
| SHA-384 | 384-bit | When 256-bit is insufficient. |
| SHA-512 | 512-bit | Faster than SHA-256 on 64-bit platforms. |
| BLAKE3 | 256-bit | Fastest, tree-hashable. Good for checksums. |

### Asymmetric encryption and signatures

| Algorithm | Key Size | Notes |
|-----------|----------|-------|
| RSA-4096 | 4096-bit | Prefer for new deployments. 2048-bit minimum. |
| Ed25519 | 256-bit | Preferred for signatures. Fast, small keys. |
| ECDSA P-256 | 256-bit | Widely supported. Use deterministic nonces (RFC 6979). |
| ECDSA P-384 | 384-bit | Higher security margin. |
| X25519 | 256-bit | Key exchange. Preferred over ECDH P-256. |

### Post-quantum (NIST standardized 2024)

| Algorithm | Purpose | Security Level |
|-----------|---------|----------------|
| ML-KEM-768 | Key encapsulation | 192-bit |
| ML-KEM-1024 | Key encapsulation | 256-bit |
| ML-DSA-65 | Digital signatures | 192-bit |
| ML-DSA-87 | Digital signatures | 256-bit |
| SLH-DSA | Digital signatures (stateless hash-based) | 192/256-bit |

NIST timeline: algorithms with 112-bit security strength deprecated after
2030, disallowed after 2035. Plan migration for long-lived systems.

## Critical implementation rules

### Nonces and IVs

- **GCM nonces must NEVER be reused** with the same key. Reuse destroys both
  confidentiality and the authentication key. Use a counter or random 96-bit
  nonce with key rotation before 2^32 encryptions.
- **CBC IVs must be random** (not predictable, not zero, not a counter).
- **XChaCha20 uses 192-bit nonces** - random generation is safe without
  counter tracking.
- Hardcoded IV (`iv = b'\x00' * 16`) is always wrong.

### Timing attacks

- Use constant-time comparison for all secret data: HMAC verification,
  token comparison, password hash comparison.
- Language-specific functions:
  - Python: `hmac.compare_digest()`
  - Rust: `constant_time_eq` crate
  - JavaScript: `crypto.timingSafeEqual()`
- Flag: `==` or `===` comparison of tokens, hashes, or HMACs.
- Flag: early return on first byte mismatch in manual comparison loops.

### Key management

- Never hardcode encryption keys in source.
- Derive per-purpose keys from a master key (HKDF).
- Rotate keys on a schedule. Document the rotation procedure.
- Zeroize key material when no longer needed.
