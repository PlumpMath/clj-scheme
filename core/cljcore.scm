

(define nil 'nil)
(define true #t)
(define false #f)

(define (false? x) (not (and x #t)))
(define (true? x) (and x #t))

(define (identity x) x)
(define (constantly c) (lambda (x) c))

(define (eof? x)  (equal? x #!eof))
(define (void? x) (equal? x #!void))

(define (even? x) (= 0 (remainder x 2)))
(define (odd? x) (= 1 (remainder x 2)))

(define concat append)

(define (println x)
  (display x)
  (newline))



(define-macro (wrap-nil sexp)
  `(with-exception-catcher
   (lambda (e) nil)
   (lambda () ,sexp)
   ))

(define (nil? x)
  (or
       (not  x)
       (equal? x 'nil)
       (equal? x #!void)
       (equal? x #!eof)
       (null? x)))

(define (not-nil? x)
  (not (nil? x)))

(define (first xs)
  (if (nil? xs)
      nil
      (car xs)
      ))


(define (second xs)
  (if (null? xs)
      nil
      (if (null? (cdr xs))
          nil
          (cadr xs))))

(define (rest xs)
  (if (nil? xs)
      nil
      (cdr xs)
      ))

(define (last xs)
  (if (nil? xs)
      nil
      (if (nil? (rest xs))
          (first xs)
          (last (rest xs))
          )))

(define (consc hd tl)
  (if (nil? tl)
      (cons hd '())
      (cons hd tl)
      ))

(define  (partial f . args)
  (lambda (args-rest)
    (apply f (append
              args
              (if (list?  args-rest)
                  args-rest
                  (list args-rest)
                  )))))


;;; Convert plist to association list
(define (plist->alist plist)
  (if (null? plist)
      '()
      (cons
       (list (car plist) (cadr plist))
       (plist->alist (cddr plist)))))

;;; Convert association list to plist
(define (alist->plist assocl)
(if (null? assocl)
      '()
      (let
          ((hd (car assocl))
           (tl (cdr assocl)))
        (cons (car hd)
           (cons (cadr hd)
                 (alist->plist tl))))))


(define (plist-get key params)

  (if ( nil? params)
      nil
      (let
          ((hd1 ( car params))
           (hd2 ( cadr params))
           (tl2 ( cddr params))

           )
        (if (equal? hd1 key)
            hd2
            (if (nil? (cdr tl2))
                nil
                (plist-get key tl2)
                )))))


(define (apply-or-nil f arg)
  (if (not (nil? arg))
      (f arg)
      nil
      ))

;;
;; Based on: https://adambard.com/blog/acceptable-error-handling-in-clojure/
;;
(define (bind-error f var-err)
  (if (nil? (car var-err))
      (f var-err)
      (list nil (cadr var-err))
      ))

(define (bind-nil f arg #!optional (val nil))
  (if (nil? arg)
      val
      (f arg)
   ))

(define (fnil f #!optional (default nil))
  (lambda (arg)
    (if (nil? arg)
        default
        (f arg)
        )))

(define (inc x)
  "Increment a number, add 1"
  (+ x 1) )

(define (dec x)
  "Decrement a number, subract 1"
  (- x 1))


(define (list-get lst n)
  (if  (or (>= n (length lst)) (< n 0))
       nil
       (list-ref lst n)
       ))


(define empty? null?)


(define  (__reduce f xs acc)
  (if (null? xs)
      acc
      (__reduce f (cdr xs) (f acc (car xs)))
      ))

(define (reduce f xs #!optional (acc nil))
  (if (nil? acc)
       (__reduce f (cdr xs) (car xs))
      (__reduce f xs acc)
   ))



(defn find (pred xs)
  (match xs
         (()    nil)
         ((hd . tl) (if (pred hd)
                        hd
                        (find pred tl)
                        ))))


(define (__filter f xs acc)
  (if (null? xs)
      (reverse acc)
      (let ((hd (car xs))
            (tl (cdr xs))
            )
        (__filter f tl  (if (f hd)
                            (cons hd acc)
                            acc
                            )))))

(define (filter f xs)
  (__filter f xs '()))

(define (reject f xs)
  (filter
   (lambda (x) (not (f x)))
   xs))


(define (zipv . xss)
  (apply map vector xss))

(define (zip . xss)
  (apply map list xss))


(define (plist->assoc plist)
  (if (null? plist)
      '()
      (cons
       (list (car plist) (cadr plist))
       (plist->assoc (cddr plist)))))

(define (alist-get alist key)
  (if (nil? alist)
      nil
      (bind-nil cadr (assoc key alist))
      ))

(define (alist-kv? alist key val)
  (equal? (alist-get alist key) val))

;;
;; Oly returns true if all arguments are true
;;
(define (all? . args)
  (reduce (lambda (acc x) (and acc x)) args true))

(define (any? . args)
  (reduce (lambda (acc x) (or acc x)) args false))

(define (for-all? pred xs)
  (apply all? (map pred xs)))

(define (for-any? pred xs)
  (apply any? (map pred xs)))

;;
;; Invert predicate function
;;
(define (compl pred)
  (lambda (x) (not (pred x))))

;;
;; Join predicate functions
;;
(define (pred-or . preds)
  (lambda (x)
    (reduce
     (lambda (acc f) (or (f x) acc)  )
     preds
     #f
     )))

(define (pred-and . preds)
  (lambda (x)
    (reduce
     (lambda (acc f) (and (f x) acc))
     preds
     #t
     )))

(define (pred-nor . preds)
  (lambda (x)
    (not (reduce
       (lambda (acc f) (or (f x) acc)  )
       preds
       #f
       ))))

(define (pred-nand . preds)
  (lambda (x)
    (not
     (reduce
       (lambda (acc f) (and (f x) acc))
       preds
       #t
       ))))

(define (pred-false x)  #f)
(define (pred-true  x)  #t)




(define (__take-while f xs acc)

  (if (null? xs)
      '()
      (bind-cons (hd . tl) xs
                 (if (f hd)
                     (reverse acc )
                     (__take-while f tl (cons hd acc))) )
      ))

(define (take-while f xs)
  (__take-while f xs '()))


(define (__take n xs acc)
  (if (or (null? xs) (zero? n))
      (reverse acc)
      (__take (- n 1) (cdr xs) (cons (car xs) acc))
      ))

(define (take n xs)
  (__take n xs '()))

(define (drop n xs)
  (if (or (null? xs) (zero? n))
      xs
      (drop (- n 1) (cdr xs))))

(define (__drop-while f xs acc)

  (if (null? xs)
      acc
      (bind-cons (hd . tl) xs
                 (if (not  (f hd))
                     (__drop-while f tl (cons hd acc))
                     (reverse acc)
                  ))))

(define (drop-while f xs)
  (__drop-while f xs '()))

;;
;; Function Composition
;;
(define (__compose funcs x)
  (if (null? funcs)
      x
      (__compose (cdr funcs) ((car funcs) x))))

(define (fcomp . funcs)
  (lambda (x) (__compose funcs x)))


(define (juxt . funcs)
  (lambda (x)
    (map
     (lambda (f) (f x))
     funcs
     )))

(define (juxtp . params)
  (let*

      (
       (alist (plist->alist params))
       (tags  (map car  alist))
       (funcs (map cadr alist))
       )
    (lambda (x)
      (zip tags ((apply juxt funcs) x)))))



(define (__map-index-m f xs acc index)
  (if (for-all? null? xs)
      (reverse acc)

      (__map-index-m
       f
       (map cdr xs)
       (cons    (apply f index (map car xs)) acc)
       (+ 1 index))))


(define (map-index f . xs)
  (__map-index-m f xs '() 0 ))


(define (__collect-until pred func acc)
  (let
      (
       (x (func))
       )
    (if (pred x)
        (reverse acc)
        (__collect-until
         pred
         func
         (cons x acc)
         )
        )))

(define (collect-until pred func)
  (__collect-until pred func '()))

(define (__collect-times n f z acc)
  (if (= n z)
      (reverse acc)
      (__collect-times
       n
       f
       (+ z 1)
       (cons (f z) acc)
       )
      ))

(define (collect-times n f)
  (__collect-times n f 0 '()))

(define (__exec-times n f z)
  (if (not  (= n z))
      (begin
        (f z)
        (__exec-times n f (+ z 1) ))))

(define (exec-times n f)
  (__exec-times n f 0))

(defn __count-until (f_iter f_cond f_sel x0 acc)
        (letc

         [out   (f_iter x0)]

         (if (f_cond out)
             acc
             (if (f_sel out)
                 (__count-until f_iter f_cond f_sel  out (+ 1 acc))
                 (__count-until f_iter f_cond f_sel  out acc)
                 ))))

(defn count-until  (f_iter f_cond x0 #!optional (f_sel pred-true))
  (__count-until f_iter f_cond f_sel x0  0))


(defn iterate-until (f_iter f_cond x0 )
  "
  Example:

   > (iterate-until inc (partial < 10) 0 even?)
     (1 3 5 7 9)

  > (iterate-until inc (partial < 10) 0 odd?)
    (0 2 4 6 8)
  >

  "
  (begin
      (defn __iterate-until (x0 acc)
        (letc

         [ out   ( f_iter x0)]

         (if ( f_cond out)
             (if ( f_cond x0)
                 (reverse acc)
                 (reverse (cons x0 acc))
                 )
             (__iterate-until  out (cons x0 acc))
             )))

      (__iterate-until x0 '())
    ))


(defn iteratep-until (f_iter f_cond f_sel f_proj f_acc x0 acc)
       "
        General higher order loop function

         Parameters:

         * f_iter - Iterator function that generates the next element of the sequence.
         * f_cond - Predicate function that when is true stop the loop and returns
                    the accumulator
         * f_sel  - Predicate selector, only the values that satifies f_sel are
                    accumulated.

         * f_proj  - Function to be applied to each element before be accumulated.

         * x0      - Initial element of the sequence

         * acc     - Initial value of the accumulator

         Example:

        > (iteratep-until  inc  (partial < 10)  pred-true  identity   cons 1 '())
           (9 8 7 6 5 4 3 2 1)
        >

       > (iteratep-until  inc  (partial < 10)  pred-true  (partial * 2)   cons 1 '())
         (18 16 14 12 10 8 6 4 2)

       > (iteratep-until  inc  (partial < 10)  pred-false (partial * 2)   cons 1 '())
       ()

       > (iteratep-until  inc  (partial < 10)  odd? identity   cons 1 '())
       (9 7 5 3 1)
       >

       > (iteratep-until  inc  (partial < 10)  even? identity   cons 1 '())
       (8 6 4 2)


       > (iteratep-until  inc  (partial < 10)  even?  (partial * 3)   cons 1 '())
         (24 18 12 6)

        > (iteratep-until  inc  (partial < 10)  even?  (constantly 1)  cons 1 '())
          (1 1 1 1)


       It will calculate:  (* 18 16 14 12 10 8 6 4 2)
       > (iteratep-until  inc  (partial < 10)  pred-true  (partial * 2)   * 1 1)
         185794560

        It will sum: 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1

        > (iteratep-until  inc  (partial < 10)  pred-true  identity   + 1 0)
          45
        >


       "

        (letc

         [ out   (f_iter x0)]

         (if (f_cond out)
             acc
             (if (not (f_sel out))
                 (iteratep-until f_iter f_cond f_sel f_proj f_acc out (f_acc (f_proj x0) acc))
                 (iteratep-until f_iter f_cond f_sel f_proj f_acc out acc)
                 )
             )))


;; (iteratep-until  inc  (partial < 10)  odd?  identity  *  1  1)
;; (iteratep-until  inc  (partial < 10)  pred-true  identity   cons 1 '())


(comment


"
Example:
>
(
 (group-by-pred
  (list \"pdf\"     (file/ends-with \".pdf\"))
  (list \"tar.gz\"  (file/ends-with \".tar.gz\"))
  (list \"tar.bz2\" (file/ends-with \".tar.bz2\"))
  (list \"tgz\"     (file/ends-with \".tgz\"))
  )

  (dir/list \"~/Downloads\") )
"
  ) ;;; End of comment

(define  (group-by-pred . pred-list)
  (lambda (xs)
    (map
     (lambda (row)

       (let
           ((tag (car  row))
            (fun (cadr row))
            )

         (list
          tag
          (filter fun xs)
          )
         ))
     pred-list
     )))



;;
(comment "Function Transformations:")

(define (t-map f)
  (lambda (list xs) (apply map f xs)))

(define (t-filter)
  (partial filter f))

(define (t-reduce f #!optional (acc nil))
  (lambda (xs) (reduce f xs acc)))

(define (t-curry f)
  "A function of many arguments is turned into
   a function of one argument that takes a list
   of original function."
  (lambda (list xs) (apply f xs)))

(define sum  (t-reduce + 0))
(define prod (t-reduce * 1))


(define (vector-map f vec)
  (let*

      ((n  (vector-length vec))
       (v-new (make-vector n))
       )

    (dotimes i n
             (vector-set! v-new i (f (vector-ref vec i))))
    v-new
   ))


;; (def f
;;      (juxtp
;;       name: identity
;;       type: (comp file-info file-info-type)
;;       size: (comp file-info file-info-size)
;;       ))


(define (str s)
  "
  Example:

  > (str (vector (list 1 2 3 4) (vector '+ 3 4 6) 12 \"hello world\"))
  \"[(1 2 3 4) [+ 3 4 6] 12 \\\"hello world\\\"]\"
  >

  > (vector (list 1 2 3 4) (vector '+ 3 4 6) 12 \"hello world\")
  #((1 2 3 4) #(+ 3 4 6) 12 \"hello world\")
  >
  "
  (cond

   ((equal? s #t) "#t")
   ((equal? s #f) "#f")
   ((and (list? s) (null? s))   "()")
   ((string? s) (string-append "\"" s "\""))
   ((number? s) (number->string s))
   ((symbol? s) (symbol->string s))

   ((keyword? s) (string-append (keyword->string s) ":"))
   ((list? s)   (string-append "(" (string/join " "
                                                (map str s)) ")"))
   ((pair? s)   (string-append "(" (str (car s)) " . " (str (cdr s))  ")"))

   ((vector? s) (string-append "["
                               (string/join " "
                                            (map str (vector->list s))) "]"))



   ))


(define-macro ($dbg f . args)
  "
  Debug Injection Macro:

  > (def a 10)
  > (+ 10 40 ($dbg - 10 ($dbg a)))
  > a = 10
  > (- 10 ($dbg a)) = 0
  50
  >
  "
  (let

      ((result (gensym)))

    `(let
         ((,result ,(if (null? args) f `(,f ,@args) )))

       (display " > ")
       (display (str ,(if (null? args) `(quote ,f) `(quote (,f ,@args)))))
       (display " = ")
       (display (str ,result))
       (newline)

       ,result ;;; Return value

       )))
