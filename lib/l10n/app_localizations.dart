import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeToQalqanDsm.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Qalqan'**
  String get welcomeToQalqanDsm;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get enterPassword;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please, enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @click_back.
  ///
  /// In en, this message translates to:
  /// **'Click back again to exit'**
  String get click_back;

  /// No description provided for @encrypt.
  ///
  /// In en, this message translates to:
  /// **'Encrypt'**
  String get encrypt;

  /// No description provided for @decrypt.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get decrypt;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectkeytype.
  ///
  /// In en, this message translates to:
  /// **'Select key type'**
  String get selectkeytype;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get new_password;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirm_password;

  /// No description provided for @password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords are mismatch'**
  String get password_mismatch;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @password_saved.
  ///
  /// In en, this message translates to:
  /// **'Password is saved'**
  String get password_saved;

  /// No description provided for @incorrect_password.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrect_password;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get try_again;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @selectafile.
  ///
  /// In en, this message translates to:
  /// **'Select a file'**
  String get selectafile;

  /// No description provided for @tkphoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get tkphoto;

  /// No description provided for @tkvideo.
  ///
  /// In en, this message translates to:
  /// **'Take a video'**
  String get tkvideo;

  /// No description provided for @tkrec.
  ///
  /// In en, this message translates to:
  /// **'Take a record'**
  String get tkrec;

  /// No description provided for @txtmsg.
  ///
  /// In en, this message translates to:
  /// **'Type a message . . .'**
  String get txtmsg;

  /// No description provided for @showmsg.
  ///
  /// In en, this message translates to:
  /// **'Show a message'**
  String get showmsg;

  /// No description provided for @pleaseselectkeytype.
  ///
  /// In en, this message translates to:
  /// **'Please, select a key type'**
  String get pleaseselectkeytype;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Fill all fields'**
  String get fillAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select a file'**
  String get selectFile;

  /// No description provided for @enterCipherText.
  ///
  /// In en, this message translates to:
  /// **'Enter cipher text...'**
  String get enterCipherText;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @takeVideo.
  ///
  /// In en, this message translates to:
  /// **'Take a video'**
  String get takeVideo;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record an audio'**
  String get recordAudio;

  /// No description provided for @typeMsg.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMsg;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connectionEstablished.
  ///
  /// In en, this message translates to:
  /// **'Connection established'**
  String get connectionEstablished;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @audioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio call'**
  String get audioCall;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get videoCall;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @noRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms'**
  String get noRooms;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @plsfill.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get plsfill;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check your credentials.'**
  String get loginFailed;

  /// No description provided for @autologinFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-login failed'**
  String get autologinFailed;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @keyfilenf.
  ///
  /// In en, this message translates to:
  /// **'Key file not found'**
  String get keyfilenf;

  /// No description provided for @stopRecord.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecord;

  /// No description provided for @loggedas.
  ///
  /// In en, this message translates to:
  /// **'You are logged in as'**
  String get loggedas;

  /// No description provided for @changepassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changepassword;

  /// No description provided for @adduser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get adduser;

  /// No description provided for @peopleSection.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleSection;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @failedToLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave room'**
  String get failedToLeaveRoom;

  /// No description provided for @youLeftRoom.
  ///
  /// In en, this message translates to:
  /// **'You left {roomName}'**
  String youLeftRoom(Object roomName);

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @ringing.
  ///
  /// In en, this message translates to:
  /// **'Ringing'**
  String get ringing;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @microphone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get microphone;

  /// Shown when receiving room events fails
  ///
  /// In en, this message translates to:
  /// **'Error receiving events: {error}'**
  String errorRoomEvents(String error);

  /// No description provided for @loadHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat history'**
  String get loadHistoryError;

  /// No description provided for @sendMessageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get sendMessageError;

  /// No description provided for @sendFileError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send file'**
  String get sendFileError;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @imagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'[image]'**
  String get imagePlaceholder;

  /// No description provided for @filePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'[file]'**
  String get filePlaceholder;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @updateYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updateYourPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @repeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get repeatNewPassword;

  /// No description provided for @pwStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get pwStrengthWeak;

  /// No description provided for @pwStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get pwStrengthFair;

  /// No description provided for @pwStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get pwStrengthGood;

  /// No description provided for @pwStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get pwStrengthStrong;

  /// No description provided for @pwMustInclude.
  ///
  /// In en, this message translates to:
  /// **'Password must include:'**
  String get pwMustInclude;

  /// No description provided for @pwAtLeastNChars.
  ///
  /// In en, this message translates to:
  /// **'At least {n} characters'**
  String pwAtLeastNChars(Object n);

  /// No description provided for @pwUpperLower.
  ///
  /// In en, this message translates to:
  /// **'Uppercase and lowercase letters'**
  String get pwUpperLower;

  /// No description provided for @pwAtLeastOneNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number'**
  String get pwAtLeastOneNumber;

  /// No description provided for @pwAtLeastOneSpecial.
  ///
  /// In en, this message translates to:
  /// **'At least one special character'**
  String get pwAtLeastOneSpecial;

  /// No description provided for @pwMustMeetRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must meet the requirements below'**
  String get pwMustMeetRequirements;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @logoutOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Log out on other devices'**
  String get logoutOtherDevices;

  /// No description provided for @newChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChatTitle;

  /// No description provided for @startChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChatTitle;

  /// No description provided for @userLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'User Login'**
  String get userLoginLabel;

  /// No description provided for @startChatButton.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChatButton;

  /// No description provided for @answeredelsewhere.
  ///
  /// In en, this message translates to:
  /// **'Answered on another device'**
  String get answeredelsewhere;

  /// No description provided for @enterLoginPlease.
  ///
  /// In en, this message translates to:
  /// **'Please enter a login'**
  String get enterLoginPlease;

  /// No description provided for @userNotFoundOnServer.
  ///
  /// In en, this message translates to:
  /// **'User not found on server'**
  String get userNotFoundOnServer;

  /// No description provided for @failedToCreateChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to create chat'**
  String get failedToCreateChat;

  /// No description provided for @warningCouldntUpdateDirectRooms.
  ///
  /// In en, this message translates to:
  /// **'Warning: couldn’t update direct rooms'**
  String get warningCouldntUpdateDirectRooms;

  /// No description provided for @saveFileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save file?'**
  String get saveFileQuestion;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @saveFileExplanation.
  ///
  /// In en, this message translates to:
  /// **'File saved temporary. Would you to save file to Downloads?'**
  String get saveFileExplanation;

  /// The message that the file was saved inserts the real path instead of {path}
  ///
  /// In en, this message translates to:
  /// **'File saved: {path}'**
  String fileSaved(String path);

  /// No description provided for @errorSavingFile.
  ///
  /// In en, this message translates to:
  /// **'Can\'t save file'**
  String get errorSavingFile;

  /// Подсказка к кнопке, Прикрепить файл
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get attach;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
