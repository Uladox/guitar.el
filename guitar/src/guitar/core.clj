(ns guitar.core)
(use 'overtone.live)
(use 'overtone.inst.piano)

(defn foo
  "I don't do a whole lot."
  [x]
  (println x "Hello, World!"))

(defn play-chord [chord]
  (doseq [note chord] (piano note)))

(defn key-setup [note scale]
  (play-chord (chord note scale)))

(defn a-key []
  (key-setup :D4 :minor))
(defn s-key []
  (key-setup :A4 :minor))
(defn d-key []
  (key-setup :E4 :minor))
(defn f-key []
  (key-setup :F4 :minor))

