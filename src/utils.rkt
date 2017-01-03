#lang racket/base

(require charterm
         racket/system
         racket/string
         (only-in racket/port with-output-to-string))

(provide sh->string)

(define (sh->string command)
  (with-output-to-string (lambda () (system command))))

(define (sh->list command)
  (string-split (sh->string command) "\n"))


(define (menu items n-active)
  (let ([active (list-ref items n-active)])
    (map
      (lambda (item)
        (if (eqv? item active)
          (printf "  \033[36mο\033[0m ~a\033[0m\n" item)
          (printf "    \033[90m~a\033[0m\n" item)))
        items)))

(define (show-menu title items n-active)
  (with-charterm (charterm-clear-screen))

  (printf "~a\n\n" title)
  (menu items n-active)

  (let ([char (with-charterm (charterm-read-key))]
        [prev (if (> n-active 0) (- n-active 1) 0)]
        [next (if (= n-active (- (length items) 1))
                  (- (length items) 1)
                  (+ n-active 1))])

    (cond
      [(eqv? char 'down) (show-menu title items next)]
      [(eqv? char 'up) (show-menu title items prev)]
      [(eqv? char 'return) (list-ref items n-active)])))


(define (multichoice-menu items active selected)
  (let ([checked "\033[36m[\u2713]"]
        [unchecked "\033[90m[ ]"]
        [text "\033[90m"]
        [text-active "\033[0m"])

  (for ([i (in-naturals)]
        [item items])
        (if (member i selected)
          (printf "  ~a" checked)
          (printf "  ~a" unchecked))

        (if (eqv? i active)
          (printf " ~a~a \033[0m\n" text-active item)
          (printf " ~a~a \033[0m\n" text item)))))

(define (toggle el li)
  (if (member el li) (remv el li) (cons el li)))

(define (select idx l)
  (foldr (lambda (id ret) (cons (list-ref l id) ret)) '() idx))

(define (show-multichoice-menu title items active selected)
  (with-charterm (charterm-clear-screen))

  (printf "~a\n\n" title)
  (multichoice-menu items active selected)

  (let ([char (with-charterm (charterm-read-key))]
        [prev (modulo (- active 1) (length items))]
        [next (modulo (+ active 1) (length items))])

    (cond
      [(eqv? char 'down) (show-multichoice-menu title items next selected)]
      [(eqv? char 'up) (show-multichoice-menu title items prev selected)]
      [(eqv? char #\space) (show-multichoice-menu title items active (toggle active selected))]
      [(eqv? char 'return) (select (sort selected <) items)])))

(define (release-name name)
  (let* ([sname (if (number? name) (number->string name) name)]
         [vname (if (regexp-match #rx"^[v|V].*" sname) (string-downcase sname) (string-append "v" sname))])
    (cond
      [(regexp-match #px"^v[0-9]{1,3}$" vname) (string-append vname ".0.0")]
      [(regexp-match #px"^v[0-9]{1,2}\\.[0-9]{1,2}$" vname) (string-append vname ".0")]
      [(regexp-match #px"^v[0-9]{1,2}\\.[0-9]{1,2}\\.[0-9]{1,2}$" vname) vname]
      [else #f])))

;(select '(1 2) '("a" "b" "c"))
;(show-menu "Scegli quello che vuoi?" (list "ciao" "come" "stai") 0)
;(show-multichoice-menu "Quale saluto preferisci?" (list "ciao" "come stai" "buongiorno") 0 '(0))
