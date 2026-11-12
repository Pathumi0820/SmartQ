# Security Policy

## SmartQ – Hospital Queue Management System

SmartQ is a digital hospital queue management system developed to improve patient queue management, token generation, and administrative operations through technology.

We take the security, privacy, and intellectual property protection of SmartQ seriously. This document outlines our security practices, vulnerability reporting procedures, and guidelines for protecting the project against unauthorized access, copying, modification, and distribution.

## 1. Supported Versions

Currently, security updates are provided for the latest version of SmartQ available in the main branch.

| Version | Supported |
|---|---|
| Latest | Yes |
| Older versions | No |

## 2. Reporting a Vulnerability

If you discover a security vulnerability in SmartQ, please report it responsibly rather than publicly posting it in the GitHub Issues section.

When reporting a vulnerability, please include:

- A clear description of the vulnerability.
- Steps to reproduce the issue.
- The affected feature or component.
- Potential security impact.
- Screenshots or logs, if applicable.
- Suggested mitigation, if available.

Please avoid sharing sensitive information such as passwords, authentication tokens, patient information, or private credentials in reports.

## 3. Security Practices

SmartQ follows several security practices, including:

- Firebase Authentication for user authentication.
- Role-based access control for different user and administrative roles.
- Firebase Security Rules to control access to cloud data.
- Secure handling of authentication credentials and tokens.
- Input validation to reduce invalid or malicious data.
- QR-based verification for queue/token verification.
- Separation of patient and administrative functionality.
- Secure storage of sensitive configuration values.

## 4. Intellectual Property & Copyright Protection

**SmartQ is an original software project developed as an individual Final Year Project. All rights to the original source code, project structure, documentation, UI/UX designs, database designs, and other original project materials are reserved by the project author.**

The project is protected by applicable copyright and intellectual property laws.

The following activities are strictly prohibited without prior written permission from the project owner:

- Copying or reproducing the source code, either partially or entirely.
- Downloading and reusing the project or its components in other projects.
- Modifying, redistributing, or republishing the source code.
- Uploading copies of this project to other repositories under different ownership.
- Claiming this project or any of its original components as your own work.
- Using the project's original designs, documentation, or implementation for commercial or academic purposes without authorization.

**Public availability of this repository does not grant permission to copy, modify, distribute, or reuse its contents.**

Viewing the repository for learning and reference purposes does not transfer ownership or grant reuse rights.

For permission to use any part of SmartQ, please contact the project owner and obtain written authorization beforehand.

## 5. Sensitive Information

The following information must never be committed to the public repository:

- Firebase private keys.
- API keys and secrets.
- Authentication credentials.
- Database credentials.
- Access tokens.
- `.env` files containing secrets.
- Patient or other personally identifiable information.

Developers should use environment variables or appropriate secret-management mechanisms for sensitive configuration.

## 6. Dependency Security

Project dependencies should be kept up to date to reduce exposure to known vulnerabilities.

Before deploying a new version, dependencies should be reviewed and updated where appropriate.

## 7. Responsible Disclosure

Security vulnerabilities should be reported privately to the project maintainers.

Please allow reasonable time for vulnerabilities to be investigated and addressed before publicly disclosing them.

We appreciate responsible security research and contributions that help make SmartQ safer.

## 8. Contact

For security-related concerns, copyright questions, or permission requests, please contact the SmartQ project owner through the official GitHub repository.

---

**Copyright © 2026 SmartQ. All Rights Reserved.**

Unauthorized copying, reproduction, modification, redistribution, or reuse of this project's original materials is prohibited without prior written permission.
