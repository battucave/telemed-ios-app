# Premedicus App

Description:

 * The App is a hybrid app that uses Cordova (v5.3.3) to wrap HTML5 + CSS + JS for installation on mobile devices
 * Currently, the only platform is Android (cordova platform android v4.1.1)
 * The Webservice is built using PHP and the CodeIgniter framework (v2.2.3)
 * The Database is MySQL


### Steps to run the project on local machine:

The repo doesn't contain the plugins nor the platforms. Run the following to add these to your local project:
```
git clone https://bitbucket.org/premedicus/premedicus.git
cd premedicus/cordova
sh install-plugins.sh
```

If the project doesn't compile:
```
cordova build android
```

Update necessary packages using android package manager:
```
android update sdk --no-ui
```

Check the latest Android SDK tools



### App config options:

The main file for config the cordova app is located at
> cordova/www/js/Config.js

These are the most important configurable options for the app:

+ Google map api key
```
Config.maps_key = 'AIzaSyBbMiEvs-T07FM65SYIeBJAEgozhR5H-DE';
```
+ Google Analytics account
```
Config.analytics_account = 'UA-68764195-1';
```
+ The url for the app at playstore
```
Config.google_play_url="market://details?id=com.premedicus.app";
```

### Steps for publishing the app:

1 - Set up Config.js as release version:
```
Config.development = false;
```

Important! Config.version is a string and is used to compare with the webservice value (version.txt).
  If the version.txt is different than this one, then the user will be prompted to update app.
```
Config.version =  "1.1.2";
```


2 - Update app versions in config.xml:

* cordova/config.xml

Update the version to the same version from Config.version above and increment the android-versionCode up by 1:
```
<widget id="com.premedicus.app" version="1.1.2" android-versionCode="1000109"
```


3 - Secure necessary js files using [JScrambler] at http://jscrambler.com. Use client's account. The recommended files to scramble are:

* cordova/www/js/Config.js
* cordova/www/js/App/components/AlgorithmLegend.js
* cordova/www/js/App/services/http.js
* cordova/www/js/App/services/resources.js

The options to use in JScrambler are:  

* source code protection (encrypted)
* mobile project
* don't lock app for specific domain
* don't expire the app at specific time

Place the encrypted AlgorithmLegend.js, http.js, and resources.js files in the following directory:  
```
www/js/App/build/jscrambler/
```
And simply replace the Config.js file with the encrypted version.


NOTE: To save money, client has downgraded to free version of JScrambler. As such, the only files that are REQUIRED to be scrambled are:

* cordova/www/js/App/components/AlgorithmLegend.js
* cordova/www/js/App/services/resources.js

Until these files change, continue to use the previously generated encrypted files and simply use the unscrambled versions of Config.js and http.js (both of which have changed since the last successful scramble).
This will involve temporarily editing the following files to point the http.js file to the correct path:

* cordova/www/js/App.js
* cordova/www/js/App/build/App-build.js

The path to temporarily point to is:
```
js/App/services/http.js
```

  
4 - Compile the javascript into one file using build.sh, removing development-only plugins. The developer must have installed:
node.js and r.j, instructions at http://requirejs.org/docs/optimization.html
```
$cd {root_repo}/cordova
$sh www/js/App/build/build.sh  
```

The paths of the output file is: (this includes the encrypted files)  
+ www/js/premedicus.app.min.js  

Delete the following directory and dev files:
```
$rm -Rf www/js/App
$rm -Rf www/js/libs
```


5 - Locate or generate a new keystore:
It will be located on SolutionBuilt's coderepo drive under _misc/Certificates/Android/Signed Android Keys/PreMedicus/premedicus.keystore

If the file doesn't exist, create it using the following:
```
$keytool -genkey -v -keystore premedicus.keystore -alias premedicus -keyalg RSA -keysize 2048 -validity 10000
```

And store it in the following locations:

+ The location on SolutionBuilt's coderepo drive referenced above
+ In the project itself: cordova/build_assets/android


6 - Build the Cordova APK file
```
$cordova build android --release
```

A signed APK file should automatically be generated using the cordova/hooks/after_prepare_copy_android_build_assets.js and cordova/build_assets/android/release-signing.properties files.
The APK file will be located in platforms/android/build/outputs/apk. There should be 2 files: android-release.apk and android-release-unsigned.apk.
If android-release.apk does not exist, then we will have to manually sign the unreleased version:
```
$jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore cordova/build_assets/android/premedicus.keystore platforms/android/build/outputs/apk/android-release-unsigned.apk premedicus -signedjar android-release-unaligned.apk
$jarsigner -verify -verbose -certs -keystore cordova/build_assets/android/premedicus.keystore android-release-unaligned.apk
$$ANDROID_HOME/build-tools/21.1.2/zipalign -v 4 android-release-unaligned.apk android-release.apk
```

Upload the android-release.apk file to the store


7 - Revert the deleted files
```
$cd ../
$git checkout -- cordova/www/js/App # revert deleted files
git checkout -- cordova/www/js/Config.js # revert deleted files
git checkout -- cordova/www/js/Config.*.js # revert deleted files
git tag [verion_num] # new app version 
git push origin --tags #send the new tag to repo
```


Keep working :-)


8 - After the app has been approved and published in the Google Play store, update the server to return new version:

* webservice/version.txt

Update the value in this file to the new version from Config.js and publish to web server:

* /var/www/html/webservice/version.txt
