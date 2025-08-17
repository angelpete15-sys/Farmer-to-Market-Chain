(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_FARMER_NOT_FOUND (err u101))
(define-constant ERR_PRODUCT_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u105))
(define-constant ERR_MARKET_NOT_FOUND (err u106))
(define-constant ERR_INVALID_QUANTITY (err u107))

(define-data-var product-id-nonce uint u0)
(define-data-var batch-id-nonce uint u0)
(define-data-var transaction-id-nonce uint u0)

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
    (list 10
        {
        reviewer: principal,
        rating: uint,
        comment: (string-ascii 100),
    })
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
