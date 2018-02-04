#lang racket/base

(require  racket/set
          racket/list
          racket/string
          "utils.rkt"
          "release.rkt")

(provide (all-defined-out))

(define (get-root edges)
  (let ([parents (list->set (map car edges))]
        [children (list->set (map cadr edges))])
        (set-first (set-subtract parents children))))

(define (get-children edges parent)
  (map cadr (filter (lambda (edge) (equal? (car edge) parent)) edges)))

(define (make-tree edges root)
  (let ([children (get-children edges root)])
    (if (empty? children)
      (hasheq 'name root)
      (hasheq 'name root 'children (map (lambda (v) (make-tree edges v)) children)))))

(define (parent-row-format? row)
  (regexp-match #px"^\\[[^\\s]+ -> [^\\s]+\\]$" row))

(define (git-notes-filter-parents path)
  (filter parent-row-format? (set->list (list->set (sh->list (format "cd ~a; git log --all --show-notes=cdflow --pretty=format:%N" path))))))

(define (git-notes-parents->pairs path)
  (map 
    (lambda (row) (string-split (substring row 1 (- (string-length row) 1)) " -> ")) 
    (git-notes-filter-parents path)))

(define (tree-status path)
  (let* ([releases-edges (filter (lambda (edge) (release-branch? (cadr edge))) (git-notes-parents->pairs path))]
         [commits (apply hash (flatten (git-remote-commits path)))]
         [releases-commit (map (lambda (edge) (cons (hash-ref commits (car edge) #f) edge)) releases-edges)])
    (filter (lambda (row) (and (car row) (not (git-remote-branch-contains-commit? path (caddr row) (car row))))) releases-commit)))