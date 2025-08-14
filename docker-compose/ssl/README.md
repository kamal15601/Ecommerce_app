# SSL Certificates for Production

This directory should contain your SSL certificates for production deployment.

## Required Files

1. `server.crt` - Your server's SSL certificate
2. `server.key` - Your server's private key
3. `ca.crt` - Certificate Authority bundle (if applicable)

## Instructions

1. Obtain SSL certificates from a trusted Certificate Authority (or use Let's Encrypt)
2. Place the certificates in this directory
3. Ensure the files have the correct permissions (readable by nginx)
4. Update the nginx.conf file to reference these certificates correctly

For development or testing purposes, you can generate self-signed certificates:

```bash
# Generate a self-signed certificate (for testing only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.crt
```

**IMPORTANT**: Never commit actual SSL certificate files to version control. Add them to .gitignore.
