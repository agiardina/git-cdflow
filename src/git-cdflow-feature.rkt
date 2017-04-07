#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/system
         racket/string
         racket/list
         racket/file
         "lib/utils.rkt"
         "lib/parent.rkt")

(define help #<<MESSAGE

usage: git cdflow feature start <feature-name>
       git cdflow feature finish
       git cdflow feature checkout <feature-name>
       git cdflow feature public
       git cdflow feature private

       start    Create a new branch and switch the working tree 
                to feature/<feature-name>.
              
                Example usage:
                git cdflow feature start myfeature  

       finish   Switch to parent branch and merge there the current branch.
                The parent branch is the branch that generated the current one 
                or the one that has been set with `git cdflow parent set` command.
             
                Example usage:
                git cdflow feature finish

       checkout Checking out a branch updates the files in the working directory.
                In case on origin there are both a private feature branch and a
                public one a menu will ask to the user to select the right one.

       public   Push the current branch on origin: origin/feature/<feature-name>

       private  Push the current branch on origin but on private path:
                origin/private/feature/<feature-name>   


MESSAGE
)

(define (get-feature-branch feature-name)
  (cond
    [(not feature-name) #f]
    [(regexp-match #px"^feature\\/" feature-name) feature-name]
    [else (format "feature/~a" feature-name)]))

(define (start feature-name)
  (cond
    [feature-name (create-feature-branch (get-feature-branch feature-name))]
    [else (display-err "Please specify the name of the feature branch\n")]))

(define (public)
  (cond
    [(regexp-match #px"^feature\\/" (git-current-branch)) (git-push-origin (git-current-branch))]
    [else (display-err "Please move in a feature branch\n")]))

(define (private)
  (cond
    [(regexp-match #px"^feature\\/" (git-current-branch)) (git-push-origin (format "private/~a" (git-current-branch)))]
    [else (display-err "Please move in a feature branch\n")]))

(define (git-select-remote-feature-branch branch-name)
  (git-fetch)
  (let* ([feature-branch (get-feature-branch branch-name)]
         [possible-branches (list feature-branch (format "private/~a" feature-branch))]
         [branches  (filter git-remote-branch-exists possible-branches)])
    (cond
      [(not (equal? branches '())) (show-menu "Select remote branch" (cons "NONE" branches) 1)]
      [else #f])))

(define (checkout branch-name)
  (cond 
    [(not branch-name) (display-err "No branch selected.\nUsage: git cdflow feature checkout <branch-name>\n")]
    [(git-local-branch-exists (get-feature-branch branch-name)) (git-checkout-branch (get-feature-branch branch-name))]
    [else (let ([remote-branch (git-select-remote-feature-branch branch-name)])
            (cond [remote-branch
                   (git-checkout-remote-branch-to remote-branch (get-feature-branch branch-name))]))]))

(define (try-close-in-remote-branch parent-branch)
  (let ([remote-branch (git-select-remote-feature-branch parent-branch)]
        [current-branch (git-current-branch)])
    (cond
      [remote-branch (git-checkout-remote-branch-to remote-branch parent-branch)
                     (git-merge current-branch)]
      [else (display-err "Remote branch not available or selected. Aborted!")])))

(define (close-feature-branch)
  (let ([current-branch  (git-current-branch)]
        [parent-branch  (get-parent)])
    (cond
      [(git-local-branch-exists parent-branch) (git-merge-from-to current-branch parent-branch)]
      [else (try-close-in-remote-branch parent-branch)])))

(define (finish)
  (let ([current-branch (git-current-branch)]
        [parent (get-parent)]
        [files-to-commit (git-files-to-commit)])
    (cond
      [(not (equal? files-to-commit '())) (display-err "There are files to commit. Aborted!\n") ]
      [(not parent) (display-err "No parent has been set, please see `git cdflow parent help`\n") ]
      [(not (regexp-match #px"^feature\\/" current-branch)) (display-err "Please move in a feature branch\n")]
      [else (close-feature-branch)])))

(define (main)
  (let-values (
    [(action feature-name)
      (command-line
        #:args (action [feature-name #f])
        (values action feature-name))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "start") (start feature-name)]
      [(equal? action "public") (public)]
      [(equal? action "private") (private)]
      [(equal? action "checkout") (checkout feature-name)]
      [(equal? action "finish") (finish)]
      [else (display help)])))

;(current-directory "/Users/agiardina/dev/test-repo2")

(void (main))

