;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))

;; Data structures
(define-map documents
  { hash: (buff 32) }
  {
    owner: principal,
    name: (string-ascii 64),
    mime-type: (string-ascii 64),
    timestamp: uint,
    status: (string-ascii 16)
  }
)

(define-map document-history
  { hash: (buff 32), index: uint }
  {
    owner: principal,
    timestamp: uint,
    action: (string-ascii 16)
  }
)

(define-data-var history-index uint u0)

;; Events
(define-public (print-event (event-type (string-ascii 12)) (hash (buff 32)))
  (ok (print { event-type: event-type, hash: hash, caller: tx-sender }))
)

;; Storage functions
(define-public (store-document (hash (buff 32)) (name (string-ascii 64)) (mime-type (string-ascii 64)))
  (begin
    (asserts! (> (len hash) u0) err-invalid-input)
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len mime-type) u0) err-invalid-input)
    
    (let ((doc-exists (get-document-info hash)))
      (if (is-ok doc-exists)
        err-already-exists
        (begin
          (try! (map-set documents
            { hash: hash }
            {
              owner: tx-sender,
              name: name,
              mime-type: mime-type,
              timestamp: block-height,
              status: "active"
            }
          ))
          (try! (add-history-entry hash tx-sender "created"))
          (try! (print-event "store" hash))
          (ok true)
        )
      )
    )
  )
)

;; Verification functions
(define-read-only (verify-document (hash (buff 32)))
  (match (map-get? documents {hash: hash})
    doc (ok doc)
    err-not-found
  )
)

;; History tracking
(define-read-only (get-document-history (hash (buff 32)))
  (ok (map-get? document-history {hash: hash, index: u0}))
)

;; Ownership management
(define-public (transfer-ownership (hash (buff 32)) (new-owner principal))
  (let ((doc (unwrap! (get-document-info hash) err-not-found)))
    (asserts! (is-eq (get owner doc) tx-sender) err-unauthorized)
    (begin
      (try! (map-set documents
        { hash: hash }
        (merge doc { owner: new-owner })
      ))
      (try! (add-history-entry hash new-owner "transferred"))
      (try! (print-event "transfer" hash))
      (ok true)
    )
  )
)

;; Document status management
(define-public (set-document-status (hash (buff 32)) (new-status (string-ascii 16)))
  (let ((doc (unwrap! (get-document-info hash) err-not-found)))
    (asserts! (is-eq (get owner doc) tx-sender) err-unauthorized)
    (begin
      (try! (map-set documents
        { hash: hash }
        (merge doc { status: new-status })
      ))
      (try! (add-history-entry hash tx-sender new-status))
      (try! (print-event "status" hash))
      (ok true)
    )
  )
)

;; Helper functions
(define-private (get-document-info (hash (buff 32)))
  (ok (unwrap! (map-get? documents {hash: hash}) err-not-found))
)

(define-private (add-history-entry (hash (buff 32)) (owner principal) (action (string-ascii 16)))
  (let ((current-index (var-get history-index)))
    (begin
      (try! (map-set document-history
        { hash: hash, index: current-index }
        {
          owner: owner,
          timestamp: block-height,
          action: action
        }
      ))
      (var-set history-index (+ current-index u1))
      (ok true)
    )
  )
)
