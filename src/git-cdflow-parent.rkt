#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/match
         racket/string
         "lib/utils.rkt"
         "lib/parent.rkt")

(define help #<<MESSAGE
usage: git cdflow parent show
       git cdflow parent set <parent-branch>
       git cdflow parent [-l|--local] pull

       show   If the current branch has a parent branch the command show it.
              The parent branch is automatically set when a new feature or
              a new release branch has been created with git cdflow.
              The parent branch can be set with the *cdflow parent set* 
              command.

       set    Set the parent branch of the current one.
              Example: git cdflow parent set release/v8.0.0

       pull   Fetch the changes from the parent branch and merge in the current
              one.

OPTIONS
       -l, --local
           The command does not run a git fetch and a git push.
  

MESSAGE
  )

(define fetch? (make-parameter #t))

(define (show)
  (let ([parent (get-parent)])
    (if parent
      (displayln parent)
      (display-err "Parent has not been set.
Use git cdflow parent set <branch> to set parent branch.

Try 'git cdflow parent help' for details.

"))))

(define (pull)
  (cond [(fetch?) (git-fetch)])
  (sh (format "git merge origin/~a" (get-parent))))

(define (set-parent parent)
  (git-fetch)
  (git-notes-remove-parent (git-current-branch))
  (git-notes-add-parent parent (git-current-branch))
  (git-notes-push))

(define (try-set-parent params)
  (cond
    [(equal? params '())
      (display-err "Missing <parent-branch> parameter.\n\n")
      (display-err help)]
    [(> (length params) 1)
      (display-err "Too many parameters.\n\n")
      (display-err help)]
    [(string=? (parent-full-name (car params)) (git-current-branch))
      (display-err "In order to be parent of yourself create first a time machine!!!\n\n")
      (display-err help)]
    [(not (git-remote-branch-exists (parent-full-name (car params))))
      (display-err (format "Branch \"~a\"does not exists on origin.\n\n" (car params)))
      (display-err help)]
    [else (set-parent (parent-full-name (car params)))]))

(define (main)
  (let-values (
    [(action params)
      (command-line
       #:once-each
       [("-l" "--local") "No fetch before running the command"
                       (fetch? #f)]
       #:args (action . params)
        (values action params))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "pull") (pull)]
      [(equal? action "set") (try-set-parent params)]
      [(equal? action "show") (show)])))

(void (main))
