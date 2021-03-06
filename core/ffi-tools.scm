(define-macro (apply-macros macros exps)
  `(begin

     ,@(apply append

              (map
               (lambda (e)
                 (map (lambda (m) `(,m ,e)) macros ))
               exps
               ))))

(define-macro (c-include header)
  `(c-declare ,(string-append "#include " header)))

(comment
 (define-macro (defc-const var type . const)
    "
  Example: 

  

  "
    (let*
        (

         (const  (if (not (null? const))
                     (symbol->string (car const))
                     (symbol->string var)))
         
         (str    (string-append "___result = " const ";"))
         
         )

      `(define ,var ((c-lambda () ,type ,str))))))


(define-macro (defc-enum-prefix prefix . consts)

 "
Example of output:

> (defc-enum-prefix 'address-family
  'AF_UNIX
  'AF_INET
  'AF_INET6  
  )
(begin
  (def address-family/AF_UNIX ((c-lambda () int \"___result = AF_UNIX ;\")))
  (def address-family/AF_INET ((c-lambda () int \"___result = AF_INET ;\")))
  (def address-family/AF_INET6 ((c-lambda () int \"___result = AF_INET6 ;\"))))
> 

"
  (letc

   [
    pref    (symbol->string prefix)

    syms    (map
               (fn [s]  (string->symbol
                        (string-append  pref "/"  (symbol->string s))))

               consts
               )

    ]

   `(begin

      ,@(map
         (fn (sym const)

             `(def ,sym
                   ((c-lambda () int
                    ,(string-append "___result = "
                     (symbol->string const) " ;")))
                   ))
         syms
         consts
         ))
   ))


  (comment
   (define (defc-enum- prefix . consts)

      (letc

       [
        pref    (symbol->string prefix)

                syms    (map
                         (fn [s]  (string->symbol
                                   (string-append  pref "/"  (symbol->string s))))

                         consts
                         )

                ]

       `(begin

          ,@(map
             (fn (sym const)

                 `(def ,sym
                       ((c-lambda () int
                                  ,(string-append "___result = "
                                                  (symbol->string const) " ;")))
                       ))
             syms
             consts
             ))
       )))


(define-macro (defc-func name c-name params return)
  `(define ,name
     (c-lambda ,params ,return ,c-name)))


(define-macro (defc-f name params return)
  `(define ,name
     (c-lambda ,params ,return ,(symbol->string name))))


(define-macro (defc-func-code name params return code)
  `(define ,name
     (c-lambda ,params ,return ,code)))

(define-macro (defc-func-cast name from-type to-type)
  `(define ,name
     (c-lambda
      (,from-type)
      ,to-type
      "___result = ___arg1 ;"
      )))


(define-macro (def-void-ptr-cast name c-type #!optional (c-type-string #f))
  `(defc-func-code ,name
                 ((pointer void))
                 (pointer ,c-type)
                 ,(string-append
                   "___result_voidstar = ( "
                   (or c-type-string (symbol->string c-type))
                   " * ) ___arg1 ;")
                 ))



(define-macro (def-ptr-setter name type)
  `(defc-func-code ,name
                  ((pointer ,type #f) ,type)
                  void
                  "* ___arg1 = ___arg2 ;"
                  ))

(define-macro (def-ptr-getter name type)
  `(defc-func-code ,name
                 ((pointer ,type #f))
                 ,type
                 "___result = * ___arg1 ;"
                 ))



(define-macro (c-sizeof c-type )
  `((c-lambda
     ()  unsigned-int
     ,(string-append "___result = sizeof ("
                     (if (symbol?  c-type)
                         (symbol->string c-type)
                         c-type
                         ) " );"
                           ))))

(define-macro (def-enum . enums)
  `(begin
     ,@(map-index (lambda (idx e) `(define ,e ,idx)) enums)
     ))


;; Null pointer
;;
(define NULL #f)

(c-define-type FILE "FILE")
(c-define-type FILE* (pointer FILE))
(c-define-type char* (pointer char))
(c-define-type void* (pointer void))
(c-define-type time_t "time_t")

(c-include "<stdlib.h>")
(c-include "<stdio.h>")
(c-include "<unistd.h>")
(c-include "<time.h>")

(def-void-ptr-cast ptr-void->int int)
(def-void-ptr-cast ptr-void->char char)
(def-void-ptr-cast ptr-void->double double)
(def-void-ptr-cast ptr-void->float float)
(def-void-ptr-cast ptr-void->time_t time_t)


(def-ptr-getter ptr-int-get int)
(def-ptr-getter ptr-char-get char)
(def-ptr-getter ptr-double-get double)
(def-ptr-getter ptr-float-get float)
(def-ptr-getter ptr-time_t-get time_t)

(def-ptr-setter ptr-int-set int)
(def-ptr-setter ptr-char-set char)
(def-ptr-setter ptr-double-set double)
(def-ptr-setter ptr-float-set  float)
(def-ptr-setter ptr-time_t-set time_t)


(define sizeof-ctypes
  `(
   (int     ,(c-sizeof int))
   (double  ,(c-sizeof double))
   (float   ,(c-sizeof float))
   (char    ,(c-sizeof char))
   (char*   ,(c-sizeof "char *"))
   (double* ,(c-sizeof "double *"))
   (time_t  ,(c-sizeof "time_t"))
   (size_t  ,(c-sizeof "size_t"))
   ))

(define (sizeof type)
  (let
      ((c (assoc type sizeof-ctypes)))
    (if c
        (cadr c)
        #f
        )))

(define malloc (c-lambda (int) (pointer void #f) "malloc"))
(define free (c-lambda ((pointer void #f)) void "free"))

(define (make-memory bytes)
  (let ((mem (malloc bytes)))
    (make-will mem (lambda (obj) (display "free function called\n") (free obj)))
    mem))


(define-macro (with-malloc params . body)
  (let
      (
       (var    (car  params))
       (size-t (cadr params))
       (out    (gensym))
       )
   `(let*
        ((,var (malloc ,size-t))
         (,out (begin ,@body))
         )
      (free ,var)
      ,out
      )))


(define-macro (make-carray-type-getter type)
  (let
      (
       (name    (string->symbol
                 (string-append
                  "carray-"
                  (symbol->string type)
                  "-ref"
                  )))
       )

    `(define ,name
      (c-lambda
       ((pointer ,type #f) int)
       ,type
       "___result = ___arg1[___arg2];"))
    ))


(define-macro (make-carray-type-setter type)
  (let
      (
       (name    (string->symbol
                 (string-append
                  "carray-"
                  (symbol->string type)
                  "-set!"
                  )))
       )

    `(define ,name
      (c-lambda
       ((pointer ,type #f) int ,type)
       ,type
       "___arg1[___arg2] = ___arg3;"
       ))
    ))

(define (carray-make len type #!optional (typesize #f) )
  (apply vector
         `(c-array:
           ,type
           ,len
           ,(malloc
             (* len
                (or typesize (sizeof type)))))))


(define-macro (with-cstring ptr str body)
  `(let*
       (
        (n (string-length ,str))
        (,ptr (ptr-void->char  (malloc n)))
        (chars (string->list ,str))
        )

     (let*
         ((,ptr ,ptr)
          (out ,body))

       (dotimes i n
                (carray-char-set! ,ptr  ($dbg i) (list-ref chars i)))

       (carray-char-set! ,ptr n #\nul)

       (free ,ptr)
       out

       )))

(apply-macros
 (make-carray-type-getter
  make-carray-type-setter
  )
 (
  int
  unsigned-int8
  unsigned-int16
  float
  double
  char
  ))


(define-macro (c-struct-field struct field return-type)
  (let*
      (
       (struct-str ( symbol->string struct))
       (field-str  ( symbol->string field))

       (accessor   ( string->symbol
                   (string-append
                    struct-str "->"  field-str)))
       )

    `(defc-func-code ,accessor
                      ((pointer  (struct ,struct-str)))
                      ,return-type
                      ,(string-append  "___result = ___arg1->" field-str " ;")
                      )))


(define-macro (c-struct-field-setter
               struct
               field
               type
               )
  (let* (
         (struct-name (symbol->string struct))
         (field-name  (symbol->string field))

         (setter      (string->symbol
                       (string-append
                         struct-name
                         "->"
                         field-name
                         "!"
                         )))
         )

    `(defc-func-code ,setter
      ((pointer (struct ,struct-name)) ,type)
       void
       ,(string-append
         "___arg1->" field-name  " = ___arg2 ;")
      )))



(define-macro (c-struct struct . field-return-values)

  (let*
      (
       (make-accessor-name (lambda (struct field)
                             (string->symbol
                              (string-append
                               (symbol->string  struct)
                               "->"
                               (symbol->string field)))))

       (struct-str    (symbol->string struct))

       (field-names   (map car field-return-values))

       (destructor-name     (string->symbol
                             (string-append
                              struct-str
                              "-fields"
                              )))

       (destructor-tag-names     (string->symbol
                                  (string-append
                                   struct-str
                                   "-fields-tags"
                                   )))



       (field-accessors  (map
                          (lambda (c)
                            (make-accessor-name struct (car c)))
                          field-return-values
                          )))

   `(begin
      ,@(map
         (lambda (c) `(c-struct-field ,struct ,(car c) ,(cadr c)))
         field-return-values
         )

      (begin
         ,@(map
            (lambda (c) `(c-struct-field-setter
                           ,struct ,(car c) ,(cadr c)))
            field-return-values
            ))

      (define (,destructor-name st)
        (list ,@(map
                 (lambda (f) `(,f st))
                 field-accessors
                 )))

      (define (,destructor-tag-names st)
        (list  ,@(map

                  (lambda (f tag)
                    `(list (quote ,tag) (,f st)))

                  field-accessors
                  field-names
                  )))
      )))
