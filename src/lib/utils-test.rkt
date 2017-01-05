#lang racket/base

(require rackunit)
(require "utils.rkt")

;toggle
(check-equal? (toggle "a" '("a" "b")) '("b"))
(check-equal? (toggle "c" '("a" "b")) '("c" "a" "b"))

;select
(check-equal? (select '(1 2) '("a" "b" "c")) '("b" "c"))

;release-name
(check-equal? (release-name 10) "v10.0.0")
(check-equal? (release-name "10") "v10.0.0")
(check-equal? (release-name "v10") "v10.0.0")
(check-equal? (release-name "V10") "v10.0.0")
(check-equal? (release-name "v10.1") "v10.1.0")
(check-equal? (release-name "10.1.2") "v10.1.2")
(check-equal? (release-name "a") #f)

;list<?
(check-equal? (list<? '(1 2 3) '(1 2 4)) #t)
(check-equal? (list<? '(1 2 3) '(1 3 1)) #t)
(check-equal? (list<? '(1 2 3) '(2 3 1)) #t)
(check-equal? (list<? '(2 2 3) '(1 3 4)) #f)

;take-upto
(check-equal? (take-upto '(1 2 3) 2) '(1 2) )
(check-equal? (take-upto '(1 2 3) 4) '(1 2 3) )
