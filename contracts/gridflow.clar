;; GridFlow: Decentralized Energy Distribution Network

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-insufficient-capacity (err u102))

;; Data variables
(define-map producers principal 
  {
    capacity: uint,
    available: uint,
    price-per-unit: uint
  }
)

(define-map energy-trades uint
  {
    seller: principal,
    buyer: principal,
    amount: uint,
    price: uint,
    status: (string-ascii 20)
  }
)

(define-data-var trade-nonce uint u0)

;; Public functions
(define-public (register-producer (capacity uint) (price-per-unit uint))
  (begin
    (map-set producers tx-sender
      {
        capacity: capacity,
        available: capacity,
        price-per-unit: price-per-unit
      }
    )
    (ok true)
  )
)

(define-public (list-energy (amount uint) (price-per-unit uint))
  (let ((producer-data (unwrap! (map-get? producers tx-sender) (err u103))))
    (if (and
      (<= amount (get capacity producer-data))
      (> amount u0))
      (begin
        (map-set producers tx-sender
          {
            capacity: (get capacity producer-data),
            available: amount,
            price-per-unit: price-per-unit
          }
        )
        (ok true)
      )
      err-invalid-amount
    )
  )
)

(define-public (purchase-energy (amount uint) (producer principal))
  (let (
    (producer-data (unwrap! (map-get? producers producer) (err u104)))
    (total-cost (* amount (get price-per-unit producer-data)))
    (trade-id (var-get trade-nonce))
  )
    (if (<= amount (get available producer-data))
      (begin
        (try! (stx-transfer? total-cost tx-sender producer))
        (map-set energy-trades trade-id
          {
            seller: producer,
            buyer: tx-sender,
            amount: amount,
            price: total-cost,
            status: "completed"
          }
        )
        (map-set producers producer
          {
            capacity: (get capacity producer-data),
            available: (- (get available producer-data) amount),
            price-per-unit: (get price-per-unit producer-data)
          }
        )
        (var-set trade-nonce (+ trade-id u1))
        (ok trade-id)
      )
      err-insufficient-capacity
    )
  )
)

;; Read-only functions
(define-read-only (get-producer-data (producer principal))
  (ok (map-get? producers producer))
)

(define-read-only (get-trade (trade-id uint))
  (ok (map-get? energy-trades trade-id))
)
