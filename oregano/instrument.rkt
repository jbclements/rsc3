#lang racket
(require rsc3 rhs/rhs)


;; --- gui stuff

(require (prefix-in gui: racket/gui))

(define frame (new gui:frame% [label "Example"]))

;; parent should be a frame
(new gui:slider% [parent frame]
     [label "freq"]
     [min-value 300]
     [max-value 1000]
     [init-value 400]
     ;; callback receives the slider object and an event object
     [callback (lambda (s event)
                   (send-msg (n-set1 1001 "freq" (gui:send s get-value))))])

(gui:send frame show #t)


;; hypothetical usage
#;(add-filter track2 (lpf #:resonance .3
                        #:cutoff (slider 300 800 500)))

(define (slider min-n max-n init)
  (define bus-id 16)
  
  (new gui:slider% [parent frame]
     [label "amp"]
     [min-value min-n]
     [max-value max-n]
     [init-value init]
     ;; callback receives the slider object and an event object
     [callback (lambda (s event)
                   (send-msg
                    (c-set1 bus-id (/ (gui:send s get-value) 1000))))])

  
  (in 1 kr bus-id))

; -------





;; simplifies sending osc messages to server
(define (send-msg msg)
  (with-sc3 (lambda (fd)
              (send fd msg))))

(define current-node-id 1000)
(define (gen-node-id)
  (set! current-node-id (add1 current-node-id))
  current-node-id)


(define (wave-instrument wave-func)
  (letc ([bus 0]
         [freq 440])
        (out bus (mul 0.2 (wave-func ar freq 0)))))
  
(define sin-instrument
  (letc ([bus 0]
         [freq 440])
        (out bus (mul (slider 100 800 200) (sin-osc ar freq 0)))))

(define saw-instrument
  (letc ([bus 0]
         [freq 440])
        (out bus (mul 0.2 (saw ar freq)))))


;; setup
;; show osc messages on server
(with-sc3 (lambda (fd)
            (send fd (dump-osc 1))))
(with-sc3 reset)

;; send synthdefs
(with-sc3 (lambda (fd)
                  (send-synth fd "sin-inst" sin-instrument) ; (wave-instrument sin-osc))
                  (send-synth fd "saw-inst" saw-instrument)))


(define (make-instrument ins)
  (match ins
    ['sin (let ([node-id (gen-node-id)])
            (send-msg (s-new0 "sin-inst" node-id 1 1))
            ; don't make sound upon creation
            (send-msg (n-run1 node-id 0))
            node-id)]
    [else (error "unknown instrument used")]))

(define (note-on inst freq track)
  (send-msg (n-set1 inst "freq" freq))
  (send-msg (n-set1 inst "bus" track))
  (send-msg (n-run1 inst 1)))

(define (note-off inst)
  (send-msg (n-run1 inst 0)))

#|

- to stop/run:
  (send-msg (n-run1 1001 1))

|#

;; ======== test run ===========

(define my-sin (make-instrument 'sin))


;; example:

; (note-on my-sin 500 1)

; (note-off my-sin)


