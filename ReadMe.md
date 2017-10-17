# MyTeleMed App

Description:

 * The MyTeleMed iPhone app allows doctors to securely manage their important medical messages with HIPAA Compliance by protecting any Personal Health Information (PHI).


### Steps to run the project on local machine:

Open the following file:
> iOS/MyTeleMed.xcodeproj



### How to test push notifications:

TeleMed's test and production servers both send push notifications through Apple's production server. Only apps signed with Ad Hoc or Distribution provisioning profiles can receive these notifications - not Debug. Additionally, apps will only receive push notifications sent through Apple's production server if they were installed via IPA file (TestFairy or App Store).
However, the Mac app "APN Tester Free" provides a way to test push notifications to all schemes - even Debug.

##### How to use APN Tester Free:
1. Find/generate a Production "Apple Push Notification service SSL (Sandbox & Production)" certificate through Apple's developer portal. A unique certificate will need to be generated for each app id to be tested. SolutionBuilt has these files saved internally on our network drive at *coderepo/_misc/Certificates & Keys/iOS/Certificates (CER)* (Debug certificates in *Development* and Ad Hoc / Production certificates in *Production*).  
2. To test the Debug app, use the "MyTeleMed" scheme. To test the Beta app, use "MyTeleMed Ad Hoc" scheme.
3. Generate a device token by registering the app with TeleMed. Must use an actual device.  
	* If the app is already installed on device, delete it first so that it can re-register its device token.  
	* Run the app in either Debug or Ad Hoc mode from XCode.  
	* In the console look for "My Device Token <pattern of alphanumeric characters>".
	* Copy the string starting with "<" and ending with ">".  
4. Continue with app registration process by logging in and entering phone number.  
5. Use the following settings for APN Tester Free:  
	* Device Token: copied device token from previous step.  
	* Payload: Sample payloads can be found in AppDelegate.m's *didReceiveRemoteNotification* method.  
	* Certificate: unique certificate created in step 1 corresponding to the scheme you want to test.  
	* Gateway: Development (always use Development for testing).  
5. Press "Push".

##### How to test Release Version:
Its difficult to test the release version. Only known way is to change the Beta version's bundle identifier to "com.solutionbuilt.telemed" and BASE_URL to "https://www.mytelemed.com". These can both be found in the project's "Build Settings". Then run the app using the Ad Hoc scheme and follow the APN Tester Free instructions for testing Beta app.
