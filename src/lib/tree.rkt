#lang racket/base

(require  racket/set
          racket/list
          racket/string
          racket/function
          "utils.rkt"
          "release.rkt")

(provide (all-defined-out))

(define (get-root edges)
  (let ([parents (list->set (map car edges))]
        [children (list->set (map cadr edges))])
        (set-first (set-subtract parents children))))

(define (visualize-tree t0)
  (let loop ([t t0] [last? #t] [indent '()])
    (define (I mid last) (cond [(eq? t t0) ""] [last? mid] [else last]))
    (for-each display (reverse indent))
    (unless (eq? t t0) (printf "|\n"))
    (for-each display (reverse indent))
    (printf "~a~a\n" (I "+-" "+-") (car t))
    (for ([s (cdr t)] [n (in-range (- (length t) 2) -1 -1)])
      (loop s (zero? n) (cons (I "  " "| ") indent)))))

(define (get-children edges parent)
  (map cadr (filter (lambda (edge) (equal? (car edge) parent)) edges)))

(define make-tree
  (case-lambda
    [(edges root) (let ([children (get-children edges root)])
        (if (empty? children)
          (list root)
          (cons root (map (lambda (v) (make-tree edges v)) children))))]
    [(edges) (make-tree edges (get-root edges))]))

(define (parent-row-format? row)
  (regexp-match #px"^\\[[^\\s]+ -> [^\\s]+\\]$" row))

(define (git-notes-filter-parents path)
  (filter parent-row-format? (set->list (list->set (sh->list (format "cd ~a; git log --all --show-notes=cdflow --pretty=format:%N" path))))))

(define (git-notes-parents->pairs path)
  (map 
    (lambda (row) (string-split (substring row 1 (- (string-length row) 1)) " -> ")) 
    (git-notes-filter-parents path)))

(define (branches-edges path)
  (let ([pairs (git-notes-parents->pairs path)]
        [branches-set (list->set (git-remote-branches-list path))])
        
    (filter (lambda (pair) (andmap (curry set-member? branches-set) pair)) pairs)))

(define (tree-status path)
  (let* ([releases-edges (filter (lambda (edge) (release-branch? (cadr edge))) (git-notes-parents->pairs path))]
         [releases-edges-remote (filter (lambda (edge) (andmap git-remote-branch-exists edge)) releases-edges)]
         [commits (apply hash (flatten (git-remote-commits path)))]
         [releases-commit (map (lambda (edge) (cons (hash-ref commits (car edge) #f) edge)) releases-edges-remote)])
    (filter 
      (lambda (row) 
        (and 
          (car row)
          (not (git-remote-branch-contains-commit? path (caddr row) (car row))))) 
      releases-commit)))