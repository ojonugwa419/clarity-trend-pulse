;; TrendPulse Rewards Contract

(define-fungible-token trend-points)

(define-constant reward-per-vote u1)
(define-constant reward-per-submission u10)

(define-public (reward-submission (user principal))
  (ft-mint? trend-points reward-per-submission user))

(define-public (reward-vote (user principal))
  (ft-mint? trend-points reward-per-vote user))

(define-read-only (get-points-balance (user principal))
  (ok (ft-get-balance trend-points user)))
