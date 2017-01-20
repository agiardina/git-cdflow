#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/system
         racket/string
         racket/list
         racket/file
         "lib/utils.rkt")

(define help #<<MESSAGE

usage: git cdflow feature start <feature-name>
       git cdflow feature finish
       git cdflow feature public
       git cdflow feature private

       start   Create a new branch and switch the working tree 
               to feature/<feature-name>.
              
               Example usage:
               git cdflow feature start myfeature  

       finish  Switch to parent branch and merge there the current branch.
               The parent branch is the branch that generated the current one 
               or the one that has been set with `git cdflow parent set` command.
             
               Example usage:
               git cdflow feature finish

       public  Push the current branch on origin: origin/feature/<feature-name>

       private Push the current branch on origin but on private path:
               origin/private/feature/<feature-name>   


MESSAGE
)

(define (get-feature-branch feature-name)
  (cond
    [(not feature-name) #f]
    [(regexp-match #px"^feature\\/" feature-name) feature-name]
    [else (format "feature/~a" feature-name)]))

(define (create-feature-branch feature-branch)
  (let ([current-branch (git-current-branch)])
    (git-branch feature-branch)
    (git-notes-add-parent current-branch feature-branch)))

(define (start feature-name)
  (cond
    [feature-name (create-feature-branch (get-feature-branch feature-name))]
    [else (display-err "Please specify the name of the feature branch\n")]))

(define (finish)
  (display "finish"))

(define (main)
  (let-values (
    [(action feature-name)
      (command-line
        #:args (action [feature-name #f])
        (values action feature-name))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "start") (start feature-name)]
      [(equal? action "finish") (finish)]
      [else (display help)])))

(void (main))
