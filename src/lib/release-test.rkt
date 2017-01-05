#lang racket/base

(require rackunit)
(require "release.rkt")

;version-snapshot
(check-equal? (version-snapshot 10) "10.0.0-SNAPSHOT")
(check-equal? (version-snapshot "v10.1.2") "10.1.2-SNAPSHOT")

;replace projcet version
(check-equal? (replace-clj-project-version
             "(defproject uhc-edq-crm-service \"2.0.0-SNAPSHOT\"" 3)
             "(defproject uhc-edq-crm-service \"3.0.0-SNAPSHOT\"" 3)

 (check-equal? (replace-clj-project-version
              "(defproject  \t\nuhc-edq-crm-service\t\n \"2.0.0-SNAPSHOT\"" 3)
              "(defproject  \t\nuhc-edq-crm-service\t\n \"3.0.0-SNAPSHOT\"" 3)
