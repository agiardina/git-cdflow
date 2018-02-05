#! /usr/bin/env racket
#lang racket/base

(require racket/cmdline
         racket/match
         "lib/tree.rkt"
         "lib/utils.rkt")

(define help #<<MESSAGE
usage: git cdflow tree [--no-fetch] status

        status  For each release check if the last commit of the parent branch 
                has been merged in.

OPTIONS
        --no-fetch
            The command does not run a git fetch before checkin for status.


MESSAGE
)

(define fetch? (make-parameter #t))

(define (display-status-errors errors)
  (display "Family tree missing merges:\n")
  (for ([row errors])
    (display (format "~a\tnot merged in ~a\n" (cadr row) (caddr row)))))

(define (display-no-errors)
    (display "Family tree is ok!\n"))

(define (status)
  (when (fetch?) (git-fetch))
  (match (tree-status ".")  
    ['() (display-no-errors)]
    [errors (display-status-errors errors)]))

(define (main)
  (let ([command (command-line 
    #:program "git-cdflow-tree"
    #:once-each [("--no-fetch") "Does not fetch before checking tree status" (fetch? #f)]
    #:args (command)
    command)])
    (match command
      ["help" (display help)]
      ["status" (status)])))

(void (main))