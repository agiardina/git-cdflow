#lang racket/base

(provide (all-defined-out))

(require racket/string
         "utils.rkt")

(define (release-name name)
  (let* ([sname (if (number? name) (number->string name) name)]
         [vname (if (regexp-match #rx"^[v|V].*" sname) (string-downcase sname) (string-append "v" sname))])
    (cond
      [(regexp-match #px"^v[0-9]{1,3}$" vname) (string-append vname ".0.0")]
      [(regexp-match #px"^v[0-9]{1,2}\\.[0-9]{1,2}$" vname) (string-append vname ".0")]
      [(regexp-match #px"^v[0-9]{1,2}\\.[0-9]{1,2}\\.[0-9]{1,2}$" vname) vname]
      [else #f])))

(define (release-branch version)
  (cond
    [(release-name version) (string-append "release/" (release-name version))]
    [else #f]))

(define (version->list version)
  (map string->number
    (string-split
      (substring (release-name version) 1)
      ".")))

(define (sort-releases releases [reverse #f])
  (sort releases (lambda (x y)
    (if reverse
      (not (list<? (version->list x) (version->list y)))
      (list<? (version->list x) (version->list y))))))

(define (version-snapshot version)
  (string-append (substring (release-name version) 1) "-SNAPSHOT"))

(define (replace-clj-project-version str version)
  (regexp-replace
    #px"(defproject\\s+[\\w\\-]+\\s+)\"([\\w\\.\\-]+)\""
    str
    (format "\\1\"~a\"" (version-snapshot version))
    ))

(define (replace-node-project-version str version)
  (display version)
  (regexp-replace
   #px"(\"version\"\\s*:\\s*)\"([\\w\\.\\-]*)\""
   str
  (format "\\1\"~a\"" (version-snapshot version))
   )
  )
