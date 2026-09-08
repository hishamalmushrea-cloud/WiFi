#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# NetControl — إنشاء IPA غير موقّع بعد الأرشفة
#
# يُشغَّل تلقائياً كـ Post-Action ضمن ArchiveAction في سكيم Runner
# (انظر ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme).
#
# السبب: أمر `flutter build ipa --no-codesign` (حتى Flutter 3.24.x) يبني
# xcarchive فقط ثم يطبع "skipping IPA" ويعود دون إنشاء الملف — بينما تتوقع
# خطوات CI وجود build/ios/ipa/Runner.ipa. هذا السكربت يجمّعه من الأرشيف.
#
# التصميم:
#  - يعمل فقط عندما يكون التوقيع معطلاً (flutter يمرر CODE_SIGNING_ALLOWED=NO).
#  - لا يلمس IPA موجوداً (لا يستبدل ملفاً موقّعاً أنتجه flutter أو Xcode).
#  - أي فشل داخلي يخرج بصمت دون إفساد الأرشفة (exit 0 دائماً).
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_DIR="${PROJECT_DIR:-}"

# لا نعمل إلا عند تعطيل التوقيع (flutter --no-codesign يمرر CODE_SIGNING_ALLOWED=NO).
if [ "${CODE_SIGNING_ALLOWED:-}" != "NO" ] || [ -z "$PROJECT_DIR" ]; then
    exit 0
fi

# جذر مشروع Flutter (المجلد الأب لمجلد ios/).
REPO_ROOT="$(cd "$PROJECT_DIR/.." 2>/dev/null && pwd)" || exit 0
[ -n "$REPO_ROOT" ] || exit 0

# أحدث أرشيف أنتجه xcodebuild (flutter يمرر المسار المطلق عبر -archivePath).
ARCHIVE="$(ls -d "$REPO_ROOT"/build/ios/archive/*.xcarchive 2>/dev/null | head -n 1 || true)"
if [ -z "$ARCHIVE" ] || [ ! -d "$ARCHIVE/Products/Applications/Runner.app" ]; then
    exit 0
fi

IPA_DIR="$REPO_ROOT/build/ios/ipa"
mkdir -p "$IPA_DIR" 2>/dev/null || exit 0

# لا نستبدل IPA موجوداً (قد يكون موقّعاً من flutter أو من Xcode).
if [ -f "$IPA_DIR/Runner.ipa" ]; then
    exit 0
fi

# تجميع Payload/Runner.app → IPA (غير موقّع).
cd "$REPO_ROOT" || exit 0
rm -rf Payload
mkdir Payload
cp -R "$ARCHIVE/Products/Applications/Runner.app" Payload/Runner.app
if [ ! -d Payload/Runner.app ]; then
    rm -rf Payload
    exit 0
fi

# ‎-y تحفظ الروابط الرمزية داخل الـ Frameworks كما هي.
/usr/bin/zip -qry "$IPA_DIR/Runner.ipa" Payload
STATUS=$?
rm -rf Payload
if [ "$STATUS" -ne 0 ]; then
    rm -f "$IPA_DIR/Runner.ipa"
    exit 0
fi

echo "[netcontrol] تم إنشاء IPA غير موقّع: $IPA_DIR/Runner.ipa"
exit 0
