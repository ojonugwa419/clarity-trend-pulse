;; TrendPulse Rewards Contract

(define-trait reward-trait
  ((reward-submission (principal) (response uint uint))
   (reward-vote (principal) (response uint uint))))

(define-fungible-token trend-points)

(define-constant contract-owner tx-sender)
(define-constant reward-per-vote u1)
(define-constant reward-per-submission u10)
(define-constant max-points-per-day u100)

(define-map daily-points {user: principal, day: uint} uint)

(define-private (get-current-day)
  (/ block-height u144))

(define-private (check-daily-limit (user principal) (amount uint))
  (let ((current-day (get-current-day))
        (current-points (default-to u0 (map-get? daily-points {user: user, day: current-day}))))
    (<= (+ current-points amount) max-points-per-day)))

(define-public (reward-submission (user principal))
  (let ((current-day (get-current-day)))
    (asserts! (check-daily-limit user reward-per-submission) (err u1))
    (try! (ft-mint? trend-points reward-per-submission user))
    (map-set daily-points {user: user, day: current-day}
      (+ (default-to u0 (map-get? daily-points {user: user, day: current-day}))
         reward-per-submission))
    (ok reward-per-submission)))

(define-public (reward-vote (user principal))
  (let ((current-day (get-current-day)))
    (asserts! (check-daily-limit user reward-per-vote) (err u1))
    (try! (ft-mint? trend-points reward-per-vote user))
    (map-set daily-points {user: user, day: current-day}
      (+ (default-to u0 (map-get? daily-points {user: user, day: current-day}))
         reward-per-vote))
    (ok reward-per-vote)))

(define-read-only (get-points-balance (user principal))
  (ok (ft-get-balance trend-points user)))

(define-read-only (get-daily-points (user principal))
  (ok (default-to u0 (map-get? daily-points {user: user, day: (get-current-day)}))))
