;; TrendPulse Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-trend-not-found (err u101))
(define-constant err-already-voted (err u102))

;; Data Variables
(define-data-var total-trends uint u0)

;; Data Maps
(define-map trends uint {
  title: (string-ascii 50),
  category: (string-ascii 20),
  creator: principal,
  timestamp: uint,
  votes: uint
})

(define-map user-votes {user: principal, trend-id: uint} bool)

;; Public Functions
(define-public (submit-trend (title (string-ascii 50)) (category (string-ascii 20)))
  (let
    ((trend-id (var-get total-trends)))
    (try! (map-insert trends trend-id {
      title: title,
      category: category,
      creator: tx-sender,
      timestamp: block-height,
      votes: u0
    }))
    (var-set total-trends (+ trend-id u1))
    (ok trend-id)))

(define-public (vote-trend (trend-id uint))
  (let
    ((vote-key {user: tx-sender, trend-id: trend-id}))
    (asserts! (is-none (map-get? user-votes vote-key)) err-already-voted)
    (match (map-get? trends trend-id)
      trend (begin
        (try! (map-set trends trend-id 
          (merge trend {votes: (+ (get votes trend) u1)})))
        (map-insert user-votes vote-key true)
        (ok true))
      err-trend-not-found)))

;; Read Only Functions
(define-read-only (get-trend (trend-id uint))
  (ok (map-get? trends trend-id)))

(define-read-only (get-total-trends)
  (ok (var-get total-trends)))
