#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline)
(require racket/system)
(require racket/string)
(require net/http-client)
(require json)
(require "lib/utils.rkt"
         "lib/issue.rkt")

(define-values (in out) (make-pipe))

(define help #<<MESSAGE
usage: git cdflow issue list
       git cdflow issue config
       git cdflow issue status

       list     If a Redmine issue tracker in configured, the command will
                show the list of issues assigned to the configured user.
                Issues can be selected in order to start a new feature to work
                on it.

       config   Start the configuration process in order to setup a Redmine
                Issue Tracker linked with the repository.

       status   Show the current configuration.

MESSAGE
  )

(define (configure-issue-url)
  (let []
    (display "Insert Issue Tracker URL: \n")
    (define url (read-line))
    (if (non-empty-string? url)
      (let []
        (git-fetch)
        (git-notes-remove-tracker-url)
        (git-notes-add-issue-tracker-url url)
        (git-notes-push))
        #f)))

(define (configure-api-key)
  (display "Insert Issue Tracker Api Key: \n")
  (define key (read-line))
  (if (non-empty-string? key)
    (let []
      (create-settings-folder-if-not-exists)
      (save-setting "apikey" key))
      #f))

(define (issue-configuration)
  (configure-issue-url)
  (configure-api-key)
  (issue-status))

(define (issue-status)
  (display "ISSUE TRACKER SETUP\n\n")
  (display "[Redmine URL]: \t")
  (if (is-set-tracker-url?)
    (display (get-tracker-url))
    (display "-"))

  (display "\n[API Key]: \t")
  (if (is-set-apikey?)
    (display (get-setting "apikey"))
    (display "-"))

  (display "\n\nStatus: ")
  (if (and (is-set-tracker-url?) (is-set-apikey?))
    (display "OK\n\n")
    (display "Not Ready! Run: git cdflow issue config\n\n")
  )
)

(define (put-issue-inprogress issue_id endpoint key)
  (http-sendrecv "projects.hoverstate.com"
                 (string-append "/issues/" issue_id ".json&key=" key)
                 #:ssl? #t
                 ;#:port 8888
                 #:method #"PUT"
                 #:headers (list "Content-Type: application/json")
                 #:data "{\"issue\":{\"status_id\":\"2\"}}"))

;(let-values   ([(status headers port) (http-sendrecv "projects.hoverstate.com" "/issues.json?status_id=9&project_id=82&key=1baae9438c564e80319b0d5bb1372d2b38fb7885&assigned_to_id=me" #:ssl? #t )])
;  (let* ([menu-items (map (lambda (issue)
;                  (string-append "#" (number->string (hash-ref issue 'id)) " - " (hash-ref issue 'subject)))
;                          (hash-ref (read-json port) 'issues))]
;         [item (show-menu "Select the issue to close" menu-items 0)]
;         [issue (substring item 0 6)]
;         [issue_id (substring item 1 6)])
;
;    (create-feature-branch (string-append "feature/" issue))
;    (put-issue-inprogress issue_id "projects.hoverstate.com" "1baae9438c564e80319b0d5bb1372d2b38fb7885")))


(define (main)
  (let-values (
    [(action)
      (command-line
        #:args ([action #f])
        (values action))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "list") (display "TODO")]
      [(equal? action "config") (issue-configuration)]
      [(equal? action "status") (issue-status)]

      ;[(equal? action #f) (display (git-objects-notes))]

      )))

(void (main))
