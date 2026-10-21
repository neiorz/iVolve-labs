# Lab 5: Docker Image Vulnerability Scanning with Trivy

- **Source code:** https://github.com/Ibrahim-Adel15/TrivyImage.git (cloned into this folder: `TrivyImage/`)
- **App:** Node.js (Express) on port 3000, provided Dockerfile based on `node:18-bullseye`.

## Objective

Scan a Docker image for known vulnerabilities with Trivy (full scan, HIGH/CRITICAL only, HTML report), then remediate the image — newer base image and patched dependencies — and prove the fix with a rescan.

## Lab Tasks

- [ ] Clone the application and Dockerfile from https://github.com/Ibrahim-Adel15/TrivyImage.git.
- [ ] Build a Docker image from the provided Dockerfile and tag it `trivy-lab:v1`.
- [ ] Install Trivy and verify the installation.
- [ ] Scan the Docker image for vulnerabilities and review the scan results.
- [ ] Scan the image to identify only HIGH and CRITICAL vulnerabilities.
- [ ] Generate an HTML vulnerability report and review the identified security issues.

### Bonus: Vulnerability Remediation

- [ ] Investigate the detected HIGH and CRITICAL vulnerabilities.
- [ ] Fix the identified issues by updating the vulnerable base image and application dependencies, where applicable.
- [ ] Rebuild the Docker image and tag it as `ivolve-app:v2`.
- [ ] Rescan the updated image and generate a new HTML report to verify the remediation.
- [ ] Ensure that no HIGH or CRITICAL vulnerabilities remain, where fixes are available.

## Screenshot Moments

| # | What you do | Command | Screenshot file |
|---|---|---|---|
| 1 | Install Trivy and verify | install script, then `trivy --version` | `lab5-install.png` |
| 2 | Build the provided image | `docker build -t trivy-lab:v1 .` | `lab5-build-v1.png` |
| 3 | Full scan | `trivy image trivy-lab:v1` | `lab5-scan.png` |
| 4 | HIGH and CRITICAL only | `trivy image --severity HIGH,CRITICAL trivy-lab:v1` | `lab5-scan-hc.png` |
| 5 | Generate the HTML report | `trivy image --format html -o trivy-report.html trivy-lab:v1`, `ls -lh` | `lab5-report1.png` |
| 6 | Review the report | open `trivy-report.html` in the browser | `lab5-report1-browser.png` |
| 7 | The fix (base image + dependency) | `cat Dockerfile.fixed`, `cat package.json` | `lab5-fix-files.png` |
| 8 | Rebuild as v2 | `docker build -f Dockerfile.fixed -t ivolve-app:v2 .` | `lab5-build-v2.png` |
| 9 | Rescan v2 for HIGH/CRITICAL | `trivy image --severity HIGH,CRITICAL ivolve-app:v2` | `lab5-rescan.png` |
| 10 | New HTML report and review | `trivy image --format html -o trivy-report-v2.html ivolve-app:v2`, open it | `lab5-report2-browser.png` |

Notes for the run: the first scan downloads Trivy's vulnerability database (give it a minute), the first build pulls the `node:18-bullseye` base (a few minutes), and the two HTML reports are kept in the repo as evidence. Steps and screenshots get added here after the run, same style as the other labs.
