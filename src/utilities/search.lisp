(in-package #:matlisp-utilities)

(eval-every

(defun function-inlineablep (x n)
  (match x
    ((list 'quote (guard x (symbolp x))) t)
    ((list 'function x) (or (symbolp x)
			    (match x ((list* 'lambda (guard args
							    (and (listp args)
								 (= (length args) n)
								 (every #'symbolp args)))
					     _) t))))
    ((list* 'lambda (guard args
			   (and (listp args)
				(= (length args) n)
				(every #'symbolp args)))
	    _) t)))

(let ((code `(lambda (val lb ub vec &key (order #'<) (test #'=))
	       (declare (type fixnum lb ub)
			(type vector vec))
	       (cond
		 ((or (= lb ub) (funcall order val (aref vec lb))) (values nil lb))
		 ((funcall order (aref vec (1- ub)) val) (values nil ub))
		 (t (loop :for j :of-type fixnum := (floor (+ lb ub) 2)
		       :repeat #.(ceiling (log array-dimension-limit 2))
		       :do (cond ((funcall test (aref vec j) val) (return j))
				 ((>= lb (1- ub)) (return (values nil (if (funcall order (aref vec lb) val) (1+ lb) lb))))
				 (t (if (funcall order val (aref vec j))
					(setf ub j)
					(setf lb (1+ j)))))))))))
  (setf (symbol-function 'binary-search) (compile nil code))
  (define-compiler-macro binary-search (&whole form val lb ub vec &key (order '(function <)) (test '(function =)))
    (letv* ((vtype-givenp (and (consp vec) (eql (first vec) 'the)))
	    ((inline-orderp inline-testp) (mapcar #'(lambda (x)	(function-inlineablep x 2)) (list order test))))
      (if (or vtype-givenp inline-orderp inline-testp)
	  (let ((code (maptree-if #'(lambda (x) (and (consp x) (or (and vtype-givenp (equal x '(type vector vec)))
								   (match x
								     ((list* 'funcall 'order _) t)
								     ((list* 'funcall 'test _) t)))))
				  #'(lambda (x)
				      (if (and vtype-givenp (equal (first x) 'type))
					  `(type ,(second vec) vec)
					  (if-let (code (ecase (second x) (order (and inline-orderp order)) (test (and inline-testp test))))
					    (match code
					      ((list (or 'function 'quote) (guard f (symbolp f))) `(,(second code) ,@(cddr x)))
					      ((list 'function (list* 'lambda _)) (let ((code (second code))) `(let (,@(zip (second code) (cddr x))) ,@(cddr code))))
					      ((list* 'lambda _) `(let (,@(zip (second code) (cddr x))) ,@(cddr code)))
					      (_ (error "can't parse pattern ~a" code)))
					    x)))
				  (cddr code)))
		(decl (zip (subseq (second code) 0 4) (cdr form))))
	    `(let (,@decl
		   ,@(unless inline-orderp `((order ,order)))
		   ,@(unless inline-testp `((test ,test))))
	       ,@code))
	  form))))

(let ((code `(lambda (seq predicate &key key)
	       (declare (type vector seq))
	       (let*-typed ((key (or key #'identity))
			    (len (length seq) :type fixnum)
			    (perm (make-array len :element-type 'fixnum) :type (simple-array fixnum))
			    (jobs (make-array len :adjustable t :fill-pointer 0)))
		 (declare (ignorable key))
		 (loop :for i :of-type fixnum :from 0 :below (length perm) :do (setf (aref perm i) i))
		 (loop
		    :for bounds := (cons 0 len) :then (unless (zerop (length jobs)) (vector-pop jobs))
		    :until (null bounds)
		    :do (let*-typed ((below-idx (car bounds) :type fixnum)
				     (above-idx (cdr bounds) :type fixnum)
				     (piv (+ below-idx (floor (- above-idx below-idx) 2)) :type fixnum))
			  (loop
			     :with ele := (funcall key (aref seq piv))
			     :with lbound :of-type fixnum := below-idx
			     :with ubound :of-type fixnum := (1- above-idx)
			     :until (progn
				      (loop :for i :of-type fixnum :from lbound :to piv
					 :until (or (= i piv) (funcall predicate ele (funcall key (aref seq i))))
					 :finally (setq lbound i))
				      (loop :for i :of-type fixnum :downfrom ubound :to piv
					 :until (or (= i piv) (funcall predicate (funcall key (aref seq i)) ele))
					 :finally (setq ubound i))
				      (cond
					((= ubound lbound piv)
					 (when (> (- piv below-idx) 1)
					   (vector-push-extend (cons below-idx piv) jobs))
					 (when (> (- above-idx (1+ piv)) 1)
					   (vector-push-extend (cons (1+ piv) above-idx) jobs))
					 t)
					((< lbound piv ubound)
					 (rotatef (aref seq lbound) (aref seq ubound))
					 (rotatef (aref perm lbound) (aref perm ubound))
					 (incf lbound) (decf ubound)
					 nil)
					((= lbound piv)
					 (rotatef (aref seq piv) (aref seq (1+ piv)))
					 (rotatef (aref perm piv) (aref perm (1+ piv)))
					 (unless (= ubound (1+ piv))
					   (rotatef (aref seq piv) (aref seq ubound))
					   (rotatef (aref perm piv) (aref perm ubound)))
					 (incf piv) (incf lbound)
					 nil)
					((= ubound piv)
					 (rotatef (aref seq (1- piv)) (aref seq piv))
					 (rotatef (aref perm (1- piv)) (aref perm piv))
					 (unless (= lbound (1- piv))
					   (rotatef (aref seq lbound) (aref seq piv))
					   (rotatef (aref perm lbound) (aref perm piv)))
					 (decf piv) (decf ubound)
					 nil)))))
		    :finally (return (values seq perm)))))))
  (setf (symbol-function 'sort-index) (compile nil code)
	(documentation 'sort-index 'function)
	"
  Sorts a lisp-vector in-place, by using the function @arg{predicate} as the
  order. Also computes the permutation action which would sort the original
  sequence @arg{seq} when applied.")

  ;;
  (define-compiler-macro sort-index (&whole form seq predicate &key key)
    (letv* ((key (or key '(lambda (x) x)))
	    (vtype-givenp (and (consp seq) (eql (first seq) 'the)))
	    (inline-predicatep (function-inlineablep predicate 2))
	    (inline-keyp (function-inlineablep key 1)))
      (if (or vtype-givenp inline-predicatep inline-keyp)
	  (let ((code (maptree-if #'(lambda (x) (and (consp x) (or (and vtype-givenp (equal x '(type vector seq)))
								   (match x
								     ((list* 'funcall 'predicate _) t)
								     ((list* 'funcall 'key _) t)))))
				  #'(lambda (x)
				      (if (and vtype-givenp (equal (first x) 'type))
					  `(type ,(second seq) seq)
					  (if-let (code (ecase (second x) (predicate (and inline-predicatep predicate)) (key (and inline-keyp key))))
					    (match code
					      ((list (or 'function 'quote) (guard f (symbolp f))) (values `(,(second code) ,@(cddr x)) #'mapcar))
					      ((list 'function (list* 'lambda _)) (let ((code (second code))) `(let (,@(zip (second code) (cddr x))) ,@(cddr code))))
					      ((list* 'lambda _) `(let (,@(zip (second code) (cddr x))) ,@(cddr code)))
					      (_ (error "can't parse pattern ~a" code)))
					    x)))
				  (cddr code))))
	    `(let ((seq ,seq)
		   ,@(unless inline-predicatep `((predicate ,predicate)))
		   (key ,(if inline-keyp nil key)))
	       ,@code))
	  form))))
)
