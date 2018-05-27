;;; lemonbar.el --- Lemonbar integration for Emacs -*- lexical-binding: t -*-

;; Copyright (C) 2018 by Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/akirak/lemonbar.el

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library runs lemonbar as an asynchronous process and updates its content
;; periodically and/or by event.

;;; Code:

(require 'timer)
(require 'comint)
(require 'cl-lib)

(defconst lemonbar-buffer "*lemonbar*"
  "Name of the buffer used by lemonbar.")

(defcustom lemonbar-options nil
  "List of command line options used in the lemonbar."
  :type '(repeat string)
  :group 'lemonbar)

(defcustom lemonbar-update-interval nil
  "Interval in seconds to update the lemonbar content.

When nil, lemonbar is not updated until `lemonbar-update' function is manually
called or the function is triggered by external events."
  :type 'number
  :group 'lemonbar)

(defvar lemonbar-start-hook '(lemonbar-set-timer)
  "List of functions to run after lemonbar is started.")

(defvar lemonbar-kill-hook '(lemonbar-cancel-timer)
  "List of functions to run after the process of lemonbar is killed.")

(defvar lemonbar-before-update-hook nil
  "List of functions to run before a new content is sent to the running
lemonbar.")

(defvar lemonbar-started nil
  "Non-nil if lemonbar has started.")

(defun lemonbar-start ()
  "Start a lemonbar."
  (interactive)
  (lemonbar-kill)
  (when-let ((buf (apply #'make-comint-in-buffer "lemonbar" lemonbar-buffer
                         "lemonbar" nil lemonbar-options)))
    (set-process-query-on-exit-flag (get-buffer-process buf) nil))
  (setq lemonbar-started t)
  (run-hooks 'lemonbar-start-hook)
  (lemonbar-update))

(defun lemonbar-kill ()
  "Kill the process of lemonbar and return non-nil if it is running."
  (interactive)
  (when-let ((proc (get-buffer-process lemonbar-buffer)))
    (when (process-live-p proc)
      (interrupt-process proc)
      (sleep-for 0.05)
      (kill-buffer lemonbar-buffer)
      (run-hooks 'lemonbar-kill-hook)
      (setq lemonbar-started nil)
      t)))

(defvar lemonbar-timer nil
  "Timer object to update the lemonbar periodically.")

(defun lemonbar-set-timer ()
  "Set a timer to update the lemonbar periodically."
  (when lemonbar-update-interval
    (setq lemonbar-timer (run-at-time t lemonbar-update-interval
                                      #'lemonbar-update))))

(defun lemonbar-cancel-timer ()
  "Cancel the timer to update the lemonbar."
  (when lemonbar-timer
    (cancel-timer lemonbar-timer)
    (setq lemonbar-timer nil)))

(defun lemonbar--log (string)
  "Send STRING to the lemonbar."
  (when-let ((proc (get-buffer-process lemonbar-buffer)))
    (comint-send-string proc string)))

(defun lemonbar-update (&optional skip-hooks)
  "Update the content of the lemonbar. "
  (unless skip-hooks
    (run-hooks 'lemonbar-before-update-hook))
  (lemonbar--log (concat (lemonbar--generate-output) "\n")))

(defcustom lemonbar-separator ""
  "Separator inserted between items in `lemonbar-output-template'."
  :group 'lemonbar
  :type 'string)

(defun lemonbar--generate-output ()
  "Generate an output string from `lemonbar-output-template'."
  (mapconcat (lambda (item)
               (pcase item
                 ((pred stringp) item)
                 ('() nil)
                 ('t nil)
                 ((and (pred symbolp)
                       (pred boundp)) (symbol-value item))
                 (`(:eval ,list) (eval list))
                 ((pred listp) (eval item))))
             lemonbar-output-template
             lemonbar-separator))

(defcustom lemonbar-output-template nil
  "Output template of lemonbar."
  :type '(repeat (choice string variable sexp))
  :group 'lemonbar)

;;;###autoload
(defun lemonbar-set-output-template (list)
  "Update the output template to LIST and immediately refresh the bar content.

This is a convenient way to experiment with `lemonbar-output-template' during
development, but also is it safe to call this function before the lemonbar is
started, because it checks if the lemonbar has started."
  (setq lemonbar-output-template list)
  (when lemonbar-started (lemonbar-update)))

(defconst lemonbar-align-right "%{r}"
  "Align the following content to the right.")

(defconst lemonbar-align-center "%{c}"
  "Align the following content to the center.")

(with-eval-after-load 'desktop
  (add-hook 'desktop-clear-preserve-buffers "\\*lemonbar\\*"))

(provide 'lemonbar)
