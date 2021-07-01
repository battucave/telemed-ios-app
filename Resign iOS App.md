### How to Re-sign iOS App with a New Certificate ###

1. Log in to [Apple Developer Center](https://developer.apple.com/membercenter/).
2. Renew the "TeleMed Inc Distribution" certificate on the [Certificates](https://developer.apple.com/account/resources/certificates/add) tab.
	* Download and install the new certificate on a Mac by opening it with Keychain Access.
3. Add new devices on the [Devices](https://developer.apple.com/account/resources/devices/add) tab.
4. Open the [Profiles](https://developer.apple.com/account/resources/profiles/list) tab and edit the existing "MyTeleMed Ad Hoc" provisioning profile.
	1. Review the Devices list and enable any new devices.
	2. Download the provisioning profile on a Mac and note its location.
5. Locate the existing IPA file that needs to be resigned. Navigate to it in command line.
	* Note: All IPA files are uploaded to SolutionBuilt's Nextcloud server. The IPA files for MyTeleMed are located at:  
	  `Common/_Active Clients/TeleMed/IPAs/MyTeleMed/Beta`
6. Unzip the IPA file:  
	`$ unzip {FILE NAME}.ipa`
7. Remove the existing code signature:  
	`$ rm -rf Payload/MyTeleMed\ β.app/_CodeSignature/`
8. Replace the existing provisioning profile with the new one:  
	`$ cp {PATH TO DOWNLOADED PROFILE}/MyTeleMed\ Ad\ Hoc.mobileprovision Payload/MyTeleMed\ β.app/embedded.mobileprovision`  
9. Update the version number and/or build number:  
	1. Open "Payload/MyTeleMed β.app/Info.plist" using XCode.
		* Note: Right-click and choose "Show Package Contents" to get into the Summerset.app file.
	2. Update the "Bundle versions string, short" to update the version number.
	3. Update the "Bundle version" to update the build number.
	4. Save the file.
10. Extract the entitlements from the app:  
	`$ codesign -d --entitlements :entitlements.plist Payload/MyTeleMed\ β.app/`
11. Verify the certificate name to use for code signing:  
	`$ security find-identity`  
	The name of the certificate is the valid identity in quotes with or without the Team ID parentheses.  
	Current certificate name: "Apple Distribution: TeleMed Inc. (FLMB52V94K)"
12. Re-sign the new app using the new distribution certificate:  
	`$ codesign -f -s "Apple Distribution: TeleMed Inc. (FLMB52V94K)" --entitlements entitlements.plist Payload/MyTeleMed\ β.app` 
13. Compress the payload as a new IPA file:  
	`$ zip -qr MyTeleMed\ β\ v{VERSION NUMBER}\ -\ Build\ {BUILD NUMBER}.ipa Payload/`
14. Distribute the new IPA file through TestFairy.


### How to Re-sign iOS App with a New UDID ###
1. Follow steps 1 - 7 in the *How to Re-sign iOS App with a New Certificate* section, skipping step 2 (renew certificate).
2. Skip step 8 (replace provisioning profile). Instead:  
	1. Open "Payload/MyTeleMed β.app/embedded.mobileprovision" in a text editor.
	2. Search for "ProvisionedDevices".
	3. Add the new device UDID into the list of provisioned devices with the appropriate "<string>" formatting.
	4. Save the file.
3. Continue with the rest of the steps.


#### Additional Documentation/Examples: ####

* [https://coderwall.com/p/dgdgeq/how-to-re-sign-ios-builds](https://coderwall.com/p/dgdgeq/how-to-re-sign-ios-builds)  
* [https://stackoverflow.com/questions/53302781/resigned-ipa-do-not-install-on-ios-devices](https://stackoverflow.com/questions/53302781/resigned-ipa-do-not-install-on-ios-devices)
