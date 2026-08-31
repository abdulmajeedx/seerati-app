import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Seerati'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Seerati'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a professional resume and cover letter in Arabic and English — free and offline.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @newResume.
  ///
  /// In en, this message translates to:
  /// **'New Resume'**
  String get newResume;

  /// No description provided for @newResumeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a professional resume step by step'**
  String get newResumeSubtitle;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @coverLetterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a ready-to-send cover letter'**
  String get coverLetterSubtitle;

  /// No description provided for @myResumes.
  ///
  /// In en, this message translates to:
  /// **'My Resumes'**
  String get myResumes;

  /// No description provided for @noResumesYet.
  ///
  /// In en, this message translates to:
  /// **'No resumes yet. Create your first one!'**
  String get noResumesYet;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @languagesSection.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesSection;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @addExperience.
  ///
  /// In en, this message translates to:
  /// **'Add Experience'**
  String get addExperience;

  /// No description provided for @addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add Education'**
  String get addEducation;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add Skill'**
  String get addSkill;

  /// No description provided for @addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add Language'**
  String get addLanguage;

  /// No description provided for @addCourse.
  ///
  /// In en, this message translates to:
  /// **'Add Course'**
  String get addCourse;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @currentJob.
  ///
  /// In en, this message translates to:
  /// **'I currently work here'**
  String get currentJob;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @issuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @resumeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Resume Language'**
  String get resumeLanguage;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose Template'**
  String get chooseTemplate;

  /// No description provided for @templateClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get templateClassic;

  /// No description provided for @templateModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get templateModern;

  /// No description provided for @templateMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get templateMinimal;

  /// No description provided for @templateColorful.
  ///
  /// In en, this message translates to:
  /// **'Colorful'**
  String get templateColorful;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient Name'**
  String get recipientName;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @extrasStep.
  ///
  /// In en, this message translates to:
  /// **'Languages & Courses'**
  String get extrasStep;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume Title'**
  String get resumeTitle;

  /// No description provided for @untitledResume.
  ///
  /// In en, this message translates to:
  /// **'Untitled Resume'**
  String get untitledResume;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelNative.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get levelNative;

  /// No description provided for @noExperienceYet.
  ///
  /// In en, this message translates to:
  /// **'No experience added yet'**
  String get noExperienceYet;

  /// No description provided for @noEducationYet.
  ///
  /// In en, this message translates to:
  /// **'No education added yet'**
  String get noEducationYet;

  /// No description provided for @skillsHint.
  ///
  /// In en, this message translates to:
  /// **'Type a skill and press Enter'**
  String get skillsHint;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @resumeSaved.
  ///
  /// In en, this message translates to:
  /// **'Resume saved successfully'**
  String get resumeSaved;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @summaryHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short professional summary about yourself…'**
  String get summaryHint;

  /// No description provided for @optionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// No description provided for @endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get endBeforeStart;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmDeleteMsg;

  /// No description provided for @myCoverLetters.
  ///
  /// In en, this message translates to:
  /// **'My Cover Letters'**
  String get myCoverLetters;

  /// No description provided for @noCoverLettersYet.
  ///
  /// In en, this message translates to:
  /// **'No cover letters yet. Create your first one!'**
  String get noCoverLettersYet;

  /// No description provided for @newCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'New Cover Letter'**
  String get newCoverLetter;

  /// No description provided for @letterBody.
  ///
  /// In en, this message translates to:
  /// **'Letter Text'**
  String get letterBody;

  /// No description provided for @coverLetterSaved.
  ///
  /// In en, this message translates to:
  /// **'Cover letter saved'**
  String get coverLetterSaved;

  /// No description provided for @senderName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get senderName;

  /// No description provided for @untitledLetter.
  ///
  /// In en, this message translates to:
  /// **'Untitled Letter'**
  String get untitledLetter;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Seerati Premium'**
  String get premiumTitle;

  /// No description provided for @premiumBenefit1.
  ///
  /// In en, this message translates to:
  /// **'All 4 templates unlocked'**
  String get premiumBenefit1;

  /// No description provided for @premiumBenefit2.
  ///
  /// In en, this message translates to:
  /// **'No watermark on exported PDFs'**
  String get premiumBenefit2;

  /// No description provided for @premiumBenefit3.
  ///
  /// In en, this message translates to:
  /// **'One-time payment — yours forever'**
  String get premiumBenefit3;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is not available on this device.'**
  String get storeUnavailable;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful — enjoy!'**
  String get purchaseSuccess;

  /// No description provided for @alreadyPremium.
  ///
  /// In en, this message translates to:
  /// **'You already own Premium.'**
  String get alreadyPremium;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @haveActivationCode.
  ///
  /// In en, this message translates to:
  /// **'Have an activation code?'**
  String get haveActivationCode;

  /// No description provided for @activationCode.
  ///
  /// In en, this message translates to:
  /// **'Activation Code'**
  String get activationCode;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a minute.'**
  String get tooManyAttempts;

  /// No description provided for @aiImprove.
  ///
  /// In en, this message translates to:
  /// **'Improve with AI'**
  String get aiImprove;

  /// No description provided for @aiRewrite.
  ///
  /// In en, this message translates to:
  /// **'Rewrite professionally'**
  String get aiRewrite;

  /// No description provided for @aiWorking.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get aiWorking;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your internet and try again.'**
  String get networkError;

  /// No description provided for @quotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s AI quota.'**
  String get quotaExhausted;

  /// No description provided for @quotaExhaustedPremium.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s AI quota. It resets tomorrow.'**
  String get quotaExhaustedPremium;

  /// No description provided for @upgradeForMore.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeForMore;

  /// No description provided for @aiDeclined.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate this text. Try rephrasing your input.'**
  String get aiDeclined;

  /// No description provided for @coverLetterFromAd.
  ///
  /// In en, this message translates to:
  /// **'Cover letter from a job ad'**
  String get coverLetterFromAd;

  /// No description provided for @coverLetterFromAdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the ad and get a tailored letter'**
  String get coverLetterFromAdSubtitle;

  /// No description provided for @jobAd.
  ///
  /// In en, this message translates to:
  /// **'Job ad text'**
  String get jobAd;

  /// No description provided for @jobAdHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the job ad here…'**
  String get jobAdHint;

  /// No description provided for @generateWithAi.
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get generateWithAi;

  /// No description provided for @aiSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiSectionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
