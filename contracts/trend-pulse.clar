;; TrendPulse Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-trend-not-found (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-invalid-title (err u103))
(define-constant err-invalid-category (err u104))
(define-constant err-trend-expired (err u105))

;; Data Variables
(define-data-var total-trends uint u0)
(define-data-var contract-paused bool false)

;; Configuration
(define-constant max-trend-lifetime u144) ;; ~1 day in blocks
(define-constant max-trends-per-user u5)

;; Data Maps
(define-map trends uint {
  title: (string-ascii 50),
  category: (string-ascii 20),
  creator: principal,
  timestamp: uint,
  votes: uint,
  expires-at: uint
})

(define-map user-votes {user: principal, trend-id: uint} bool)
(define-map user-trend-count principal uint)
(define-map category-trends (string-ascii 20) (list 50 uint))

;; Events
(define-data-var last-event-id uint u0)

(define-map events uint {
  event-type: (string-ascii 20),
  trend-id: uint,
  user: principal,
  timestamp: uint
})

;; Private Functions
(define-private (is-trend-active (trend-id uint))
  (match (map-get? trends trend-id)
    trend (< block-height (get expires-at trend))
    false))

(define-private (validate-trend-input (title (string-ascii 50)) (category (string-ascii 20)))
  (and
    (> (len title) u0)
    (>= u50 (len title))
    (> (len category) u0)
    (>= u20 (len category))))

(define-private (emit-event (event-type (string-ascii 20)) (trend-id uint))
  (let ((event-id (var-get last-event-id)))
    (map-set events event-id {
      event-type: event-type,
      trend-id: trend-id,
      user: tx-sender,
      timestamp: block-height
    })
    (var-set last-event-id (+ event-id u1))))

;; Public Functions
(define-public (submit-trend (title (string-ascii 50)) (category (string-ascii 20)))
  (let
    ((trend-id (var-get total-trends))
     (user-trends (default-to u0 (map-get? user-trend-count tx-sender))))
    
    ;; Input validation
    (asserts! (not (var-get contract-paused)) (err u106))
    (asserts! (validate-trend-input title category) err-invalid-title)
    (asserts! (<= user-trends max-trends-per-user) (err u107))
    
    (try! (map-insert trends trend-id {
      title: title,
      category: category,
      creator: tx-sender,
      timestamp: block-height,
      votes: u0,
      expires-at: (+ block-height max-trend-lifetime)
    }))
    
    (map-set user-trend-count tx-sender (+ user-trends u1))
    (var-set total-trends (+ trend-id u1))
    (emit-event "trend-submitted" trend-id)
    
    ;; Reward the submission
    (contract-call? .trend-rewards reward-submission tx-sender)
    (ok trend-id)))

(define-public (vote-trend (trend-id uint))
  (let
    ((vote-key {user: tx-sender, trend-id: trend-id}))
    (asserts! (not (var-get contract-paused)) (err u106))
    (asserts! (is-trend-active trend-id) err-trend-expired)
    (asserts! (is-none (map-get? user-votes vote-key)) err-already-voted)
    
    (match (map-get? trends trend-id)
      trend (begin
        (try! (map-set trends trend-id 
          (merge trend {votes: (+ (get votes trend) u1)})))
        (map-insert user-votes vote-key true)
        (emit-event "trend-voted" trend-id)
        (contract-call? .trend-rewards reward-vote tx-sender)
        (ok true))
      err-trend-not-found)))

;; Admin Functions
(define-public (set-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (ok (var-set contract-paused paused))))

;; Read Only Functions
(define-read-only (get-trend (trend-id uint))
  (ok (map-get? trends trend-id)))

(define-read-only (get-total-trends)
  (ok (var-get total-trends)))

(define-read-only (is-paused)
  (ok (var-get contract-paused)))

(define-read-only (get-trends-by-category (category (string-ascii 20)) (limit uint))
  (let ((all-trends (var-get total-trends)))
    (filter is-trend-active 
      (list-trends-helper all-trends (- all-trends u1) limit category))))

(define-private (list-trends-helper (total uint) (current uint) (limit uint) (category (string-ascii 20)))
  (if (or (is-eq current u0) (is-eq limit u0))
    (list current)
    (match (map-get? trends current)
      trend (if (is-eq (get category trend) category)
             (concat (list current) 
                    (list-trends-helper total (- current u1) (- limit u1) category))
             (list-trends-helper total (- current u1) limit category))
      (list-trends-helper total (- current u1) limit category))))
