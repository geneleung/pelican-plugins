(add-to-list 'load-path "~/.emacs.d/plugin")
(require 'json)
(require 'org)
(require 'ox)
(require 'ox-publish)
(require 'htmlize)

;; org导出html时换行不出现空格
(defadvice org-html-paragraph (before org-html-paragraph-advice
                                      (paragraph contents info) activate)
  "Join consecutive Chinese lines into a single long line without
unwanted space when exporting org-mode to html."
  (let* ((origin-contents (ad-get-arg 1))
         (fix-regexp "[[:multibyte:]]")
         (fixed-contents
          (replace-regexp-in-string
           (concat
            "\\(" fix-regexp "\\) *\n *\\(" fix-regexp "\\)") "\\1\\2" origin-contents)))

    (ad-set-arg 1 fixed-contents)))
(setq org-html-htmlize-output-type 'css)
;; (setq org-export-with-toc nil);;设置生成时不输出文章章节目录
(defun org->pelican (filename backend)
  (progn
    (save-excursion
      ; open org file
      (find-file filename)

      ; pre-process some metadata
      (let (; extract org export properties
            (org-export-env (org-export-get-environment))
            ; convert MODIFIED prop to string
            (modifiedstr (cdr (assoc-string "MODIFIED" org-file-properties t)))
            ; prepare date property
            (dateobj (car (plist-get (org-export-get-environment) ':date)))
            )

        ; check if #+TITLE: is given and give sensible error message if not
        (if (symbolp (car (plist-get org-export-env :title)))
            (error "Each page/article must have a #+TITLE: property"))

        ; construct the JSON object
        (princ (json-encode
                (list
                 ; org export environment
                 :title (substring-no-properties
                         (car (plist-get org-export-env :title)))
                 ; if #+DATE is not given, dateobj is nil
                 ; if #+DATE is a %Y-%m-%d string, dateobj is a string,
                 ; and otherwise we assume #+DATE is a org timestamp
                 :date (if (symbolp dateobj)
                           ""
                         (if (stringp dateobj)
                             (org-read-date nil nil dateobj nil)
                           (org-timestamp-format dateobj "%Y-%m-%d")))

                 ;:author (substring-no-properties
					;         (car (plist-get org-export-env ':author)))
		 :author "chappie"

                 ; org file properties
                 :category (cdr (assoc-string "CATEGORY" org-file-properties t))

                 ; custom org file properties, defined as #+PROPERTY: NAME ARG
                 :language (cdr (assoc-string "LANGUAGE" org-file-properties t))
                 :save_as (cdr (assoc-string "SAVE_AS" org-file-properties t))
                 :tags (cdr (assoc-string "TAGS" org-file-properties t))
                 :summary (cdr (assoc-string "SUMMARY" org-file-properties t))
                 :slug (cdr (assoc-string "SLUG" org-file-properties t))
                 :modified (if (stringp modifiedstr)
                               (org-read-date nil nil modifiedstr nil)
                             "")
                 :post (org-export-as backend nil nil t)
                 )
                )
               )
        )
      )
    )
  )
