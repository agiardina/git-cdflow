#lang racket/base

(require charterm
         racket/system
         racket/string
         racket/list
         racket/format
         (only-in racket/port with-output-to-string))

(provide (all-defined-out))
  
(define (err m [callback #f])
  (printf "\033[0;31m~a\033[0m\n" m)
  (cond [callback (callback)]))

(define (display-err msg)
  (display msg (current-error-port)))

(define (sh command)
  (cond [(not (system command)) (exit)]))

(define (list<? l1 l2)
  (cond
    [(equal? l1 '()) #t]
    [(< (car l1) (car l2)) #t]
    [(> (car l1) (car l2)) #f]
    [else (list<? (cdr l1) (cdr l2))]))

(define (take-upto l n)
  (take l (min n (length l))))

(define (string->list str)
  (string-split str "\n"))

(define (list->string lst)
  (string-join lst "\n"))

(define (sh->string command)
  (with-output-to-string (lambda () (sh command))))

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

(define (show-menu title items [n-active 0])
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
      [(eqv? char 'return) (let ([val (list-ref items n-active)])
                             (if (string=? val "NONE") #f val))])))


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

(define (git-checkout-branch branch-name)
  (sh (format "git checkout ~a" branch-name)))

(define (git-current-branch)
  (car (sh->list "git rev-parse --abbrev-ref HEAD")))

(define (git-branch branch-name)
  (sh (format "git branch ~a" branch-name)))

(define (git-add files)
  (for-each (lambda (file)
    (sh (format "git add \"~a\"" file)))
    (if (string? files) `(,files) files)))

(define (git-commit files message)
  (git-add files)
  (sh (format "git commit -m \"~a\"" message)))

(define (git-pull)
  (sh "git pull"))

(define (git-notes)
  (sh->list "git log --show-notes=cdflow"))

(define (git-objects-with-notes)
    (map (lambda (row)
      (cadr (string-split row " ")))
      (sh->list "git notes --ref=cdflow")))

(define (git-object-show-notes obj)
  (sh->string (format "git notes --ref=cdflow show ~a" obj)))

(define (git-objects-notes)
  (map (lambda (obj)
    (list obj (git-object-show-notes obj)))
    (git-objects-with-notes)))

(define (git-notes-start-from from to)
  (sh
    (format "git notes --ref cdflow append -m \"[~a -> ~a]\"" from to)))

(define (git-notes-replace notes object)
  (sh (format "git notes --ref cdflow add -f -m \"~a\" ~a" notes object)))

(define (git-branch-from from to)
  (git-checkout-branch from)
  (git-pull)
  (git-branch to)
  (git-checkout-branch to)
  (git-notes-start-from from to))

(define (git-push-origin branch)
  (sh (format "git push -u origin ~a" branch)))
