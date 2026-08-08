# Security Policy

## SmartQ – Hospital Queue Management System

SmartQ is a digital hospital queue management system designed to improve patient queue management, token generation, and administrative operations.

We take the security of SmartQ and its users seriously. This document explains how security vulnerabilities should be reported and how they are handled.

## Supported Versions

Currently, security updates are provided for the latest version of SmartQ available in the main branch.

| Version        | Supported |
| -------------- | --------- |
| Latest         | ✅ Yes     |
| Older versions | ❌ No      |

## Reporting a Vulnerability

If you discover a security vulnerability in SmartQ, please report it responsibly rather than publicly posting it in the GitHub Issues section.

When reporting a vulnerability, please include:

* A clear description of the vulnerability
* Steps to reproduce the issue
* The affected feature or component
* Potential security impact
* Screenshots or logs, if applicable
* Any suggested mitigation, if available

Please avoid sharing sensitive information such as passwords, authentication tokens, patient information, or private credentials in the report.

## Security Practices

SmartQ follows several security practices, including:

* **Firebase Authentication** for secure user authentication.
* **Role-based access control** for different user and administrative roles.
* **Firebase Security Rules** to control access to cloud data.
* **Secure handling of authentication credentials and tokens.**
* **Input validation** to reduce invalid or malicious data.
* **QR-based verification** for secure queue/token verification.
* **Separation of user and administrative functionality.**
* Sensitive configuration values and credentials should not be committed to the public repository.

## Sensitive Information

Do not commit the following information to the repository:

* Firebase private keys
* API keys and secrets
* Authentication credentials
* Database credentials
* Access tokens
* `.env` files containing secrets
* Patient or other personally identifiable information

Developers should use environment variables or appropriate secret-management mechanisms for sensitive configuration.

## Dependency Security

Project dependencies should be kept up to date to reduce exposure to known vulnerabilities.

Before deploying a new version, dependencies should be reviewed and updated where appropriate.

## Responsible Disclosure

Security vulnerabilities should be reported privately to the project maintainers. Please allow reasonable time for the vulnerability to be investigated and addressed before publicly disclosing the issue.

We appreciate responsible security research and contributions that help make SmartQ safer.

## Contact

For security-related concerns, please contact the SmartQ project maintainers through the project's official GitHub repository.

Thank you for helping improve the security of SmartQ.
