#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline)
(require racket/system)
(require racket/string)
(require "lib/utils.rkt"
         "lib/issue.rkt"
         "lib/feature.rkt")

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

(define (display-insert-setting-label label)
  (display (string-append label " (enter to confirm, empty string will be ignored) \n")))

(define (configure-issue-url)
  (let []
    (display-insert-setting-label "Insert Issue Tracker URL:")
    (define url (read-line))
    (if (non-empty-string? url)
      (let []
        (git-fetch)
        (git-notes-remove-issue "url")
        (git-notes-add-issue-note "url" url)
        (git-notes-push))
        #f)))

(define (configure-issue-project)
  (let []
    (display-insert-setting-label "Insert Issue Tracker Project:")
    (define project (read-line))
    (if (non-empty-string? project)
      (let []
        (git-fetch)
        (git-notes-remove-issue "project")
        (git-notes-add-issue-note "project" project)
        (git-notes-push))
        #f)))

(define (configure-api-key)
  (display-insert-setting-label "Insert Issue Tracker Api Key:")
  (define key (read-line))
  (if (non-empty-string? key)
    (let []
      (create-settings-folder-if-not-exists)
      (save-setting "apikey" key))
      #f))

(define (select-issue-status statuses type)
  (let* ([item (show-menu
                 (format "Select the \"~a\" status from the list:\n" type)
                 (map (lambda (s) (string-append (format "~a : ~a" (hash-ref s 'id) (hash-ref s 'name)))) statuses)
                 0)])
    (string-trim (car (string-split item ":")))
    ))

(define (configure-issue-statuses)
  (let* ([resp (call-tracker-api "GET" "issue_statuses.json")]
         [statuses (hash-ref resp 'issue_statuses)]
         [open (select-issue-status statuses "OPEN")]
         [in-progress (select-issue-status statuses "IN PROGRESS")]
         [resolved (select-issue-status statuses "RESOLVED")])

    (clear-terminal-screen)

    (display "Pushing settings...\n")

    (git-fetch)

    (git-notes-remove-issue "status-open")
    (git-notes-remove-issue "status-in-progress")
    (git-notes-remove-issue "status-resolved")

    (git-notes-add-issue-note "status-open" open)
    (git-notes-add-issue-note "status-in-progress" in-progress)
    (git-notes-add-issue-note "status-resolved" resolved)

    (git-notes-push)))

(define (issue-configuration)
  (configure-issue-url)
  (configure-issue-project)
  (configure-api-key)

  (if (and (is-set-tracker-note? "url") (is-set-tracker-note? "project") (is-set-apikey?))
    (configure-issue-statuses)
    #f
  )
  (issue-status))

(define (is-configuration-ok?)
  (if (and
        (is-set-tracker-note? "url")
        (is-set-tracker-note? "project")
        (is-set-apikey?)
        (is-set-tracker-note? "status-open")
        (is-set-tracker-note? "status-in-progress")
        (is-set-tracker-note? "status-resolved")
        )
    #t
    #f))

(define (issue-status)
  (display "ISSUE TRACKER SETUP\n\n")
  (display "[Redmine URL]: \t")
  (if (is-set-tracker-note? "url")
    (display (get-issue-note "url"))
    (display "-"))

  (display "\n[Project]: \t")
  (if (is-set-tracker-note? "project")
    (display (get-issue-note "project"))
    (display "-"))

  (display "\n[API Key]: \t")
  (if (is-set-apikey?)
    (display (get-setting "apikey"))
    (display "-"))

  (display "\n[open]: \t")
  (if (is-set-tracker-note? "status-open")
    (display (get-issue-note "status-open"))
    (display "-"))

  (display "\n[in-progress]: \t")
  (if (is-set-tracker-note? "status-in-progress")
    (display (get-issue-note "status-in-progress"))
    (display "-"))

  (display "\n[resolved]: \t")
  (if (is-set-tracker-note? "status-resolved")
    (display (get-issue-note "status-resolved"))
    (display "-"))

  (display "\n\nCONFIGURATION: ")
  (if (is-configuration-ok?)
    (display "OK\n\n")
    (display "Not Ready! Run: git cdflow issue config\n\n")
  ))

(define (put-issue-inprogress id)
  (let* ([data (format "{\"issue\":{\"status_id\":\"~a\"}}" (get-issue-note "status-in-progress"))])
    (call-tracker-api "PUT" (format "issues/~a.json" id) "" data)))

(define (get-my-issues-list)
  (if (is-configuration-ok?)
    (let* ([query (string-append "assigned_to_id=me&sort=fixed_version:desc,priority:desc&status_id=" (get-issue-note "status-open"))]
           [resp (call-tracker-api "GET" "issues.json" query)]
           [issues (hash-ref resp 'issues)]
           [item (show-menu "Select the issue to close" (map (lambda (s) (build-issue-row s)) issues) 0)]
           [issue-name-list (map (lambda (s) (string-downcase (string-replace (string-replace s "[" "") "]" ""))) (cdr (string-split item)))]
           [issue-id (car issue-name-list)]
           [new-feature-name (string-join issue-name-list "-")])

           (clear-terminal-screen)
           (display (string-append "Starting feature " new-feature-name "\n"))
           (put-issue-inprogress issue-id)
           (create-feature-branch (string-append "feature/" new-feature-name))
           (open-browser-page (string-append (get-issue-note "url") "/issues/" issue-id))
      )
      (display "Project Issue Tracker not configured!\nRun: git cdflow issue config\n")))

(define (main)
  (let-values (
    [(action)
      (command-line
        #:args ([action #f])
        (values action))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "list") (get-my-issues-list)]
      [(equal? action "config") (issue-configuration)]
      [(equal? action "status") (issue-status)]
      )))

(void (main))
