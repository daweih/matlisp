;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Package: :matlisp; Base: 10 -*-
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Copyright (c) 2000 The Regents of the University of California.
;;; All rights reserved.
;;;
;;; Permission is hereby granted, without written agreement and without
;;; license or royalty fees, to use, copy, modify, and distribute this
;;; software and its documentation for any purpose, provided that the
;;; above copyright notice and the following two paragraphs appear in all
;;; copies of this software.
;;;
;;; IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY
;;; FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
;;; ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
;;; THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.
;;;
;;; THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
;;; INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;; MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
;;; PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
;;; CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
;;; ENHANCEMENTS, OR MODIFICATIONS.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package #:matlisp)

(defmacro generate-typed-gemm! (func (tensor-class blas-gemm-func blas-gemv-func fortran-lb-parameter))
  (let* ((opt (if-ret (get-tensor-class-optimization-hashtable tensor-class)
		      (error 'tensor-cannot-find-optimization :tensor-class tensor-class)))
	 (matrix-class (getf opt :matrix))
	 (blas? (and blas-gemm-func blas-gemv-func)))
    (setf (getf opt :gemm) func
	  (get-tensor-class-optimization tensor-class) opt)
    `(defun ,func (alpha A B beta C job)
       (declare (type ,(getf opt :element-type) alpha beta)
		(type ,matrix-class A B C)
		(type symbol job))
       ;;The big done-in-lisp-gemm, loop-ordering was inspired by the BLAS dgemm reference implementation.
       ,(let
	 ((lisp-routine
	   `(let-typed ((nr-C (nrows C) :type index-type)
			(nc-C (ncols C) :type index-type)
			(dotl (ecase job-A (:n (ncols A)) (:t (nrows A))) :type index-type)
					;
			(rstp-A (row-stride A) :type index-type)
			(cstp-A (col-stride A) :type index-type)
			(hd-A (head A) :type index-type)
			(sto-A (store A) :type ,(linear-array-type (getf opt :store-type)))
					;
			(rstp-B (row-stride B) :type index-type)
			(cstp-B (col-stride B) :type index-type)
			(hd-B (head B) :type index-type)
			(sto-B (store B) :type ,(linear-array-type (getf opt :store-type)))
					;
			(rstp-C (row-stride C) :type index-type)
			(cstp-C (col-stride C) :type index-type)
			(hd-C (head C) :type index-type)
			(sto-C (store C) :type ,(linear-array-type (getf opt :store-type))))
		       ;;Replace with separate loops to maximize Row-ordered MM performance
		       (when (eq job-A :t)
			 (rotatef rstp-A cstp-A))
		       (when (eq job-B :t)
			 (rotatef rstp-B cstp-B))
		       ;;
		       (let-typed ((of-A hd-A :type index-type)
				   (of-B hd-B :type index-type)
				   (of-C hd-C :type index-type)
				   (r.cstp-C (* cstp-C nc-C) :type index-type)
				   (d.rstp-B (- rstp-B (* cstp-B nc-C)) :type index-type)
				   (d.rstp-A (- rstp-A (* cstp-A dotl)) :type index-type))
			 (very-quickly
			   (loop :repeat nr-C
			      :do (progn
				    (loop :repeat dotl
				       :do (let-typed ((ele-A (,(getf opt :f*) alpha (,(getf opt :reader) sto-A of-A)) :type ,(getf opt :element-type)))
					     (loop :repeat nc-C
						:do (progn
						      (,(getf opt :value-writer)
							(,(getf opt :f+)
							  (,(getf opt :reader) sto-C of-C)
							  (,(getf opt :f*) ele-A (,(getf opt :reader) sto-B of-B)))
							sto-C of-C)
						      (incf of-C cstp-C)
						      (incf of-B cstp-B)))
					     (decf of-C r.cstp-C)
					     (incf of-A cstp-A)
					     (incf of-B d.rstp-B)))
				    (incf of-C rstp-C)
				    (incf of-A d.rstp-A)
				    (setf of-B hd-B))))))))
	 ;;Tie together Fortran and lisp-routines.
	 `(mlet* (((job-A job-B) (ecase job
				   (:nn (values :n :n))
				   (:nt (values :n :t))
				   (:tn (values :t :n))
				   (:tt (values :t :t)))
		   :type (symbol symbol))
		  ,@(when blas?
			  `((call-fortran? (> (max (nrows C) (ncols C) (if (eq job-A :n) (ncols A) (nrows A)))
					      ,fortran-lb-parameter))
			    ((maj-A ld-A fop-A) (blas-matrix-compatible-p A job-A) :type (symbol index-type (string 1)))
			    ((maj-B ld-B fop-B) (blas-matrix-compatible-p B job-B) :type (symbol index-type (string 1)))
			    ((maj-C ld-C fop-C) (blas-matrix-compatible-p C :n) :type (symbol index-type nil)))))
		 ,(if blas?
		      `(cond
			 ((and call-fortran? maj-A maj-B maj-C)
			  (let-typed ((nr-C (nrows C) :type index-type)
				      (nc-C (ncols C) :type index-type)
				      (dotl (ecase job-A (:n (ncols A)) (:t (nrows A))) :type index-type))
				     (when (eq maj-C :row-major)
				       (rotatef A B)
				       (rotatef ld-A ld-B)
				       (rotatef maj-A maj-B)
				       (rotatef nr-C nc-C)
				       (setf (values fop-A fop-B)
					     (values (fortran-snop fop-B) (fortran-snop fop-A))))
				     (,blas-gemm-func fop-A fop-B nr-C nc-C dotl
						      alpha (store A) ld-A (store B) ld-B
						      beta (store C) ld-C
						      (head A) (head B) (head C))))
			 ((and call-fortran? maj-A)
			  (let-typed ((nc-C (ncols C) :type index-type)
				      (strd-C (col-stride C) :type index-type)
				      (stp-C (row-stride C) :type index-type)
				      (sto-C (store C) :type ,(linear-array-type (getf opt :store-type)))
					;
				      (nr-A (nrows A) :type index-type)
				      (nc-A (ncols A) :type index-type)
				      (sto-A (store A) :type ,(linear-array-type (getf opt :store-type)))
				      (hd-A (head A) :type index-type)
					;
				      (stp-B (if (eq job-B :n) (row-stride B) (col-stride B)) :type index-type)
				      (sto-B (store B) :type ,(linear-array-type (getf opt :store-type)))
				      (strd-B (if (eq job-B :n) (col-stride B) (row-stride B)) :type index-type))
				     (when (eq maj-A :row-major)
				       (rotatef nr-A nc-A))
				     (very-quickly
				       (loop repeat nc-C
					  for of-B of-type index-type = (head B) then (+ of-B strd-B)
					  for of-C of-type index-type = (head C) then (+ of-C strd-C)
					  do (,blas-gemv-func fop-A nr-A nc-A
							      alpha sto-A ld-A
							      sto-B stp-B
							      beta sto-C stp-C
							      hd-A of-B of-C)))))
			 ((and call-fortran? maj-B)
			  (let-typed ((nr-C (nrows C) :type index-type)
				      (stp-C (col-stride C) :type index-type)
				      (strd-C (row-stride C) :type index-type)
				      (sto-C (store c) :type ,(linear-array-type (getf opt :store-type)))
					;
				      (stp-A (if (eq job-A :n) (col-stride A) (row-stride A)) :type index-type)
				      (strd-A (if (eq job-A :n) (row-stride A) (col-stride A)) :type index-type)
				      (sto-A (store A) :type ,(linear-array-type (getf opt :store-type)))
					;
				      (nr-B (nrows B) :type index-type)
				      (nc-B (ncols B) :type index-type)
				      (hd-B (head B) :type index-type)
				      (fop-B (fortran-snop fop-B) :type (string 1))
				      (sto-B (store B) :type ,(linear-array-type (getf opt :store-type))))
				     (when (eq maj-B :row-major)
				       (rotatef nr-B nc-B))
				     (very-quickly
				       (loop repeat nr-C
					  for of-A of-type index-type = (head A) then (+ of-A strd-A)
					  for of-C of-type index-type = (head C) then (+ of-C strd-C)
					  do (,blas-gemv-func fop-B nr-B nc-B
							      alpha sto-B ld-B
							      sto-A stp-A
							      beta sto-C stp-C
							      hd-B of-A of-C)))))
			 (t
			  ,lisp-routine))
		      lisp-routine)))
       C)))
;;Real
(generate-typed-gemm! real-base-typed-gemm!
  (real-tensor dgemm dgemv *real-l3-fcall-lb*))

(definline real-typed-gemm! (alpha A B beta C job)
  (real-base-typed-gemm! alpha A B beta C
			 (apply #'combine-jobs
				(mapcar #'(lambda (x)
					    (ecase x ((:n :t) x) (:h :t) (:c :n)))
					(multiple-value-list (split-job job))))))

;;Complex
(generate-typed-gemm! complex-base-typed-gemm!
  (complex-tensor zgemm zgemv *complex-l3-fcall-lb*))

(definline complex-typed-gemm! (alpha A B beta C job)
  (declare (type complex-matrix A B C)
	   (type complex-type alpha beta)
	   (type symbol job))
  (multiple-value-bind (job-A job-B) (split-job job)
    (if (and (member job-A '(:n :t))
	     (member job-B '(:n :t)))
	(complex-base-typed-gemm! alpha A B beta C job)
	(let ((A (ecase job-A
		   ((:n :t) A)
		   ((:h :c)
		    ;;BUG!
		    ;;Multiplication does not yield the complex conjugate!
		    (let ((ret (apply #'make-complex-tensor (lvec->list (dimensions A)))))
		      (complex-typed-axpy! #c(-1d0 0d0) A ret)))))
	      (B (ecase job-B
		   ((:n :t) B)
		   ((:h :c)
		    ;;BUG!
		    ;;Multiplication does not yield the complex conjugate!
		    (let ((ret (apply #'make-complex-tensor (lvec->list (dimensions B)))))
		      (complex-typed-axpy! #c(-1d0 0d0) B ret)))))
	      (tjob (combine-jobs (ecase job-A ((:n :t) job-A) (:h :t) (:c :n))
				  (ecase job-B ((:n :t) job-B) (:h :t) (:c :n)))))
	  (complex-base-typed-gemm! alpha A B
				    beta C tjob)))))

;;Symbolic
#+maxima
(generate-typed-gemm! symbolic-base-typed-gemm!
  (symbolic-tensor nil nil 0))

;;---------------------------------------------------------------;;

(defgeneric gemm! (alpha A B beta C &optional job)
  (:documentation
"
  Syntax
  ======
  (GEMM! alpha a b beta c [job])

  Purpose
  =======
  Performs the GEneral Matrix Multiplication given by
	       --      -      -

	    C <- alpha * op(A) * op(B) + beta * C

  and returns C.

  alpha,beta are scalars and A,B,C are matrices.
  op(A) means either A or A'.

  JOB must be a keyword with two of these alphabets
     N                 Identity
     T                 Transpose
     C                 Complex conjugate
     H                 Hermitian transpose {conjugate transpose}

  so that (there are 4x4 operations in total).

     JOB                    Operation
  ---------------------------------------------------
     :NN (default)      alpha * A * B + beta * C
     :TN                alpha * transpose(A) * B + beta * C
     :NH                alpha * A * transpose o conjugate(B) + beta * C
     :HC                alpha * transpose o conjugate(A) * conjugate(B) + beta * C
")
  (:method :before ((alpha number) (A standard-matrix) (B standard-matrix)
		    (beta number) (C standard-matrix)
		    &optional (job :nn))
  (let ((nr-a (nrows A))
	(nc-a (ncols A))
	(nr-b (nrows B))
	(nc-b (ncols B))
	(nr-c (nrows C))
	(nc-c (ncols C)))
    (declare (type index-type nr-a nc-a nr-b nc-b nr-c nc-c))
    (let ((sjobs (multiple-value-list (split-job job))))
      (assert (= (length sjobs) 2) nil 'invalid-arguments :message "Ill formed job")
      (ecase (first sjobs) ((:n :c) t) ((:t :h) (rotatef nr-a nc-a)))
      (ecase (second sjobs) ((:n :c) t) ((:t :h) (rotatef nr-b nc-b))))
    (assert (not (or (eq A C) (eq B C))) nil 'invalid-arguments
	    :message "GEMM!: C = {A or B} is not allowed.")
    (assert (and (= nr-c nr-a)
		 (= nc-a nr-b)
		 (= nc-b nc-c)) nil 'tensor-dimension-mismatch))))

(defmethod gemm! ((alpha number) (a real-matrix) (b real-matrix)
		  (beta number) (c real-matrix)
		  &optional (job :nn))
  (real-typed-gemm! (coerce-real alpha) a b
		    (coerce-real beta) c job))

(defmethod gemm! ((alpha number) (a complex-matrix) (b complex-matrix)
		  (beta number) (c complex-matrix)
		  &optional (job :nn))
  (complex-typed-gemm! (coerce-complex alpha) a b
		       (coerce-complex beta) c job))

(defmethod gemm! ((alpha number) (a real-matrix) (b real-matrix)
		  (beta number) (c complex-matrix)
		  &optional (job :nn))
  (unless (= beta 1)
    (scal! beta c))
  (unless (= alpha 0)
    (if (complexp alpha)
	(let ((A.x (make-real-tensor (nrows c) (ncols c)))
	      (vw.c (tensor-realpart~ c)))
	  (real-typed-gemm! (coerce-real 1) A B (coerce-real 0) A.x job)
	  ;;Re
	  (axpy! (realpart alpha) A.x vw.c)
	  ;;Im
	  (incf (head vw.c))
	  (axpy! (imagpart alpha) A.x vw.c))
	(let ((vw.c (tensor-realpart~ c)))
	  (real-typed-gemm! (coerce-real alpha) A B
			    (coerce-real 1) vw.c job))))
  C)

(defmethod gemm! ((alpha number) (a real-matrix) (b complex-matrix)
		  (beta number) (c complex-matrix)
		  &optional (job :nn))
  (let ((A.cplx (copy! A (make-complex-tensor (nrows a) (ncols a)))))
    (complex-typed-gemm! (coerce-complex alpha) A.cplx B
			 (coerce-complex beta) C job))
  C)

(defmethod gemm! ((alpha number) (a complex-matrix) (b real-matrix)
		  (beta number) (c complex-matrix)
		  &optional (job :nn))
  (let ((B.cplx (copy! B (make-complex-tensor (nrows B) (ncols B)))))
    (complex-typed-gemm! (coerce-complex alpha) A B.cplx
			 (coerce-complex beta) C job))
  C)

;;---------------------------------------------------------------;;
(defgeneric gemm (alpha a b beta c &optional job)
  (:documentation
"
  Syntax
  ======
  (GEMM alpha a b beta c [job])

  Purpose
  =======
  Performs the GEneral Matrix Multiplication given by
	       --      -      -

	     alpha * op(A) * op(B) + beta * C

  and returns the result in a new matrix.

  alpha,beta are scalars and A,B,C are matrices.
  op(A) means either A or A'.

  JOB must be a keyword with two of these alphabets
     N                 Identity
     T                 Transpose
     C                 Complex conjugate
     H                 Hermitian transpose {conjugate transpose}

  so that (there are 4x4 operations in total).

     JOB                    Operation
  ---------------------------------------------------
     :NN (default)      alpha * A * B + beta * C
     :TN                alpha * transpose(A) * B + beta * C
     :NH                alpha * A * transpose o conjugate(B) + beta * C
     :HC                alpha * transpose o conjugate(A) * conjugate(B) + beta * C
"))

(defmethod gemm ((alpha number) (a standard-matrix) (b standard-matrix)
		 (beta number) (c complex-matrix)
		 &optional (job :nn))
  (let ((result (copy C)))
    (gemm! alpha A B beta result job)))

;; if all args are not real then at least one of them
;; is complex, so we need to call GEMM! with a complex C
(defmethod gemm ((alpha number) (a standard-matrix) (b standard-matrix)
		 (beta number) (c real-matrix)
		 &optional (job :nn))
  (let ((result (if (or (complexp alpha) (complexp beta)
			(typep a 'complex-matrix) (typep b 'complex-matrix))
		    (make-complex-tensor (nrows C) (ncols C))
		    (make-real-tensor (nrows C) (ncols C)))))
    (copy! C result)
    (gemm! alpha A B beta result job)))

(defmethod gemm ((alpha number) (a standard-matrix) (b standard-matrix)
		 (beta (eql nil)) (c (eql nil))
		 &optional (job :nn))
  (multiple-value-bind (job-A job-B) (split-job job)
    (let ((result (apply
		   (if (or (complexp alpha) (complexp beta)
			   (typep a 'complex-matrix) (typep b 'complex-matrix))
		       #'make-complex-tensor
		       #'make-real-tensor)
		   (list (if (member job-A '(:n :c)) (nrows A) (ncols A))
			 (if (member job-B '(:n :c)) (ncols B) (nrows B))))))
      (gemm! alpha A B 0 result job))))
