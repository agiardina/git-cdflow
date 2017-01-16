#lang racket/base

(require rackunit)
(require "parent.rkt")

(check-equal? (notes-filter-out-parent "[release/v9.0.0 -> release/v10.0.0]\n\n[release/v9.0.0 -> release/v11.0.0]\n\n[release/v9.0.0 -> release/v11.0.0]\n\n[release/v9.0.0 -> release/v100.0.0]\n" "release/v11.0.0") "[release/v9.0.0 -> release/v10.0.0]\n\n\n\n[release/v9.0.0 -> release/v100.0.0]")
