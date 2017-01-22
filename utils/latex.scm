(define derivative-symbol 'D)

(define (up-maker? expr) (and (pair? expr) (eq? (car expr) 'up)))

(define (vector-maker? expr) (and (pair? expr) (eq? (car expr) 'vector)))

(define (down-maker? expr) (and (pair? expr) (eq? (car expr) 'down)))

(define (matrix-by-rows-maker? expr)
  (and (pair? expr) (eq? (car expr) 'matrix-by-rows)))

(define (make-box voffset width binding-power lines)
  (append (list 'box voffset width binding-power)
	  lines))

(define (explicit-box? elt)
  (and (pair? elt)
       (eq? (car elt) 'box)))

(define (box-voffset box)
  (if (explicit-box? box)
      (list-ref box 1)
      0))

(define (box-width box)
  (if (explicit-box? box)
      (list-ref box 2)
      (string-length box)))

(define (box-binding-power box)
  (if (explicit-box? box)
      (list-ref box 3)
      max-bp))

(define (box-lines box)
  (if (explicit-box? box)
      (list-tail box 4)
      (list (make-line (list box)))))

(define (box-nlines box)
  (length (box-lines box)))

(define (make-box-with-bp bp box)
  (make-box (box-voffset box)
	    (box-width box)
	    bp
	    (box-lines box)))

(define (make-empty-box width height)
  (let ((lines (make-list height (make-blank-line width))))
    (make-box 0		       ;v-offset arbitrary
	      width
	      max-bp	       ;binding power arbitrary
	      lines)))

(define (glue-horiz boxes)
  (if (null? (cdr boxes))
      (car boxes)
      (join2-right (car boxes) (glue-horiz (cdr boxes)))))

(define (join2-right box1 box2)
  (let ((v1 (box-voffset box1))
	(v2 (box-voffset box2))
	(blank1 (make-blank-line (box-width box1)))
	(blank2 (make-blank-line (box-width box2))))
    (make-box (max v1 v2)
	      (+ (box-width box1) (box-width box2))
	      (box-binding-power box1)
	      (cond ((> v1 v2)
		     ;;must pad box2 on top to start
		     (join-lines-horiz
		      (box-lines box1)
		      (append (make-list (- v1 v2) blank2)
			      (box-lines box2))
		      blank1
		      blank2))
		    ((> v2 v1)
		     ;;must pad box1 on top
		     (join-lines-horiz
		      (append (make-list (- v2 v1) blank1)
			      (box-lines box1))
		      (box-lines box2)
		      blank1
		      blank2))
		    (else (join-lines-horiz (box-lines box1)
					    (box-lines box2)
					    blank1
					    blank2))))))

(define (join-lines-horiz lines1 lines2 blank1 blank2)
  (cond ((null? lines1)
	 (map (lambda (line2) (make-line (append (line-elements blank1)
						 (line-elements line2))))
	      lines2))
	((null? lines2)
	 (map (lambda (line1) (make-line (append (line-elements line1)
						 (line-elements blank2))))
	      lines1))
	(else (cons (make-line (append (line-elements (car lines1))
				       (line-elements (car lines2))))
		    (join-lines-horiz (cdr lines1) (cdr lines2) blank1 blank2)))))


;;; Glue boxes vertically.  The boxes will all be extended to the
;;; width of the maximum width box, and centered within that width.
;;; The voffset will be the voffset of the first box.  (I.e., the
;;; first box will stay at the same level, and the other boxes will be
;;; appended below it.)  The binding power will be the binding power
;;; of the first box.

(define (glue-vert boxes)
  (if (null? (cdr boxes))
      (car boxes)
      (glue-below (car boxes) (glue-vert (cdr boxes)))))


(define (glue-below box1 box2)
  (let* ((new-width (max (box-width box1) (box-width box2)))
	 (nbox1 (pad-box-centered-to-width new-width box1))
	 (nbox2 (pad-box-centered-to-width new-width box2)))
    (make-box
     (box-voffset box1)
     new-width
     (box-binding-power box1)
     (append (box-lines nbox1) (box-lines nbox2)))))


;;; Glue-above is similar to glue-below below, except that the
;;; v-offset of the top line in box2 remains
;;; what it was, and box1 is glued in above it.

(define (glue-above box1 box2)
  (let* ((new-width (max (box-width box1) (box-width box2)))
	 (nbox1 (pad-box-centered-to-width new-width box1))
	 (nbox2 (pad-box-centered-to-width new-width box2)))
    (make-box
     (+ (box-voffset box2) (length (box-lines box1)))
     new-width
     (box-binding-power box1)
     (append (box-lines nbox1) (box-lines nbox2)))))


;;;pad the box on both the left and the right so it is centered in a
;;;box of the given width

(define (pad-box-centered-to-width width box)
  (let* ((extra (- width (box-width box)))
	 (extra-left (floor->exact (/ extra 2)))
	 (extra-right (- extra extra-left))
	 (pad-left (make-blank-line-elts extra-left))
	 (pad-right (make-blank-line-elts extra-right)))
    (make-box (box-voffset box)
	      width
	      (box-binding-power box)
	      (map (lambda (line)
		     (make-line
		      (append pad-left
			      (line-elements line)
			      pad-right)))
		   (box-lines box)))))


;;; pad the box on both the top and the bottom so it will be centeted
;;; in a box of the given height.  "Centered" here means that the box
;;; will appear in the center of the expanded box, regardles of where
;;; the zero line was.

(define (pad-box-centered-to-height height box)
  (let* ((extra (- height (box-nlines box)))
	 (extra-top (floor->exact (/ extra 2)))
	 (extra-bottom (- extra extra-top))
	 (width (box-width box)))
    (let ((padded-box
	   (glue-below (glue-above (make-empty-box width extra-top)
				   box)
		       (make-empty-box width extra-bottom))))
      (shift-top-to (- (box-nlines padded-box) 1)
		    padded-box))))

;;; Offsetting boxes vertically

;;; Make the voffset of the bottom of the box be at n
(define (shift-bottom-to n box)
  (shift-top-to (+ n -1 (box-nlines box)) box))


;;; Shift the box so that its zero line is now at n
(define (shift-zero-to n box)
  (shift-top-to (+ n (box-voffset box)) box))


;;; Shift the box so that the top of the box is now at n
(define (shift-top-to n box)
  (make-box n
	    (box-width box)
	    (box-binding-power box)
	    (box-lines box)))


;;;Create a box from a list of strings, on string per line.  The
;;;strings are padded on the right to be all the same width.

(define (strings->vbox voffset strings)
  (let* ((width (apply max (map string-length strings)))
	 (padded-strings
	  (map (lambda (string)
		 (string-append (make-string
				 (- width (string-length string))
				 #\SPACE)
				string))
	       strings))
	 (lines (map (lambda (string)
		       (make-line (list string)))
		     padded-strings)))
    (make-box voffset
	      width
	      max-bp
	      lines)))

;;; List utility:
;;;Interpolate element between all items in the list

(define (interpolate element list)
  (cond ((null? list) '())
	((null? (cdr list)) list)
	(else (cons (car list)
		    (cons element
			  (interpolate element (cdr list)))))))

(define max-bp 200)

;;; Enclose the box in parentheses if its binding power is less than
;;; the required bp. Uptable is the unparsing table (needed in order
;;; to know how to parenthesize).

(define (insure-bp uptable required box)
  (if (< (box-binding-power box) required)
      ((cadr (assq 'parenthesize uptable)) uptable box)
      box))

(define (make-line elements)
  (cons 'line elements))

(define (line-elements line)
  (cdr line))

(define (make-blank-line width)
  (make-line (make-blank-line-elts width)))

(define (make-blank-line-elts width)
  (if (= width 0)
      '()
      (list (make-string width #\SPACE))))

(define (tex:parenthesize uptable box)
  (make-box-with-bp max-bp (glue-horiz (list "\\left( " box " \\right)"))))


(define (unparse-default uptable args)
  (make-box-with-bp 130
		    (glue-horiz
		     (list (insure-bp uptable 130 (car args))
			   ((cadr (assq 'parenthesize uptable))
			    uptable
			    (if (null? (cdr args))
				""
				(glue-horiz (interpolate ", " (cdr args)))))))))

(define (unparse-sum uptable args)
  (let ((args (map (lambda (a) (insure-bp uptable 100 a)) args)))
    (make-box-with-bp 100 (glue-horiz (interpolate " + " args)))))

(define (unparse-difference uptable args)
  (let ((args (map (lambda (a) (insure-bp uptable 100 a)) args)))
    (make-box-with-bp 100 (glue-horiz (interpolate " - " args)))))

(define (unparse-negation uptable args)
  (make-box-with-bp 99
		    (glue-horiz
		     (list  "- " (insure-bp uptable 101 (car args))))))

(define (unparse-signed-sum uptable signs terms)
  (let ((args (map (lambda (a) (insure-bp uptable 100 a)) terms)))
    (make-box-with-bp 100 (glue-horiz (interpolate-signs signs args)))))

;;number of signs should equal number of args
(define (interpolate-signs signs args)
  (define (interp signs args)
    (cond ((null? args) '())
	  ((null? (cdr args)) args)
	  (else (cons (car args)
		      (cons (if (eq? (car signs) '-) " - " " + ")
			    (interp (cdr signs) (cdr args)))))))
  (let ((after-first-sign (interp (cdr signs) args)))
    (if (eq? (car signs) '-)
	(cons " - " after-first-sign)
	after-first-sign)))


(define (tex:unparse-product uptable args)
  (let ((args (map (lambda (a) (insure-bp uptable 120 a)) args)))
    (make-box-with-bp 120 (glue-horiz (interpolate-for-tex-product args)))))

(define (interpolate-for-tex-product list)
  (define (separator a1 a2)
    (if (or (= (box-binding-power a1) 190)
	    (= (box-binding-power a2) 190))
	" \\cdot "
	" "))
  (cond ((null? list) '())
	((null? (cdr list)) list)
	(else (cons (car list)
		    (cons (separator (car list) (cadr list))
			  (interpolate-for-tex-product (cdr list)))))))


(define (tex:unparse-quotient uptable args)
  (let ((box1 (car args))
	(box2 (cadr args)))
    (make-box-with-bp 120
		      (glue-horiz
		       (list  "{" "{" box1 "}"
			     "\\over "
			       "{" box2 "}" "}")))))

(define (tex:unparse-expt uptable args)
  (let ((base (insure-bp uptable 140 (car args)))
	(expt (insure-bp uptable 100 (cadr args))))
    (make-box-with-bp
     130
     (glue-horiz (list "{" base "}^{" expt "}")))))


(define (tex:unparse-subscript uptable args)
  (let ((top (insure-bp uptable 140 (car args)))
	(scripts
	 (map (lambda (ss)
		(insure-bp uptable 140 ss))
	      (cdr args))))
    (make-box-with-bp
     140
     (glue-horiz
      (append (list "{")
	      (list top)
	      (list "}_{")
	      (let lp ((scripts scripts))
		(if (null? (cdr scripts))
		    (list (car scripts))
		    (append (list (car scripts))
			    (list ", ")
			    (lp (cdr scripts)))))
	      (list "}"))))))

(define (tex:unparse-superscript uptable args)
  (let ((top (insure-bp uptable 140 (car args)))
	(scripts
	 (map (lambda (ss)
		(insure-bp uptable 140 ss))
	      (cdr args))))
    (make-box-with-bp
     140
     (glue-horiz
      (append (list "{")
	      (list top)
	      (list "}^{")
	      (let lp ((scripts scripts))
		(if (null? (cdr scripts))
		    (list (car scripts))
		    (append (list (car scripts))
			    (list ", ")
			    (lp (cdr scripts)))))
	      (list "}"))))))


(define (unparse-derivative uptable args)
  (make-box-with-bp
   140
   (glue-horiz (list "D" (insure-bp uptable 140 (car args))))))


(define (tex:unparse-sqrt uptable args)
  (make-box-with-bp
   140
   (glue-horiz (list "\\sqrt{" (insure-bp uptable 90 (car args)) "}"))))

(define (tex:unparse-dotted uptable args)
  (make-box-with-bp
   140
   (glue-horiz (list "\\dot{" (insure-bp uptable 140 (car args)) "}"))))


(define (tex:unparse-dotdotted uptable args)
  (make-box-with-bp
   140
   (glue-horiz (list "\\ddot{" (insure-bp uptable 140 (car args)) "}"))))


(define (tex:unparse-primed uptable args)
  (let ((top (insure-bp uptable 140 (car args))))
    (make-box-with-bp 140
     (glue-horiz (list "{" top "}^\\prime")))))


(define (tex:unparse-primeprimed uptable args)
  (let ((top (insure-bp uptable 140 (car args))))
    (make-box-with-bp 140
     (glue-horiz (list "{" top "}^{\\prime\\prime}")))))


(define (tex:unparse-second-derivative uptable args)
  (make-box-with-bp
   140
   (glue-horiz (list (tex:unparse-expt uptable (list "D" "2"))
		     (insure-bp uptable 140 (car args))))))


(define (tex:unparse-partial-derivative uptable args)
  (make-box-with-bp
   140
   (glue-horiz
    (list (tex:unparse-subscript uptable (cons "\\partial" (cdr args)))
	  (insure-bp uptable 140 (car args))))))


(define (tex:unparse-nth-derivative uptable args)
  (let ((op (tex:unparse-expt uptable (list "D" (cadr args)))))
    (make-box-with-bp
     140
     (glue-horiz (list op (insure-bp uptable 140 (car args)))))))

(define (tex:unparse-vector uptable args)
  ;;args here is the list of vector elements
  (tex:unparse-matrix uptable
		      (map list args)))

(define (tex:unparse-matrix uptable matrix-list)
  (let* ((displaystyle-rows
	  (map (lambda (row)
		 (map (lambda (elt)
			(glue-horiz (list "\\displaystyle{ "
					  elt
					  "}")))
		      row))
	       matrix-list))
	 (separated-rows
	  (map (lambda (row) (glue-horiz (interpolate " & " row)))
	       displaystyle-rows))
	 (separated-columns
	  (glue-horiz (interpolate " \\cr \\cr " separated-rows))))
    #;
    (glue-horiz
     (list "\\left\\{ \\begin{matrix}"
	   separated-columns
	   "\\end{matrix} \\right\\}"))
    (glue-horiz
     (list "\\left\\lgroup \\begin{matrix}"
     separated-columns
	   "\\end{matrix} \\right\\rgroup"))))

(define (tex:unparse-up uptable matrix-list)
  (let* ((displaystyle-rows
	  (map (lambda (row)
		 (map (lambda (elt)
			(glue-horiz (list "\\displaystyle{ "
					  elt
					  "}")))
		      row))
	       matrix-list))
	 (separated-rows
	  (map (lambda (row) (glue-horiz (interpolate " & " row)))
	       displaystyle-rows))
	 (separated-columns
	  (glue-horiz (interpolate " \\cr \\cr " separated-rows))))
    (glue-horiz
     (list left-up-delimiter separated-columns right-up-delimiter))))

(define (tex:unparse-down uptable matrix-list)
  (let* ((displaystyle-rows
	  (map (lambda (row)
		 (map (lambda (elt)
			(glue-horiz (list "\\displaystyle{ "
					  elt
					  "}")))
		      row))
	       matrix-list))
	 (separated-rows
	  (map (lambda (row) (glue-horiz (interpolate " & " row)))
	       displaystyle-rows))
	 (separated-columns
	  (glue-horiz (interpolate " \\cr \\cr " separated-rows))))
    (glue-horiz
     (list left-down-delimiter separated-columns right-down-delimiter))))

(define tex:unparse-table
  `((parenthesize ,tex:parenthesize)
    (default ,unparse-default)
    (+ ,unparse-sum)
    ;;need sum (in addition to +) as an internal hook for
    ;;process-sum
    (sum ,unparse-sum)
    (- ,unparse-difference)
    (* ,tex:unparse-product)
    (& ,tex:unparse-product)
    (negation ,unparse-negation)
    (/ ,tex:unparse-quotient)
    (signed-sum ,unparse-signed-sum)
    (expt ,tex:unparse-expt)
    (,derivative-symbol ,unparse-derivative)
    (derivative ,unparse-derivative)
    (second-derivative ,tex:unparse-second-derivative)
    (nth-derivative ,tex:unparse-nth-derivative)
    (partial-derivative ,tex:unparse-partial-derivative)
    (subscript ,tex:unparse-subscript)
    (superscript ,tex:unparse-superscript)
    (vector ,tex:unparse-vector)
    (column ,tex:unparse-up)
    (row ,tex:unparse-down)
    (up ,tex:unparse-up)
    (down ,tex:unparse-down)
    (matrix ,tex:unparse-matrix)
    (sqrt ,tex:unparse-sqrt)
    (dotted ,tex:unparse-dotted)
    (dotdotted ,tex:unparse-dotdotted)
    (primed ,tex:unparse-primed)
    (primeprimed ,tex:unparse-primeprimed)
    ))

(define tex:symbol-substs
  (append `((derivative "D")
	    (acos "\\arccos")
	    (asin "\\arcsin")
	    (atan "\\arctan")
	    )
	  (map (lambda (string)
		 (list (string->symbol string)
		       (string-append "\\" string)))
	       '(
		 "alpha" "beta" "gamma" "delta" "epsilon" "zeta" "eta" "theta"
		 "iota" "kappa" "lambda" "mu" "nu" "xi"
		 ;; "omicron" does not appear in tex
		 "pi" "rho" "tau" "upsilon" "phi" "chi" "psi" "omega"
		 "varepsilon" "vartheta" "varpi" "varrho" "varsigma" "varphi"

		 ;;"Alpha" "Beta"
		 "Gamma" "Delta"
		 ;;"Epsilon" "Zeta" "Eta"
		 "Theta"
		 ;;"Iota" "Kappa"
		 "Lambda"
		 ;;"Mu" "Nu"
		 "Xi"
		 ;;"Omicron"
		 "Pi"
		 ;;"Rho" "Tau"
		 "Upsilon" "Phi"
		 ;;"Chi"
		 "Psi" "Omega"

		 "aleph" "hbar" "nabla" "top" "bot" "mho" "Re" "Im"
		 "infty" "Box" "diamond" "Diamond" "triangle"

		 "sin" "cos" "tan" "cot" "sec" "csc" "log" "exp"
		 ))
	  (map (lambda (string)
		 (list (string->symbol string)
		       (string-append "{\\rm\\ " string " }")))
               '("&meter" "&kilogram" "&second"
                 "&ampere" "&kelvin" "&mole"
                 "&candela" "&radian"

                 "&newton" "&joule" "&coulomb"
                 "&watt" "&volt" "&ohm"
                 "&siemens" "&farad" "&weber"
                 "&henry" "&hertz" "&tesla"
                 "&pascal" "&katal" "&becquerel"
                 "&gray" "&sievert" "&inch"
                 "&pound" "&slug" "&foot"
                 "&mile" "&dyne" "&calorie"
                 "&day" "&year" "&sidereal-year"
                 "&AU" "&arcsec" "&pc"
                 "&ly" "&esu" "&ev"))))

(define (unparse exp symbol-substs uptable)
  (let ((exp (unparse-special-convert exp))
	(up (lambda (exp) (unparse exp symbol-substs uptable))))
    (cond ((null? exp) "")
	  ((number? exp) (unparse-number exp symbol-substs uptable))
	  ((symbol? exp) (unparse-symbol exp symbol-substs uptable))
	  ((up-maker? exp)
	   ((cadr (assq 'column uptable))
	    uptable
	    (map list (map up (cdr exp)))))
	  ((down-maker? exp)
	   ((cadr (assq 'row uptable))
	    uptable
	    (map list (map up (cdr exp)))))
	  ((vector-maker? exp)
	   ((cadr (assq 'vector uptable))
	    uptable
	    (map up (cdr exp))))
	  ((matrix-by-rows-maker? exp)
	   ((cadr (assq 'matrix uptable))
	    uptable
	    (map (lambda (row) (cdr (map up row)))
		 (cdr exp))))
	  ((eq? (car exp) '+)
	   (process-sum exp symbol-substs uptable))
	  ((symbol? (car exp))
	   (let ((proc (assq (car exp) uptable)))
	     (if proc
		 ((cadr proc) uptable (map up (cdr exp)))
		 ((cadr (assq 'default uptable)) uptable (map up exp)))))
	  (else
	   (let ((proc (assq 'default uptable)))
	     ((cadr proc) uptable (map up exp)))))))


(define (unparse-number n symbol-substs uptable)
  (cond ((and (real? n) (< n 0))
	 (unparse `(- ,(- n)) symbol-substs uptable))
	((and (rational? n) (exact? n) (not (= (denominator n) 1)))
	 (unparse `(/ ,(numerator n) ,(denominator n))
		  symbol-substs
		  uptable))
	(else (number->string n))))

(define (unparse-symbol symbol symbol-substs uptable)
  (let ((s (assq symbol symbol-substs)))
    (if s
	(cadr s)
	(let ((string (symbol->string symbol)))
	  (split-at-underscore-or-caret
	   string
	   (lambda (before at after)
	     (if (not before)		;no underscore or caret in symbol
		 (unparse-string string symbol-substs uptable)
		 (unparse `(,at ,(string->symbol before) ,(string->symbol after))
			  symbol-substs
			  uptable))))))))


(define dotdot-string "dotdot")
(define dotdot-string-length (string-length dotdot-string))

(define dot-string "dot")
(define dot-string-length (string-length dot-string))

(define primeprime-string "primeprime")
(define primeprime-string-length (string-length primeprime-string))

(define prime-string "prime")
(define prime-string-length (string-length prime-string))

(define (unparse-string string symbol-substs uptable)
  (define (for-terminal special-string special-string-length special-symbol)
    (let ((n (string-search-forward special-string string)))
      (if (and n (= (+ n special-string-length) (string-length string)))
	  (unparse `(,special-symbol
		     ,(string->symbol (string-head string n)))
		   symbol-substs uptable)
	  #f)))
  (cond ((= (string-length string) 1) string)
	((for-terminal dotdot-string     dotdot-string-length     'dotdotted))
	((for-terminal dot-string        dot-string-length        'dotted))
	((for-terminal primeprime-string primeprime-string-length 'primeprimed))
	((for-terminal prime-string      prime-string-length      'primed))
	(else (make-box-with-bp 190 string))))

(define (split-at-underscore-or-caret string cont)
  ;;cont = (lambda (before at after) ...)
  (let ((index (string-find-next-char-in-set string (char-set #\^ #\_))))
    (if (not index)
	(cont #f #f #f)
	(cont (string-head string index)
	      (if (char=? (string-ref string index) #\^)
		  'superscript
		  'subscript)
	      (string-tail string (+ index 1))))))

(define (unparse-special-convert exp)
  (cond ((and
	  ;;((expt derivative n) f) --> (nth-derivative f n)
	  (pair? exp)
	  (pair? (car exp))
	  (= (length exp) 2)
	  (= (length (car exp)) 3)
	  (eq? (caar exp) 'expt)
	  (or (eq? (cadar exp) 'derivative)
	      (eq? (cadar exp) derivative-symbol)))
	 (let ((exponent (list-ref (car exp) 2))
	       (base (cadr exp)))
	   (if (eq? exponent 2)
	       `(second-derivative ,base)
	       `(nth-derivative ,base ,exponent))))
	((and
	  ;;((partial x) f) --> (partial-derivative f x)
	  (pair? exp)
	  (pair? (car exp))
	  (= (length exp) 2)
	  (eq? (caar exp) 'partial))
	 `(partial-derivative ,(cadr exp) ,@(cdr (car exp))))
	((and
	  ;;(- x) --> (negation x)
	  (pair? exp)
	  (eq? (car exp) '-)
	  (eq? (length exp) 2))
	 `(negation ,(cadr exp)))
	(else exp)))

;;; for a sum, find all terms of the form (* -1 .....) and make them
;;; appear without the -1 and with a negative sign in the sum

(define (process-sum exp symbol-substs uptable)
  (let ((terms (cdr exp)))
    (cond ((null? terms)
	   (unparse 0 symbol-substs uptable))
	  ((null? (cdr terms))
	   (unparse (car terms) symbol-substs uptable))
	  (else
	   (let ((signed-terms
		  (map (lambda (term)
			 (cond ((and (pair? term) (eq? (car term) '*))
				(let ((first-factor (cadr term)))
				  (if (and (real? first-factor) (negative? first-factor))
				      (if (and (= first-factor -1) (not (null? (cddr term))))
					  (list '- (cons '* (cddr term)))
					  (list '- (cons '* (cons (- first-factor) (cddr term)))))
				      (list '+ term))))
			       ((and (pair? term) (eq? (car term) '/))
				(let ((numer (cadr term)))
				  (cond ((and (real? numer) (negative? numer))
					 (list '- (cons '/ (cons (- numer) (cddr term)))))
					((and (pair? numer) (eq? (car numer) '*))
					 (let ((first-factor (cadr numer)))
					   (if (and (real? first-factor) (negative? first-factor))
					       (if (and (= first-factor -1) (not (null? (cddr numer))))
						   (list '-
							 (cons '/
							       (cons (cons '* (cddr numer))
								     (cddr term))))
						   (list '-
							 (cons '/
							       (cons (cons '*
									   (cons (- first-factor)
										 (cddr numer)))
								     (cddr term)))))
					       (list '+ term))))
					(else
					 (list '+ term)))))
			       (else
				(list '+ term))))
		       terms)))
	     (let ((processed-terms
		    (map (lambda (exp) (unparse exp symbol-substs uptable))
			 (map cadr signed-terms))))
	       ((cadr (assq 'signed-sum uptable))
		uptable
		(map car signed-terms)
		processed-terms
		)))))))

(define left-up-delimiter "\\left( \\begin{matrix} ")
(define right-up-delimiter "\\end{matrix} \\right)")

(define left-down-delimiter "\\left[ \\begin{matrix} ")
(define right-down-delimiter "\\end{matrix} \\right]")

(define (expression->tex-string exp)
  (let* ((one-line-box (unparse exp tex:symbol-substs tex:unparse-table)))
    (with-output-to-string
      (lambda ()
        (for-each display
            (line-elements (car (box-lines one-line-box))))))))
