;;;; package.lisp

(defpackage webdriver-client
  (:use :cl :assoc-utils)
  (:nicknames :webdriver)
  (:export #:*default-capabilities*
           #:make-capabilities
           #:merge-capabilities
           #:chrome-capabilities
           #:firefox-capabilities

           #:webdriver-status

           #:make-session
           #:delete-session
           #:with-session
           #:use-session

           #:start-interactive-session
           #:stop-interactive-session

           #:key
           #:keys

           #:url
           #:back
           #:refresh
           #:page-title
           #:page-source

           #:find-element
           #:find-elements
           #:find-element-from-element
           #:find-elements-from-element
           #:active-element
           #:element-clear
           #:element-click
           #:element-displayed
           #:element-enabled
           #:element-rect
           #:element-send-keys
           #:element-id
           #:element-text
           #:element-tagname
           #:element-attribute

           ;; contexts
           #:get-window-handle
           #:get-window-handles
           #:close-window
           #:switch-to-window
           #:switch-to-frame
           #:new-window

           #:mouse-move-to
           #:mouse-click

           #:make-cookie
           #:cookie
           #:delete-cookie
           #:delete-all-cookies
           #:find-cookie

           #:log-types
           #:logs

           #:screenshot
           #:element-screenshot

           #:dismiss-alert
           #:accept-alert
           #:alert-text

           #:perform-actions

           #:execute-script

           #:no-such-element-error

           #:window-resize)
  (:import-from  #:alexandria
                 #:with-gensyms
                 #:assoc-value)
  (:documentation "This package exports functions for working with Selenium WebDriver.

For documentation see:
- https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
- https://www.w3.org/TR/webdriver1"))

(defpackage webdriver-client-utils
  (:use :cl :webdriver-client)
  (:export #:*timeout*
           #:*default-element-func*
           #:find-elem
           #:wait-for
           #:get-cookie
           #:elem
           #:attr
           #:id
           #:classname
           #:classlist
           #:text
           #:send-key
           #:send-keys
           #:click)
  (:import-from #:alexandria
                #:assoc-value
                #:rcurry)
  (:documentation "Package with the purpose of reducing boilerplate.

The exported definitions work with an implicit element. The default implicit element is the current active element. So, it is not neccesary to pass the element you are working with around most of the time.
"))

(defpackage webdriver-client-user
  (:nicknames :webdriver-user)
  (:use :cl :webdriver-client)
  (:import-from #:webdriver-client-utils
                #:send-keys
                #:click
                #:wait-for)
  (:documentation "User package for interacting with WebDriver (interactive session)."))
