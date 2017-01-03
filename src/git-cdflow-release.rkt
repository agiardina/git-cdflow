#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline)
(require racket/system)

(define help #<<MESSAGE
usage: git cdflow release

Available subcommands are:
   feature   Manage your feature branches.
   release   Manage your release branches.
   hotfix    Manage your hotfix branches.
   version   Shows version information.

Try 'git cdflow <subcommand> help' for details.

MESSAGE
)

(display help)
