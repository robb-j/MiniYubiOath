# Changelog

Notable features, fixes and updates are logged in this file.

## 1.0.0

Major version release, no changes just stabilisation!

## 0.4.0

Yoath communicates more intelligently than before. It uses more optimal smartcard commands to only fetch the data it needs. To fetch accounts it only lists the accounts and doesn't calculate codes which are unised. To fetch a code it only fetches the specific code it needs, rather than fetching all of them then picking the one it needs from those.

* Fixed a bug where the wrong code was selected if there were multiple credentials with the same account (e.g. same email address)
* Fixed a bug where only the first code was calculated when selecting from credentials with the same isser  

## 0.3.0

Yoath communicates with the YubiKey a lot less now. It will grab accounts on first load or when a new card is inserted, then Yoath will only fetch codes on demand after that. There is a new "refresh accounts" button to reload the accounts if you have added them since plugging in the device. 

* Improve first-connection, adds a short delay after plugging in before fetching codes
* Improved the menubar icon on non-retina screens.

## 0.2.0

* Add "Get help" menu option to start a GitHub issue
* Add "Open Yubico Authenticator" menu option (when it is installed) to open that app
* Refresh state whenever Smart Cards are inserted or remove

## 0.1.0

🎉 Everything is new!
