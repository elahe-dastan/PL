;; PL Project - Spring 2020
;; NUMEX interpreter

#lang racket
(provide (all-defined-out)) ;; so we can put tests in a second file

;; definition of structures for NUMEX programs

;; CHANGE add the missing ones

(struct var  (string) #:transparent)  ;; a variable, e.g., (var "foo")
(struct num  (int)    #:transparent)  ;; a constant number, e.g., (num 17)

(struct bool (boolean) #:transparent)

(struct plus  (e1 e2)  #:transparent)  ;; add two expressions
(struct minus (e1 e2)  #:transparent)
(struct mult (e1 e2)  #:transparent)
(struct div (e1 e2)  #:transparent)
(struct neg (e)  #:transparent)
(struct andalso (e1 e2)  #:transparent)
(struct orelse (e1 e2)  #:transparent)
(struct cnd (e1 e2 e3)  #:transparent)
(struct iseq (e1 e2)  #:transparent)
(struct ifnzero (e1 e2 e3)  #:transparent)
(struct ifleq (e1 e2 e3 e4)  #:transparent)
(struct with (s e1 e2)  #:transparent)


(struct lam  (nameopt formal body) #:transparent) ;; a recursive(?) 1-argument function
(struct apply (funexp actual)       #:transparent) ;; function application


(struct munit   ()      #:transparent) ;; unit value -- good for ending a list
(struct ismunit (e)     #:transparent) ;; if e1 is unit then true else false

;; a closure is not in "source" programs; it is what functions evaluate to
(struct closure (env f) #:transparent) 

(struct letrec (s1 e1 s2 e2 s3 e3 e4) #:transparent) ;; a letrec expression for recursive definitions
(struct queue (e q) #:transparent) ;; it holds several expressions
(struct enqueue (e q) #:transparent) ;; it enqueues e into q
(struct dequeue (q) #:transparent) ;; it dequeues q
(struct extract (q) #:transparent) ;; it returns queue's top element

(struct apair (e1 e2) #:transparent)
(struct 1st (e) #:transparent)
(struct 2nd (e) #:transparent)


;; Problem 1

(define (racketlist->numexlist xs) (cond [(null? xs) (munit)]
                                         [(list? xs) (apair (car xs) (racketlist->numexlist (cdr xs)))]
                                         [#t error "racketlist->numexlist: input is not a list"])
)
(define (numexlist->racketlist xs) (cond [(munit? xs) null]
                                         [(apair? xs) (cons (apair-e1 xs) (numexlist->racketlist (apair-e2 xs)))]
                                         [#t error "numexlist->racketlist: input is not a list"]))

;; Problem 2

;; lookup a variable in an environment
;; Complete this function
(define (envlookup env str)
  (cond [(null? env) (error "unbound variable during evaluation" str)]
        [(list? env) (cond [(equal? str (car (car env))) (cdr (car env))]
                           [#t (envlookup (cdr env) str)])]
        [#t error "envlookup: env is not a list"]
        )
 )

;; Complete more cases for other kinds of NUMEX expressions.
;; We will test eval-under-env by calling it directly even though
;; "in real life" it would be a helper function of eval-exp.
(define (eval-under-env e env)
  (cond [(var? e) 
         (envlookup env (var-string e))]
        [(plus? e) 
         (let ([v1 (eval-under-env (plus-e1 e) env)]
               [v2 (eval-under-env (plus-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (+ (num-int v1) 
                       (num-int v2)))
               (error "NUMEX addition applied to non-number")))]
        ;; CHANGE add more cases here
        [(num? e)
         (envlookup env (num-int e))]
        [(bool? e)
        (envlookup env (bool-boolean e))]
        [(closure? e)
         e]
        [(munit? e)
         e]
        [(apair? e)
         (apair (eval-under-env (apair-e1 e) env)
                (eval-under-env (apair-e2 e) env))]
        [(minus? e)
         (let ([v1 (eval-under-env (minus-e1 e) env)]
               [v2 (eval-under-env (minus-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (- (num-int v1)
                       (num-int v2)))
               (error "NUMEX subteaction applied to non-number")))]
        [(mult? e)
         (let ([v1 (eval-under-env (mult-e1 e) env)]
               [v2 (eval-under-env (mult-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (num (* (num-int v1)
                       (num-int v2)))
                (error "NUMEX multipliction applied to non-number")))]
        [(div? e)
         (let ([v1 (eval-under-env (div-e1 e) env)]
               [v2 (eval-under-env (div-e2 e) env)])
           (if (and (num? v1)
                    (num? v2))
               (if (eq? 0 (num-int v2))
                   (error "NUMEX div by 0")
               (num (quotient (num-int v1) (num-int v2)))
               )
               (error "NUMEX div applied to non-number")))]
        
        [(neg? e)
         (let ([v (eval-under-env (neg-e e) env)])
           (cond [(num? v) (num (* -1 (num-int v)))]
                 [(bool? v) (bool (if (bool-boolean v) #f #t))]
                 [else (error "NUMEX neg applied to non-number and non-boolean")]))]
        [(andalso? e)
         (let ([v1 (eval-under-env (andalso-e1 e) env)])
           (if (bool? v1)
               (if (equal? (bool-boolean v1) #f) (bool #f)
                   (let ([v2 (eval-under-env (andalso-e2 e) env)])
                     (if (bool? v2)
                         (if (bool-boolean v2) (bool #t) (bool #f))
                     (error "NUMEX andalso applied to non-boolean")))
                   )
               (error "NUMEX andalso applied to non-boolean")))]
        [(orelse? e)
         (let ([v1 (eval-under-env (orelse-e1 e) env)])
           (if (bool? v1)
               (if (bool-boolean v1) (bool #t)
                   (let ([v2 (eval-under-env (orelse-e2 e) env)])
                     (if (bool? v2)
                         (if (bool-boolean v2) (bool #t) (bool #f))
                     (error "NUMEX andalso applied to non-boolean")))
                   )
               (error "NUMEX andalso applied to non-boolean")))]
        [(cnd? e)
         (let ([v1 (eval-under-env (cnd-e1 e) env)])
           (if (bool? v1)
               (if (bool-boolean v1) (eval-under-env (cnd-e2 e) env) (eval-under-env (cnd-e3 e) env))
               (error "NUMEX cnd applied to non-boolean")))]
        [(iseq? e)
         (let ([v1 (eval-under-env (iseq-e1 e) env)]
               [v2 (eval-under-env (iseq-e2 e) env)])
           (cond [(and (num? v1) (num? v2)) (bool (= (num-int v1)(num-int v2)))]
                 [(and (bool? v1) (bool? v2)) (if (bool-boolean v1) v2 (bool (not (bool-boolean v2))))]
                 [(or (and (num? v1) (bool? v2)) (and (bool? v1) (num? v2))) (bool #f)]
                 [#t error "NUMEX iseq applied to non-number and non-boolean"]))]
        [(ifnzero? e)
         (let ([v1 (eval-under-env (ifnzero-e1 e) env)])
           (if (num? v1)
               (if (= (num-int v1) 0) (eval-under-env (ifnzero-e3 e) env) (eval-under-env (ifnzero-e2 e) env))
               (error "NUMEX ifnzero applied to non-number")))]
        [(ifleq? e)
         (let ([v1 (eval-under-env (ifleq-e1 e) env)]
               [v2 (eval-under-env (ifleq-e2 e) env)])
           (if (and (num? v1) (num? v2))
               (if (> (num-int v1) (num-int v2)) (eval-under-env (ifleq-e4 e) env) (eval-under-env (ifleq-e3 e) env))
               (error "NUMEX ifleq applied to non-number")))]
        [(with? e)
         (let ([v1 (eval-under-env (with-e1 e) env)])
           (if (string? (with-s e))
               (eval-under-env (with-e2 e) (cons (cons (with-s e) v1) env))
               (error "NUMEX with applied to non-string")))]
        [(lam? e)
         (if (and (or (string? (lam-nameopt e)) (null? (lam-nameopt e))) (string? (lam-formal e)))
             (closure env e)
             (error "NUMEX lam applied to non-string"))]
        [(apply? e)
         (let ([funclosure (eval-under-env (apply-funexp e) env)]
               [actualpar (eval-under-env (apply-actual e) env)])
           (if (closure? funclosure)
               (eval-under-env (lam-body (closure-f funclosure))
                               (if (null? (lam-nameopt (closure-f funclosure)))
                                   (cons (cons (lam-formal (closure-f funclosure)) actualpar) (closure-env funclosure))
                                   (cons (cons (lam-formal (closure-f funclosure)) actualpar)
                                         (cons (cons (lam-nameopt (closure-f funclosure)) funclosure) (closure-env funclosure)))))
               (error "NUMEX apply applied to non-function")))]
        [(1st? e)
         (let ([v (eval-under-env (1st-e e) env)])
           (if (apair? v)
               (apair-e1 v)
               (error "NUMEX 1st applied to a non-pair")))]
        [(2nd? e)
         (let ([v (eval-under-env (2nd-e e) env)])
           (if (apair? v)
               (apair-e2 v)
               (error "NUMEX 2nd applied to a non-pair")))]
        [(ismunit? e)
         (let ([v (eval-under-env (ismunit-e e) env)])
           (if (munit? v)
               (bool #t)
               (bool #f)))]
        [(letrec? e)
         (if (and (string? (letrec-s1 e)) (string? (letrec-s2 e)))
             (let ([str1 (letrec-s1 e)] [str2 (letrec-s2 e)])
               (eval-under-env (letrec-e3 e) (cons (cons str2 (apply (letrec-e1 e))) (cons (cons str1 (apply (letrec-e1 e) (letrec-e2 e))) env))))
             (error "NUMEX letrec applied to non-string"))]
        
        [#t (error (format "bad NUMEX expression: ~v" e))]))

;; Do NOT change
(define (eval-exp e)
  (eval-under-env e null))
        
;; Problem 3

(define (ifmunit e1 e2 e3) "CHANGE")

(define (with* bs e2) "CHANGE")

(define (ifneq e1 e2 e3 e4) "CHANGE")

;; Problem 4

(define numex-filter "CHANGE")

(define numex-all-gt
  (with "filter" numex-filter
        "CHANGE (notice filter is now in NUMEX scope)"))