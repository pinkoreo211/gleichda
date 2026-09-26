// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Need someone? Right there.';

  @override
  String get welcomeSubtitle =>
      'Verified service providers near you – found fast, booked easily.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String roleSelectionTitle(String appName) {
    return 'How do you want to use $appName?';
  }

  @override
  String get roleCustomerTitle => 'I need a service';

  @override
  String get roleCustomerDescription =>
      'Find, book and pay verified pros near you.';

  @override
  String get roleProviderTitle => 'I offer services';

  @override
  String get roleProviderDescription =>
      'Get jobs in your area, send offers and earn.';

  @override
  String get roleSwitchHint => 'You can switch modes anytime in your profile.';

  @override
  String get roleSelectionContinue => 'Continue';

  @override
  String get roleCustomerModeName => 'Customer mode';

  @override
  String get roleProviderModeName => 'Provider mode';

  @override
  String get tabHome => 'Home';

  @override
  String get tabBookings => 'Bookings';

  @override
  String get tabMessages => 'Chats';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabEarnings => 'Earnings';

  @override
  String get customerHomeTitle => 'What do you need?';

  @override
  String get customerHomeMessage =>
      'Soon you can describe what you need or pick a category – and find verified pros near you.';

  @override
  String get customerBookingsEmptyTitle => 'No bookings yet';

  @override
  String get customerBookingsEmptyMessage =>
      'Your bookings and projects will show up here with their current status.';

  @override
  String get conversationsEmptyTitle => 'No chats yet';

  @override
  String get conversationsEmptyCustomer =>
      'As soon as a provider accepts your request, you can write to each other here.';

  @override
  String get conversationsEmptyProvider =>
      'As soon as you accept a request, you can write to the customer here.';

  @override
  String get conversationsLoadFailed => 'The chats could not be loaded.';

  @override
  String get providerJobsEmptyTitle => 'No jobs yet';

  @override
  String get providerJobsEmptyMessage =>
      'Once your profile is verified, matching requests and projects from your area will show up here.';

  @override
  String get availabilityTitle => 'Your availability';

  @override
  String get availabilityMessage =>
      'Soon you can set when you work and see your appointments here.';

  @override
  String get earningsEmptyTitle => 'No earnings yet';

  @override
  String get earningsEmptyMessage =>
      'Your completed jobs and payouts will show up here.';

  @override
  String get profileCurrentMode => 'Current mode';

  @override
  String get profileSwitchToProvider => 'Switch to provider mode';

  @override
  String get profileSwitchToCustomer => 'Switch to customer mode';

  @override
  String get profileAccountComingSoon =>
      'Personal details and settings are coming soon.';

  @override
  String get profileSignedInAs => 'Signed in as';

  @override
  String get signOut => 'Sign out';

  @override
  String get loginTitle => 'Sign in or sign up';

  @override
  String get loginEmailIntro =>
      'Enter your email address. We\'ll send you a code – no password needed.';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginSendCode => 'Send code';

  @override
  String get loginCodeTitle => 'Enter code';

  @override
  String loginCodeIntro(String email) {
    return 'We sent a code to $email. Please also check your spam folder.';
  }

  @override
  String get loginCodeLabel => 'Code from the email';

  @override
  String get loginVerifyCode => 'Confirm';

  @override
  String get loginResendCode => 'Resend code';

  @override
  String get loginCodeResent => 'A new code is on its way.';

  @override
  String get loginChangeEmail => 'Use a different email address';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorInvalidOrExpiredCode =>
      'The code is wrong or has expired. Request a new one if needed.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorEmailNotAuthorized =>
      'We can\'t send emails to this address at the moment.';

  @override
  String get errorUnknown =>
      'That didn\'t work. Please check your internet connection and try again.';

  @override
  String get customerHomeInputHint => 'Describe what you need …';

  @override
  String get customerHomeExamplesLabel => 'Examples';

  @override
  String get customerHomeExampleWashingMachine =>
      'My washing machine is leaking water.';

  @override
  String get customerHomeExampleCleaning => 'I need someone to clean tomorrow.';

  @override
  String get customerHomeExampleTv => 'Someone should mount my TV.';

  @override
  String get customerHomeExampleGarden => 'My garden needs trimming.';

  @override
  String get customerHomeContinue => 'Continue';

  @override
  String get customerHomePopularServices => 'Popular services';

  @override
  String get customerHomeUpcomingBookings => 'Your next bookings';

  @override
  String customerHomeNoBookingsMessage(String appName) {
    return 'Book your first service with $appName.';
  }

  @override
  String get categoryHandyman => 'Handyman';

  @override
  String get categoryCleaning => 'Cleaning';

  @override
  String get categoryMoving => 'Moving & transport';

  @override
  String get categoryCar => 'Car';

  @override
  String get categoryPets => 'Pets';

  @override
  String get categoryBeauty => 'Beauty';

  @override
  String get categoryRenovation => 'Renovation';

  @override
  String get categoryOther => 'Other';

  @override
  String get requestTitle => 'Tell us briefly what you need';

  @override
  String get requestDescriptionLabel => 'Your request';

  @override
  String get requestDescriptionRequired =>
      'Please describe briefly what you need.';

  @override
  String get requestCategoryLabel => 'Category';

  @override
  String get requestCategoryHint =>
      'Optional – we will detect the right service automatically later.';

  @override
  String get requestLocationLabel => 'Where is the service needed?';

  @override
  String get requestLocationChoose => 'Choose location';

  @override
  String get requestTimingLabel => 'When do you need help?';

  @override
  String get requestTimingAsap => 'As soon as possible';

  @override
  String get requestTimingToday => 'Today';

  @override
  String get requestTimingTomorrow => 'Tomorrow';

  @override
  String get requestTimingPickDate => 'Pick a date';

  @override
  String get requestPhotosLabel => 'Photos';

  @override
  String get requestAddPhoto => 'Add photo';

  @override
  String get requestSubmit => 'Create request';

  @override
  String get requestSaved => 'Request saved.';

  @override
  String get requestNotSentYet =>
      'Once saved, we show you matching providers. Nothing is sent until you pick one.';

  @override
  String get customerRequestsTitle => 'Your requests';

  @override
  String get customerRequestsNotSent => 'Not sent yet';

  @override
  String get profileName => 'Name';

  @override
  String get profileNameMissing => 'Not set yet';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileSettings => 'Settings';

  @override
  String get comingSoon => 'This feature is coming soon.';

  @override
  String get catalogLoading => 'Loading services …';

  @override
  String get catalogErrorMessage => 'Services could not be loaded.';

  @override
  String get catalogRetry => 'Try again';

  @override
  String get catalogEmptyTitle => 'No services available';

  @override
  String get catalogEmptyMessage =>
      'No services are available right now. Please check back later.';

  @override
  String get categoryServicesEmptyMessage =>
      'This category has no services yet.';

  @override
  String servicePriceFrom(String price) {
    return 'from $price';
  }

  @override
  String get serviceQuoteBadge => 'Quote';

  @override
  String get servicePriceOptionsTitle => 'Price options';

  @override
  String get serviceQuoteHint =>
      'For this service you create a request and receive matching offers.';

  @override
  String get servicePricesExampleHint =>
      'Example prices. The final price is agreed with the provider.';

  @override
  String get serviceContinue => 'Continue';

  @override
  String get serviceNotFound => 'This service is no longer available.';

  @override
  String serviceDurationMinutes(int minutes) {
    return 'approx. $minutes min';
  }

  @override
  String providerOnboardingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get providerPersonalTitle => 'Tell us a little about yourself.';

  @override
  String get providerFirstNameLabel => 'First name';

  @override
  String get providerLastNameLabel => 'Last name';

  @override
  String get providerPhotoAdd => 'Add profile photo';

  @override
  String get providerBusinessTitle =>
      'Do you work for yourself or for a company?';

  @override
  String get providerKindSelfEmployed => 'Self-employed';

  @override
  String get providerKindCompany => 'Company';

  @override
  String get providerCompanyNameLabel => 'Company name';

  @override
  String get providerTradingNameLabel => 'Your trading name';

  @override
  String get providerServicesTitle => 'Which services do you offer?';

  @override
  String get providerServicesHint =>
      'Pick everything you offer. You can change this at any time.';

  @override
  String get providerAreaTitle => 'Where do you want to take jobs?';

  @override
  String get providerCityLabel => 'City';

  @override
  String get providerPostalCodeLabel => 'Postal code';

  @override
  String providerRadiusLabel(int km) {
    return 'Radius: $km km';
  }

  @override
  String get providerFinishTitle => 'Almost there.';

  @override
  String get providerFinishMessage =>
      'Your profile is set up. As soon as there are jobs near you, they appear in your area.';

  @override
  String get providerFinishButton => 'Finish profile';

  @override
  String get providerBack => 'Back';

  @override
  String get providerVerificationTitle => 'Verification';

  @override
  String get providerVerificationUnverified => 'Not verified';

  @override
  String get providerVerificationPending => 'In review';

  @override
  String get providerVerificationVerified => 'Verified';

  @override
  String get providerVerificationRejected => 'Rejected';

  @override
  String get providerVerificationExplanation =>
      'We check your documents before customers see you as verified. Which documents are needed depends on your services.';

  @override
  String providerHomeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get providerHomeGreetingPlain => 'Hello';

  @override
  String get providerHomeSubtitle => 'Ready for your next job?';

  @override
  String get providerHomeNoJobs => 'You have no jobs yet.';

  @override
  String get providerHomeMyServices => 'My services';

  @override
  String get providerHomeAvailability => 'My availability';

  @override
  String providerServicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
      zero: 'No service selected yet',
    );
    return '$_temp0';
  }

  @override
  String get errorFirstNameRequired => 'Please enter your first name.';

  @override
  String get errorLastNameRequired => 'Please enter your last name.';

  @override
  String get errorBusinessNameRequired =>
      'Please enter the name of your business.';

  @override
  String get errorServicesRequired => 'Please select at least one service.';

  @override
  String get errorCityRequired => 'Please enter your city.';

  @override
  String get providerAddService => 'Add service';

  @override
  String get providerEdit => 'Edit';

  @override
  String get providerNoPriceYet => 'No price set yet';

  @override
  String get providerPricingTitle => 'Pricing';

  @override
  String get providerAddPrice => 'Add price option';

  @override
  String get providerPriceNameLabel => 'Label';

  @override
  String get providerPriceAmountLabel => 'Price in euro';

  @override
  String get providerPriceUnitLabel => 'Unit';

  @override
  String get providerPriceDurationLabel => 'Duration in minutes';

  @override
  String get providerPriceSave => 'Save';

  @override
  String get providerPriceDeactivate => 'Deactivate';

  @override
  String get providerPriceActivate => 'Activate';

  @override
  String get providerPriceDelete => 'Delete';

  @override
  String get providerPriceInactive => 'Deactivated';

  @override
  String get providerQuoteNoPriceNeeded =>
      'This service needs no fixed price. Customers request a quote.';

  @override
  String get providerPricesEmpty =>
      'You have not set a price for this service yet.';

  @override
  String get providerServicesEmpty => 'You do not offer any services yet.';

  @override
  String get errorPriceNameRequired => 'Please enter a label.';

  @override
  String get errorPriceInvalid => 'Please enter a valid price.';

  @override
  String get providerMatchesTitle => 'Providers for this service';

  @override
  String get providerMatchesShow => 'Show providers';

  @override
  String get providerMatchesEmptyTitle => 'Nobody available yet';

  @override
  String get providerMatchesEmptyMessage =>
      'No provider offers this service yet. Your request stays saved — as soon as someone signs up, you will find them here.';

  @override
  String get providerUnnamed => 'Provider';

  @override
  String get providerNoPriceGiven => 'Price on request';

  @override
  String get requestCityLabel => 'Town or city';

  @override
  String get requestCityPlaceholder => 'e.g. Vienna';

  @override
  String get requestPostalCodeLabel => 'Postcode';

  @override
  String get requestLocationHint =>
      'Without a town we show you providers from everywhere.';

  @override
  String get requestMatchesTitle => 'Matching providers';

  @override
  String get requestMatchesNoServiceTitle => 'No service chosen yet';

  @override
  String get requestMatchesNoServiceMessage =>
      'This request does not name a service yet. Pick one from the catalogue and we will look for providers.';

  @override
  String get providerMatchSend => 'Send request';

  @override
  String get providerMatchSent => 'Request sent';

  @override
  String requestSentToProvider(String name) {
    return 'Your request went to $name.';
  }

  @override
  String get customerRequestsShowProviders => 'Matching providers';

  @override
  String customerRequestsSentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent to $count providers',
      one: 'Sent to 1 provider',
      zero: 'Not sent yet',
    );
    return '$_temp0';
  }

  @override
  String get providerIncomingTitle => 'Requests for you';

  @override
  String get providerIncomingEmpty =>
      'You have not received any requests yet. As soon as someone asks for you, it appears here.';

  @override
  String providerIncomingFrom(String name) {
    return 'from $name';
  }

  @override
  String get providerIncomingCustomerUnknown => 'Customer';

  @override
  String providerIncomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests',
      one: '1 request',
      zero: 'No requests',
    );
    return '$_temp0';
  }

  @override
  String get providerIncomingAccept => 'Accept';

  @override
  String get providerIncomingDecline => 'Decline';

  @override
  String get providerIncomingAccepted => 'You accepted';

  @override
  String get providerIncomingDeclined => 'You declined';

  @override
  String get providerIncomingAcceptedToast => 'Request accepted.';

  @override
  String get providerIncomingDeclinedToast => 'Request declined.';

  @override
  String get requestStatusOpen => 'Still open';

  @override
  String get requestStatusAccepted => 'Accepted';

  @override
  String get requestStatusDeclined => 'Declined';

  @override
  String get jobStatusScheduled => 'Time agreed';

  @override
  String get jobStatusOnTheWay => 'On the way';

  @override
  String get jobStatusInProgress => 'In progress';

  @override
  String get jobStatusCompleted => 'Done';

  @override
  String get jobStatusConfirmed => 'Confirmed by the customer';

  @override
  String get jobStatusCancelled => 'Cancelled';

  @override
  String get jobsTitle => 'Your jobs';

  @override
  String jobAppointment(String when) {
    return 'Appointment: $when';
  }

  @override
  String get jobNoAppointment => 'No time agreed yet';

  @override
  String jobOnTheWayNamed(String name) {
    return '$name is on the way';
  }

  @override
  String get jobOnTheWaySelf => 'You are on the way';

  @override
  String get jobCompletedAsk => 'Please confirm that the work is finished.';

  @override
  String get jobCompletedWaiting => 'Waiting for the customer to confirm.';

  @override
  String get jobFinished => 'Job completed';

  @override
  String get jobSetAppointment => 'Agree a time';

  @override
  String get jobOnMyWay => 'I am on my way';

  @override
  String get jobStartWork => 'Start work';

  @override
  String get jobReportDone => 'Work is done';

  @override
  String get jobConfirm => 'Confirm the job';

  @override
  String get jobWaitingForProvider =>
      'The provider will get in touch when they set off.';

  @override
  String get jobOpenChat => 'Write a message';

  @override
  String get jobChanged => 'Job updated.';

  @override
  String get jobAppointmentPickTime => 'Pick a time';

  @override
  String get reviewTitle => 'How was your job?';

  @override
  String get reviewCommentLabel => 'What would you like to say about the job?';

  @override
  String get reviewCommentHint => 'Your experience (optional)';

  @override
  String get reviewSubmit => 'Submit review';

  @override
  String get reviewRate => 'Rate the job';

  @override
  String get reviewThanks => 'Thank you for your review!';

  @override
  String get reviewYours => 'Your review';

  @override
  String get reviewBackToJobs => 'Back to my jobs';

  @override
  String get reviewAlready => 'You have already reviewed this job.';

  @override
  String get reviewStars1 => 'Very poor';

  @override
  String get reviewStars2 => 'Not good';

  @override
  String get reviewStars3 => 'Okay';

  @override
  String get reviewStars4 => 'Good';

  @override
  String get reviewStars5 => 'Excellent';

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get reviewNone => 'No reviews yet';

  @override
  String get reviewYourRatingTitle => 'Your rating';

  @override
  String customerRequestsAcceptedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count providers accepted',
      one: '1 provider accepted',
    );
    return '$_temp0';
  }

  @override
  String customerRequestsDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count providers declined',
      one: '1 provider declined',
    );
    return '$_temp0';
  }

  @override
  String get errorRequestAlreadyAnswered =>
      'This request has already been answered.';

  @override
  String get errorMessageEmpty => 'The message is empty.';

  @override
  String get chatOtherUnknown => 'Chat';

  @override
  String get chatNoAppointment => 'No appointment agreed yet';

  @override
  String get chatMessageHint => 'Write a message …';

  @override
  String get chatSend => 'Send';

  @override
  String get chatEmptyTitle => 'No messages yet';

  @override
  String get chatEmptyMessage => 'Write the first message to agree on a time.';

  @override
  String get chatLoadFailed => 'The chat could not be loaded.';

  @override
  String get chatWithProvider => 'Contact provider';

  @override
  String get chatWithCustomer => 'Contact customer';

  @override
  String get actionRetry => 'Try again';

  @override
  String get verificationHeadline => 'Verify your profile';

  @override
  String get verificationIntro =>
      'Your documents let us confirm that you offer the listed services professionally.';

  @override
  String get verificationTeamNote =>
      'A person looks at every document by hand. Until we are done, you see no verified badge — and neither do your customers.';

  @override
  String get verificationRequired => 'Required';

  @override
  String get verificationOptional => 'Optional';

  @override
  String get verificationNotUploaded => 'Not uploaded yet';

  @override
  String get verificationStatusWaiting => 'Review pending';

  @override
  String get verificationStatusAccepted => 'Checked';

  @override
  String get verificationStatusRejected => 'Document rejected';

  @override
  String verificationRejectionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String verificationUploadedOn(String date) {
    return 'Uploaded on $date';
  }

  @override
  String get verificationUpload => 'Upload document';

  @override
  String get verificationUploadNew => 'Upload a new document';

  @override
  String get verificationReplace => 'Replace document';

  @override
  String get verificationUploadDone => 'Document uploaded';

  @override
  String get verificationSourceCamera => 'Take a photo';

  @override
  String get verificationSourceGallery => 'Choose a photo';

  @override
  String get verificationSourceFile => 'Choose a PDF';

  @override
  String get verificationLoadFailed => 'The documents could not be loaded.';

  @override
  String get verificationAllHandedIn =>
      'Everything required is here. We will get back to you once we have checked it.';

  @override
  String get verificationMissing =>
      'Some required documents are still missing.';

  @override
  String get verificationNoProfile => 'Set up your provider profile first.';

  @override
  String get documentTypeIdentity => 'Proof of identity';

  @override
  String get documentTypeIdentityHint => 'Passport, ID card or driving licence';

  @override
  String get documentTypeBusinessRegistration => 'Business registration';

  @override
  String get documentTypeBusinessRegistrationHint =>
      'Trade licence or an extract from the business register';

  @override
  String get documentTypeTradeLicense => 'Trade authorisation';

  @override
  String get documentTypeTradeLicenseHint =>
      'Proof of competence for a regulated trade';

  @override
  String get documentTypeQualification => 'Qualification';

  @override
  String get documentTypeQualificationHint =>
      'Master craftsman certificate, diploma or certificate';

  @override
  String get documentTypeInsurance => 'Insurance';

  @override
  String get documentTypeInsuranceHint => 'Liability insurance for your work';

  @override
  String get documentTypeOther => 'Other document';

  @override
  String get documentTypeOtherHint => 'A document that fits no other category';

  @override
  String get errorDocumentLocked =>
      'This document is being checked and cannot be replaced.';

  @override
  String get errorDocumentTooLarge =>
      'That file is too large. Please upload at most 10 MB.';

  @override
  String get errorDocumentTypeNotAllowed =>
      'That file format does not work. PDF, JPG, PNG, HEIC and WEBP are accepted.';
}
