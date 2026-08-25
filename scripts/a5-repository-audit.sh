#!/usr/bin/env bash

set -u

PASS_COUNT=0
FAIL_COUNT=0


pass() {
    printf 'PASS: %s\n' "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}


fail() {
    printf 'FAIL: %s\n' "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}


check_directory() {
    if [ -d "$1" ]; then
        pass "Directory $1 exists"
    else
        fail "Directory $1 is missing"
    fi
}


check_file() {
    if [ -f "$1" ]; then
        pass "File $1 exists"
    else
        fail "File $1 is missing"
    fi
}


echo "=========================================="
echo " MediCore DTS206 A5 Repository Audit"
echo "=========================================="
echo


echo "===== REQUIRED DIRECTORIES ====="

check_directory "infrastructure"
check_directory "docker"
check_directory "kubernetes"
check_directory "screenshots"
check_directory "analysis"

echo


echo "===== ROOT DOCUMENTATION ====="

check_file "README.md"
check_file ".gitignore"

echo


echo "===== TERRAFORM ====="

check_file "infrastructure/versions.tf"
check_file "infrastructure/provider.tf"
check_file "infrastructure/variables.tf"
check_file "infrastructure/data.tf"
check_file "infrastructure/network.tf"
check_file "infrastructure/key-pair.tf"
check_file "infrastructure/security-groups.tf"
check_file "infrastructure/compute.tf"
check_file "infrastructure/storage.tf"
check_file "infrastructure/database.tf"
check_file "infrastructure/outputs.tf"

check_file "infrastructure/a2-data.tf"
check_file "infrastructure/a2-security.tf"
check_file "infrastructure/a2-iam.tf"
check_file "infrastructure/a2-monitoring.tf"
check_file "infrastructure/a2-outputs.tf"

check_file "infrastructure/a3-variables.tf"
check_file "infrastructure/a3-network.tf"
check_file "infrastructure/a3-security-groups.tf"
check_file "infrastructure/a3-load-balancer.tf"
check_file "infrastructure/a3-autoscaling.tf"
check_file "infrastructure/a3-outputs.tf"

check_file "infrastructure/terraform.tfvars.example"

echo


echo "===== DOCKER ====="

check_file "docker/Dockerfile"
check_file "docker/docker-compose.yml"
check_file "docker/.dockerignore"
check_file "docker/pyproject.toml"
check_file "docker/vulnerability-notes.md"
check_file "docker/.trivyignore.yaml"
check_file "docker/.grype.yaml"
check_file "docker/src/medicore_app/__init__.py"
check_file "docker/secrets/README.md"

echo


echo "===== KUBERNETES ====="

check_file "kubernetes/deployment.yaml"
check_file "kubernetes/service.yaml"
check_file "kubernetes/README.md"

echo


echo "===== SECRET SAFETY ====="

if git check-ignore -q docker/secrets/db_password.txt; then
    pass "Docker password file is ignored by Git"
else
    fail "Docker password file is NOT ignored by Git"
fi


if git check-ignore -q infrastructure/terraform.tfvars; then
    pass "terraform.tfvars is ignored by Git"
else
    fail "terraform.tfvars is NOT ignored by Git"
fi


if git check-ignore -q infrastructure/terraform.tfstate; then
    pass "Terraform state is ignored by Git"
else
    fail "Terraform state is NOT ignored by Git"
fi


if git check-ignore -q infrastructure/a3-ha.tfplan; then
    pass "Saved Terraform plans are ignored by Git"
else
    fail "Saved Terraform plans may not be ignored"
fi


if git ls-files \
    | grep -Eq '(^|/)(terraform\.tfvars|terraform\.tfstate|db_password\.txt)$'
then
    fail "Sensitive runtime file appears in Git tracked files"
else
    pass "No known sensitive runtime files are tracked"
fi

echo


echo "===== SCREENSHOTS ====="

SCREENSHOT_COUNT=$(
    find screenshots \
        -maxdepth 1 \
        -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
        | wc -l
)

echo "Screenshot count: $SCREENSHOT_COUNT"

if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
    pass "Screenshot evidence exists"
else
    fail "No screenshot evidence found"
fi

echo


echo "===== README CONTENT ====="

for TEXT in \
    "Architecture Overview" \
    "Deployment From Scratch" \
    "Tools and Rationale" \
    "AI Declaration" \
    "References"
do
    if grep -qi "$TEXT" README.md; then
        pass "README contains: $TEXT"
    else
        fail "README missing: $TEXT"
    fi
done

echo


echo "===== VULNERABILITY DOCUMENTATION ====="

if grep -qi "Trivy" docker/vulnerability-notes.md; then
    pass "Trivy documented"
else
    fail "Trivy documentation missing"
fi

if grep -qi "Grype" docker/vulnerability-notes.md; then
    pass "Grype documented"
else
    fail "Grype documentation missing"
fi

if grep -qi "CVE-" docker/vulnerability-notes.md; then
    pass "CVE entries found"
else
    fail "No CVE entries found"
fi

if grep -q "REVIEW REQUIRED" docker/vulnerability-notes.md; then
    fail "vulnerability-notes.md still contains REVIEW REQUIRED"
else
    pass "No unresolved REVIEW REQUIRED placeholders"
fi

echo


echo "===== RESULT ====="

echo "PASS count: $PASS_COUNT"
echo "FAIL count: $FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo
    echo "A5 REPOSITORY AUDIT: PASS"
    exit 0
fi

echo
echo "A5 REPOSITORY AUDIT: FAIL"
exit 1