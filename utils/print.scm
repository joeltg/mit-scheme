(let ()
  (define result-type 0)

  (define (rlookup key table)
    (cond ((null? table) #f)
          ((null? (general-car-cdr table 5)) (rlookup key (cdr table)))
          ((eq? key (general-car-cdr table 13)) (car table))
          (else (rlookup key (cdr table)))))

  (define (object-name object . environments)
    (let lp ((environments environments))
      (if (null? environments)
          #f
          (let ((temp (rlookup object (environment-bindings (car environments)))))
            (if temp
                (car temp)
                (lp (cdr environments)))))))

  (define ((disjunction . predicates) object)
    (any (lambda (p) (p object)) predicates))

  (define (global? expr)
    (and (procedure? expr)
         (object-name expr system-global-environment)))

  (define (operator? expr)
    (and (pair? expr)
         (eq? (car expr) '*operator*)))

  (define (solution? expr)
    (and (pair? expr) (eq? (car expr) '*solution*)))

  (define simplifiable?
    (disjunction symbol? list? vector? procedure?))

  (define unsimplifiable?
    (disjunction boolean? null? number? pathname? global? solution? operator?))

  (define (get-latex object)
    (ignore-errors
      (lambda ()
        (expression->tex-string object))))

  (define (print-undefined)
    (*send* result-type "\"No return value\""))

  (define (print-string . strings)
    (apply *send* result-type (map string->json strings)))

  (define (print-unsimplifiable object)
    (print-string (write-to-string object)))

  (define (simple expr)
    (or
      (and
        (not (with-units? expr))
        (apply object-name expr (system-environments)))
      (arg-suppressor (simplify expr))))

  (define (print-simplifiable object)
    (if *scmutils*
      (let ((val (simple object)))
        (if (unsimplifiable? val)
          (print-unsimplifiable val)
          (print-complex object val)))
      (print-unsimplifiable object)))

  (define (print-complex object val)
    (let ((string (open-output-string)))
      (pp val string)
      (print-string
        (write-to-string object)
        (get-output-string string)
        (get-latex val))))

  (define (print-record object)
    (let ((name (record-type-name (record-type-descriptor object)))
          (description (record-description object))
          (string (open-output-string)))
      (pp `(*record* ,name ,@description) string)
      (print-string (write-to-string object) (get-output-string string))))

  (define (repl-write object s-expression environment repl)
    (cond
      ((eq? *silence* object))
      ((undefined-value? object)
        (print-undefined))
      ((unsimplifiable? object)
        (print-unsimplifiable object))
      ((simplifiable? object)
        (print-simplifiable object))
      ((record? object)
        (print-record object))
      (else (print-unsimplifiable object))))

  (set! hook/repl-write repl-write))
