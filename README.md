# guitar.el
Turn emacs into a musical instrament!

Add guitar.el to your .emacs load path and the guitar folder in the same folder as guitar.el

Requires cider clojure and lein and makes use of overtone.

[http://overtone.github.io/](overtone),
[https://github.com/clojure-emacs/cider](cider),
[http://leiningen.org/](lein)

To start use M-x guitar-mode. Use the numbered keys on the right.

To change octaves press tab to switch between sharp, flat or normal mode.

The keys from ~ to 6 play C D E F G A B in the current octave.

The keys from 7 to \<backspace> play the keys of the next

octave in the same order.

By default all keys are played in minor howerver holding

shift and playing the key plays it in major mode.

If a bug is found email me once I have a public email address.

Most bugs can be fixed by C-g, however they are still bugs.

The Scarborough Fair (public domain version mind you) can be disabled by:

(add-hook 'guitar-mode-hook #'guitar-no-play-theme)

If you want to use this package for your own or a package pack

feel free to, just email me as I want to know the stangest place

my code ends up at.

Current Bugs:

Running guitar-mode twice

Sound/strangeness after running
(especially on internet videos)
