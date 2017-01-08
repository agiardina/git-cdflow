#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline)
(require racket/system)
(require racket/string)

(define version "git-cdflow version 0.0.1")


(define help #<<MESSAGE
usage: git cdflow <command>

Available command are:
   feature   Manage your feature branches.
   release   Manage your release branches.
   version   Shows version information.

Try 'git cdflow <command> help' for details.

MESSAGE
)

(define subcommands '("feature" "release" "hotfix"))

(define (subcommand command params)
  (void (system (string-join (cons (string-append "git-cdflow-" command) params)))))

; Main Body
(define args (vector->list (current-command-line-arguments)))

(cond
  [(= (length args) 0) (display help)]
  [(equal? (car args) "version") (displayln version)]
  [(member (car args) subcommands) (subcommand (car args) (cdr args))]
  [else (display help)])
;(command-line #:args (filename) filename)
