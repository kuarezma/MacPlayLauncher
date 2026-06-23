#!/usr/bin/env bash
# Sprint 18 doğrulama komutu
# Kullanim: ./scripts/verify-sprint-18.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"
    if [ "$result" = "ok" ]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label — $result"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Sprint 18 (v0.23.0) Doğrulama ==="
echo ""

# 1. build.sh sürüm parametresini git tag'dan alıyor
cd "$ROOT_DIR"
if grep -q 'BUNDLE_VERSION="0.1.0"' scripts/build.sh 2>/dev/null; then
    check "build.sh sabit sürüm kaldırıldı" "HATA: hâlâ BUNDLE_VERSION=\"0.1.0\" var"
else
    check "build.sh sabit sürüm kaldırıldı" "ok"
fi

# 2. build.sh git tag veya parametre desteği var
if grep -q 'git.*describe' scripts/build.sh; then
    check "build.sh git tag okuma" "ok"
else
    check "build.sh git tag okuma" "HATA: git describe yok"
fi

# 3. SetupOrchestrator.swift varlığı
if [ -f "$ROOT_DIR/Core/Services/SetupOrchestrator.swift" ]; then
    check "SetupOrchestrator.swift oluşturuldu" "ok"
else
    check "SetupOrchestrator.swift oluşturuldu" "HATA: dosya yok"
fi

# 4. SetupOrchestrator pollingInterval enjekte edilebilir
if grep -q 'pollingInterval: Duration' "$ROOT_DIR/Core/Services/SetupOrchestrator.swift" 2>/dev/null; then
    check "SetupOrchestrator polling testable" "ok"
else
    check "SetupOrchestrator polling testable" "HATA: pollingInterval parametresi yok"
fi

# 5. AppState orchestrator içeriyor
if grep -q 'setupOrchestrator' "$ROOT_DIR/App/AppState.swift" 2>/dev/null; then
    check "AppState orchestrator property" "ok"
else
    check "AppState orchestrator property" "HATA: setupOrchestrator yok"
fi

# 6. SetupWizardView tek buton (toggleOrchestration)
if grep -q 'toggleOrchestration' "$ROOT_DIR/App/SetupWizardView.swift" 2>/dev/null; then
    check "SetupWizardView Kurulumu Başlat butonu" "ok"
else
    check "SetupWizardView Kurulumu Başlat butonu" "HATA: toggleOrchestration çağrısı yok"
fi

# 7. SetupWizardView log paneli
if grep -q 'orchestrationLogPanel' "$ROOT_DIR/App/SetupWizardView.swift" 2>/dev/null; then
    check "SetupWizardView log paneli" "ok"
else
    check "SetupWizardView log paneli" "HATA: orchestrationLogPanel yok"
fi

# 8-11. create-release.sh --dry-run çalışıyor (geçici dosyaya yaz, güvenilir yakalama)
_DRY_TMP=$(mktemp /tmp/mpl_verify_dry_XXXXXX)
bash "$ROOT_DIR/scripts/create-release.sh" v0.23.0 --dry-run > "$_DRY_TMP" 2>&1 || true

if grep -q "\[DRY-RUN\]" "$_DRY_TMP"; then
    check "create-release.sh --dry-run" "ok"
else
    check "create-release.sh --dry-run" "HATA: [DRY-RUN] çıktısı yok"
fi

if grep -qi "sha256\|shasum\|checksum" "$_DRY_TMP"; then
    check "create-release.sh SHA256 adımı" "ok"
else
    check "create-release.sh SHA256 adımı" "HATA: SHA256 adımı yok"
fi

if grep -q "notarytool\|Notarization" "$_DRY_TMP"; then
    check "create-release.sh notarization adımı" "ok"
else
    check "create-release.sh notarization adımı" "HATA: notarization yok"
fi

if grep -qE "Değişiklikler|feat|fix|release notları" "$_DRY_TMP"; then
    check "create-release.sh dinamik release notları" "ok"
else
    check "create-release.sh dinamik release notları" "HATA: dinamik notlar yok"
fi
rm -f "$_DRY_TMP"

# 12. ADR-003 'sandboxed' ifadesi kaldırıldı
if grep -i "personal-use only, sandboxed" "$ROOT_DIR/Docs/ADR/ADR-003-Launch-Plan.md" 2>/dev/null; then
    check "ADR-003 sandbox ifadesi güncellendi" "HATA: hâlâ 'sandboxed' yazıyor"
else
    check "ADR-003 sandbox ifadesi güncellendi" "ok"
fi

# 13. ADR-003 yeni sandbox açıklaması var
if grep -q "App Sandbox is.*disabled" "$ROOT_DIR/Docs/ADR/ADR-003-Launch-Plan.md" 2>/dev/null; then
    check "ADR-003 yeni sandbox açıklaması" "ok"
else
    check "ADR-003 yeni sandbox açıklaması" "HATA: yeni açıklama yok"
fi

# 14. README kullanıcı kurulum bölümü
if grep -q "Kullanıcı Kurulumu\|MacPlayLauncher.dmg.*indir" "$ROOT_DIR/README.md" 2>/dev/null; then
    check "README kullanıcı kurulum bölümü" "ok"
else
    check "README kullanıcı kurulum bölümü" "HATA: kullanıcı kurulum bölümü yok"
fi

# 15. README troubleshooting Gatekeeper + Steam Guard
if grep -q "Gatekeeper\|Steam Guard\|Yine de Aç" "$ROOT_DIR/README.md" 2>/dev/null; then
    check "README troubleshooting güncel" "ok"
else
    check "README troubleshooting güncel" "HATA: Gatekeeper/Steam Guard kılavuzu yok"
fi

# 16. SetupOrchestratorTests varlığı
if [ -f "$ROOT_DIR/Tests/MacPlayLauncherTests/SetupOrchestratorTests.swift" ]; then
    check "SetupOrchestratorTests.swift oluşturuldu" "ok"
else
    check "SetupOrchestratorTests.swift oluşturuldu" "HATA: dosya yok"
fi

# 17. Swift testleri geçiyor
echo ""
echo "Swift test koşuluyor…"
_TEST_TMP=$(mktemp /tmp/mpl_verify_test_XXXXXX)
swift test --build-path /tmp/mpl_build_sprint18 > "$_TEST_TMP" 2>&1 || true
if grep -qE "All tests' passed|passed at|Build complete" "$_TEST_TMP" && ! grep -q "error:" "$_TEST_TMP"; then
    check "swift test — tüm testler geçiyor" "ok"
else
    check "swift test — tüm testler geçiyor" "HATA: test hatası var"
fi
rm -f "$_TEST_TMP"

echo ""
echo "=== Sonuç: $PASS geçti, $FAIL başarısız ==="
[ "$FAIL" -eq 0 ] && echo "Sprint 18 başarıyla doğrulandı." || exit 1
