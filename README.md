<div dir="rtl">

# سيرتي (Seerati) 📄

> **⬇️ تحميل مباشر لأندرويد:** [seerati.apk — أحدث إصدار](https://github.com/abdulmajeedx/seerati-app/releases/latest/download/seerati.apk)
>
> ملاحظة: عند التثبيت قد يطلب أندرويد تفعيل **"التثبيت من مصادر غير معروفة"** — فعّلها مؤقتاً من الإعدادات ثم ثبّت التطبيق.

تطبيق مجاني لإنشاء **سيرة ذاتية** و**خطاب تقديم** احترافيين بالعربية والإنجليزية — يعمل بالكامل بدون إنترنت.

## المميزات

- ✅ واجهة ثنائية اللغة (عربي/إنجليزي) مع دعم كامل للاتجاهين RTL/LTR
- ✅ لغة السيرة الذاتية مستقلة عن لغة الواجهة
- ✅ نموذج إدخال متدرّج: معلومات شخصية، ملخص، خبرات، تعليم، مهارات، لغات ودورات
- ✅ 4 قوالب (كلاسيكي، عصري، بسيط، ملوّن) — الأول مجاني
- ✅ معاينة حيّة وتصدير PDF مع مشاركة/حفظ
- ✅ حفظ محلي (Hive) مع قائمة "سيري الذاتية"
- ✅ مولّد خطاب تقديم من قالب نصي
- ✅ الوضع الفاتح والداكن (Material 3)

## التشغيل

</div>

```bash
git clone https://github.com/abdulmajeedx/seerati-app.git
cd seerati-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

<div dir="rtl">

## هيكل المشروع

</div>

```
lib/
├── main.dart / app.dart
├── core/            # theme, constants, services, providers
├── features/
│   ├── welcome/     # welcome screen
│   ├── home/        # home screen
│   ├── resume/      # models, forms, templates, preview, PDF
│   └── cover_letter/
├── l10n/            # app_ar.arb, app_en.arb
└── shared/          # shared widgets
```

<div dir="rtl">

## خارطة الطريق

- [x] هيكل المشروع + النماذج + الترجمة
- [x] نماذج الإدخال (RTL/LTR)
- [x] القوالب والمعاينة وتصدير PDF
- [x] الحفظ المحلي + خطاب التقديم
- [x] الشراء داخل التطبيق
- [x] نشر أول إصدار أندرويد
- [ ] إصدار iOS

</div>

---

# Seerati (سيرتي) 📄 — English

> **⬇️ Direct Android download:** [seerati.apk — latest release](https://github.com/abdulmajeedx/seerati-app/releases/latest/download/seerati.apk)
>
> Note: Android may ask you to enable **"Install from unknown sources"** — enable it temporarily in Settings, then install.

A free, fully offline bilingual (Arabic/English) **resume** and **cover letter** builder.

## Features

- ✅ Bilingual UI (Arabic/English) with full RTL/LTR mirroring
- ✅ Resume language independent from UI language
- ✅ Stepper form: personal info, summary, experience, education, skills, languages & courses
- ✅ 4 templates (Classic, Modern, Minimal, Colorful) — first one free
- ✅ Live preview and PDF export with Share/Save
- ✅ Local storage (Hive) with a "My Resumes" list
- ✅ Cover letter generator from a text template
- ✅ Material 3 light & dark themes

## Run

```bash
git clone https://github.com/abdulmajeedx/seerati-app.git
cd seerati-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Roadmap

- [x] Project structure + models + localization
- [x] Forms with RTL/LTR
- [x] Templates, live preview, PDF export (AR+EN)
- [x] Local storage + cover letter
- [x] In-app purchase
- [x] First Android release
- [ ] iOS release

## License

MIT — see [LICENSE](LICENSE).
