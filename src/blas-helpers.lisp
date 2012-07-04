(in-package :matlisp)

(defun blas-copyable-p (ten-a ten-b)
  (declare (type standard-tensor ten-a ten-b))
  (mlet*
   (((sort-std-a std-a-perm) (idx-sort-permute (copy-seq (strides ten-a)) #'<) :type ((index-array *) permutation))
    (perm-a-dims (permute (dimensions ten-a) std-a-perm) :type (index-array *))
    ;;If blas-copyable then the strides must have the same sorting permutation.
    (sort-std-b (permute (strides ten-b) std-a-perm) :type (index-array *))
    (perm-b-dims (permute (dimensions ten-b) std-a-perm) :type (index-array *)))
   (very-quickly
     (loop
	for sost-a across sort-std-a
	for sodi-a across perm-a-dims
	for a-aoff of-type index-type = (aref sort-std-a 0) then (the index-type (* a-aoff sodi-a))
	;;
	for sost-b across sort-std-b
	for sodi-b across perm-b-dims
	for b-aoff of-type index-type = (aref sort-std-b 0) then (the index-type (* b-aoff sodi-b))
	;;
	do (unless (and (= sost-a a-aoff)
			(= sost-b b-aoff)
			(= sodi-a sodi-b))
	     (return nil))
	finally (return (list (aref sort-std-a 0) (aref sort-std-b 0)))))))

(defun consecutive-store-p (tensor)
  (declare (type standard-tensor tensor))
  (mlet* (((sort-std std-perm) (idx-sort-permute (copy-seq (strides tensor)) #'<) :type ((index-array *) permutation))
	  (perm-dims (permute (dimensions tensor) std-perm) :type (index-array *)))
      (very-quickly
	(loop
	   for so-st across sort-std
	   for so-di across perm-dims
	   and accumulated-off = (aref sort-std 0) then (the index-type (* accumulated-off so-di))
	   unless (= so-st accumulated-off) do (return nil)
	   finally (return (aref sort-std 0))))))


;; (defun blas-matrix-compatible-p (matrix &optional (op :n))
;;   (declare (optimize (safety 0) (speed 3))
;; 	   (type (or real-matrix complex-matrix) matrix))
;;   (mlet* (((rs cs) (slot-values matrix '(row-stride col-stride))
;; 	   :type (fixnum fixnum)))
;; 	 (cond
;; 	   ((= cs 1) (values :row-major rs (fortran-nop op)))
;; 	   ((= rs 1) (values :col-major cs (fortran-op op)))
;; 	   ;;Lets not confound lisp's type declaration.
;; 	   (t (values nil -1 "?")))))

;; (definline fortran-op (op)
;;   (ecase op (:n "N") (:t "T")))

;; (definline fortran-nop (op)
;;   (ecase op (:t "N") (:n "T")))

;; (defun fortran-snop (sop)
;;   (cond
;;     ((string= sop "N") "T")
;;     ((string= sop "T") "N")
;;     (t (error "Unrecognised fortran-op."))))
