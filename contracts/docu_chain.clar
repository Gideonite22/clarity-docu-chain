;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))

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

;; Storage functions
(define-public (store-document (hash (buff 32)) (name (string-ascii 64)) (mime-type (string-ascii 64)))
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
        (try! (map-set document-history
          { hash: hash, index: u0 }
          {
            owner: tx-sender,
            timestamp: block-height,
            action: "created"
          }
        ))
        (ok true)
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
    (if (is-eq (get owner doc) tx-sender)
      (begin
        (try! (map-set documents
          { hash: hash }
          (merge doc { owner: new-owner })
        ))
        (try! (map-set document-history
          { hash: hash, index: u1 }
          {
            owner: new-owner,
            timestamp: block-height,
            action: "transferred"
          }
        ))
        (ok true)
      )
      err-unauthorized
    )
  )
)

;; Helper functions
(define-private (get-document-info (hash (buff 32)))
  (ok (unwrap! (map-get? documents {hash: hash}) err-not-found))
)
