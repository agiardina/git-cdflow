#! /usr/bin/env racket
#lang racket/base

(require racket/cmdline
         racket/match
         "lib/tree.rkt"
         "lib/utils.rkt")

(define help #<<MESSAGE
usage: git cdflow tree status

        status  For each release check if the last commit of the parent branch 
                has been merged in.

OPTIONS
        --no-fetch
            The command does not run a git fetch before checkin for status.


MESSAGE
)

(define fetch? (make-parameter #t))

(define (status)
  (when (fetch?) (git-fetch))
  (for ([row (tree-status ".")])
    (display (format "~a has not been merged in ~a\n" (cadr row) (caddr row)))))

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