;;; guitar.el --- Turns emacs into a musical instrument. Yes really.
;;;
;;; Are you going to Scarborough Fair?
;;;
;;; Author: Uladox
;;; URL: https://github.com/Uladox/guitar.el
;;; Version: 0.0.0.1Beta-Snapshot-First
;;; Keywords: guitar, music, cider, clojure, overtone
;;;
;;; Inspired by the amazing overtone team and the concept of emacs as an
;;; operating system... one step closer.
;;; written by Uladox
;;; See: https://github.com/Uladox/guitar.el

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LICENSE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; I highly recomend these pages for learning overtone
; http://bzg.fr/emacs-org-babel-overtone-intro.html
; https://github.com/overtone/overtone/wiki/Chords-and-scales
; https://github.com/overtone/overtone/blob/master/src/overtone/music/pitch.clj

;; I apologize in advance for the stupidly long function names
(defconst +guitar-directory+ (file-name-directory (or load-file-name buffer-file-name)))
(setq guitar-safe t)
(setq guitar-octave 2)
(setq guitar-theme t)
(setq guitar-flat-norm-sharp "")
(require 'cider-client)
(require 'cider-interaction)
(require 'cider-eldoc)
(require 'cider-repl)
(require 'cider-mode)
(require 'cider-util)
(require 'tramp-sh)

(defun guitar-wait-for-loading-buffer (buffer-name)
  (while (not (get-buffer buffer-name))
    (sit-for 0.2))
  (switch-to-buffer (get-buffer buffer-name))
  (while (< (buffer-size) 10) (sit-for 0.2)))

(defun guitar-wait-for-indicator-char (in-char pos-back)
  (end-of-buffer)
  (while (not (char-equal in-char (char-before (- (point) pos-back))))
    (end-of-buffer)
    (sit-for 0.2)))

(defun guitar-wait-for-repl ()
  (guitar-wait-for-indicator-char ?> 1))

(defun guitar-get-after (after)
  (let ((buff (split-string (buffer-string))) (next nil))
    (dolist (element buff)
      (if next (return element)
	(if (string= element after)
	    (setq next t))))))

(defun guitar-start-server (project)
  (setq project-dir (nrepl-project-directory-for project))
  (nrepl-start-server-process project-dir "lein repl")
  (guitar-wait-for-loading-buffer "*nrepl-server guitar*")
  (guitar-wait-for-repl)
  (end-of-buffer))

(defun guitar-start-repl ()
  (guitar-goto-server)
  (cider-connect (guitar-get-after "host") (guitar-get-after "port"))
  (guitar-wait-for-loading-buffer "*cider-repl guitar*")
  (guitar-wait-for-repl))

(defun guitar-goto-server ()
  (switch-to-buffer (get-buffer "*nrepl-server guitar*")))

(defun guitar-goto-repl ()
  (switch-to-buffer (get-buffer "*cider-repl guitar*")))

;; The one of the most important functions
(defun guitar-pipe (command)
  (guitar-goto-repl)
  (end-of-buffer)
  (insert command)
  (cider-repl-return)
  (guitar-wait-for-repl))

(defun guitar-pipe-safe (command)
  (if guitar-safe
      (progn
	(setq guitar-safe nil)
	(guitar-goto-repl)
	(end-of-buffer)
	(insert command)
	(cider-repl-return)
	(setq guitar-safe t))
    nil))

(defun guitar-mode-setup (project)
  (guitar-start-server project)
  (guitar-start-repl)
  (guitar-pipe "(require 'guitar.core)"))

(defun guitar-key-func (key-name note)
  (eval `(lambda ()
	   (interactive)
	   (if (and (string= guitar-flat-norm-sharp "b") (string= ,note ":F"))
	       nil
	     (progn 
	       (guitar-pipe-safe ,key-name)
	       (switch-to-buffer "*Guitar-mode*"))))))

(defun guitar-play (note cord)
     (guitar-key-func `(concat "(guitar.core/key-setup "
			       ,note
			       guitar-flat-norm-sharp
			       (number-to-string guitar-octave)
			       " "
			       ,cord
			       ")")
		      note))

(defun guitar-play-greater (note cord)
    (guitar-key-func `(concat "(guitar.core/key-setup "
			      ,note
			      guitar-flat-norm-sharp
			      (number-to-string (+ guitar-octave 1))
			      " "
			      ,cord
			      ")")
		     note))

; I am way too lazy to define all octaves manually
(defun guitar-switch-octave (octave-number)
  (eval `(lambda ()
	   (interactive)
	   (setq guitar-octave ,octave-number))))

(defun guitar-run-note (note chord length)
  (guitar-pipe-safe 
   (concat "(guitar.core/key-setup "
	   note
	   " "
	   chord
	   ")"))
  (switch-to-buffer "*Guitar-mode*")
  (sit-for length))

(defun guitar-load-ballard (ballard)
  (dolist (element ballard)
    (if (string= (car element) "rest")
	(sit-for (car (cdr element)))
      (if (string= (car element) "code")
	  (eval (car (cdr element)))
	(apply 'guitar-run-note element)))))

(defun guitar-switch-flat-norm-sharp ()
  (interactive)
  (if (string= guitar-flat-norm-sharp "") 
      (progn 
	(setq guitar-flat-norm-sharp "#")
	(setq mode-name "Guitar #")
	(recenter))
    (if (string= guitar-flat-norm-sharp "#")
	(progn
	  (setq guitar-flat-norm-sharp "b")
	  (setq mode-name "Guitar b")
	  (recenter))
      (progn
	(setq guitar-flat-norm-sharp "")
	(setq mode-name "Guitar")
	(recenter)))))

(defun guitar-no-play-theme ()
  (setq guitar-theme nil))

(defun guitar-get-default-image ()
  (create-image (concat +guitar-directory+ "/guitar/guitar-pic.png")))

(defun guitar-scarborough ()
  (switch-to-buffer "*Guitar-mode*")
  (guitar-load-ballard 
   '(
     ("code" (insert "Are "))
     (":Db5" ":minor" 1.0)
     ("code" (insert "You "))
     (":Db5" ":minor" 0.5)     

     ("code" (insert "going "))
     (":Ab6" ":minor" 1.0)
     ("code" (insert "to "))
     (":Ab6" ":minor" 0.5)
     
     ("code" (insert "Scar"))
     (":Eb5" ":minor" 0.75)
     ("code" (insert "bor"))
     (":F5" ":minor" 0.25)
     ("code" (insert "ough "))
     (":Eb5" ":minor" 0.5)
    
     ("code" (insert "Fair? "))
     (":Db6" ":minor" 1.5)
     
     ("rest" 1.0)
     ("code" (insert "Par"))
     (":Ab6" ":minor" 1.0)
     ("code" (insert "sley, "))
     (":Cb6" ":minor" 1.0)
     
     ("code" (insert "Sage, "))
     (":Db6" ":minor" 2.0)
     ("code" (insert "Rose"))
     (":Cb6" ":minor" 1.0)
     
     ("code" (insert "ma"))
     (":Ab6" ":minor" 1.0)
     ("code" (insert "ry "))
     (":C6" ":minor" 1.0)
     ("code" (insert "and "))
     (":Gb5" ":minor" 1.0)
     
     ("code" (insert "Thyme."))
     (":Ab6" ":minor" 3.0)

     ("code" (newline))
     ("code" (insert-image (guitar-get-default-image)))

     (":A4" ":major" 0.0)
     (":B4" ":major" 0.0)
     (":C4" ":major" 0.0)
     (":D4" ":major" 0.0))))

;(funcall (key-func "joe"))
;;; Start of mode
(defvar guitar-mode-hook nil)

(defvar guitar-mode-map
  (let ((map (make-keymap)))
    (define-key map [?`] (guitar-play ":C" ":minor"))
    (define-key map [?1] (guitar-play ":D" ":minor"))
    (define-key map [?2] (guitar-play ":E" ":minor"))
    (define-key map [?3] (guitar-play ":F" ":minor"))
    (define-key map [?4] (guitar-play ":G" ":minor"))
    (define-key map [?5] (guitar-play ":A" ":minor"))
    (define-key map [?6] (guitar-play ":B" ":minor"))

    (define-key map [?7] (guitar-play-greater ":C" ":minor"))
    (define-key map [?8] (guitar-play-greater ":D" ":minor"))
    (define-key map [?9] (guitar-play-greater ":E" ":minor"))
    (define-key map [?0] (guitar-play-greater ":F" ":minor"))
    (define-key map [?-] (guitar-play-greater ":G" ":minor"))
    (define-key map [?=] (guitar-play-greater ":A" ":minor"))
    (define-key map (kbd "<backspace>") (guitar-play-greater ":B" ":minor"))

    (define-key map [?~] (guitar-play ":C" ":major"))
    (define-key map [?!] (guitar-play ":D" ":major"))
    (define-key map [?@] (guitar-play ":E" ":major"))
    (define-key map [?#] (guitar-play ":F" ":major"))
    (define-key map [?$] (guitar-play ":G" ":major"))
    (define-key map [?%] (guitar-play ":A" ":major"))
    (define-key map [?^] (guitar-play ":B" ":major"))

    (define-key map [?&] (guitar-play-greater ":C" ":major"))
    (define-key map [?*] (guitar-play-greater ":D" ":major"))
    (define-key map [?(] (guitar-play-greater ":E" ":major"))
    (define-key map [?)] (guitar-play-greater ":F" ":major"))
    (define-key map [?_] (guitar-play-greater ":G" ":major"))
    (define-key map [?+] (guitar-play-greater ":A" ":major"))
    (define-key map (kbd "S-<backspace>") (guitar-play-greater ":B" ":major"))

    (define-key map (kbd "<kp-end>") (guitar-switch-octave 1))
    (define-key map (kbd "<kp-down>") (guitar-switch-octave 2))
    (define-key map (kbd "<kp-next>") (guitar-switch-octave 3))
    (define-key map (kbd "<kp-left>") (guitar-switch-octave 4))
    (define-key map (kbd "<kp-begin>") (guitar-switch-octave 5))
    (define-key map (kbd "<kp-right>") (guitar-switch-octave 6))
    (define-key map (kbd "<kp-home>") (guitar-switch-octave 7))
    (define-key map (kbd "<kp-up>") (guitar-switch-octave 8))
    (define-key map (kbd "<kp-prior>") (guitar-switch-octave 9))

    (define-key map (kbd "<tab>") 'guitar-switch-flat-norm-sharp)

    map))



(defun guitar-mode ()
  "Major mode for turning Emacs into a musical instrument"
  (interactive)
  (kill-all-local-variables)
  (guitar-mode-setup (concat +guitar-directory+ "/guitar"))
  (switch-to-buffer (get-buffer-create "*Guitar-mode*"))
  (delete-other-windows)
  (setq cursor-type nil)
  (setq major-mode 'guitar-mode)
  (setq mode-name "Guitar")
  (use-local-map guitar-mode-map)
  (run-hooks 'guitar-mode-hook)
  (if guitar-theme
      (guitar-scarborough)
    nil))
 
(provide 'guitar-mode)
;; (global-set-key (kbd "<tab>~") (lambda () (interactive) (insert "hello")))
