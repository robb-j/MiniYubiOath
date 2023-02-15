# Changelog

Notable features, fixes and updates are logged in this file.

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
