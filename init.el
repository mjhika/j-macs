;;; init.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 mjhika
;;
;; Author: mjhika <mjhika@D3ADBE3F.local>
;; Maintainer: mjhika <mjhika@D3ADBE3F.local>
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;; disable some gui items
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; some other basic emacs options config
(setq vc-follow-symlinks t
      enable-recursive-minibuffers t
      gc-cons-threshold 2000000
      electric-indent-mode nil
      inhibit-startup-screen t)

;; stop polluting my projects with your backus and auto-saves.
;; move them into my user-emacs-directory
(when (not (file-directory-p (expand-file-name "auto-save-list" user-emacs-directory)))
  (make-directory (expand-file-name "auto-save-list" user-emacs-directory)))

;; Put backups and auto-save files in subdirectories, so the
;; user-emacs-directory doesn't clutter
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups" user-emacs-directory)))
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save-list/" user-emacs-directory) t)))

(when (eq system-type 'gnu/linux)
  (let ((machine-go "/usr/local/go/bin")
	(user-go "~/go/bin"))
    (add-to-list 'exec-path "/usr/local/go/bin")
    (add-to-list 'exec-path "~/go/bin")
    (setenv "PATH"
	    (concat
	     machine-go path-separator
	     user-go path-separator
	     (getenv "PATH")))))

;;; the elpaca installer
(defvar elpaca-installer-version 0.5)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
			      :ref nil
			      :files (:defaults (:exclude "extensions"))
			      :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (call-process "git" nil buffer t "clone"
                                       (plist-get order :repo) repo)))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; elpaca use-package support
(elpaca elpaca-use-package
  ;; Enable :elpaca use-package keyword.
  (elpaca-use-package-mode)
  ;; Assume :elpaca t unless otherwise specified.
  (setq elpaca-use-package-by-default t))

;; block until the current queue is processed
(elpaca-wait)

(defun reload-init-file ()
  (interactive)
  (load-file user-init-file)
  (load-file user-init-file))

;; general is for rebinding
(use-package general
  :demand t
  :config
  (general-evil-setup)

  ;; set up 'SPC' as the global leader key
  (general-create-definer jm/leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC" ;; set leader
    :global-prefix "M-SPC") ;; access leader in insert mode

  (general-create-definer jm/localleader-keys
    :states '(normal visual)
    :prefix ",") ;; set localleader

  (jm/leader-keys
    "u" '(universal-argument :wk "C-u")
    "SPC" '(execute-extended-command :wk "M-x"))

  (jm/leader-keys
    "TAB" '(:ignore t :wk "Comment")
    "TAB TAB" '(comment-line :wk "Comment line")
    "TAB r" '(comment-or-uncomment-region :wk "Comment or Uncomment region"))

  (jm/leader-keys
    "f" '(:ignore t :wk "File")
    "f s" '(save-buffer :wk "File save")
    "f f" '(find-file :wk "Find file")
    "f c" '((lambda () (interactive)
	      (find-file (concat user-emacs-directory
				 "init.el")))
	    :wk "Edit emacs config"))

  (jm/leader-keys
    "b" '(:ignore t :wk "Buffer")
    "b b" '(switch-to-buffer :wk "Switch buffer")
    "b i" '(ibuffer :wk "Ibuffer")
    "b k" '(kill-this-buffer :wk "Kill this buffer")
    "b n" '(next-buffer :wk "Next buffer")
    "b p" '(previous-buffer :wk "Previous buffer")
    "b r" '(revert-buffer :wk "Reload buffer"))

  (jm/localleader-keys
    :keymaps 'emacs-lisp-mode-map
    "e" '(:ignore t :wk "Eval")    
    "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
    "e d" '(eval-defun :wk "Evaluate defun containing or after point")
    "e e" '(eval-expression :wk "Evaluate and elisp expression")
    "e l" '(eval-last-sexp :wk "Evaluate elisp expression before point")
    "e r" '(eval-region :wk "Evaluate elisp in region")) 

  (jm/leader-keys
    "h" '(:ignore t :wk "Help")
    "h f" '(describe-function :wk "Describe function")
    "h v" '(describe-variable :wk "Describe variable")
    "h r r" '((lambda () (interactive)
		(load-file (concat user-emacs-directory
				   "init.el"))
		(ignore (elpaca-process-queues)))
              :wk "Reload emacs config"))

  (jm/leader-keys
    "t" '(:ignore t :wk "Toggle")
    "t l" '(display-line-numbers-mode :wk "Toggle line numbers")
    "t t" '(visual-line-mode :wk "Toggle truncated lines"))

  (jm/localleader-keys
    :keymaps 'clojure-mode-map
    "'" '(:ignore t :wk "jack in")
    "' c" '(cider-jack-in :wk "jack-in")
    "' j" '(cider-jack-in-clj :wk "jack-in clj")
    "' b" '(cider-jack-in-clj&cljs :wk "jack-in clj&cljs")
    "' s" '(cider-jack-in-cljs :wk "jack-in cljs")
    "' u" '(cider-jack-in-universal :wk "jack-in universal")
    "." '(:ignore t :wk "connect")
    ". c" '(cider-connect :wk "connect")
    ". j" '(cider-connect-clj :wk "connect clj")
    ". b" '(cider-connect-clj&cljs :wk "connect clj&cljs")
    ". s" '(cider-connect-cljs :wk "connect cljs")
    ". C" '(cider-connect-sibling-clj :wk "connect universal")
    ". S" '(cider-connect-sibling-cljs :wk "connect universal")
    "d" '(:ignore t :wk "Doc")
    "d d" '(cider-doc :wk "cider doc")
    "d c" '(cider-clojuredocs :wk "clojuredocs cider")
    "d w" '(cider-clojuredocs-web :wk "clojuredocs web")
    "d j" '(cider-javadoc :wk "javadoc")
    "e" '(:ignore t :wk "Eval")
    "e e" '(cider-eval-last-sexp :wk "last sexp")
    "e d" '(:ignore t :wk "defun")
    "e d d" '(cider-eval-defun-at-point :wk "defun at point")
    "e d u" '(cider-eval-defun-up-to-point :wk "defun to point")
    "e d c" '(cider-eval-defun-to-comment :wk "defun to comment")
    "e p" '(:ignore t :wk "pprint")
    "e p d" '(:ignore t :wk "pprint defun")
    "e p d d" '(cider-pprint-eval-defun-at-point :wk "pprint defun")
    "e p d c" '(cider-pprint-eval-defun-to-comment :wk "pprint defun to comment")
    "e b" '(:ignore t :wk "buffer")
    "e b b" '(cider-load-buffer :wk "buffer")
    "e b r" '(cider-load-buffer :wk "buffer load repl")
    "e f" '(:ignore t :wk "file")
    "e f f" '(cider-load-file :wk "file")
    "e f a" '(cider-load-all-files :wk "all files")
    "e r" '(cider-eval-region :wk "region")
    "e n" '(cider-eval-ns-form :wk "ns form")
    "e l" '(:ignore t :wk "last sexp")
    "e l r" '(cider-eval-last-sexp-to-repl :wk "last sexp repl")
    "e l s" '(cider-eval-last-sexp :wk "last sexp")
    "e l x" '(cider-eval-last-sexp-and-replace :wk "last sexp replace")
    "e l c" '(cider-eval-last-sexp-in-context :wk "last sexp context")
    "e t" '(:ignore t :wk "tap")
    "e t l" '(cider-tap-last-sexp :wk "last sexp")
    "e t a" '(cider-tap-sexp-at-point :wk "sexp at point")
    "e i" '(cider-interrupt :wk "interrupt")
    "q" '(:ignore t :wk "quit")
    "q q" '(cider-quit :wk "quit")
    "q r" '(cider-restart :wk "restart"))

  (jm/leader-keys
    :keymaps 'smartparens-mode-map
    "s" '(:ignore t :wk "smartparens")
    "s <" '(sp-backward-barf-sexp :wk "Barf backward")
    "s >" '(sp-forward-barf-sexp :wk "Barf forward")
    "s (" '(sp-backward-slurp-sexp :wk "Slurp backward")
    "s )" '(sp-forward-slurp-sexp :wk "Slurp forward")
    "s }" '(sp-slurp-hybrid-sexp :wk "Slurp (hybrid)")
    "s +" '(sp-join-sexp :wk "Join")
    "s -" '(sp-split-sexp :wk "Split")
    "s a" '(sp-absorb-sexp :wk "Absorb")
    "s c" '(sp-clone-sexp :wk "Clone")
    "s C" '(sp-convolute-sexp :wk "Convolute")
    "s m" '(sp-mark-sexp :wk "Mark")
    "s r" '(sp-raise-sexp :wk "Raise")
    "s s" '(sp-splice-sexp-killing-around :wk "Splice")
    "s t" '(sp-transpose-sexp :wk "Transpose")
    "s T" '(sp-transpose-hybrid-sexp :wk "Transpose (hybrid)")
    ;; Narrow and Widen, use default emacs for widening
    "s w" '(widen :wk "Widen")
    "s n" '(:ignore t :wk "Narrow")
    "s n n" '(narrow-to-defun :wk "defun")
    "s n s" '(sp-narrow-to-sexp :wk "sexp"))

  (jm/leader-keys
    "w" '(:ignore t :wk "Windows")
    ;; Window splits
    "w c" '(evil-window-delete :wk "Close window")
    "w n" '(evil-window-new :wk "New window")
    "w s" '(evil-window-split :wk "Horizontal split window")
    "w v" '(evil-window-vsplit :wk "Vertical split window")
    ;; Window motions
    "w h" '(evil-window-left :wk "Window left")
    "w j" '(evil-window-down :wk "Window down")
    "w k" '(evil-window-up :wk "Window up")
    "w l" '(evil-window-right :wk "Window right")
    "w w" '(evil-window-next :wk "Goto next window")
    ;; Move Windows
    "w H" '(buf-move-left :wk "Buffer move left")
    "w J" '(buf-move-down :wk "Buffer move down")
    "w K" '(buf-move-up :wk "Buffer move up")
    "w L" '(buf-move-right :wk "Buffer move right"))

  (jm/leader-keys
    "p" '(projectile-command-map :wk "Projectile"))

  )

(elpaca-wait)

;; some nice icons
(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

;; setup some window moving commands
(require 'windmove)

;;;###autoload
(defun buf-move-up ()
  "Swap the current buffer and the buffer above the split.
If there is no split, ie now window above the current one, an
error is signaled."
  ;;  "Switches between the current buffer, and the buffer above the
  ;;  split, if possible."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'up))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No window above this one")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-down ()
  "Swap the current buffer and the buffer under the split.
If there is no split, ie now window under the current one, an
error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'down))
         (buf-this-buf (window-buffer (selected-window))))
    (if (or (null other-win) 
            (string-match "^ \\*Minibuf" (buffer-name (window-buffer other-win))))
        (error "No window under this one")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-left ()
  "Swap the current buffer and the buffer on the left of the split.
If there is no split, ie now window on the left of the current
one, an error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'left))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No left split")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-right ()
  "Swap the current buffer and the buffer on the right of the split.
If there is no split, ie now window on the right of the current
one, an error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'right))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No right split")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;; evil for better movements
(use-package evil
  :demand t
  :init      ;; tweak evil's configuration before loading it
  (setq evil-want-integration t) ;; This is t by default.
  (setq evil-want-keybinding nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-d-scroll t)
  (setq evil-shift-width 2)
  (evil-mode))
(use-package evil-collection
  :after evil
  :config
  (setq evil-collection-mode-list '(dashboard dired ibuffer))
  (evil-collection-init))

;; set the default fonts
(set-face-attribute 'default nil
		    :font "Berkeley Mono"
		    :height 130
		    :weight 'medium)
(set-face-attribute 'variable-pitch nil
		    :font "Berkeley Mono Variable"
		    :height 140
		    :weight 'medium)
(set-face-attribute 'fixed-pitch nil
		    :font "Berkeley Mono"
		    :height 130
		    :weight 'medium)
;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
		    :slant 'italic)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "Berkeley Mono-13"))

;; theme
(use-package doom-themes
  :ensure t
  :init (setq doom-themes-enable-bold t
              doom-themes-enable-italic t)
  :config (load-theme 'doom-one t))

;; doom modeline
(use-package doom-modeline
  :ensure t
  :init
  (setq doom-modeline-icon nil)
  (doom-modeline-mode 1)
  :hook (after-init . doom-modeline-mode))

;; rainbow delimiters
(use-package rainbow-delimiters
  :hook ((prog-mode) . rainbow-delimiters-mode))

;; Uncomment the following line if line spacing needs adjusting.
;; (setq-default line-spacing 0.12)

;; line numbers
(global-display-line-numbers-mode 1)
(global-visual-line-mode 't)

;; edit a file that i should have opened with sudo
(use-package sudo-edit
  :config
  (jm/leader-keys
    "f u" '(sudo-edit-find-file :wk "Sudo find file")
    "f U" '(sudo-edit :wk "Sudo edit file")))

;; setup and enable which-key
(use-package which-key
  :init (which-key-mode 1)
  :config
  (setq which-key-side-window-location 'bottom
	which-key-sort-order #'which-key-key-order-alpha
	which-key-sort-uppercase-first nil
	which-key-add-column-padding 1
	which-key-max-display-columns nil
	which-key-min-display-lines 6
	which-key-side-window-slot -10
	which-key-side-window-max-height 0.25
	which-key-idle-delay 0.8
	which-key-max-description-length 25
	which-key-allow-imprecise-window-fit t
	which-key-separator " → "))

;; setup auto complete
(use-package company
  :hook ((prog-mode text-mode) . company-mode)
  :init (setq company-idle-delay 0
	      company-require-match nil
	      company-minimum-prefix-length 1
	      company-auto-update-doc t))

;; yasnippet
(use-package yasnippet-snippets
  :after yasnippet)
(use-package yasnippet
  ;; :config (yas-global-mode 1)
  :hook (prog-mode . yas-minor-mode))

;; projectile
(use-package projectile
  :init (setq )
  :config
  (projectile-mode +1))

;; fzf.el
(use-package fzf
  ;; :bind
  ;; Don't forget to set keybinds!
  :config
  (setq fzf/args "-x --color bw --print-query --margin=1,0 --no-hscroll"
        fzf/executable "fzf"
        fzf/git-grep-args "-i --line-number %s"
        ;; command used for `fzf-grep-*` functions
        ;; example usage for ripgrep:
        ;; fzf/grep-command "rg --no-heading -nH"
        fzf/grep-command "grep -nrH"
        ;; If nil, the fzf buffer will appear at the top of the window
        fzf/position-bottom t
        fzf/window-height 15))

;; vertico
(use-package vertico
  :init
  (vertico-mode)
  ;; Different scroll margin
  ;; (setq vertico-scroll-margin 0)
  ;; Show more candidates
  (setq vertico-count 20)
  ;; Grow and shrink the Vertico minibuffer
  (setq vertico-resize t)
  ;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
  (setq vertico-cycle t))
(use-package savehist
  :elpaca nil
  :init ;; vertico will sort by history
  (savehist-mode))

;; smartparens
(use-package smartparens
  :config (smartparens-global-mode 1))
(use-package evil-smartparens)

;; aggressive-indent
(use-package aggressive-indent
  :config (global-aggressive-indent-mode 1))

;; lsp
(use-package lsp-mode
  :hook ((go-mode) . lsp)
  :hook (lsp-mode . lsp-enable-which-key-integration)
  :commands lsp
  :init
  (setq lsp-keymap-prefix "C-,"))
(use-package lsp-ui
  :commands lsp-ui-mode)

;; flycheck
(use-package flycheck
  :hook (afrter-init . global-flycheck-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; languages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; clojure
(use-package clojure-mode
  :init
  (setq clojure-indent-style 'align-arguments
	clojure-toplevel-inside-comment-form t
	clojure-verify-major-mode nil)
  :config
  (add-hook 'clojure-mode-hook #'subword-mode)
  (add-hook 'clojure-mode-hook #'rainbow-delimiters-mode)
  (add-hook 'clojure-mode-hook #'aggressive-indent-mode))

(use-package cider
  :init
  (setq cider-repl-pop-to-buffer-on-connect 'display-only
	cider-preferred-build-tool 'clojure-cli
	cider-repl-display-help-banner nil
	cider-enrich-classpath t
	nrepl-hide-special-buffers t
        nrepl-log-messages nil
	cider-save-file-on-load t
        cider-font-lock-dynamically '(macro core function var deprecated)
        cider-overlays-use-font-lock t
        cider-prompt-for-symbol nil
        cider-repl-result-prefix ";; => "
        cider-repl-print-length 100
        cider-repl-use-clojure-font-lock t
        cider-repl-use-pretty-printing t
        cider-repl-wrap-history nil
        cider-stacktrace-default-filters '(tooling dup)))

;;; golang
(use-package go-mode)
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;;; html & css
(use-package web-mode
  :init
  (setq web-mode-markup-indent-offset 2
	web-mode-css-indent-offset 2
	web-mode-code-indent-offset 2)
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end languages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; add magit
(use-package magit
  :commands magit)

(provide 'init)
;;; init.el ends here
