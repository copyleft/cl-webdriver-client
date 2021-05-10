(in-package :cl-selenium)

(defun (setf url) (url &key (session *session*))
  "The command causes the user agent to navigate the current top-level browsing context to a new location.
See: https://www.w3.org/TR/webdriver1/#dfn-navigate-to ."
  (http-post-value (session-path session "/url") `(:url ,url)))

(defun url (&key (session *session*))
  "Get the current url in session.
See: https://www.w3.org/TR/webdriver1/#dfn-get-current-url ."
  (http-get-value (session-path session "/url")))

(defun back (&key (session *session*))
  "This command causes the browser to traverse one step backward in the joint session history of the current top-level browsing context. This is equivalent to pressing the back button in the browser chrome or invoking window.history.back.
See: https://www.w3.org/TR/webdriver1/#dfn-back ."
  (http-post-check (session-path session "/back")))

(defun page-title (&key (session *session*))
  "This command returns the document title of the current top-level browsing context, equivalent to calling document.title. 
See: https://www.w3.org/TR/webdriver2/#get-title ."
  (http-get-value (session-path session "/title")))

(defclass element ()
  ((id :initarg :id
       :initform (error "Must supply :id")
       :reader element-id)))

(defmethod print-object ((element element) stream)
  (with-slots (id) element
    (format stream
            "#<cl-selenium::element {id:~a} id=~a>"
            id
            (element-attribute element "id"))))

(defun handle-find-error (err &key value by)
  "Signal the correct type of error depending on PROTOCOL-ERROR-STATUS."
  (error
   (case (protocol-error-status err)
     (7 (make-instance 'no-such-element-error :value value :by by))
     (10 (make-instance 'stale-element-reference :value value :by by))
     (t err))))

(defun find-element (value &key (by :css-selector) (session *session*))
  "The Find Element command is used to find an element in the current browsing context that can be used as the web element context for future element-centric commands.

For example, consider this pseudo code which retrieves an element with the #toremove ID and uses this as the argument for a script it injects to remove it from the HTML document:

let body = session.find.css(\"#toremove\");
session.execute(\"arguments[0].remove()\", [body]);

The BY parameter represents the element location strategy.

It can be one of:
- :id : Finds element by id.
- :class-name : Finds element by class name.
- :css-selector : Returns element that matches css selector.
- :link-text : Returns element that matches <a> element text.
- :partial-link-text: Returns element that matches <a> element text partially.
- :tag-name: Returns element that matches tag name.
- :xpath: Returns element that matches the XPath expression.

If result is empty, a HANDLE-FIND-ERROR is signaled.

See: https://www.w3.org/TR/webdriver1/#dfn-find-element ."
  (handler-case
      (let ((response (http-post (session-path session "/element") `(:value ,value :using ,(by by)))))
        ;; TODO: find/write json -> clos
        (if (= 0 (cdr (assoc :status response)))
            (make-instance 'element
                           :id (cdadr (assoc :value response)))
            (error 'protocol-error :body response)))
    (protocol-error (err) (handle-find-error err :value value :by by))))

(defun find-elements (value &key (by :css-selector) (session *session*))
  "Find elements that match VALUE using location strategy in BY.
See FIND-ELEMENT.
See https://www.w3.org/TR/webdriver1/#find-elements ."
  (handler-case
      (let ((response (http-post (session-path session "/elements") `(:value ,value :using ,(by by)))))
        (loop for ((nil . id)) in (cdr (assoc :value response))
              collect (make-instance 'element :id id)))
    (protocol-error (err) (handle-find-error err :value value :by by))))

(deftype element-location-strategy ()
  "An element location strategy is an enumerated attribute deciding what technique should be used to search for elements in the current browsing context.
See: https://www.w3.org/TR/webdriver1/#dfn-strategy ."
  `(member
    :id
    :xpath :link-text
    :partial-link-text :name :tag-name
    :class-name :css-selector))

(defun by (type)
  "An element location strategy is an enumerated attribute deciding what technique should be used to search for elements in the current browsing context.
See: https://www.w3.org/TR/webdriver1/#dfn-strategy ."
  (ecase type
    (:id "id")
    (:xpath "xpath")
    (:link-text "link text")
    (:partial-link-text "partial link text")
    (:name "name")
    (:tag-name "tag name")
    (:class-name "class name")
    (:css-selector "css selector")))

(defun active-element (&key (session *session*))
  "Return the active element of the current browsing context’s document.
The active element is the Element within the DOM that currently has focus.
If there's no active element, an error is signaled.

See: https://www.w3.org/TR/webdriver2/#get-active-element.
See: https://developer.mozilla.org/en-US/docs/Web/API/Document/activeElement."
  (make-instance 'element
                 :id (cdadr (assoc :value (http-post (session-path session "/element/active"))))))

(defun element-clear (element &key (session *session*))
  "Clear the contents of ELEMENT (for example, a form field element).

See: https://www.w3.org/TR/webdriver1/#dfn-element-clear."
  (http-post-check (session-path session "/element/~a/clear" (element-id element))))

(defun element-send-keys (element keys &key (session *session*))
  "The Element Send Keys command scrolls into view the form control element and then sends the provided keys to the element. In case the element is not keyboard-interactable, an element not interactable error is returned.

See: https://www.w3.org/TR/webdriver1/#element-send-keys ."
  (check-type keys (string))
  (http-post-check (session-path session "/element/~a/value"
                                 (element-id element))
                   `(:value ,(coerce keys 'list))))

(defun element-click (element &key (session *session*))
  "The Element Click command scrolls into view the element if it is not already pointer-interactable, and clicks its in-view center point.

If the element’s center point is obscured by another element, an element click intercepted error is returned. If the element is outside the viewport, an element not interactable error is returned.

See: https://www.w3.org/TR/webdriver1/#element-click ."
  
  (http-post-check (session-path session "/element/~a/click"
                                 (element-id element))))

(defun element-text (element &key (session *session*))
  "The Get Element Text command intends to return an element’s text “as rendered”. An element’s rendered text is also used for locating a elements by their link text and partial link text.

See: https://www.w3.org/TR/webdriver1/#get-element-text ."
  
  (http-get-value (session-path session "/element/~a/text" (element-id element))))

(defun element-displayed (element &key (session *session*))
  "Returns T if ELEMENT is visible.

See: https://www.w3.org/TR/webdriver1/#element-displayedness ."
  (http-get-value (session-path session "/element/~a/displayed" (element-id element))))

(defun element-location (element &key (session *session*))
  "Return the ELEMENT's location."
  (http-get-value (session-path session "/element/~a/location" (element-id element))))

(defun element-tagname (element &key (session *session*))
  "Return the ELEMENT's tag name."
  (http-get-value (session-path session "/element/~a/name" (element-id element))))

(defun element-attribute (element name &key (session *session*))
  "Return the ELEMENT's attribute named NAME."
  (http-get-value (session-path session "/element/~a/attribute/~a" (element-id element) name)))

(defun log-types (&key (session *session*))
  "Return the types of logs supported by the WebDriver.

- browser: Javascript console logs from the browser.
- client: Logs from the client side implementation of the WebDriver protocol (e.g. the Java bindings).
- driver: Logs from the internals of the driver (e.g. FirefoxDriver internals).
- performance: Logs relating to the performance characteristics of the page under test (e.g. resource load timings).
- server: Logs from within the selenium server.

See: https://github.com/SeleniumHQ/selenium/wiki/Logging ."
  (http-get-value (session-path session "/log/types")))

(defun logs (type &key (session *session*))
  "Return the logs of a particular TYPE.
See: LOG-TYPES."
  (http-post-value (session-path session "/log") `(:type ,type)))

(defun screenshot (&key (session *session*))
  "Screenshots are a mechanism for providing additional visual diagnostic information. They work by dumping a snapshot of the initial viewport’s framebuffer as a lossless PNG image. It is returned to the local end as a Base64 encoded string.

See: https://www.w3.org/TR/webdriver2/#screen-capture ."
  (http-get-value (session-path session "/screenshot")))

(defclass cookie ()
  ((name :initarg :name)
   (value :initarg :value)
   (path :initarg :path)
   (domain :initarg :domain)
   (secure :initarg :secure)
   (expiry :initarg :expiry)))

(defun make-cookie (name value &key path domain secure expiry)
  (make-instance 'cookie
                 :name name
                 :value value
                 :path path
                 :domain domain
                 :secure secure
                 :expiry expiry))

(defun (setf cookie) (cookie &key (session *session*))
  "Create a cookie in the cookie store associated with the active document’s address using cookie name name, cookie value value, and an attribute-value list of the following cookie concepts listed in the table for cookie conversion from data:

If there is an error during this step, return error with error code unable to set cookie. 

See: https://www.w3.org/TR/webdriver1/#dfn-adding-a-cookie ."
  (check-type cookie cookie)
  (http-post-check (session-path session "/cookie") `(:cookie ,cookie)))

(defun cookie (&key (session *session*))
  "Retrieve all cookies visible to the current page.

See: https://www.w3.org/TR/webdriver1/#get-all-cookies .
See: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidcookie ."
  (http-get-value (session-path session "/cookie")))

(defun refresh (&key (session *session*))
  "Refresh the current page."
  (http-post (session-path session "/refresh")))

(defun switch-to-frame (id &key (session *session*))
  "Change focus to another frame on the page. If the frame id is null, the server
should switch to the page's default content.

In the context of a web browser, a frame is a part of a web page or browser window which displays content independent of its container, with the ability to load content independently.

See: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidframe .
See: https://en.wikipedia.org/wiki/Frame_(World_Wide_Web) ."
  (http-post-check (session-path session "/frame")
                   `(:id ,id)))

(defun close-current-window (&key (session *session*))
  "Close the current window."
  (http-delete (session-path session "/window")))

(defun execute-script (script args &key (session *session*))
  "Inject a snippet of JavaScript into the page for execution in the context of the currently selected frame. The executed script is assumed to be synchronous and the result of evaluating the script is returned to the client.

The script argument defines the script to execute in the form of a function body. The value returned by that function will be returned to the client. The function will be invoked with the provided args array and the values may be accessed via the arguments object in the order specified.

Arguments may be any JSON-primitive, array, or JSON object. JSON objects that define a WebElement reference will be converted to the corresponding DOM element. Likewise, any WebElements in the script result will be returned to the client as WebElement JSON objects.

See: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidexecute ."
  (check-type script string)
  (check-type args list)
  (http-post-value (session-path session "/execute")
                   `(:script ,script :args ,(or args #()))))
