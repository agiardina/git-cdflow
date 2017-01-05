#lang racket/base

(require rackunit)
(require "release.rkt")

;version-snapshot
(check-equal? (version-snapshot 10) "10.0.0-SNAPSHOT")
(check-equal? (version-snapshot "v10.1.2") "10.1.2-SNAPSHOT")

;replace projcet version
