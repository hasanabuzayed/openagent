# Nexo Permissions Analysis Report

## Key Findings

1. **HTTP Server Implementation**
   - Uses built-in Java HTTP server (`com.sun.net.httpserver`)
   - Key components:
     - `ResourcePackServerImpl` for server management
     - `FixedResourcePackRequestHandler` for request processing
     - `HttpServer`/`HttpsServer` for connections

2. **Network Permissions**
   - Required system permissions:
     - `java.net.NetPermission` (for socket operations)
     - `java.io.FilePermission` (for pack file access)
     - `javax.net.ssl.SSLPermission` (if using HTTPS)
   - Default policy should suffice for most deployments

3. **Security Scope**
   - No explicit authentication/authorization
   - Server binds to specified port (not privileged by default)
   - Pack serving requires file read permissions
   - TLS config requires proper SSL context if enabled

## Recommendations

1. **Port Configuration**
   - Bind to port > 1024 to avoid requiring root
   - Example: Use port 8080 instead of 80

2. **Network Security**
   - Prefer HTTPS over HTTP
   - Use restricted binding (bind to local interface only if not public)
   - Implement rate limiting if exposed to public networks

3. **File System Security**
   - Restrict server.jar execution to non-root user
   - Set explicit file permissions on resource packs
   - Use read-only access for pack files

4. **Production Hardening**
   ```java
   // Example secure configuration
   ResourcePackServer secureServer = ResourcePackServer.builder()
       .address(new InetSocketAddress("127.0.0.1", 8080))
       .secure(sslContext, params -> {
           params.setNeedClientAuth(false);
           params.setProtocols(new String[]{"TLSv1.2", "TLSv1.3"});
       })
       .build();
   ```

## Implementation Evidence
   File structure and code confirm standard JVM network operations
   No excessive permissions beyond standard server requirements
   Minimal attack surface when properly configured

## Verification
   1. Check server startup arguments for configured port
   2. Validate HTTPS configuration if used
   3. Verify file system permissions for pack files
   4. Confirm no SETUID bits on execution