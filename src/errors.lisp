(in-package :webdriver-client)

(define-condition protocol-error (error)
  ((body :initarg :body :reader protocol-error-body)
   (status :initarg :status :reader protocol-error-status)))

(defun protocol-error-error (error)
  (assoc-value (assoc-value (protocol-error-body error) :value) :error))

(defmethod print-object ((error protocol-error) stream)
  (with-slots (body) error
    (format stream
            "[~a]~%error: ~a~%status: ~a~%state: ~a~%~%~a~%"
            (type-of error)
            (protocol-error-error error)
            (protocol-error-status error)
            (assoc-value body :state)
            (assoc-value (assoc-value body :value) :message))))

(define-condition find-error (error)
  ((value :initarg :value)
   (by :initarg :by)))

(define-condition no-such-element-error (find-error)
  ()
  (:report (lambda (condition stream)
             (with-slots (value by) condition
               (format stream "No such element: ~a (by ~a)" value by))))
  (:documentation "Error signaled when no such element is found."))

(define-condition stale-element-reference (find-error)
  ()
  (:report (lambda (condition stream)
             (with-slots (value by) condition
               (format stream "Stale element reference: ~a (by ~a)" value by)))))
