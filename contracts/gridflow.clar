;; GridFlow: Decentralized Energy Distribution Network

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-insufficient-capacity (err u102))
(define-constant err-producer-not-found (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-self-trading (err u105))

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
    (asserts! (> price-per-unit u0) err-invalid-price)
    (asserts! (> capacity u0) err-invalid-amount)
    (map-set producers tx-sender
      {
        capacity: capacity,
        available: capacity,
        price-per-unit: price-per-unit
      }
    )
    (print {event: "producer-registered", producer: tx-sender, capacity: capacity})
    (ok true)
  )
)

(define-public (deregister-producer)
  (begin
    (asserts! (is-some (map-get? producers tx-sender)) err-producer-not-found)
    (map-delete producers tx-sender)
    (print {event: "producer-deregistered", producer: tx-sender})
    (ok true)
  )
)

(define-public (list-energy (amount uint) (price-per-unit uint))
  (let ((producer-data (unwrap! (map-get? producers tx-sender) err-producer-not-found)))
    (asserts! (and
      (<= amount (get capacity producer-data))
      (> amount u0)
      (> price-per-unit u0)) err-invalid-amount)
    (begin
      (map-set producers tx-sender
        {
          capacity: (get capacity producer-data),
          available: amount,
          price-per-unit: price-per-unit
        }
      )
      (print {event: "energy-listed", producer: tx-sender, amount: amount})
      (ok true)
    )
  )
)

(define-public (purchase-energy (amount uint) (producer principal))
  (let (
    (producer-data (unwrap! (map-get? producers producer) err-producer-not-found))
    (total-cost (* amount (get price-per-unit producer-data)))
    (trade-id (var-get trade-nonce))
  )
    (asserts! (not (is-eq tx-sender producer)) err-self-trading)
    (asserts! (<= amount (get available producer-data)) err-insufficient-capacity)
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
      (print {event: "energy-purchased", trade-id: trade-id, buyer: tx-sender, seller: producer})
      (ok trade-id)
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

(define-read-only (get-trade-count)
  (ok (var-get trade-nonce))
)
