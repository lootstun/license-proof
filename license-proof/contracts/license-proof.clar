;; License-Proof: Professional License Verification Contract
;; Self-sovereign identity verification on Stacks blockchain

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_LICENSE_EXISTS (err u101))
(define-constant ERR_LICENSE_NOT_FOUND (err u102))
(define-constant ERR_INVALID_EXPIRY (err u103))
(define-constant ERR_LICENSE_EXPIRED (err u104))
(define-constant ERR_ALREADY_REVOKED (err u105))

;; Data structures
(define-map licenses
  { license-id: (string-ascii 64) }
  {
    holder: principal,
    license-type: (string-ascii 32),
    issuing-authority: (string-ascii 64),
    issue-date: uint,
    expiry-date: uint,
    license-number: (string-ascii 32),
    status: (string-ascii 16), ;; "active", "expired", "revoked"
    verification-hash: (string-ascii 64)
  }
)

;; Map to track licenses by holder
(define-map holder-licenses
  { holder: principal }
  { license-count: uint, license-ids: (list 10 (string-ascii 64)) }
)

;; Map for authorized verifiers (institutions that can verify licenses)
(define-map authorized-verifiers
  { verifier: principal }
  { authorized: bool, verifier-name: (string-ascii 64) }
)

;; Data var for license counter
(define-data-var license-counter uint u0)

;; Public functions

;; Register a new professional license
(define-public (register-license 
  (license-type (string-ascii 32))
  (issuing-authority (string-ascii 64))
  (expiry-date uint)
  (license-number (string-ascii 32))
  (verification-hash (string-ascii 64)))
  (let 
    (
      (license-id (generate-license-id))
      (current-block-height block-height)
    )
    ;; Validate expiry date
    (asserts! (> expiry-date current-block-height) ERR_INVALID_EXPIRY)
    
    ;; Check if license already exists
    (asserts! (is-none (map-get? licenses { license-id: license-id })) ERR_LICENSE_EXISTS)
    
    ;; Create license record
    (map-set licenses
      { license-id: license-id }
      {
        holder: tx-sender,
        license-type: license-type,
        issuing-authority: issuing-authority,
        issue-date: current-block-height,
        expiry-date: expiry-date,
        license-number: license-number,
        status: "active",
        verification-hash: verification-hash
      }
    )
    
    ;; Update holder's license list
    (update-holder-licenses tx-sender license-id)
    
    ;; Increment counter
    (var-set license-counter (+ (var-get license-counter) u1))
    
    (ok license-id)
  )
)

;; Verify a license by ID
(define-read-only (verify-license (license-id (string-ascii 64)))
  (match (map-get? licenses { license-id: license-id })
    license-data 
    (if (is-license-valid license-data)
      (ok {
        holder: (get holder license-data),
        license-type: (get license-type license-data),
        issuing-authority: (get issuing-authority license-data),
        issue-date: (get issue-date license-data),
        expiry-date: (get expiry-date license-data),
        license-number: (get license-number license-data),
        status: (get status license-data),
        is-valid: true
      })
      (ok {
        holder: (get holder license-data),
        license-type: (get license-type license-data),
        issuing-authority: (get issuing-authority license-data),
        issue-date: (get issue-date license-data),
        expiry-date: (get expiry-date license-data),
        license-number: (get license-number license-data),
        status: (get status license-data),
        is-valid: false
      })
    )
    ERR_LICENSE_NOT_FOUND
  )
)

;; Get all licenses for a holder
(define-read-only (get-holder-licenses (holder principal))
  (match (map-get? holder-licenses { holder: holder })
    holder-data (ok holder-data)
    (ok { license-count: u0, license-ids: (list) })
  )
)

;; Revoke a license (only license holder can revoke their own license)
(define-public (revoke-license (license-id (string-ascii 64)))
  (match (map-get? licenses { license-id: license-id })
    license-data
    (begin
      ;; Check if caller is the license holder
      (asserts! (is-eq tx-sender (get holder license-data)) ERR_UNAUTHORIZED)
      
      ;; Check if already revoked
      (asserts! (not (is-eq (get status license-data) "revoked")) ERR_ALREADY_REVOKED)
      
      ;; Update license status
      (map-set licenses
        { license-id: license-id }
        (merge license-data { status: "revoked" })
      )
      
      (ok true)
    )
    ERR_LICENSE_NOT_FOUND
  )
)

;; Update license status (for expired licenses)
(define-public (update-license-status (license-id (string-ascii 64)))
  (match (map-get? licenses { license-id: license-id })
    license-data
    (let
      (
        (current-block-height block-height)
        (new-status 
          (if (> current-block-height (get expiry-date license-data))
            "expired"
            (get status license-data)
          )
        )
      )
      (map-set licenses
        { license-id: license-id }
        (merge license-data { status: new-status })
      )
      (ok new-status)
    )
    ERR_LICENSE_NOT_FOUND
  )
)

;; Authorize a verifier (only contract owner)
(define-public (authorize-verifier (verifier principal) (verifier-name (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-verifiers
      { verifier: verifier }
      { authorized: true, verifier-name: verifier-name }
    )
    (ok true)
  )
)

;; Check if a verifier is authorized
(define-read-only (is-authorized-verifier (verifier principal))
  (match (map-get? authorized-verifiers { verifier: verifier })
    verifier-data (get authorized verifier-data)
    false
  )
)

;; Private functions

;; Generate unique license ID (max 64 chars)
(define-private (generate-license-id)
  (concat "LIC" (int-to-ascii (var-get license-counter)))
)

;; Update holder's license list
(define-private (update-holder-licenses (holder principal) (license-id (string-ascii 64)))
  (match (map-get? holder-licenses { holder: holder })
    existing-data
    (let
      (
        (current-count (get license-count existing-data))
        (current-list (get license-ids existing-data))
        (new-list (unwrap-panic (as-max-len? (append current-list license-id) u10)))
      )
      (map-set holder-licenses
        { holder: holder }
        { 
          license-count: (+ current-count u1),
          license-ids: new-list
        }
      )
    )
    ;; First license for this holder
    (map-set holder-licenses
      { holder: holder }
      { 
        license-count: u1,
        license-ids: (list license-id)
      }
    )
  )
)

;; Check if license is valid (not expired and not revoked)
(define-private (is-license-valid (license-data {holder: principal, license-type: (string-ascii 32), issuing-authority: (string-ascii 64), issue-date: uint, expiry-date: uint, license-number: (string-ascii 32), status: (string-ascii 16), verification-hash: (string-ascii 64)}))
  (and
    (> (get expiry-date license-data) block-height)
    (is-eq (get status license-data) "active")
  )
)

;; Read-only functions for getting contract stats
(define-read-only (get-total-licenses)
  (var-get license-counter)
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)