#lang racket/base

(require rackunit)

(require/expose "utils.rkt" (toggle select release-name))

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
