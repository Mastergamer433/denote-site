;; Initialize package sources
(require 'package)

;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(setq package-user-dir (expand-file-name "./.packages"))

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install and load weblorg
(unless (package-installed-p 'weblorg)
  (package-install 'weblorg))
(require 'weblorg)

;; Install and load Denote
(unless (package-installed-p 'denote)
  (package-install 'denote))
(require 'denote)

(setq denote-directory "~/Notes")

;; (setq files-to-publish
;;       (mapcar #'file-name-nondirectory
;;               (denote--directory-files-matching-regexp "_public.*\\.org$")))

;; (defun get-article-output-path (org-file pub-dir)
;;   (if (string-match "\\/index\\(.org|.html\\)$" org-file)
;;       pub-dir
;;     (let ((article-dir (concat pub-dir
;;                                (thread-first org-file
;;                                              (file-name-nondirectory)
;;                                              (file-name-sans-extension)
;;                                              (file-name-as-directory)
;;                                              (dw/strip-file-name-metadata)
;;                                              (concat "/")))))
;;       (message "ARTICLE DIR: %s" article-dir)
;;       (unless (file-directory-p article-dir)
;;         (make-directory article-dir t))
;;       article-dir)))

;; (defun org-html-publish-to-html (plist filename pub-dir)
;;   "Publish an org file to HTML, using the FILENAME as the output directory."
;;   (let ((article-path (get-article-output-path filename pub-dir)))
;;     (cl-letf (((symbol-function 'org-export-output-file-name)
;;                (lambda (extension &optional subtreep pub-dir)
;;                  (concat article-path "index" extension))))
;;       (org-publish-org-to 'html
;;                           filename
;;                           (concat "." (or (plist-get plist :html-extension)
;;                                           "html"))
;;                           plist
;;                           article-path))))

;; (setq org-publish-project-alist
;;       (list
;;        (list "blog-site:main"
;;              :auto-sitemap t
;;              :sitemap-filename "index.html"
;;              :base-extension "org"
;;              :base-directory denote-directory
;;              :exclude "\\.org$"
;;              :include files-to-publish
;;              :publishing-function '(org-html-publish-to-html)
;;              :publishing-directory "./public"
;;              :with-timestamps t
;;              :with-title nil)))

;; (org-publish-all t)

;; Configure the site
(setq denote-site (weblorg-site
                   :name "daviwil.com"
                   :base-url (if (string= (getenv "PROD") "false") ; TODO chande this to true
                                 "https://daviwil.com"
                               "http://localhost:8080")))

(defun dw/fix-slugs (posts)
  (weblorg-input-aggregate-all-desc
   (mapcar (lambda (post)
             (message "Post:" (cdaadr post))
             post)
           posts)))

(defun dw/strip-file-name-metadata (file-name)
  (replace-regexp-in-string "^.*--\\(.*?\\)__.*$" "\\1" file-name))

(setq posts
      (mapcar (lambda (file)
                ;; This also needs "route" and "url" which seems to be something
                ;; you need to do yourself when using :input-sources
                `("post" . (("title" . ,(denote--retrieve-title-value file 'org))
                            ("slug" . ,(dw/strip-file-name-metadata file))
                            ("file" . ,file))))
              (denote--directory-files-matching-regexp "_public.*\\.org$")))

;; Live streams index page
(weblorg-route
 :name "index"
 :site denote-site
 :input-source posts
 :template "post-index.html"
 :output "public/index.html"
 :url "index.html")

(weblorg-route
 :name "posts"
 :site denote-site
 :input-source posts
 :template "post.html"
 :output "public/{{ slug }}/index.html"
 :url "/{{ slug }}/")

;; Export the site
(weblorg-export)
