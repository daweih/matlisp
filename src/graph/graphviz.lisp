(in-package :matlisp)

(defun graph->dot (stream g &optional self-loops node-name)
  (if (null stream)
      (with-output-to-string (out) (graph->dot out g))
      (progn; ((nei (neighbors graph)))
	(format stream "digraph G{~%graph [];~%node[shape=point];~%~%")
	(iter (for u from 0 below (dimensions g -1)) (format stream "~a [xlabel=\"~a\"];~%" u (typecase node-name
												(function (funcall node-name u))
												(sequence (elt node-name u))
												(null "")
												(t u))))
	(iter (for u from 0 below (dimensions g -1))
	      (letv* ((lb ub (fence g u)))
		(iter (for v in-vector (δ-i g) from lb below ub)
		      (when (or (and (= u v) (not self-loops)) (and (< v u) (δ-i g v u))) (next-iteration))
		      (format stream (string+ "~a->~a [" (if (δ-i g v u) "dir=none,color=red," "")  "label=\"\",];~%") v u))))
	(format stream "}~%"))))

(defun display-graph (graph &optional self-loops (node-name t) &aux (name (symbol-name (gensym))) (dot-name (string+ "/tmp/matlisp-tmp-" name ".out")) (svg-name (string+ "/tmp/matlisp-tmp-" name ".svg")))
  (with-open-file (out dot-name :direction :output :if-exists :supersede :if-does-not-exist :create)
    (graph->dot out graph self-loops node-name))
  (with-open-file (out svg-name :direction :output :if-exists :supersede :if-does-not-exist :create)
    (external-program:run "/usr/bin/neato" (list dot-name "-Tsvg") :output out))
  (bt:make-thread #'(lambda () (external-program:run "/usr/bin/inkview" (list svg-name) :output nil :wait nil)))
  graph)
