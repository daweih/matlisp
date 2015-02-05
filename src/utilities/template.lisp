(in-package #:matlisp-template)
;;Macro-management is the word.
;;Suck on that C++ :)

(eval-when (:compile-toplevel :load-toplevel :execute)

(defvar *template-table* (make-hash-table))

(defun topological-sort (lst func &optional (test #'eql))
  (multiple-value-bind (nlst len) (loop :for ele :in lst
				     :for i := 0 :then (1+ i)
				     :collect (cons i ele) :into ret
				     :finally (return (values ret (1+ i))))
    (let* ((S nil)
	   (graph (let ((ret (make-array len)))
		    (loop :for (i . ele) :in nlst
		       :do (let ((children (mapcar #'car (remove-if-not #'(lambda (x) (and (not (funcall test (cdr x) ele)) (funcall func (cdr x) ele))) nlst)))
				 (parents (mapcar #'car (remove-if-not #'(lambda (x) (and (not (funcall test (cdr x) ele)) (funcall func ele (cdr x)))) nlst))))
			     (when (null parents)
			       (push i S))
			     (setf (aref ret i) (list ele children parents))))
		    ret))
	   (ordering nil))
    (let ((last-S (last S)))
      (do ((slst S (cdr slst)))
	  ((null slst))
	(let* ((i (car slst))
	       (children (second (aref graph i))))
	  (mapcar #'(lambda (x)
		      (let ((par (third (aref graph x))))
			(let ((par (remove i par)))
			  (setf (third (aref graph x)) par)
			  (when (null par)
			    (setf (cdr last-S) (cons x nil)
				  last-S (cdr last-S))))))
		  children)
	  (push i ordering))))
    (mapcar #'(lambda (x) (car (aref graph x))) ordering))))

(defun match-lambda-lists (lsta lstb)
  (let ((optional? nil))
    (labels ((optp? (a b)
	       (if (and (consp a) (atom b)) (optp? b a)
		   (progn
		     (if (or (member a lambda-list-keywords) (not optional?)) nil
			 (if (null (cddr b)) t nil)))))
	     (lst-walker (a b)
	       (cond
		 ((and (atom a) (atom b))
		  (if (eq a b)
		      (progn
			(when (member a lambda-list-keywords)
			  (setq optional? (if (member a '(&optional &key)) t nil)))
			t)
		      (if (or (member a lambda-list-keywords) (member b lambda-list-keywords)) nil t)))
		 ((or (atom a) (atom b))
		  (if (optp? a b) t nil))
		 ((and (consp a) (consp b))
		  (and (lst-walker (car a) (car b))
		       (lst-walker (cdr a) (cdr b)))))))
      (lst-walker lsta lstb))))

;;
(defgeneric compute-t/dispatch (name args)
  (:method ((name symbol) args)
    (let* ((data (or (gethash name *template-table*)
		     (error "undefined template : ~a~%" name)))
	   (pred (getf data :predicate))
	   (meth (getf data :methods)))
      (flet ((ffilter (pred)
	       (iter ff (for ele in meth)
		     (when (funcall pred args (first ele))
		       (iter (for (code . pp) in (cdr ele)) (when (or (not pp) (funcall pp args)) (return-from ff code)))))))
	(or (ffilter #'equal)
	    (ffilter #'(lambda (a m) (and (not (equal a m)) (funcall pred a m))))
	    (error "could not find a \"~a\" template for : ~a~%" name args))))))

;;
(defun single-argp (name)
  (let* ((data (or (gethash name *template-table*)
		   (error "Undefined template : ~a~%" name)))
	 (ll (getf data :lambda-list)))
    (values (not (consp (first ll))) ll)))

(defgeneric preprocess-t/dispatch (name args)
  (:method ((name symbol) args)
    (funcall (if (single-argp name) #'funcall #'mapcar)
	     #'macroexpand-1 args)))
;;
(defmacro deft/generic ((name predicate &optional sorter (sort-function 'topological-sort)) disp args)
  (when (consp disp)
    (assert (null (remove-if-not #'(lambda (x) (member x cl:lambda-list-keywords)) disp)) nil "dispatch list contains keywords."))
  (with-gensyms (warg-sym disp-sym meth-sym pred-sym)
    (multiple-value-bind (disp-arg disp-far)
	(if (consp disp)
	    (values `(&whole ,disp-sym ,@disp) disp-sym)
	    (values disp disp))
      `(eval-when (:compile-toplevel :load-toplevel :execute)
	 (setf (gethash ',name *template-table*) (list :lambda-list (list ',disp ',args) :predicate ,predicate :sorter ,(or sorter predicate) :methods nil :sort-function ',sort-function))
	 (defmacro ,name (&whole ,warg-sym ,disp-arg ,@args)
	   (declare (ignore ,@(remove-if #'(lambda (x) (member x cl:lambda-list-keywords)) args) ,@(when (consp disp) disp)))
	   (let* ((,pred-sym (preprocess-t/dispatch ',name ,disp-far))
		  (,meth-sym (compute-t/dispatch ',name ,pred-sym)))
	     (apply ,meth-sym (cons ,pred-sym (cddr ,warg-sym)))))))))

(defmacro deft/method (name disp args &rest body)
  (with-gensyms (data-sym meth-sym afun-sym disp-sym sort-sym)
    (letv* (((name &optional filter) (ensure-list name))
	    (data (or (gethash name *template-table*) (error "Undefined template : ~a~%" name)))
	    (ll (getf data :lambda-list))
	    (single? (not (consp (first ll))))
	    ;;
	    (disp-vars (funcall (if single? #'funcall #'mapcar) #'(lambda (x) (if (consp x) (car x) x)) disp))
	    (disp-spls (funcall (if single? #'funcall #'mapcar) #'(lambda (x) (if (consp x) (cadr x) t)) disp)))
      (assert (match-lambda-lists (list disp-vars args) ll) nil "mismatch in lambda-lists.")
    `(eval-when (:compile-toplevel :load-toplevel :execute)
       (let* ((,data-sym (or (gethash ',name *template-table*) (error "Undefined template : ~a~%" ',name)))
	      (,meth-sym (getf ,data-sym :methods))
	      (,afun-sym (lambda (,(if single? disp-vars disp-sym) ,@args)
			   (declare (ignorable ,@(remove-if #'(lambda (x) (member x cl:lambda-list-keywords))
							    (mapcar #'(lambda (x) (if (consp x) (car x) x))
								    (cons (if single? disp-vars disp-sym) args)))))
			   ,(recursive-append
			     (unless single?
			       `(destructuring-bind (,@disp-vars) ,disp-sym
				  (declare (ignorable ,@disp-vars))))
			     `(locally ,@body))))
	      (,sort-sym (getf ,data-sym :sorter)))
	 (declare (ignorable ,data-sym ,meth-sym ,afun-sym ,sort-sym))
	 (if-let (lst (assoc ',disp-spls ,meth-sym :test #'equal))
	   (if-let (flst (find ,filter (cdr lst) :key #'cdr))
	     (rplaca flst ,afun-sym)
	     (rplacd lst (sort (list* (cons ,afun-sym ,filter) (cdr lst)) #'(lambda (a b) (or (not (cdr a)) (cdr b))))))
	   (setf ,meth-sym (,(getf data :sort-function) (list* (list ',disp-spls (cons ,afun-sym ,filter)) ,meth-sym)
			     #'(lambda (a b) (funcall ,sort-sym (first a) (first b))))))
	 (setf (getf ,data-sym :methods) ,meth-sym)
	 ,afun-sym)))))

(defun remt/method (name spls)
  (letv* (((name &optional (filter '*)) (ensure-list name))
	  (data (or (gethash name *template-table*) (error "Undefined template : ~a~%" name)))
	  (meth (getf data :methods)))
    (if (eql filter '*)
	(setf (getf data :methods) (remove spls meth :test #'(lambda (a b) (equal a (first b)))))
	(when-let (lst (find spls meth :test #'(lambda (a b) (equal a (first b)))))
	  (rplacd lst (remove filter (cdr lst) :test #'(lambda (a b) (eql a (cdr b)))))))
    nil))

)
