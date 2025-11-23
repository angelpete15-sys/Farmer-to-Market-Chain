(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_FARMER_NOT_FOUND (err u101))
(define-constant ERR_PRODUCT_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u105))
(define-constant ERR_MARKET_NOT_FOUND (err u106))
(define-constant ERR_INVALID_QUANTITY (err u107))
(define-constant ERR_INSURANCE_NOT_FOUND (err u108))
(define-constant ERR_POLICY_EXPIRED (err u109))
(define-constant ERR_CLAIM_ALREADY_EXISTS (err u110))
(define-constant ERR_INVALID_CLAIM_TYPE (err u111))
(define-constant ERR_INSUFFICIENT_PREMIUM (err u112))
(define-constant ERR_CLAIM_PERIOD_EXPIRED (err u113))
(define-constant ERR_INVALID_PREMIUM_RATE (err u114))
(define-constant ERR_ESCROW_NOT_FOUND (err u120))
(define-constant ERR_ESCROW_FORBIDDEN (err u121))
(define-constant ERR_ESCROW_NOT_DEPOSITED (err u122))
(define-constant ERR_ESCROW_ALREADY_FUNDED (err u123))
(define-constant ERR_ESCROW_ALREADY_CLOSED (err u124))
(define-constant ERR_ESCROW_DEADLINE_PASSED (err u125))

(define-data-var product-id-nonce uint u0)
(define-data-var batch-id-nonce uint u0)
(define-data-var transaction-id-nonce uint u0)
(define-data-var insurance-policy-nonce uint u0)
(define-data-var claim-id-nonce uint u0)

(define-map farmers
    principal
    {
        name: (string-ascii 50),
        location: (string-ascii 100),
        certification: (string-ascii 50),
        registered-at: uint,
        is-active: bool,
    }
)

(define-map markets
    principal
    {
        name: (string-ascii 50),
        location: (string-ascii 100),
        market-type: (string-ascii 30),
        registered-at: uint,
        is-active: bool,
    }
)

(define-map products
    uint
    {
        farmer: principal,
        name: (string-ascii 50),
        category: (string-ascii 30),
        quantity: uint,
        unit: (string-ascii 20),
        harvest-date: uint,
        expiry-date: uint,
        price-per-unit: uint,
        quality-grade: (string-ascii 10),
        organic-certified: bool,
        created-at: uint,
        status: (string-ascii 20),
    }
)

(define-map product-batches
    uint
    {
        product-id: uint,
        batch-number: (string-ascii 30),
        quantity: uint,
        current-owner: principal,
        origin-farmer: principal,
        processing-date: (optional uint),
        quality-tests: (list 5 (string-ascii 50)),
        temperature-log: (list 10 uint),
        location-history: (list 10 (string-ascii 100)),
        status: (string-ascii 20),
        created-at: uint,
    }
)

(define-map transactions
    uint
    {
        batch-id: uint,
        from-owner: principal,
        to-owner: principal,
        quantity: uint,
        price-total: uint,
        transaction-date: uint,
        delivery-date: (optional uint),
        quality-check: bool,
        notes: (string-ascii 200),
    }
)

(define-map farmer-certifications
    principal
    (list 5 (string-ascii 50))
)
(define-map market-ratings
    principal
    {
        average-rating: uint,
        total-reviews: uint,
    }
)
(define-map product-reviews
    uint
    (list
        10
        {
            reviewer: principal,
            rating: uint,
            comment: (string-ascii 100),
        }
    )
)

(define-map insurance-policies
    uint
    {
        policy-holder: principal,
        batch-id: uint,
        coverage-amount: uint,
        premium-paid: uint,
        policy-start: uint,
        policy-end: uint,
        coverage-type: (string-ascii 30),
        premium-rate: uint,
        is-active: bool,
    }
)

(define-map insurance-claims
    uint
    {
        policy-id: uint,
        claimant: principal,
        claim-type: (string-ascii 30),
        claim-amount: uint,
        evidence: (string-ascii 200),
        filed-at: uint,
        status: (string-ascii 20),
        payout-amount: uint,
        processed-at: (optional uint),
    }
)

(define-map insurance-pool
    (string-ascii 30)
    {
        total-deposits: uint,
        total-claims-paid: uint,
        active-policies: uint,
        base-premium-rate: uint,
    }
)

(define-public (register-farmer
        (name (string-ascii 50))
        (location (string-ascii 100))
        (certification (string-ascii 50))
    )
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? farmers caller)) ERR_ALREADY_EXISTS)
        (map-set farmers caller {
            name: name,
            location: location,
            certification: certification,
            registered-at: stacks-block-height,
            is-active: true,
        })
        (ok true)
    )
)

(define-public (register-market
        (name (string-ascii 50))
        (location (string-ascii 100))
        (market-type (string-ascii 30))
    )
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? markets caller)) ERR_ALREADY_EXISTS)
        (map-set markets caller {
            name: name,
            location: location,
            market-type: market-type,
            registered-at: stacks-block-height,
            is-active: true,
        })
        (ok true)
    )
)

(define-public (add-product
        (name (string-ascii 50))
        (category (string-ascii 30))
        (quantity uint)
        (unit (string-ascii 20))
        (harvest-date uint)
        (expiry-date uint)
        (price-per-unit uint)
        (quality-grade (string-ascii 10))
        (organic-certified bool)
    )
    (let (
            (caller tx-sender)
            (new-product-id (+ (var-get product-id-nonce) u1))
        )
        (asserts! (is-some (map-get? farmers caller)) ERR_FARMER_NOT_FOUND)
        (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
        (map-set products new-product-id {
            farmer: caller,
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            harvest-date: harvest-date,
            expiry-date: expiry-date,
            price-per-unit: price-per-unit,
            quality-grade: quality-grade,
            organic-certified: organic-certified,
            created-at: stacks-block-height,
            status: "available",
        })
        (var-set product-id-nonce new-product-id)
        (ok new-product-id)
    )
)

(define-public (create-batch
        (product-id uint)
        (batch-number (string-ascii 30))
        (quantity uint)
    )
    (let (
            (caller tx-sender)
            (product (unwrap! (map-get? products product-id) ERR_PRODUCT_NOT_FOUND))
            (new-batch-id (+ (var-get batch-id-nonce) u1))
        )
        (asserts! (is-eq (get farmer product) caller) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status product) "available") ERR_INVALID_STATUS)
        (asserts! (<= quantity (get quantity product)) ERR_INVALID_QUANTITY)
        (map-set product-batches new-batch-id {
            product-id: product-id,
            batch-number: batch-number,
            quantity: quantity,
            current-owner: caller,
            origin-farmer: caller,
            processing-date: none,
            quality-tests: (list),
            temperature-log: (list),
            location-history: (list (get location
                (unwrap! (map-get? farmers caller) ERR_FARMER_NOT_FOUND)
            )),
            status: "harvested",
            created-at: stacks-block-height,
        })
        (var-set batch-id-nonce new-batch-id)
        (ok new-batch-id)
    )
)

(define-public (transfer-batch
        (batch-id uint)
        (new-owner principal)
        (price-total uint)
        (delivery-date (optional uint))
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts!
            (or (is-some (map-get? farmers new-owner)) (is-some (map-get? markets new-owner)))
            ERR_NOT_AUTHORIZED
        )
        (try! (stx-transfer? price-total new-owner caller))
        (map-set product-batches batch-id
            (merge batch {
                current-owner: new-owner,
                status: "in-transit",
            })
        )
        (let ((new-transaction-id (+ (var-get transaction-id-nonce) u1)))
            (map-set transactions new-transaction-id {
                batch-id: batch-id,
                from-owner: caller,
                to-owner: new-owner,
                quantity: (get quantity batch),
                price-total: price-total,
                transaction-date: stacks-block-height,
                delivery-date: delivery-date,
                quality-check: false,
                notes: "",
            })
            (var-set transaction-id-nonce new-transaction-id)
        )
        (ok true)
    )
)

(define-public (update-batch-status
        (batch-id uint)
        (new-status (string-ascii 20))
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (map-set product-batches batch-id (merge batch { status: new-status }))
        (ok true)
    )
)

(define-public (add-quality-test
        (batch-id uint)
        (test-result (string-ascii 50))
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (current-tests (get quality-tests batch))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts! (< (len current-tests) u5) ERR_INVALID_STATUS)
        (map-set product-batches batch-id
            (merge batch { quality-tests: (unwrap! (as-max-len? (append current-tests test-result) u5)
                ERR_INVALID_STATUS
            ) }
            ))
        (ok true)
    )
)

(define-public (add-temperature-reading
        (batch-id uint)
        (temperature uint)
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (current-temps (get temperature-log batch))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts! (< (len current-temps) u10) ERR_INVALID_STATUS)
        (map-set product-batches batch-id
            (merge batch { temperature-log: (unwrap! (as-max-len? (append current-temps temperature) u10)
                ERR_INVALID_STATUS
            ) }
            ))
        (ok true)
    )
)

(define-public (update-location
        (batch-id uint)
        (new-location (string-ascii 100))
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (current-locations (get location-history batch))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts! (< (len current-locations) u10) ERR_INVALID_STATUS)
        (map-set product-batches batch-id
            (merge batch { location-history: (unwrap! (as-max-len? (append current-locations new-location) u10)
                ERR_INVALID_STATUS
            ) }
            ))
        (ok true)
    )
)

(define-public (confirm-delivery
        (batch-id uint)
        (quality-passed bool)
        (notes (string-ascii 200))
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status batch) "in-transit") ERR_INVALID_STATUS)
        (map-set product-batches batch-id
            (merge batch { status: (if quality-passed
                "delivered"
                "rejected"
            ) }
            ))
        (ok true)
    )
)

(define-public (set-processing-date (batch-id uint))
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (map-set product-batches batch-id
            (merge batch { processing-date: (some stacks-block-height) })
        )
        (ok true)
    )
)

(define-public (add-farmer-certification (certification (string-ascii 50)))
    (let (
            (caller tx-sender)
            (current-certs (default-to (list) (map-get? farmer-certifications caller)))
        )
        (asserts! (is-some (map-get? farmers caller)) ERR_FARMER_NOT_FOUND)
        (asserts! (< (len current-certs) u5) ERR_INVALID_STATUS)
        (map-set farmer-certifications caller
            (unwrap! (as-max-len? (append current-certs certification) u5)
                ERR_INVALID_STATUS
            ))
        (ok true)
    )
)

(define-public (rate-market
        (market principal)
        (rating uint)
        (comment (string-ascii 100))
    )
    (let (
            (caller tx-sender)
            (current-rating (default-to {
                average-rating: u0,
                total-reviews: u0,
            }
                (map-get? market-ratings market)
            ))
            (new-total (+ (get total-reviews current-rating) u1))
            (new-average (/
                (+
                    (* (get average-rating current-rating)
                        (get total-reviews current-rating)
                    )
                    rating
                )
                new-total
            ))
        )
        (asserts! (is-some (map-get? markets market)) ERR_MARKET_NOT_FOUND)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_STATUS)
        (map-set market-ratings market {
            average-rating: new-average,
            total-reviews: new-total,
        })
        (ok true)
    )
)

(define-public (add-product-review
        (product-id uint)
        (rating uint)
        (comment (string-ascii 100))
    )
    (let (
            (caller tx-sender)
            (current-reviews (default-to (list) (map-get? product-reviews product-id)))
            (new-review {
                reviewer: caller,
                rating: rating,
                comment: comment,
            })
        )
        (asserts! (is-some (map-get? products product-id)) ERR_PRODUCT_NOT_FOUND)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_STATUS)
        (asserts! (< (len current-reviews) u10) ERR_INVALID_STATUS)
        (map-set product-reviews product-id
            (unwrap! (as-max-len? (append current-reviews new-review) u10)
                ERR_INVALID_STATUS
            ))
        (ok true)
    )
)

(define-public (deactivate-farmer (farmer principal))
    (let (
            (caller tx-sender)
            (farmer-data (unwrap! (map-get? farmers farmer) ERR_FARMER_NOT_FOUND))
        )
        (asserts! (is-eq caller CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map-set farmers farmer (merge farmer-data { is-active: false }))
        (ok true)
    )
)

(define-public (deactivate-market (market principal))
    (let (
            (caller tx-sender)
            (market-data (unwrap! (map-get? markets market) ERR_MARKET_NOT_FOUND))
        )
        (asserts! (is-eq caller CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map-set markets market (merge market-data { is-active: false }))
        (ok true)
    )
)

(define-public (emergency-pause-product (product-id uint))
    (let (
            (caller tx-sender)
            (product (unwrap! (map-get? products product-id) ERR_PRODUCT_NOT_FOUND))
        )
        (asserts! (is-eq caller CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map-set products product-id (merge product { status: "paused" }))
        (ok true)
    )
)

(define-public (create-insurance-policy
        (batch-id uint)
        (coverage-amount uint)
        (coverage-type (string-ascii 30))
        (policy-duration uint)
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (product (unwrap! (map-get? products (get product-id batch))
                ERR_PRODUCT_NOT_FOUND
            ))
            (new-policy-id (+ (var-get insurance-policy-nonce) u1))
            (base-rate (get-coverage-base-rate coverage-type))
            (risk-multiplier (calculate-risk-multiplier product batch))
            (premium-amount (/ (* (* coverage-amount base-rate) risk-multiplier) u10000))
            (policy-start stacks-block-height)
            (policy-end (+ policy-start policy-duration))
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts! (> coverage-amount u0) ERR_INVALID_QUANTITY)
        (asserts! (> policy-duration u0) ERR_INVALID_STATUS)
        (asserts! (>= base-rate u1) ERR_INVALID_PREMIUM_RATE)
        (try! (stx-transfer? premium-amount caller (as-contract tx-sender)))
        (map-set insurance-policies new-policy-id {
            policy-holder: caller,
            batch-id: batch-id,
            coverage-amount: coverage-amount,
            premium-paid: premium-amount,
            policy-start: policy-start,
            policy-end: policy-end,
            coverage-type: coverage-type,
            premium-rate: base-rate,
            is-active: true,
        })
        (update-insurance-pool coverage-type premium-amount u0 true)
        (var-set insurance-policy-nonce new-policy-id)
        (ok new-policy-id)
    )
)

(define-public (file-insurance-claim
        (policy-id uint)
        (claim-type (string-ascii 30))
        (claim-amount uint)
        (evidence (string-ascii 200))
    )
    (let (
            (caller tx-sender)
            (policy (unwrap! (map-get? insurance-policies policy-id)
                ERR_INSURANCE_NOT_FOUND
            ))
            (new-claim-id (+ (var-get claim-id-nonce) u1))
            (current-block stacks-block-height)
        )
        (asserts! (is-eq (get policy-holder policy) caller) ERR_NOT_AUTHORIZED)
        (asserts! (get is-active policy) ERR_POLICY_EXPIRED)
        (asserts! (< current-block (get policy-end policy)) ERR_POLICY_EXPIRED)
        (asserts! (<= claim-amount (get coverage-amount policy))
            ERR_INVALID_QUANTITY
        )
        (asserts! (> claim-amount u0) ERR_INVALID_QUANTITY)
        (asserts!
            (or
                (is-eq claim-type "crop-failure")
                (or
                    (is-eq claim-type "quality-dispute")
                    (or
                        (is-eq claim-type "delivery-failure")
                        (is-eq claim-type "weather-damage")
                    )
                )
            )
            ERR_INVALID_CLAIM_TYPE
        )
        (map-set insurance-claims new-claim-id {
            policy-id: policy-id,
            claimant: caller,
            claim-type: claim-type,
            claim-amount: claim-amount,
            evidence: evidence,
            filed-at: current-block,
            status: "pending",
            payout-amount: u0,
            processed-at: none,
        })
        (var-set claim-id-nonce new-claim-id)
        (ok new-claim-id)
    )
)

(define-public (process-insurance-claim
        (claim-id uint)
        (approved bool)
        (payout-amount uint)
    )
    (let (
            (caller tx-sender)
            (claim (unwrap! (map-get? insurance-claims claim-id) ERR_INSURANCE_NOT_FOUND))
            (policy (unwrap! (map-get? insurance-policies (get policy-id claim))
                ERR_INSURANCE_NOT_FOUND
            ))
            (current-block stacks-block-height)
            (final-payout (if approved
                payout-amount
                u0
            ))
        )
        (asserts! (is-eq caller CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status claim) "pending") ERR_INVALID_STATUS)
        (asserts! (<= payout-amount (get claim-amount claim))
            ERR_INVALID_QUANTITY
        )
        (asserts! (<= payout-amount (get coverage-amount policy))
            ERR_INVALID_QUANTITY
        )
        (if approved
            (try! (as-contract (stx-transfer? final-payout tx-sender (get claimant claim))))
            true
        )
        (map-set insurance-claims claim-id
            (merge claim {
                status: (if approved
                    "approved"
                    "denied"
                ),
                payout-amount: final-payout,
                processed-at: (some current-block),
            })
        )
        (if approved
            (update-insurance-pool (get coverage-type policy) u0 final-payout
                false
            )
            true
        )
        (ok true)
    )
)

(define-read-only (get-farmer (farmer principal))
    (map-get? farmers farmer)
)

(define-read-only (get-market (market principal))
    (map-get? markets market)
)

(define-read-only (get-product (product-id uint))
    (map-get? products product-id)
)

(define-read-only (get-batch (batch-id uint))
    (map-get? product-batches batch-id)
)

(define-read-only (get-farmer-certifications (farmer principal))
    (map-get? farmer-certifications farmer)
)

(define-read-only (get-market-rating (market principal))
    (map-get? market-ratings market)
)

(define-read-only (get-product-reviews (product-id uint))
    (map-get? product-reviews product-id)
)

(define-read-only (get-transaction (transaction-id uint))
    (map-get? transactions transaction-id)
)

(define-read-only (get-current-product-id)
    (var-get product-id-nonce)
)

(define-read-only (get-current-batch-id)
    (var-get batch-id-nonce)
)

(define-read-only (is-farmer-active (farmer principal))
    (match (map-get? farmers farmer)
        farmer-data (get is-active farmer-data)
        false
    )
)

(define-read-only (is-market-active (market principal))
    (match (map-get? markets market)
        market-data (get is-active market-data)
        false
    )
)

(define-read-only (get-batch-owner (batch-id uint))
    (match (map-get? product-batches batch-id)
        batch-data (some (get current-owner batch-data))
        none
    )
)

(define-read-only (get-product-farmer (product-id uint))
    (match (map-get? products product-id)
        product-data (some (get farmer product-data))
        none
    )
)

(define-read-only (calculate-total-price
        (batch-id uint)
        (quantity uint)
    )
    (let (
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (product (unwrap! (map-get? products (get product-id batch))
                ERR_PRODUCT_NOT_FOUND
            ))
        )
        (ok (* (get price-per-unit product) quantity))
    )
)

(define-read-only (get-batch-trace (batch-id uint))
    (let (
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (product (unwrap! (map-get? products (get product-id batch))
                ERR_PRODUCT_NOT_FOUND
            ))
            (farmer-info (unwrap! (map-get? farmers (get origin-farmer batch))
                ERR_FARMER_NOT_FOUND
            ))
        )
        (ok {
            batch-id: batch-id,
            product-name: (get name product),
            origin-farmer: (get name farmer-info),
            farmer-location: (get location farmer-info),
            harvest-date: (get harvest-date product),
            current-owner: (get current-owner batch),
            status: (get status batch),
            location-history: (get location-history batch),
            quality-tests: (get quality-tests batch),
            temperature-log: (get temperature-log batch),
        })
    )
)

(define-read-only (verify-organic-certification (product-id uint))
    (match (map-get? products product-id)
        product-data (ok (get organic-certified product-data))
        ERR_PRODUCT_NOT_FOUND
    )
)

(define-read-only (check-expiry-status (product-id uint))
    (let (
            (product (unwrap! (map-get? products product-id) ERR_PRODUCT_NOT_FOUND))
            (current-block stacks-block-height)
        )
        (ok (< current-block (get expiry-date product)))
    )
)

(define-read-only (get-farmer-products (farmer principal))
    (ok farmer)
)

(define-read-only (get-market-purchases (market principal))
    (ok market)
)

(define-private (get-coverage-base-rate (coverage-type (string-ascii 30)))
    (if (is-eq coverage-type "crop-failure")
        u500
        (if (is-eq coverage-type "quality-dispute")
            u300
            (if (is-eq coverage-type "delivery-failure")
                u200
                (if (is-eq coverage-type "weather-damage")
                    u400
                    u250
                )
            )
        )
    )
)

(define-read-only (get-insurance-policy (policy-id uint))
    (map-get? insurance-policies policy-id)
)

(define-read-only (get-insurance-claim (claim-id uint))
    (map-get? insurance-claims claim-id)
)

(define-read-only (get-insurance-pool-stats (coverage-type (string-ascii 30)))
    (map-get? insurance-pool coverage-type)
)

(define-read-only (calculate-premium-quote
        (batch-id uint)
        (coverage-amount uint)
        (coverage-type (string-ascii 30))
    )
    (let (
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (product (unwrap! (map-get? products (get product-id batch))
                ERR_PRODUCT_NOT_FOUND
            ))
            (base-rate (get-coverage-base-rate coverage-type))
            (risk-multiplier (calculate-risk-multiplier product batch))
        )
        (ok (/ (* (* coverage-amount base-rate) risk-multiplier) u10000))
    )
)

(define-read-only (is-policy-active (policy-id uint))
    (match (map-get? insurance-policies policy-id)
        policy-data (and
            (get is-active policy-data)
            (< stacks-block-height (get policy-end policy-data))
        )
        false
    )
)

(define-read-only (get-policy-coverage-remaining (policy-id uint))
    (match (map-get? insurance-policies policy-id)
        policy-data (if (is-policy-active policy-id)
            (some (get coverage-amount policy-data))
            none
        )
        none
    )
)

(define-read-only (get-current-insurance-policy-id)
    (var-get insurance-policy-nonce)
)

(define-read-only (get-current-claim-id)
    (var-get claim-id-nonce)
)

(define-private (calculate-risk-multiplier
        (product {
            farmer: principal,
            name: (string-ascii 50),
            category: (string-ascii 30),
            quantity: uint,
            unit: (string-ascii 20),
            harvest-date: uint,
            expiry-date: uint,
            price-per-unit: uint,
            quality-grade: (string-ascii 10),
            organic-certified: bool,
            created-at: uint,
            status: (string-ascii 20),
        })
        (batch {
            product-id: uint,
            batch-number: (string-ascii 30),
            quantity: uint,
            current-owner: principal,
            origin-farmer: principal,
            processing-date: (optional uint),
            quality-tests: (list 5 (string-ascii 50)),
            temperature-log: (list 10 uint),
            location-history: (list 10 (string-ascii 100)),
            status: (string-ascii 20),
            created-at: uint,
        })
    )
    (let (
            (base-multiplier u100)
            (quality-bonus (if (is-eq (get quality-grade product) "A")
                u90
                u100
            ))
            (organic-bonus (if (get organic-certified product)
                u95
                u100
            ))
            (freshness-factor (if (> (get expiry-date product) (+ stacks-block-height u1000))
                u95
                u110
            ))
        )
        (/
            (* (* base-multiplier quality-bonus)
                (* organic-bonus freshness-factor)
            )
            u1000000
        )
    )
)

(define-private (update-insurance-pool
        (coverage-type (string-ascii 30))
        (premium-deposit uint)
        (claim-payout uint)
        (new-policy bool)
    )
    (let (
            (current-pool (default-to {
                total-deposits: u0,
                total-claims-paid: u0,
                active-policies: u0,
                base-premium-rate: (get-coverage-base-rate coverage-type),
            }
                (map-get? insurance-pool coverage-type)
            ))
            (new-deposits (+ (get total-deposits current-pool) premium-deposit))
            (new-claims (+ (get total-claims-paid current-pool) claim-payout))
            (new-count (if new-policy
                (+ (get active-policies current-pool) u1)
                (get active-policies current-pool)
            ))
        )
        (map-set insurance-pool coverage-type {
            total-deposits: new-deposits,
            total-claims-paid: new-claims,
            active-policies: new-count,
            base-premium-rate: (get base-premium-rate current-pool),
        })
    )
)

(define-map batch-recalls
    uint
    {
        batch-id: uint,
        recalled-by: principal,
        reason: (string-ascii 100),
        recalled-at: uint,
        active: bool,
    }
)

(define-public (recall-batch
        (batch-id uint)
        (reason (string-ascii 100))
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (existing (map-get? batch-recalls batch-id))
        )
        (asserts!
            (or (is-eq (get current-owner batch) caller) (is-eq caller CONTRACT_OWNER))
            ERR_NOT_AUTHORIZED
        )
        (match existing
            rec (begin
                (asserts! (not (get active rec)) ERR_INVALID_STATUS)
                (map-set batch-recalls batch-id
                    (merge rec {
                        reason: reason,
                        recalled-by: caller,
                        recalled-at: stacks-block-height,
                        active: true,
                    })
                )
            )
            (map-set batch-recalls batch-id {
                batch-id: batch-id,
                recalled-by: caller,
                reason: reason,
                recalled-at: stacks-block-height,
                active: true,
            })
        )
        (map-set product-batches batch-id (merge batch { status: "recalled" }))
        (ok true)
    )
)

(define-public (resolve-recall (batch-id uint))
    (let (
            (caller tx-sender)
            (rec (unwrap! (map-get? batch-recalls batch-id) ERR_PRODUCT_NOT_FOUND))
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
        )
        (asserts!
            (or (is-eq caller CONTRACT_OWNER) (is-eq (get current-owner batch) caller))
            ERR_NOT_AUTHORIZED
        )
        (map-set batch-recalls batch-id (merge rec { active: false }))
        (ok true)
    )
)

(define-read-only (get-batch-recall (batch-id uint))
    (map-get? batch-recalls batch-id)
)

(define-read-only (is-batch-recalled (batch-id uint))
    (match (map-get? batch-recalls batch-id)
        rec (get active rec)
        false
    )
)

(define-data-var escrow-id-nonce uint u0)

(define-map escrows
    uint
    {
        batch-id: uint,
        seller: principal,
        buyer: principal,
        price: uint,
        deadline: uint,
        deposited: bool,
        released: bool,
        cancelled: bool,
    }
)

(define-public (create-escrow-sale
        (batch-id uint)
        (buyer principal)
        (price uint)
        (deadline uint)
    )
    (let (
            (caller tx-sender)
            (batch (unwrap! (map-get? product-batches batch-id) ERR_PRODUCT_NOT_FOUND))
            (new-escrow-id (+ (var-get escrow-id-nonce) u1))
            (current-block stacks-block-height)
        )
        (asserts! (is-eq (get current-owner batch) caller) ERR_NOT_AUTHORIZED)
        (asserts! (> price u0) ERR_INVALID_QUANTITY)
        (asserts! (>= deadline current-block) ERR_INVALID_STATUS)
        (asserts! (not (is-batch-recalled batch-id)) ERR_INVALID_STATUS)
        (map-set escrows new-escrow-id {
            batch-id: batch-id,
            seller: caller,
            buyer: buyer,
            price: price,
            deadline: deadline,
            deposited: false,
            released: false,
            cancelled: false,
        })
        (var-set escrow-id-nonce new-escrow-id)
        (ok new-escrow-id)
    )
)

(define-public (deposit-escrow (escrow-id uint))
    (let (
            (caller tx-sender)
            (escrow (unwrap! (map-get? escrows escrow-id) ERR_ESCROW_NOT_FOUND))
            (current-block stacks-block-height)
        )
        (asserts! (is-eq caller (get buyer escrow)) ERR_ESCROW_FORBIDDEN)
        (asserts! (not (get cancelled escrow)) ERR_ESCROW_ALREADY_CLOSED)
        (asserts! (not (get released escrow)) ERR_ESCROW_ALREADY_CLOSED)
        (asserts! (not (get deposited escrow)) ERR_ESCROW_ALREADY_FUNDED)
        (asserts! (<= current-block (get deadline escrow))
            ERR_ESCROW_DEADLINE_PASSED
        )
        (try! (stx-transfer? (get price escrow) caller (as-contract tx-sender)))
        (map-set escrows escrow-id (merge escrow { deposited: true }))
        (ok true)
    )
)

(define-public (release-escrow-payment (escrow-id uint))
    (let (
            (caller tx-sender)
            (escrow (unwrap! (map-get? escrows escrow-id) ERR_ESCROW_NOT_FOUND))
            (current-block stacks-block-height)
        )
        (asserts! (is-eq caller (get buyer escrow)) ERR_ESCROW_FORBIDDEN)
        (asserts! (get deposited escrow) ERR_ESCROW_NOT_DEPOSITED)
        (asserts! (not (get cancelled escrow)) ERR_ESCROW_ALREADY_CLOSED)
        (asserts! (not (get released escrow)) ERR_ESCROW_ALREADY_CLOSED)
        (asserts! (<= current-block (get deadline escrow))
            ERR_ESCROW_DEADLINE_PASSED
        )
        (try! (as-contract (stx-transfer? (get price escrow) tx-sender (get seller escrow))))
        (map-set escrows escrow-id (merge escrow { released: true }))
        (ok true)
    )
)

(define-public (cancel-escrow (escrow-id uint))
    (let (
            (caller tx-sender)
            (escrow (unwrap! (map-get? escrows escrow-id) ERR_ESCROW_NOT_FOUND))
            (current-block stacks-block-height)
        )
        (asserts!
            (or (is-eq caller (get buyer escrow)) (is-eq caller (get seller escrow)))
            ERR_ESCROW_FORBIDDEN
        )
        (asserts! (not (get cancelled escrow)) ERR_ESCROW_ALREADY_CLOSED)
        (asserts! (not (get released escrow)) ERR_ESCROW_ALREADY_CLOSED)
        (asserts! (> current-block (get deadline escrow))
            ERR_ESCROW_DEADLINE_PASSED
        )
        (if (get deposited escrow)
            (try! (as-contract (stx-transfer? (get price escrow) tx-sender (get buyer escrow))))
            true
        )
        (map-set escrows escrow-id (merge escrow { cancelled: true }))
        (ok true)
    )
)

(define-read-only (get-escrow (escrow-id uint))
    (map-get? escrows escrow-id)
)

(define-read-only (get-current-escrow-id)
    (var-get escrow-id-nonce)
)
