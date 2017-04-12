#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/match
         racket/string
         racket/file
         "../lib/utils.rkt")

(provide (all-defined-out))

(define (is-tracker-url-note? str)
  (regexp-match "issue-tracker-url ::" str))

(define (get-note-with-tracker-url)
  (let ([note (filter (lambda (l) (is-tracker-url-note? l)) (map (lambda (l) (cadr l)) (git-objects-notes)))])
    (if (= 0 (length note)) "" (car note))))

(define (clean-tracker-url str)
  (string-trim (string-replace
    (string-replace
      (string-replace
        str
        "issue-tracker-url ::" "")
      "[" "")
      "]" "")))

(define (get-tracker-url)
  (let ([tracker (filter (lambda (l) (is-tracker-url-note? l)) (string->list (get-note-with-tracker-url)))])
    (if (= 0 (length tracker))
    #f
    (clean-tracker-url (car tracker))
    )))

(define (is-set-tracker-url?)
  (if (not (get-tracker-url))
    #f
    #t))

(define (git-notes-remove-tracker-url)
  (for-each
    (lambda (row)
      (let* ([id (car row)]
             [notes (string->list (cadr row))]
             [clean-notes (filter (lambda (l) (not (is-tracker-url-note? l))) notes)])
             (cond
               [(> (length notes) (length clean-notes)) (git-notes-replace (list->string clean-notes) id)])))
   (git-objects-notes)))

(define (is-set-apikey?)
  (let ([file-path (expand-user-path (build-path (get-settings-folder) "apikey"))])
    (if (file-exists? file-path) #t #f)))

(define (create-settings-folder-if-not-exists)
  (if (not (directory-exists? (get-settings-folder)))
    (make-directory (get-settings-folder))
    #f))

(define (get-setting filename)
  (let ([file-path (expand-user-path (build-path (get-settings-folder) filename))])
    (if (file-exists? file-path) (file->value file-path) #f)))

(define (save-setting filename value)
  (let ([file-path (expand-user-path (build-path (get-settings-folder) filename))])
    (if (file-exists? file-path) (delete-file file-path) #f)
    (display-to-file value file-path)))
