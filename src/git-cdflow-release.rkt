#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/system
         racket/string
         racket/list
         "lib/utils.rkt"
         "lib/release.rkt")

(define help #<<MESSAGE

usage: git flow release help
       git flow release list
       git flow release start <version> [<base>]

MESSAGE
)

(define sh-release-list
  "git branch -r | egrep -i \"release/v[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$\" | cut -d/ -f3")

(define (release-branch version)
  (cond
    [(release-name version) (string-append "release/" (release-name version))]
    [else #f]))

;move to lib
(define (version->list version)
  (map string->number
    (string-split
      (substring (release-name version) 1)
      ".")))

;move to lib
(define (sort-releases releases [reverse #f])
  (sort releases (lambda (x y)
    (if reverse
      (not (list<? (version->list x) (version->list y)))
      (list<? (version->list x) (version->list y))))))

(define (release-branches)
  (sh->list "git branch -r | egrep -i \"release/v[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$\" | cut -d/ -f3"))

;mobe to lib
(define (release-exists? version)
  (member (release-name version) (release-branches)))

(define (show-release-from-menu branches)
  (let ([menu-items (take-upto (sort-releases branches #t) 10)])
    (show-menu "Select the release branch you want to branch from" menu-items 0)))

(define (branch-release-from [base #f])
  (cond
    [base base]
    [(equal? (release-branches) '()) "master"]
    [else (string-append
            "release/"
            (show-release-from-menu (release-branches)))]))

(define (show-releases)
  (display (sh->string sh-release-list)))

(define (git-create-release start version)
  (system (format "git checkout ~a" start))
  (display version))

(define (display-help)
  (display help))

(define (create-release version base)
  (cond
    [(not version) (err "Missing release version" display-help)]
    [(release-exists? version) (err "Release already exists")]
    [(not (release-name version)) (err "Invalid release name")]
    [else (git-create-release (branch-release-from base) version)]))

(define (main)
  (let-values (
    [(action version base)
      (command-line
        #:args (action [version #f] [base #f])
        (values action version base))])

    (cond
      [(equal? action "help") (display help)]
      [(equal? action "list") (show-releases)]
      [(equal? action "start") (create-release version base)]
      )
  ))

(main)
;(sort-releases '("v10.0.0" "v8.5.0" "v9.0.2" "v10.1.0") )
;(release-exists? "9")


;(branch-from)
;(release-branches)
;(show-release-from-menu (release-branches))
;(display help)
