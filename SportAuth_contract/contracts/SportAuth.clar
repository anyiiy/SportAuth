
;; title: SportAuth
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for sports equipment authenticity and performance verification
;; description: This contract enables manufacturers, retailers, and consumers to track the authenticity,
;;              ownership, and performance data of sports equipment throughout the supply chain.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_EQUIPMENT_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_OWNER (err u103))
(define-constant ERR_INVALID_STATUS (err u104))

;; Equipment status constants
(define-constant STATUS_MANUFACTURED u1)
(define-constant STATUS_QUALITY_CHECKED u2)
(define-constant STATUS_SHIPPED u3)
(define-constant STATUS_RETAIL u4)
(define-constant STATUS_SOLD u5)
(define-constant STATUS_IN_USE u6)

;; data vars
(define-data-var next-equipment-id uint u1)

;; data maps
;; Map to store equipment information
(define-map equipment-registry
  { equipment-id: uint }
  {
    manufacturer: principal,
    model: (string-ascii 100),
    serial-number: (string-ascii 50),
    manufacture-date: uint,
    status: uint,
    current-owner: principal,
    authenticity-verified: bool,
    quality-score: uint
  }
)

;; Map to track ownership history
(define-map ownership-history
  { equipment-id: uint, transfer-id: uint }
  {
    previous-owner: principal,
    new-owner: principal,
    transfer-date: uint,
    transfer-type: (string-ascii 20)
  }
)

;; Map to store performance data
(define-map performance-data
  { equipment-id: uint, test-id: uint }
  {
    test-type: (string-ascii 50),
    test-date: uint,
    performance-score: uint,
    tester: principal,
    notes: (string-ascii 200)
  }
)

;; Map to track authorized entities (manufacturers, quality checkers, retailers)
(define-map authorized-entities
  { entity: principal }
  {
    entity-type: (string-ascii 20),
    authorized-by: principal,
    authorization-date: uint,
    is-active: bool
  }
)

;; Counters for sequential IDs
(define-map transfer-counters { equipment-id: uint } { counter: uint })
(define-map test-counters { equipment-id: uint } { counter: uint })

;; public functions

;; Authorize an entity (manufacturer, quality-checker, retailer)
(define-public (authorize-entity (entity principal) (entity-type (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (ok (map-set authorized-entities
      { entity: entity }
      {
        entity-type: entity-type,
        authorized-by: tx-sender,
        authorization-date: block-height,
        is-active: true
      }
    ))
  )
)

;; Register new equipment (only authorized manufacturers)
(define-public (register-equipment
  (model (string-ascii 100))
  (serial-number (string-ascii 50))
  (manufacture-date uint))
  (let
    (
      (equipment-id (var-get next-equipment-id))
      (manufacturer tx-sender)
    )
    (asserts! (is-authorized-entity manufacturer "manufacturer") ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? equipment-registry { equipment-id: equipment-id })) ERR_ALREADY_EXISTS)

    (map-set equipment-registry
      { equipment-id: equipment-id }
      {
        manufacturer: manufacturer,
        model: model,
        serial-number: serial-number,
        manufacture-date: manufacture-date,
        status: STATUS_MANUFACTURED,
        current-owner: manufacturer,
        authenticity-verified: true,
        quality-score: u0
      }
    )

    ;; Initialize counters
    (map-set transfer-counters { equipment-id: equipment-id } { counter: u0 })
    (map-set test-counters { equipment-id: equipment-id } { counter: u0 })

    (var-set next-equipment-id (+ equipment-id u1))
    (ok equipment-id)
  )
)

;; Update equipment status
(define-public (update-equipment-status (equipment-id uint) (new-status uint))
  (let
    (
      (equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) ERR_EQUIPMENT_NOT_FOUND))
    )
    (asserts! (can-update-status tx-sender equipment-id) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= new-status u1) (<= new-status u6)) ERR_INVALID_STATUS)

    (ok (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment { status: new-status })
    ))
  )
)

;; Transfer ownership
(define-public (transfer-ownership (equipment-id uint) (new-owner principal))
  (let
    (
      (equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) ERR_EQUIPMENT_NOT_FOUND))
      (current-owner (get current-owner equipment))
      (transfer-counter (default-to u0 (get counter (map-get? transfer-counters { equipment-id: equipment-id }))))
    )
    (asserts! (is-eq tx-sender current-owner) ERR_INVALID_OWNER)

    ;; Record transfer in history
    (map-set ownership-history
      { equipment-id: equipment-id, transfer-id: transfer-counter }
      {
        previous-owner: current-owner,
        new-owner: new-owner,
        transfer-date: block-height,
        transfer-type: "ownership"
      }
    )

    ;; Update equipment owner
    (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment { current-owner: new-owner })
    )

    ;; Increment transfer counter
    (map-set transfer-counters
      { equipment-id: equipment-id }
      { counter: (+ transfer-counter u1) }
    )

    (ok true)
  )
)

;; Record performance test data
(define-public (record-performance-test
  (equipment-id uint)
  (test-type (string-ascii 50))
  (performance-score uint)
  (notes (string-ascii 200)))
  (let
    (
      (equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) ERR_EQUIPMENT_NOT_FOUND))
      (test-counter (default-to u0 (get counter (map-get? test-counters { equipment-id: equipment-id }))))
    )
    (asserts! (can-test-equipment tx-sender equipment-id) ERR_NOT_AUTHORIZED)

    (map-set performance-data
      { equipment-id: equipment-id, test-id: test-counter }
      {
        test-type: test-type,
        test-date: block-height,
        performance-score: performance-score,
        tester: tx-sender,
        notes: notes
      }
    )

    ;; Update equipment quality score (average of all tests)
    (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment { quality-score: performance-score })
    )

    ;; Increment test counter
    (map-set test-counters
      { equipment-id: equipment-id }
      { counter: (+ test-counter u1) }
    )

    (ok test-counter)
  )
)

;; Verify authenticity (only authorized quality checkers)
(define-public (verify-authenticity (equipment-id uint) (is-authentic bool))
  (let
    (
      (equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) ERR_EQUIPMENT_NOT_FOUND))
    )
    (asserts! (is-authorized-entity tx-sender "quality-checker") ERR_NOT_AUTHORIZED)

    (ok (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment { authenticity-verified: is-authentic })
    ))
  )
)

;; read only functions

;; Get equipment details
(define-read-only (get-equipment-info (equipment-id uint))
  (map-get? equipment-registry { equipment-id: equipment-id })
)

;; Get ownership history
(define-read-only (get-ownership-history (equipment-id uint) (transfer-id uint))
  (map-get? ownership-history { equipment-id: equipment-id, transfer-id: transfer-id })
)

;; Get performance test data
(define-read-only (get-performance-data (equipment-id uint) (test-id uint))
  (map-get? performance-data { equipment-id: equipment-id, test-id: test-id })
)

;; Check if entity is authorized
(define-read-only (get-entity-authorization (entity principal))
  (map-get? authorized-entities { entity: entity })
)

;; Get current equipment count
(define-read-only (get-total-equipment-count)
  (- (var-get next-equipment-id) u1)
)

;; Check equipment authenticity
(define-read-only (is-equipment-authentic (equipment-id uint))
  (match (map-get? equipment-registry { equipment-id: equipment-id })
    equipment (get authenticity-verified equipment)
    false
  )
)

;; private functions

;; Check if entity is authorized for specific type
(define-private (is-authorized-entity (entity principal) (required-type (string-ascii 20)))
  (match (map-get? authorized-entities { entity: entity })
    auth-info (and
      (is-eq (get entity-type auth-info) required-type)
      (get is-active auth-info)
    )
    false
  )
)

;; Check if sender can update equipment status
(define-private (can-update-status (sender principal) (equipment-id uint))
  (match (map-get? equipment-registry { equipment-id: equipment-id })
    equipment (or
      (is-eq sender (get manufacturer equipment))
      (is-eq sender (get current-owner equipment))
      (is-authorized-entity sender "quality-checker")
      (is-authorized-entity sender "retailer")
    )
    false
  )
)

;; Check if sender can perform performance tests
(define-private (can-test-equipment (sender principal) (equipment-id uint))
  (match (map-get? equipment-registry { equipment-id: equipment-id })
    equipment (or
      (is-eq sender (get current-owner equipment))
      (is-authorized-entity sender "quality-checker")
    )
    false
  )
)
