#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/match
         racket/string
         "lib/utils.rkt"
         "lib/release.rkt")

(define help #<<MESSAGE
usage: git cdflow parent show
       git cdflow parent set <parent-branch>
       git cdflow parent pull

       show   If the current branch has a parent branch the command show it.
              The parent branch is automatically set when a new feature or
              a new release branch has been created with git cdflow.
              The parent branch can be set with the *cdflow parent set* command.

       set    Set the parent branch of the current one.
              Example: git cdflow parent set release/v8.0.0

       pull   Fetch the changes from the parent branch and merge in the current
              one.

MESSAGE
)

(define (get-parent)
  (ormap (lambda (l)
    (parent-match (git-current-branch) (cadr l)))
    (git-objects-notes)))

(define (show)
  (let ([parent (get-parent)])
    (if parent
      (displayln parent)
      (display-err "Parent has not been set.
Use git cdflow parent set <branch> to set parent branch.

Try 'git cdflow parent help' for details.

"))))
(define (set-parent parent)
  (filter
    (lambda (l) (not (parent-match (git-current-branch) l)))
    (string->list
      (git-object-show-notes "adf4358b9db228b8d418f3deed88895c6bc70d20"))))

(define (try-set-parent params)
  (cond
    [(equal? params '())
      (display-err "Missing <parent-branch> parameter.\n\n")
      (display-err help)]
    [(> (length params) 1)
      (display-err "Too many parameters.\n\n")
      (display-err help)]
    [(string=? (car params) (git-current-branch))
      (display-err "In order to be parent of yourself create first a time machine!!!\n\n")
      (display-err help)]
    [else (set-parent (car params))]))

(define (main)
  (let-values (
    [(action params)
      (command-line
        #:args (action . params)
        (values action params))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "set") (try-set-parent params)]
      [(equal? action "show") (show)])))
