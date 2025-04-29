;; StackMint Token - A fungible token implementation in Clarity (ERC-20 style)
;; Project: StackMint

;; Define token constants
(define-constant token-admin tx-sender)
(define-constant token-full-name "StackMint Token")
(define-constant token-ticker "SMT")
(define-constant token-precision u6) ;; 6 decimal places
(define-constant token-initial-supply u1000000000000) ;; 1 million SMT with 6 decimals

;; Error constants
(define-constant error-unauthorized (err u100))
(define-constant error-balance-too-low (err u101))
(define-constant error-allowance-exceeded (err u102))
(define-constant error-invalid-recipient (err u103))
(define-constant error-tokens-locked (err u104))
(define-constant error-invalid-lock-period (err u105))

;; Data storage maps
(define-data-var circulating-supply uint token-initial-supply)
(define-map token-balances principal uint)
(define-map spending-approvals (tuple (token-owner principal) (authorized-spender principal)) uint)
(define-map token-locks (tuple (account principal) (lock-id uint)) (tuple (amount uint) (unlock-height uint)))

;; Initialize the contract and allocate all tokens to the contract owner
(begin
  (map-set token-balances token-admin token-initial-supply)
  (print {event: "token-initialized", total-supply: token-initial-supply, owner: token-admin})
)

;; Read-only functions

(define-read-only (get-name)
  token-full-name
)

(define-read-only (get-symbol)
  token-ticker
)

(define-read-only (get-decimals)
  token-precision
)

(define-read-only (get-total-supply)
  (var-get circulating-supply)
)

(define-read-only (get-balance (account-holder principal))
  (default-to u0 (map-get? token-balances account-holder))
)

(define-read-only (get-lock-info (account-holder principal) (lock-id uint))
  (map-get? token-locks {account: account-holder, lock-id: lock-id})
)

(define-read-only (get-locked-amount (account-holder principal))
  (fold + 
    (map get-lock-amount 
      (filter is-valid-lock 
        (map unwrap-lock 
          (get-account-locks account-holder))))
    u0)
)

(define-read-only (get-account-locks (account-holder principal))
  (map-get? token-locks {account: account-holder, lock-id: u0})
)

(define-read-only (get-lock-amount (lock (tuple (amount uint) (unlock-height uint))))
  (get amount lock)
)

(define-read-only (is-valid-lock (lock (tuple (amount uint) (unlock-height uint))))
  (< block-height (get unlock-height lock))
)

(define-read-only (unwrap-lock (lock (optional (tuple (amount uint) (unlock-height uint)))))
  (default-to {amount: u0, unlock-height: u0} lock)
)

(define-read-only (get-available-balance (account-holder principal))
  (- (get-balance account-holder) (get-locked-amount account-holder))
)

(define-read-only (get-allowance (token-owner principal) (authorized-spender principal))
  (default-to u0 (map-get? spending-approvals {token-owner: token-owner, authorized-spender: authorized-spender}))
)

;; Public functions

(define-public (transfer (recipient principal) (transfer-amount uint))
  (let (
    (sender-current-balance (get-balance tx-sender))
    (sender-available-balance (get-available-balance tx-sender))
  )
    (asserts! (>= sender-current-balance transfer-amount) error-balance-too-low)
    (asserts! (>= sender-available-balance transfer-amount) error-tokens-locked)
    (map-set token-balances tx-sender (- sender-current-balance transfer-amount))
    (map-set token-balances recipient (+ (get-balance recipient) transfer-amount))
    (print {event: "transfer", from: tx-sender, to: recipient, amount: transfer-amount})
    (ok true)
  )
)

(define-public (transfer-from (source-account principal) (destination-account principal) (transfer-amount uint))
  (let (
    (approved-amount (get-allowance source-account tx-sender))
    (source-current-balance (get-balance source-account))
    (source-available-balance (get-available-balance source-account))
  )
    (asserts! (>= approved-amount transfer-amount) error-allowance-exceeded)
    (asserts! (>= source-current-balance transfer-amount) error-balance-too-low)
    (asserts! (>= source-available-balance transfer-amount) error-tokens-locked)
    (map-set spending-approvals {token-owner: source-account, authorized-spender: tx-sender} (- approved-amount transfer-amount))
    (map-set token-balances source-account (- source-current-balance transfer-amount))
    (map-set token-balances destination-account (+ (get-balance destination-account) transfer-amount))
    (print {event: "transfer", from: source-account, to: destination-account, amount: transfer-amount})
    (ok true)
  )
)

(define-public (approve (authorized-spender principal) (approval-amount uint))
  (map-set spending-approvals {token-owner: tx-sender, authorized-spender: authorized-spender} approval-amount)
  (print {event: "approve", owner: tx-sender, spender: authorized-spender, amount: approval-amount})
  (ok true)
)

(define-public (mint (recipient principal) (mint-amount uint))
  (begin
    (asserts! (is-eq tx-sender token-admin) error-unauthorized)
    (var-set circulating-supply (+ (var-get circulating-supply) mint-amount))
    (map-set token-balances recipient (+ (get-balance recipient) mint-amount))
    (print {event: "mint", to: recipient, amount: mint-amount})
    (ok true)
  )
)

(define-public (burn (target-account principal) (burn-amount uint))
  (let (
    (target-current-balance (get-balance target-account))
    (target-available-balance (get-available-balance target-account))
  )
    (asserts! (is-eq tx-sender token-admin) error-unauthorized)
    (asserts! (>= target-current-balance burn-amount) error-balance-too-low)
    (asserts! (>= target-available-balance burn-amount) error-tokens-locked)
    (var-set circulating-supply (- (var-get circulating-supply) burn-amount))
    (map-set token-balances target-account (- target-current-balance burn-amount))
    (print {event: "burn", from: target-account, amount: burn-amount})
    (ok true)
  )
)

(define-public (lock-tokens (lock-amount uint) (lock-blocks uint) (lock-id uint))
  (let (
    (account-balance (get-balance tx-sender))
    (unlock-at (+ block-height lock-blocks))
  )
    (asserts! (>= account-balance lock-amount) error-balance-too-low)
    (asserts! (> lock-blocks u0) error-invalid-lock-period)
    (map-set token-locks 
      {account: tx-sender, lock-id: lock-id} 
      {amount: lock-amount, unlock-height: unlock-at})
    (print {
      event: "token-lock", 
      account: tx-sender, 
      amount: lock-amount, 
      unlock-at: unlock-at,
      lock-id: lock-id
    })
    (ok true)
  )
)

(define-public (unlock-tokens (lock-id uint))
  (let (
    (lock-info (unwrap! (get-lock-info tx-sender lock-id) error-invalid-recipient))
    (unlock-height (get unlock-height lock-info))
  )
    (asserts! (>= block-height unlock-height) error-tokens-locked)
    (map-delete token-locks {account: tx-sender, lock-id: lock-id})
    (print {
      event: "token-unlock", 
      account: tx-sender,
      lock-id: lock-id,
      amount: (get amount lock-info)
    })
    (ok true)
  )
)
