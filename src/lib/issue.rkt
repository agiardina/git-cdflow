#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/match
         racket/string
         racket/file
         net/http-client
         json
         "../lib/utils.rkt")

(provide (all-defined-out))

(define (is-issue-note? type str)
  (regexp-match (string-append "issue-tracker-" type " ::") str))

(define (get-note-with-tracker-type type)
  (let ([note (filter (lambda (l) (is-issue-note? type l)) (map (lambda (l) (cadr l)) (git-objects-notes ".")))])
    (if (= 0 (length note)) "" (car note))))

(define (clean-note-value key str)
  (string-trim (string-replace
    (string-replace
      (string-replace
        str
        (string-append key " ::") "")
      "[" "")
      "]" "")))

(define (get-issue-note type)
  (let ([tracker (filter (lambda (l) (is-issue-note? type l)) (string->list (get-note-with-tracker-type type)))])
    (if (= 0 (length tracker))
    #f
    (clean-note-value (string-append "issue-tracker-" type) (car tracker)))))

(define (is-set-tracker-note? type)
  (if (not (get-issue-note type))
    #f
    #t))

(define (git-notes-remove-issue type)
  (for-each
    (lambda (row)
      (let* ([id (car row)]
             [notes (string->list (cadr row))]
             [clean-notes (filter (lambda (l) (not (is-issue-note? type l))) notes)])
             (cond
               [(> (length notes) (length clean-notes)) (git-notes-replace (list->string clean-notes) id)])))
   (git-objects-notes ".")))

(define (is-set-apikey?)
  (let ([file-path (expand-user-path (build-path (get-settings-folder) "apikey"))])
    (if (file-exists? file-path) #t #f)))

(define (create-settings-folder-if-not-exists)
  (if (not (directory-exists? (get-settings-folder)))
    (make-directory (get-settings-folder))
    #f))

(define (get-setting filename)
  (let ([file-path (expand-user-path (build-path (get-settings-folder) filename))])
    (if (file-exists? file-path) (format "~a" (file->value file-path)) #f)))

(define (save-setting filename value)
  (let ([file-path (expand-user-path (build-path (get-settings-folder) filename))])
    (if (file-exists? file-path) (delete-file file-path) #f)
    (display-to-file value file-path)))

(define (call-tracker-api method resource [query ""] [data ""])
  (let*-values ([(endpoint) (get-issue-note "url")]
                [(splitted-url) (string-split endpoint "://")]
                [(protocol) (car splitted-url)]
                [(url) (cadr splitted-url)]
                [(ssl) (if (equal? protocol "https") #t #f)]
                [(project) (get-issue-note "project")]
                [(key) (get-setting "apikey")]
                [(full-path) (string-append "/" resource "?" query "&project_id=" project "&key=" key)]
                [(status headers port) (http-sendrecv url
                                                      full-path
                                                      #:ssl? ssl
                                                      #:method method
                                                      #:headers (list "Content-Type: application/json")
                                                      #:data data)])

         (read-json port)))

(define (build-issue-row issue)
  (let* ([target-version (if (hash-ref issue 'fixed_version #f) (format "~a" (hash-ref (hash-ref issue 'fixed_version) 'name)) "[No Target]")]
         [version-num (extract-version-number target-version)])
    (format "~a - ~a\t#~a - ~a"
            (format "[~a]" version-num)
            (format "~a" (hash-ref (hash-ref issue 'priority) 'name))
            (hash-ref issue 'id)
            (hash-ref issue 'subject))
  ))
