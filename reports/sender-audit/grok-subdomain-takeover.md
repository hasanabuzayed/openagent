# Subdomain Takeover Vulnerability Check Report

## Domains Checked
- `*.senderwallet.io`
- `*.sender.org`

## Methodology
1. **Subdomain Enumeration**: Used crt.sh API to fetch SSL certificate-based subdomains.
2. **DNS Resolution**: Queried CNAME, NS, A, AAAA, MX records for all identified subdomains using `dig`.
3. **HTTP Checks**: Performed HEAD requests on potential vulnerable subdomains (those with CNAMEs) to verify if services are active.
4. **Analysis**: Checked for dangling records pointing to common takeover-prone services (e.g., GitHub Pages, Heroku, S3, etc.).

## Identified Subdomains
### senderwallet.io (5 subdomains)
```
senderwallet.io
docs.senderwallet.io
www.senderwallet.io
api.senderwallet.io
api-testnet.senderwallet.io
```

### sender.org (7 subdomains)
```
sender.org
www.sender.org
api.sender.org
api-core.sender.org
docs.sender.org
mail.sender.org
support.sender.org
```

**Total Unique: 12**

## DNS Summary
- Most subdomains resolve via Cloudflare (NS: elma.ns.cloudflare.com, javon.ns.cloudflare.com or A to CF IPs/tunnels).
- CNAME records found:
  | Subdomain            | CNAME Target                  |
  |----------------------|-------------------------------|
  | docs.sender.org     | eefa0dfaa5-hosting.gitbook.io. |
  | support.sender.org  | senderlabs.zendesk.com.       |
- `mail.sender.org`: No DNS records (A, CNAME, NS, MX empty).

Full DNS output saved to `/root/work/mission-34532a9c/temp/check_dns.sh` output.

## Vulnerability Assessment
**No subdomain takeover vulnerabilities found.**

### Details:
1. **docs.sender.org** (gitbook.io):
   - HTTPS: 307 redirect to active GitBook site (`https://app.gitbook.com/o/8euAZkJsIk98KcgFyuvC/s/1ASPZL6kbjzGUV6sxszf/`).
   - Active service, not dangling.
   - GitBook.io subdomains are managed by GitBook; not user-claimable.

2. **support.sender.org** (zendesk.com):
   - HTTPS/HTTP: 403 Forbidden (Cloudflare protected).
   - Indicates active Zendesk instance (likely login required), not "no such subdomain".
   - Zendesk subdomains require account setup; appears configured.

3. **mail.sender.org**:
   - No DNS records; resolves to NXDOMAIN for most types.
   - Not pointing to any takeover-prone service.

4. **All others**: Direct Cloudflare resolution (A/AAAA to CF IPs), no external CNAMEs.

## Recommendations
- **Monitor new subdomains**: Use tools like Subfinder + Nuclei periodically.
- **Remove unused CNAMEs**: Ensure no forgotten cloud services.
- **DNS Security**: Enable DNSSEC if possible.
- **Full Scan**: For production, run `nuclei -l subs.txt -tags takeover`.

## Files Created
- `/root/work/mission-34532a9c/temp/all_subs.txt`: List of subdomains.
- `/root/work/mission-34532a9c/temp/check_dns.sh`: DNS check script and output.
- `/root/work/mission-34532a9c/temp/senderwallet_subs.txt`
- `/root/work/mission-34532a9c/temp/sender_org_subs.txt`

**Scan completed: Saturday December 20, 2025 08:57 UTC** (adjusted for execution time).

No critical issues detected.