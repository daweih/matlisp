;;; Compiled by f2cl version 2.0 beta on 2001/02/23 at 10:10:20
;;; 
;;; Options: ((:prune-labels nil) (:auto-save t) (:relaxed-array-decls t)
;;;           (:coerce-assigns :as-needed) (:array-type 'simple-array)
;;;           (:array-slicing t))


(use-package :f2cl)

(defun dqawc
       (f a b c epsabs epsrel result abserr neval ier limit lenw last iwork
        work)
  (declare (type double-float a b c epsabs epsrel result abserr)
           (type integer4 neval ier limit lenw last)
           (type (array integer4 (*)) iwork)
           (type (array double-float (*)) work))
  (prog ((lvl 0) (l1 0) (l2 0) (l3 0))
    (declare (type integer4 l3 l2 l1 lvl))
    (declare
     (ftype
      (function
       (double-float double-float double-float double-float double-float
        double-float integer4 double-float double-float integer4 integer4
        array-double-float array-double-float array-double-float
        array-double-float array-integer4 integer4)
       (values &rest t))
      dqawce))
    (declare
     (ftype (function (string integer4 integer4 integer4) (values &rest t))
      xerror))
    (setf ier 6)
    (setf neval 0)
    (setf last 0)
    (setf result 0.0d0)
    (setf abserr 0.0d0)
    (if (or (< limit 1) (< lenw (* limit 4))) (go label10))
    (setf l1 (+ limit 1))
    (setf l2 (+ limit l1))
    (setf l3 (+ limit l2))
    (multiple-value-bind
        (var-0 var-1 var-2 var-3 var-4 var-5 var-6 var-7 var-8 var-9 var-10
         var-11 var-12 var-13 var-14 var-15 var-16)
        (dqawce f a b c epsabs epsrel limit result abserr neval ier
         (array-slice work double-float (1) ((1 lenw)))
         (array-slice work double-float (l1) ((1 lenw)))
         (array-slice work double-float (l2) ((1 lenw)))
         (array-slice work double-float (l3) ((1 lenw))) iwork last)
      (declare (ignore var-0 var-11 var-12 var-13 var-14 var-15))
      (when var-1 (setf a var-1))
      (when var-2 (setf b var-2))
      (when var-3 (setf c var-3))
      (when var-4 (setf epsabs var-4))
      (when var-5 (setf epsrel var-5))
      (when var-6 (setf limit var-6))
      (when var-7 (setf result var-7))
      (when var-8 (setf abserr var-8))
      (when var-9 (setf neval var-9))
      (when var-10 (setf ier var-10))
      (when var-16 (setf last var-16)))
    (setf lvl 0)
   label10
    (if (= ier 6) (setf lvl 1))
    (if (/= ier 0)
        (multiple-value-bind
            (var-0 var-1 var-2 var-3)
            (xerror "abnormal return from dqawc" 26 ier lvl)
          (declare (ignore var-0 var-1))
          (when var-2 (setf ier var-2))
          (when var-3 (setf lvl var-3))))
    (go end_label)
   end_label
    (return
     (values f
             a
             b
             c
             epsabs
             epsrel
             result
             abserr
             neval
             ier
             limit
             lenw
             last
             iwork
             work))))

