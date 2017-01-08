#! /usr/bin/env racket

#lang racket/base

(require racket/cmdline
         racket/system
         racket/string
         racket/list
         racket/file
         "lib/utils.rkt"
         "lib/release.rkt")

(define help #<<MESSAGE

usage: git cdflow release help
       git cdflow release list
       git cdflow release start <version> [<base>]

MESSAGE
)

(define sh-release-list
  "git branch -r | egrep -i \"release/v[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$\" | cut -d/ -f3")

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

(define (project-file filename)
  (let ([files (sh->list (format "find . -name '~a'" filename))])
    (cond
      [(equal? files '()) #f]
      [(= (length files) 1) (car files)]
      [(> (length files) 1) (show-menu
                              "Select the project file to update"
                              (cons "NONE" files) 1)])))

(define (project.clj)
  (project-file "project.clj"))

(define (project-clj-set-version file version)
  (display-to-file
    (replace-clj-project-version (file->string file) version)
    "project.clj"
    #:exists 'replace))

(define (handle-clojure-project version)
  (let ([file (project.clj)])
    (cond [file (project-clj-set-version file version)
                (git-commit file "Version number updated")]
          [else #f])))

(define (pom.xml)
  (project-file "pom.xml"))

(define (pom-set-version file version)
  (sh
    (format "cd `dirname ~a` && mvn versions:set -DnewVersion='~a'"
      file (version-snapshot version))))

(define (versionset-modified)
  (map (lambda (item)
    (substring item 0 (- (string-length item) 15)))
    (sh->list "find . -iname 'pom.xml.versionsBackup'")))

(define (git-commit-versionset-modified)
  (git-commit (versionset-modified) "Version number updated"))

(define (remove-versionset-backup-files)
  (sh "find . -name \"pom.xml.versionsBackup\" -delete"))

(define (handle-maven-project version)
  (let ([file (pom.xml)])
    (cond [file (pom-set-version file version)
                (git-commit-versionset-modified)
                (remove-versionset-backup-files)])))

(define (git-create-release start version)
  (git-branch-from start (release-branch version))
  (or (handle-clojure-project version)
      (handle-maven-project version)))

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
      [(equal? action "start") (create-release version base)])))

(void (main))
;(git-commit-versionset-modified)
;(sort-releases '("v10.0.0" "v8.5.0" "v9.0.2" "v10.1.0") )
;(release-exists? "9")


;(branch-from)
;(release-branches)
;(show-release-from-menu (release-branches))
;(display help)
