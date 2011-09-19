(defun pry ()
  "Start Pry session in a new buffer.
The buffer is in Pry mode; see `pry-mode' for the
commands to use in that buffer."
  (interactive)

  (cd "/home/jakub/prog/projects/pry")
  (set-buffer (make-term "pry" "./pry-experimental"))
  (pry-mode)
  (term-char-mode)
  (server-start)

  (switch-to-buffer "*pry*")

  ; make the Pry window dedicated so that it is not used to
  ; display Ruby when using edit-method and such
  (set-window-dedicated-p
   (car (get-buffer-window-list (current-buffer)))
   t)

  (term-send-raw-string "Pry.editor = 'emacsclient -n'\n")
  )

(define-derived-mode pry-mode term-mode "Pry")


(defun pry-eval (code)
  (with-current-buffer "*pry*"
    (term-send-raw-string code)))

(defun pry-eval-buffer ()
  (interactive)
  (pry-eval (buffer-string)))
