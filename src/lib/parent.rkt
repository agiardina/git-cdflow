#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/match
         racket/string
         "../lib/utils.rkt")

(provide (all-defined-out))

(define (rgx-parent name)
  (pregexp (format "([\\w\\./]*) -> ~a\\]" (regexp-quote name))))

(define (parent-match name str)
  (let
    ([match (regexp-match (rgx-parent name) str)])
    (if match (cadr match) #f)))

(define (get-parent)
  (ormap (lambda (l)
    (parent-match (git-current-branch) (cadr l)))
    (git-objects-notes)))

(define (notes-filter-out-parent notes branch)
  (filter
   (lambda (line) (not (parent-match branch line)))
   notes))

(define (git-notes-remove-parent branch)
  (for-each
   (lambda (row)
     (let* ([id (car row)]
           [note (string->list (cadr row))]
           [clean-note (notes-filter-out-parent note branch)])      
       (cond
         [(> (length note)
             (length clean-note))
          (git-notes-replace (list->string clean-note) id)])
       )) (git-objects-notes)))
