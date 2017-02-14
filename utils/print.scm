(define pe)
(define print-expression)

(let ()

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

  (define (print-string result-type . strings)
    (apply *send* result-type (map string->json strings)))

  (define (print-unsimplifiable result-type object)
    (print-string result-type (write-to-string object)))

  (define (simple expr)
    (or
      (and
        (not (with-units? expr))
        (apply object-name expr (system-environments)))
      (arg-suppressor (simplify expr))))

  (define (print-simplifiable result-type object)
    (if *scmutils*
      (let ((val (simple object)))
        (if (unsimplifiable? val)
          (print-unsimplifiable result-type val)
          (print-complex result-type object val)))
      (print-unsimplifiable result-type object)))

  (define (print-complex result-type object val)
    (let ((string (open-output-string)))
      (pp val string)
      (print-string
        result-type
        (write-to-string object)
        (get-output-string string)
        (get-latex val))))

  (define (print-record result-type object)
    (let ((name (record-type-name (record-type-descriptor object)))
          (description (record-description object))
          (string (open-output-string)))
      (pp `(*record* ,name ,@description) string)
      (print-string
        result-type
        (write-to-string object)
        (get-output-string string))))

  (define (*print* result-type object)
    (cond
      ((eq? *silence* object))
      ((unsimplifiable? object)
        (print-unsimplifiable result-type object))
      ((simplifiable? object)
        (print-simplifiable result-type object))
      ((record? object)
        (print-record result-type object))
      (else (print-unsimplifiable result-type object))))

  (define (repl-write object s-expression environment repl)
    (*print* 0 object))

  (set! hook/repl-write repl-write)

  (define (*print-expression* object)
    (*print* 3 object))
  (set! print-expression *print-expression*)
  (set! pe *print-expression*))
