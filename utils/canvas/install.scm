(define (canvas-open generator . args)
  (generator (apply make-canvas args)))

(define descriptor)

(define (canvas-wrapper f)
  (lambda (canvas . args)
    (let ((descriptor (record-accessor (record-type-descriptor canvas) 'descriptor)))
      (apply f (descriptor canvas) args))))

(define graphics-type/canvas (make-graphics-device-type 'canvas
  `((clear ,(canvas-wrapper canvas-clear))
    (close ,(canvas-wrapper canvas-close))
    (available? ,canvas-available?)
    (coordinate-limits ,(canvas-wrapper canvas-coordinate-limits))
    (device-coordinate-limits ,(canvas-wrapper canvas-device-coordinate-limits))
    (drag-cursor ,(canvas-wrapper canvas-drag-cursor))
    (draw-line ,(canvas-wrapper canvas-draw-line))
    (draw-point ,(canvas-wrapper canvas-draw-point))
    (draw-text ,(canvas-wrapper canvas-draw-text))
    (move-cursor ,(canvas-wrapper canvas-move-cursor))
    (open ,canvas-open)
    (flush ,canvas-flush)
    (reset-clip-rectangle ,(canvas-wrapper canvas-reset-clip-rectangle))
    (set-clip-rectangle ,(canvas-wrapper canvas-set-clip-rectangle))
    (set-coordinate-limits ,(canvas-wrapper canvas-set-coordinate-limits))
    (set-drawing-mode ,(canvas-wrapper canvas-set-drawing-mode))
    (set-line-style ,(canvas-wrapper canvas-set-line-style))
    (set-background-color ,(canvas-wrapper canvas-set-background-color))
    (set-foreground-color ,(canvas-wrapper canvas-set-foreground-color))

    (draw-points ,(canvas-wrapper canvas-draw-points))
    (draw-rect ,(canvas-wrapper canvas-draw-rect))
    (draw-rects ,(canvas-wrapper canvas-draw-rects))
    (erase-point ,(canvas-wrapper canvas-erase-point))
    (erase-points ,(canvas-wrapper canvas-erase-points))
    (erase-rect ,(canvas-wrapper canvas-erase-rect))
    (erase-rects ,(canvas-wrapper canvas-erase-rects))
    (set-font ,(canvas-wrapper canvas-set-font))
    (get-pointer-coordinates ,(canvas-wrapper canvas-get-pointer-coordinates)))))

(define (make-window/canvas width height x y)
  (make-graphics-device 'canvas))

(define (make-window width height x y #!optional display)
  (let ((window
         (let ((name (graphics-type-name (graphics-type #f))))
           (let ((temp name))
             (cond ((eq? temp 'x) (if (default-object? display) (set! display #f))
                                  (make-window/x11 width height x y display))
                   ((eq? temp 'win32)
                    (if (not (default-object? display))
                        (error "No remote Win32 display"))
                    (make-window/win32 width height x y))
                   ((eq? temp 'os/2)
                    (if (not (default-object? display))
                        (error "No remote OS/2 display"))
                    (make-window/os2 width height x y))
                   ((eq? temp 'canvas)
                    (if (not (default-object? display))
                        (error "No remove Canvas display"))
                    (make-window/canvas width height x y))
                   (else (error "Unsupported graphics type:" name)))))))
    (graphics-set-coordinate-limits window 0 (- (- height 1)) (- width 1) 0)
    window))

(define (make-display-frame #!optional xmin xmax ymin ymax frame-width frame-height frame-x-position frame-y-position display)
  (let ((xmin (if (default-object? xmin) 0. xmin))
        (xmax (if (default-object? xmax) 1. xmax))
        (ymin (if (default-object? ymin) 0. ymin))
        (ymax (if (default-object? ymax) 1. ymax))
        (frame-x (if (default-object? frame-x-position) *frame-x-position* frame-x-position))
        (frame-y (if (default-object? frame-y-position) *frame-y-position* frame-y-position))
        (frame-width (if (default-object? frame-width) *frame-width* frame-width))
        (frame-height (if (default-object? frame-height) *frame-height* frame-height)))
    (if (not
         (and (integer? frame-width)
              (> frame-width 0)
              (integer? frame-height)
              (> frame-height 0)))
        (error "Bad frame width or height"))
    (let ((window
           (if (default-object? display)
               (make-window frame-width frame-height frame-x frame-y)
               (make-window frame-width frame-height frame-x frame-y display))))
      (graphics-set-coordinate-limits window xmin ymin xmax ymax)
      (graphics-set-clip-rectangle window xmin ymin xmax ymax)
      (let ((name (graphics-type-name (graphics-type #f))))
        (let ((temp name))
          (cond ((eq? temp 'x) (graphics-operation window 'set-border-color "green")
                               (graphics-operation window 'set-mouse-color "green"))
                ((eq? temp 'win32) 'nothing-to-do)
                ((eq? temp 'os/2) 'nothing-to-do)
                ((eq? temp 'canvas) 'nothing-to-do)
                (else (error "Unsupported graphics type:" name)))))
      (graphics-operation window 'set-background-color *background-color*)
      (graphics-operation window 'set-foreground-color *foreground-color*)
      (graphics-clear window)
      window)))

(define frame make-display-frame)
(define window-coordinates graphics-coordinate-limits)
(define (window-size window) (map 1+ (cddr (graphics-device-coordinate-limits window))))
(define (get-pointer-coordinates win cont) (graphics-operation win 'get-pointer-coordinates cont))

(define (plot-function window f #!optional x0 x1 dx)
  (if (default-object? x0)
      (let ((bounds (window-coordinates window)) (size (window-size window)))
        (set! x0 (car bounds))
        (set! x1 (cadr bounds))
        (set! dx (/ (- x1 x0) (car size)))))
  (if *gnuplotting*
      (newline *gnuplotting*))
  (let loop ((x x0) (fx (f x0)))
    (if *gnuplotting*
        (begin (newline *gnuplotting*) (write x *gnuplotting*) (display " " *gnuplotting*) (write fx *gnuplotting*)))
    (let ((nx (+ x dx)))
      (let ((nfx (f nx)))
        (plot-line-internal window x fx nx nfx)
        (if (< (* (- nx x0) (- nx x1)) 0.)
            (loop nx nfx))))))
