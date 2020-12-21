//
//  LoginViewController.swift
//  TeleMed
//
//  Created by Shane Goodwin on 10/20/20.
//  Copyright © 2020 SolutionBuilt. All rights reserved.
//

import Foundation
import WebKit

class LoginViewController: CoreViewController {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var buttonBack: UIBarButtonItem!
    @IBOutlet weak var buttonCreateAccount: UIBarButtonItem! // Med2Med only; TEMPORARY
    @IBOutlet private weak var constraintToolbarBottom: NSLayoutConstraint!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var webView: WKWebView!
    
    var isLoading: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // Initialize web view and load the login page
        self.initializeWebView(webView: self.webView)
        self.startAuthentication(webView: self.webView)
        
        // Reset toolbar to the bottom of screen
        self.constraintToolbarBottom.constant = 0
        
        // Add reachability observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshWebView), name: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil)
        
        // Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop web view loading
        self.webView.stopLoading()
        
        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
	
        // Remove reachability observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    @IBAction func doLogin(_ sender: Any) {
        guard let url = webView.url else {
            return
        }
        
        // Trigger click on web view form's login button
        if url.absoluteString.contains("login.aspx") {
            self.webView.evaluateJavaScript("document.getElementById('loginButton').click();", completionHandler: nil)
        }
    }
    
    @IBAction func goBackWebView(_ sender: UIBarButtonItem) {
        self.webView.goBack()
    }
    
    @IBAction func refreshWebView(_ sender: UIBarButtonItem) {
        // If web view is loading, let it finish before refreshing again
        guard !self.isLoading else {
            return;
        }
        
        // Set is loading to true
        self.isLoading = true;
            
        // If web view is currently showing a blank screen or error message, then redirect to login page
        if self.webView.url?.absoluteString == "about:blank" {
            // Show loading screen
            self.updateWebViewLoading(true)
            
            // Delay is here is required because there is a slight delay between device going back online and requests actually going through
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.startAuthentication(webView: self.webView)
            }
            
        // Reload current page
        } else {
            self.webView.reload()
        }
    }
    
    private func hideKeyboardAccessoryView(view: UIScrollView) {
        // Simpler solution for iOS 13+: https://stackoverflow.com/questions/33853924/removing-wkwebview-accesory-bar-in-swift/58001395#58001395
        
        // Solution from https://stackoverflow.com/questions/33853924/removing-wkwebview-accesory-bar-in-swift/47553034#47553034
        guard let target = view.subviews.first(where: {
                String(describing: type(of: $0)).hasPrefix("WKContent")
            }),
            let superClass = target.superclass else {
            return
        }
        
        let noInputAccessoryViewClassName = "\(superClass)_NoInputAccessoryView"
        var newClass: AnyClass? = NSClassFromString(noInputAccessoryViewClassName)

        if newClass == nil, let targetClass = object_getClass(target), let classNameCString = noInputAccessoryViewClassName.cString(using: .ascii) {
            newClass = objc_allocateClassPair(targetClass, classNameCString, 0)

            if let newClass = newClass {
                objc_registerClassPair(newClass)
            }
        }

        guard let noInputAccessoryClass = newClass,
            let originalMethod = class_getInstanceMethod(InputAccessoryHackHelper.self, #selector(getter: InputAccessoryHackHelper.inputAccessoryView)) else {
            return
        }
        
        class_addMethod(noInputAccessoryClass.self, #selector(getter: InputAccessoryHackHelper.inputAccessoryView), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        object_setClass(target, noInputAccessoryClass)
    }
    
    private func initializeWebView(webView: WKWebView) {
        // Set WKWebView delegates
        self.webView.navigationDelegate = self
        self.webView.scrollView.delegate = self
        
        // Hide keyboard accessory view for WKWebView text fields
        self.hideKeyboardAccessoryView(view: webView.scrollView)
        
        // Disable scrolling in web view for screens taller than 480
        if UIScreen.main.bounds.size.height > 480 {
            webView.scrollView.isScrollEnabled = false
        
        // Disable horizontal scrolling in web view for screens 480 or less in height
        } else {
            webView.scrollView.showsHorizontalScrollIndicator = false
        }
        
        // Inject CSS styles into web view
        let cssStyles = loadFileAsString(name: "login", type: "css").replacingOccurrences(of: "\n", with: "")
        let cssInjection = """
            var style = document.createElement('style');
            style.innerHTML = '\(cssStyles)';
            document.head.appendChild(style);
        """
        let cssUserScript = WKUserScript(source: cssInjection, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        webView.configuration.userContentController.addUserScript(cssUserScript)
        
        // Inject meta viewport into web view
        let metaViewportInjection = """
            var metaViewport = document.createElement('meta');
            metaViewport.setAttribute('name', 'viewport');
            metaViewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0');
            document.head.appendChild(metaViewport);
        """
        let metaViewportUserScript = WKUserScript(source: metaViewportInjection, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        webView.configuration.userContentController.addUserScript(metaViewportUserScript)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        // Animate keyboard to bottom of view
        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: UIView.AnimationCurve(rawValue: animationCurve)!) {
            self.constraintToolbarBottom.constant = 0
            self.view.layoutIfNeeded()
        }
        
        animator.startAnimation()
        
        // Reset scroll position of webview
        self.webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        let safeArea = UIApplication.shared.keyWindow?.safeAreaInsets
        
        // Animate toolbar above keyboard
        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: UIView.AnimationCurve(rawValue: animationCurve)!) {
            self.constraintToolbarBottom.constant = keyboardFrame.size.height - (safeArea?.bottom ?? 0)
            self.view.layoutIfNeeded()
        }
        
        animator.startAnimation()
    }
    
    // Load asset file and return it as a string
    private func loadFileAsString(name: String, type: String) -> String {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            return ""
        }
        
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        
        } catch {
            return ""
        }
    }
    
    func showWebViewError(errorMessage: String) {
        // Hide loading screen
        self.updateWebViewLoading(false)
        
        let errorHTML = "<div style=\"margin: 50px 10px 0; color: #fff; font-size: 16px;\"><p>\(errorMessage)</p><p>Please check your network connection and press the refresh button below to try again.</p></div>"
        
        self.webView.loadHTMLString(errorHTML, baseURL: nil)
    }
    
    private func startAuthentication(webView: WKWebView) {
        // Set is loading to true
        self.isLoading = true
        
        // Clear web view cache and cookies
        WKWebView.clearBrowsingData()
        
        // Load authentication url
        let fullURL = "\(Config.authenticationBaseUrl)Authentication?idp=\(SSOProviderModel().name!)&aud=\(Config.authenticationAudience)"
        
        print("Login URL: \(fullURL)")
         
        let url = URL(string: fullURL)
        let urlRequest = URLRequest(url: url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: Config.urlRequestTimeoutPeriod)
        
        webView.load(urlRequest)
        
        // Show loading screen
        self.updateWebViewLoading(true)
    }
    
    private func updateWebViewLoading(_ isLoading: Bool) {
        // Speed up toggling the loading screen by forcing it to execute in main thread
        DispatchQueue.main.async {
            // Toggle activity indicator
            if isLoading {
                self.activityIndicator.startAnimating()
                
            } else {
                self.activityIndicator.stopAnimating()
            }
            
            // Toggle loading view container
            self.loadingView.isHidden = !isLoading
            
            // Toggle web view
            self.webView.isHidden = isLoading
            
            // Toggle back button
            self.buttonBack.isEnabled = self.webView.canGoBack
        }
    }
}


// MARK: UIScrollViewDelegate
extension LoginViewController: UIScrollViewDelegate {
    
    // Prevent horizontal scroll in web view
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
        }
    }
}


// MARK: WKNavigationDelegate
extension LoginViewController: WKNavigationDelegate {
    
    // Called when web content begins to load in a web view.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start WebView Navigation for: \(webView.url?.absoluteString ?? "")")
        
        // Show loading screen
        self.updateWebViewLoading(true)
        
        // Set is loading to true
        self.isLoading = true
        
        // Reset scroll position of webview
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    // Called when an error occurs during navigation.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView Navigation Error: \(error)")
        
        let errorCode = (error as NSError).code
	
        // Set is loading to false
        self.isLoading = false
        
        // Prevent showing an error after navigation is cancelled during decidePolicyFor navigationResponse
        if errorCode == 102 {
            return
        }
        
        self.showWebViewError(errorMessage: "There was a problem loading the login page:<br>\(error.localizedDescription)")
    }
    
    // Called when an error occurs while the web view is loading content.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView Provisional Navigation Error: \(error)")
        
        self.webView(webView, didFail: navigation, withError: error)
    }
    
    // Called when the navigation is complete.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        
        print("Finish WebView Navigation for: \(url.absoluteString)")
        
        // URL is the login screen
        if url.absoluteString.contains("login.aspx") {
            let settings = UserDefaults.standard
            
            // Prevent users from being able to go back to about:blank
            self.buttonBack.isEnabled = false
            
            // Display the reason for application log out (if any)
            if settings.object(forKey: Config.reasonApplicationDidLogout) != nil {
                let errorMessage = settings.value(forKey: Config.reasonApplicationDidLogout)!
                let javascriptErrorMessage = """
                    var errorMessageContainer = document.getElementById('lblGlobalAlert');
                    var logoRow = document.getElementById('toplogorow');
                    var errorMessageStyle = 'color: white; display: block; font-size: 13px; font-weight: bold; padding-bottom: 8px;';
                    
                    // If the error message container already exists
                    if (errorMessageContainer) {
                        errorMessageContainer.style.cssText = errorMessageStyle;
                        errorMessageContainer.textContent = '\(errorMessage)';
                    
                    // If the logo row exists, then insert a new row with the error message container after it
                    } else if (logoRow) {
                        errorMessageContainer = document.createElement('tr');
                        
                        errorMessageContainer.innerHTML = '<td colspan=\"2\"><span id=\"lblGlobalAlert\" style=\"' + errorMessageStyle + '\">\(errorMessage)</span></td>';
                        
                        logoRow.parentNode.insertBefore(errorMessageContainer, logoRow.nextSibling);
                    
                    // Fall back to showing an alert message
                    } else {
                        alert('\(errorMessage)');
                    }
                """
                
                webView.evaluateJavaScript(javascriptErrorMessage)
                
                // Reset the reason for application log out
                settings.removeObject(forKey: Config.reasonApplicationDidLogout)
                settings.synchronize()
            }
            
            // Debug mode login shortcuts
            #if DEBUG
                var javascriptLogin = """
                    var loginButton = document.getElementById('loginButton');
                    var password = document.getElementById('passwordTextBox');
                    var userName = document.getElementById('userNameTextBox');
                    
                    // Auto-populate form if value matches shortcut value
                    var autoPopulate = function(event) {
                        switch (userName.value) {
                            case 'b': case 'bturner': userName.value = 'bturner'; password.value = '%@'; break;
                            case 'j': case 'jhutchison': userName.value = 'jhutchison'; password.value = '%@'; break;
                            case 'm': case 'mattrogers': userName.value = 'mattrogers'; password.value = '%@'; break;
                            case 's': case 'shanegoodwin': userName.value = 'shanegoodwin'; password.value = '%@'; break;
                        }
                    };
                    
                    /* Convert input text to a dropdown (not supported until UIWebView converted to WKWebView)
                    const dataList = document.createElement('datalist'); dataList.setAttribute('userNameDataList');
                    ['shanegoodwin', 'bturner', 'jhutchison', 'mattrogers'].forEach(function(userName) {
                        var option = document.createElement('option');
                        option.value = userName;
                        dataList.appendChild(option);
                    });
                    userName.setAttribute('userNameDataList');
                    userName.parentNode.insertBefore(dataList, userName.nextSibling);*/
                    
                    // Update username placeholder to remind me of shortcut
                    userName.setAttribute('placeholder', 'User Name 1st Letter');
                    
                    // Add event on username to auto-populate form on blur if value matches shortcut value
                    userName.addEventListener('blur', autoPopulate);
                    
                    // Add event on login button to auto-populate form on click if value matches shortcut value
                    var doLogin = loginButton.onclick;
                    loginButton.addEventListener('click', function(event) {
                        autoPopulate(event);
                        doLogin(event);
                    });
                    
                    // Add event on username to automatically submit form when enter key pressed
                    userName.addEventListener('keypress', function(event) {
                        if (event.code == 'Enter' && userName.value.length == 1) {
                            userName.blur();
                        }
                    });
                """
                
                javascriptLogin = String(format: javascriptLogin,
                    // Passwords
                    "passw0rd", // bturner
                    "passw0rd", // jhutchison
                    "tm4321$$", // mattrogers
                    "tmd4321$$" // shanegoodwin
                )
                
                webView.evaluateJavaScript(javascriptLogin)
            #endif
        
        // URL is a blank screen
        } else if url.absoluteString == "about:blank" {
            // Prevent users from being able to go back to about:blank
            self.buttonBack.isEnabled = false
        }
        
        // Hide loading screen
        self.updateWebViewLoading(false)
        
        // Set is loading to false
        self.isLoading = false
    }

    // Decides whether to allow or cancel a navigation after its response is known.
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let url = webView.url else {
            return
        }
        
        print("Decide Response Policy for: \(url.absoluteString)")
        
        let successPageUrl = "\(Config.authenticationBaseUrl)\(Config.authenticationCallbackPage)"
        
        // If current url is for the success page, then extract the tokens from the response headers
        if url.absoluteString.hasPrefix(successPageUrl) {
            guard let response = navigationResponse.response as? HTTPURLResponse,
                let accessToken = response.allHeaderFields["X-TeleMed-AccessToken"] as? String,
                let refreshToken = response.allHeaderFields["X-TeleMed-RefreshToken"] as? String,
                let authenticationModel = AuthenticationModel.sharedInstance() else {
                self.showWebViewError(errorMessage: "There was a problem completing the login process.")
                
                decisionHandler(.cancel)
                
                return
            }
            
            print("Access Token: \(accessToken)")
            print("Refresh Token: \(refreshToken)")
            
            authenticationModel.accessToken = accessToken
            authenticationModel.refreshToken = refreshToken
            
            // Finalize authentication can occasionally get stuck in background thread, so force it to execute in main thread
            DispatchQueue.main.async {
                self.finalizeAuthentication()
            }
            
            decisionHandler(.cancel)
            
            return
        }
        
        decisionHandler(.allow)
    }
}

extension WKWebView {

    class func clearBrowsingData() {
        // Clear cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // Clear cache
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date.distantPast, completionHandler: {})
    }
}

// Used for hiding keyboard accessory view
fileprivate final class InputAccessoryHackHelper: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}
