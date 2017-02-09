(define error-type 1)

(define (format-restart restart)
  (let ((report (open-output-string)))
    (write-restart-report restart report)
    (list
      (restart/name restart)
      (get-output-string report)
      (procedure-arity-min (procedure-arity (restart/effector restart))))))

(define (restarts->json restarts)
  (array->json (map format-restart restarts)))

(define (condition-handler condition)
  (define restarts (condition/restarts condition))
  (define report (condition/report-string condition))
  (*send* error-type (string->json report) (restarts->json restarts) (stack->json))
  (let iter ((invocation (prompt-for-command-expression "" *stdio*)))
    (apply invoke-restart
      (if (number? (car invocation))
        (list-ref restarts (car invocation))
        (find
          (lambda (restart)
            (eq? (restart/name restart) (car invocation)))
          restarts))
      (map
        (lambda (expression)
          (bind-condition-handler
            '()
            condition-handler
            (lambda ()
              (eval expression *the-environment*))))
        (cdr invocation)))))

(bind-default-condition-handler '() condition-handler)
