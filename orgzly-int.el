;;; orgzly-int.el --- orgzly integration

;;; Commentary:

;; The following draws heavily from this Stack Exchange thread:
;; https://emacs.stackexchange.com/questions/10597/how-to-refile-into-a-datetree

;;; Code:

(defvar orgzly-int-org-inbox-file "~/Documents/Notizen/Mobile.org")
(defvar orgzly-int-org-journal-file "~/Documents/Notizen/Journal.org")

(defun orgzly-int/set-timestamp (date)
  (goto-char (org-entry-end-position))
  (insert
   (format "\nEntered on %s" date)))

(defun orgzly-int/org-refile-to-datetree (&optional file)
  "Refile current subtree to a datetree in FILE corresponding to it's timestamp.

The current time is used if the entry has no timestamp. If FILE
is nil, refile in the current file."
  (interactive)
  (require 'org-datetree)
  (let* ((file (cond
                (file (find-file-noselect file))
                (t (current-buffer))))
         (datetree-date (or (org-entry-get nil "CREATED" t)
                            (org-entry-get nil "TIMESTAMP_IA" t)
                            (org-read-date t nil "now")))
         (date (org-date-to-gregorian datetree-date)))
    (and (org-entry-delete nil "CREATED")
         (orgzly-int/set-timestamp datetree-date))
    (org-refile nil nil (list nil (buffer-file-name file) nil
                              (with-current-buffer file
                                (save-excursion
                                  (org-datetree-find-date-create date)
                                  (point)))))))


(defun orgzly-int/org-refile-all-to-date-tree (source target)
  "Takes two org files as arguments. Refiles all subtrees from
SOURCE into a datetree in TARGET"
    (with-current-buffer (find-file-noselect source)
      (org-map-entries (lambda ()
                         (orgzly-int/org-refile-to-datetree target)
                         (setq org-map-continue-from (point-min)))
                       t
                       nil)))


(defun orgzly-int/org-sync-journal ()
  "Takes all entries from `orgzly-int-org-inbox-file' and refiles
them into a datetree in `orgzly-int-org-journal-file'"
  (interactive)
  (orgzly-int/org-refile-all-to-date-tree
   orgzly-int-org-inbox-file
   orgzly-int-org-journal-file)
  (with-current-buffer
      (find-file-noselect orgzly-int-org-journal-file)
    (fill-flowed-fill-buffer)
    (save-buffer))
  (with-current-buffer
      (find-file-noselect orgzly-int-org-inbox-file)
    (save-buffer)))

(provide 'orgzly-int)

;;; orgzly-int.el ends here
