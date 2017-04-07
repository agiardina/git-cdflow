#! /usr/bin/env racket

#lang racket/base

(require "../lib/utils.rkt")

(provide (all-defined-out))

(define (create-feature-branch feature-branch)
  (let ([current-branch (git-current-branch)])
    (git-branch feature-branch)
    (git-notes-add-parent current-branch feature-branch)))
