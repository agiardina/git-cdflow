#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline)
(require racket/system)
(require racket/string)
(require net/http-client)
(require json)
(require "lib/utils.rkt"
         "lib/feature.rkt")

(define (put-issue-inprogress issue_id endpoint key)
  (http-sendrecv "projects.hoverstate.com"
                 (string-append "/issues/" issue_id ".json&key=" key)
                 #:ssl? #t
                 ;#:port 8888
                 #:method #"PUT"
                 #:headers (list "Content-Type: application/json")
                 #:data "{\"issue\":{\"status_id\":\"2\"}}"))

(let-values   ([(status headers port) (http-sendrecv "projects.hoverstate.com" "/issues.json?status_id=9&project_id=82&key=1baae9438c564e80319b0d5bb1372d2b38fb7885&assigned_to_id=me" #:ssl? #t )])
  (let* ([menu-items (map (lambda (issue)
                  (string-append "#" (number->string (hash-ref issue 'id)) " - " (hash-ref issue 'subject)))
                          (hash-ref (read-json port) 'issues))]
         [item (show-menu "Select the issue to close" menu-items 0)]
         [issue (substring item 0 6)]
         [issue_id (substring item 1 6)])
    
    (create-feature-branch (string-append "feature/" issue))
    (put-issue-inprogress issue_id "projects.hoverstate.com" "1baae9438c564e80319b0d5bb1372d2b38fb7885")))
