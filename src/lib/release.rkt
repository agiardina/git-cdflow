#lang racket/base

(provide (all-defined-out))

(require "utils.rkt")

(define (version-snapshot version)
  (string-append (substring (release-name version) 1) "-SNAPSHOT"))

;(define (replace-clj-project-version str version)
;  (let (
;    [str-version (substring (version-name version) 1)])))
