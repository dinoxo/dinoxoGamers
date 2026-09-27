// Public trust anchors for the Linux verification container only.
// No private keys, disabled TLS validation, or app trust overrides.
import { getCACertificates } from 'node:tls';
import { mkdir, writeFile } from 'node:fs/promises';
await mkdir('build/live-probe', { recursive: true });
await writeFile('build/live-probe/host-ca.pem', getCACertificates('system').join('\n'));
