;;; Compiled by f2cl version 2.0 beta on 2001/02/23 at 10:09:01
;;; 
;;; Options: ((:prune-labels nil) (:auto-save t) (:relaxed-array-decls t)
;;;           (:coerce-assigns :as-needed) (:array-type 'simple-array)
;;;           (:array-slicing t))


(use-package :f2cl)

(let ((wg (make-array 15 :element-type 'double-float))
      (xgk (make-array 31 :element-type 'double-float))
      (wgk (make-array 31 :element-type 'double-float)))
  (declare (type (array double-float (31)) wgk xgk)
           (type (array double-float (15)) wg))
  (fset (fref wg (1) ((1 15))) 0.007968192496166605d0)
  (fset (fref wg (2) ((1 15))) 0.01846646831109096d0)
  (fset (fref wg (3) ((1 15))) 0.02878470788332337d0)
  (fset (fref wg (4) ((1 15))) 0.03879919256962705d0)
  (fset (fref wg (5) ((1 15))) 0.04840267283059405d0)
  (fset (fref wg (6) ((1 15))) 0.057493156217619065d0)
  (fset (fref wg (7) ((1 15))) 0.06597422988218049d0)
  (fset (fref wg (8) ((1 15))) 0.0737559747377052d0)
  (fset (fref wg (9) ((1 15))) 0.08075589522942021d0)
  (fset (fref wg (10) ((1 15))) 0.08689978720108298d0)
  (fset (fref wg (11) ((1 15))) 0.09212252223778612d0)
  (fset (fref wg (12) ((1 15))) 0.09636873717464425d0)
  (fset (fref wg (13) ((1 15))) 0.09959342058679527d0)
  (fset (fref wg (14) ((1 15))) 0.1017623897484055d0)
  (fset (fref wg (15) ((1 15))) 0.10285265289355884d0)
  (fset (fref xgk (1) ((1 31))) 0.9994844100504906d0)
  (fset (fref xgk (2) ((1 31))) 0.9968934840746495d0)
  (fset (fref xgk (3) ((1 31))) 0.9916309968704046d0)
  (fset (fref xgk (4) ((1 31))) 0.9836681232797472d0)
  (fset (fref xgk (5) ((1 31))) 0.9731163225011262d0)
  (fset (fref xgk (6) ((1 31))) 0.9600218649683075d0)
  (fset (fref xgk (7) ((1 31))) 0.94437444474856d0)
  (fset (fref xgk (8) ((1 31))) 0.9262000474292743d0)
  (fset (fref xgk (9) ((1 31))) 0.9055733076999078d0)
  (fset (fref xgk (10) ((1 31))) 0.8825605357920527d0)
  (fset (fref xgk (11) ((1 31))) 0.8572052335460612d0)
  (fset (fref xgk (12) ((1 31))) 0.8295657623827684d0)
  (fset (fref xgk (13) ((1 31))) 0.799727835821839d0)
  (fset (fref xgk (14) ((1 31))) 0.7677774321048262d0)
  (fset (fref xgk (15) ((1 31))) 0.7337900624532268d0)
  (fset (fref xgk (16) ((1 31))) 0.6978504947933158d0)
  (fset (fref xgk (17) ((1 31))) 0.6600610641266269d0)
  (fset (fref xgk (18) ((1 31))) 0.6205261829892429d0)
  (fset (fref xgk (19) ((1 31))) 0.5793452358263617d0)
  (fset (fref xgk (20) ((1 31))) 0.5366241481420199d0)
  (fset (fref xgk (21) ((1 31))) 0.49248046786177857d0)
  (fset (fref xgk (22) ((1 31))) 0.44703376953808915d0)
  (fset (fref xgk (23) ((1 31))) 0.4004012548303944d0)
  (fset (fref xgk (24) ((1 31))) 0.3527047255308781d0)
  (fset (fref xgk (25) ((1 31))) 0.30407320227362505d0)
  (fset (fref xgk (26) ((1 31))) 0.25463692616788985d0)
  (fset (fref xgk (27) ((1 31))) 0.20452511668230988d0)
  (fset (fref xgk (28) ((1 31))) 0.15386991360858354d0)
  (fset (fref xgk (29) ((1 31))) 0.10280693796673702d0)
  (fset (fref xgk (30) ((1 31))) 0.0514718425553177d0)
  (fset (fref xgk (31) ((1 31))) 0.0d0)
  (fset (fref wgk (1) ((1 31))) 0.0013890136986770077d0)
  (fset (fref wgk (2) ((1 31))) 0.003890461127099884d0)
  (fset (fref wgk (3) ((1 31))) 0.0066307039159312926d0)
  (fset (fref wgk (4) ((1 31))) 0.009273279659517764d0)
  (fset (fref wgk (5) ((1 31))) 0.011823015253496341d0)
  (fset (fref wgk (6) ((1 31))) 0.014369729507045804d0)
  (fset (fref wgk (7) ((1 31))) 0.01692088918905327d0)
  (fset (fref wgk (8) ((1 31))) 0.019414141193942382d0)
  (fset (fref wgk (9) ((1 31))) 0.021828035821609193d0)
  (fset (fref wgk (10) ((1 31))) 0.0241911620780806d0)
  (fset (fref wgk (11) ((1 31))) 0.0265099548823331d0)
  (fset (fref wgk (12) ((1 31))) 0.02875404876504129d0)
  (fset (fref wgk (13) ((1 31))) 0.030907257562387762d0)
  (fset (fref wgk (14) ((1 31))) 0.03298144705748372d0)
  (fset (fref wgk (15) ((1 31))) 0.034979338028060025d0)
  (fset (fref wgk (16) ((1 31))) 0.03688236465182123d0)
  (fset (fref wgk (17) ((1 31))) 0.038678945624727595d0)
  (fset (fref wgk (18) ((1 31))) 0.040374538951535956d0)
  (fset (fref wgk (19) ((1 31))) 0.041969810215164244d0)
  (fset (fref wgk (20) ((1 31))) 0.04345253970135607d0)
  (fset (fref wgk (21) ((1 31))) 0.04481480013316266d0)
  (fset (fref wgk (22) ((1 31))) 0.04605923827100699d0)
  (fset (fref wgk (23) ((1 31))) 0.04718554656929915d0)
  (fset (fref wgk (24) ((1 31))) 0.04818586175708713d0)
  (fset (fref wgk (25) ((1 31))) 0.04905543455502978d0)
  (fset (fref wgk (26) ((1 31))) 0.04979568342707421d0)
  (fset (fref wgk (27) ((1 31))) 0.05040592140278235d0)
  (fset (fref wgk (28) ((1 31))) 0.05088179589874961d0)
  (fset (fref wgk (29) ((1 31))) 0.051221547849258774d0)
  (fset (fref wgk (30) ((1 31))) 0.05142612853745902d0)
  (fset (fref wgk (31) ((1 31))) 0.05149472942945157d0)
  (defun dqk61 (f a b result abserr resabs resasc)
    (declare (type double-float a b result abserr resabs resasc)
             (type (function (double-float) (values double-float &rest t)) f))
    (prog ((j 0) (jtw 0) (jtwm1 0) (uflow 0.0d0) (reskh 0.0d0) (resk 0.0d0)
           (resg 0.0d0) (hlgth 0.0d0)
           (fv2 (make-array 30 :element-type 'double-float))
           (fv1 (make-array 30 :element-type 'double-float)) (fval2 0.0d0)
           (fval1 0.0d0) (fsum 0.0d0) (fc 0.0d0) (epmach 0.0d0) (dhlgth 0.0d0)
           (centr 0.0d0) (dabsc 0.0d0))
      (declare (type (array double-float (30)) fv1 fv2)
               (type double-float dabsc centr dhlgth epmach fc fsum fval1 fval2
                hlgth resg resk reskh uflow)
               (type integer4 jtwm1 jtw j))
      (declare
       (ftype (function (integer4) (values double-float &rest t)) d1mach))
      (declare (ftype (function (double-float) (values double-float)) dabs))
      (declare
       (ftype (function (double-float double-float) (values double-float))
        dmin1))
      (declare
       (ftype (function (double-float double-float) (values double-float))
        dmax1))
      (setf epmach (d1mach 4))
      (setf uflow (d1mach 1))
      (setf centr (* 0.5d0 (+ b a)))
      (setf hlgth (* 0.5d0 (- b a)))
      (setf dhlgth (dabs hlgth))
      (setf resg 0.0d0)
      (setf fc
              (coerce
               (multiple-value-bind
                   (ret-val var-0)
                   (funcall f centr)
                 (declare (ignore))
                 (when var-0 (setf centr var-0))
                 ret-val)
               'double-float))
      (setf resk (* (fref wgk (31) ((1 31))) fc))
      (setf resabs (dabs resk))
      (fdo (j 1 (+ j 1))
           ((> j 15) nil)
           (tagbody
             (setf jtw (* j 2))
             (setf dabsc (* hlgth (fref xgk (jtw) ((1 31)))))
             (setf fval1 (funcall f (- centr dabsc)))
             (setf fval2 (funcall f (+ centr dabsc)))
             (fset (fref fv1 (jtw) ((1 30))) fval1)
             (fset (fref fv2 (jtw) ((1 30))) fval2)
             (setf fsum (+ fval1 fval2))
             (setf resg (+ resg (* (fref wg (j) ((1 15))) fsum)))
             (setf resk (+ resk (* (fref wgk (jtw) ((1 31))) fsum)))
             (setf resabs
                     (+ resabs
                        (* (fref wgk (jtw) ((1 31)))
                           (+ (dabs fval1) (dabs fval2)))))
            label10))
      (fdo (j 1 (+ j 1))
           ((> j 15) nil)
           (tagbody
             (setf jtwm1 (- (* j 2) 1))
             (setf dabsc (* hlgth (fref xgk (jtwm1) ((1 31)))))
             (setf fval1 (funcall f (- centr dabsc)))
             (setf fval2 (funcall f (+ centr dabsc)))
             (fset (fref fv1 (jtwm1) ((1 30))) fval1)
             (fset (fref fv2 (jtwm1) ((1 30))) fval2)
             (setf fsum (+ fval1 fval2))
             (setf resk (+ resk (* (fref wgk (jtwm1) ((1 31))) fsum)))
             (setf resabs
                     (+ resabs
                        (* (fref wgk (jtwm1) ((1 31)))
                           (+ (dabs fval1) (dabs fval2)))))
            label15))
      (setf reskh (* resk 0.5d0))
      (setf resasc (* (fref wgk (31) ((1 31))) (dabs (- fc reskh))))
      (fdo (j 1 (+ j 1))
           ((> j 30) nil)
           (tagbody
             (setf resasc
                     (+ resasc
                        (* (fref wgk (j) ((1 31)))
                           (+ (dabs (- (fref fv1 (j) ((1 30))) reskh))
                              (dabs (- (fref fv2 (j) ((1 30))) reskh))))))
            label20))
      (setf result (* resk hlgth))
      (setf resabs (* resabs dhlgth))
      (setf resasc (* resasc dhlgth))
      (setf abserr (dabs (* (- resk resg) hlgth)))
      (if (and (/= resasc 0.0d0) (/= abserr 0.0d0))
          (setf abserr
                  (* resasc
                     (dmin1 1.0d0
                            (expt (/ (* 200.0d0 abserr) resasc) 1.5d0)))))
      (if (> resabs (/ uflow (* 50.0d0 epmach)))
          (setf abserr (dmax1 (* epmach 50.0d0 resabs) abserr)))
      (go end_label)
     end_label
      (return (values f a b result abserr resabs resasc)))))

