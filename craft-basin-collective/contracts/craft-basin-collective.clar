;; CraftBasin - Decentralized Creator Patronage Platform
;; Tokenized content access with automated royalty cascades and IP protection

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-params (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-transfer-failed (err u106))
(define-constant err-not-for-sale (err u107))
(define-constant err-invalid-tier (err u108))
(define-constant err-content-locked (err u109))

;; Access tier levels
(define-constant TIER-BASIC u1)
(define-constant TIER-PREMIUM u2)
(define-constant TIER-EXCLUSIVE u3)
(define-constant TIER-LIFETIME u4)

;; Content categories
(define-constant CATEGORY-MUSIC u1)
(define-constant CATEGORY-ART u2)
(define-constant CATEGORY-WRITING u3)
(define-constant CATEGORY-EDUCATION u4)
(define-constant CATEGORY-VIDEO u5)

;; Data Variables
(define-data-var content-nonce uint u0)
(define-data-var access-nft-nonce uint u0)
(define-data-var total-creators uint u0)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee
(define-data-var min-royalty-percentage uint u5) ;; 5% minimum royalty
(define-data-var max-royalty-percentage uint u50) ;; 50% maximum royalty

;; Creator profiles
(define-map creators
    { creator: principal }
    {
        registered-at: uint,
        total-content: uint,
        total-revenue: uint,
        reputation-score: uint,
        verified: bool,
        is-active: bool
    }
)

;; Content vault - stores encrypted content metadata
(define-map content-vaults
    { content-id: uint }
    {
        creator: principal,
        title: (string-utf8 256),
        description: (string-utf8 1024),
        category: uint,
        ipfs-hash: (string-ascii 64),
        encrypted-key-hash: (buff 32),
        timestamp: uint,
        total-access-nfts: uint,
        is-active: bool
    }
)

;; Tiered access pricing
(define-map content-tiers
    { content-id: uint, tier-level: uint }
    {
        price: uint,
        max-supply: uint,
        current-supply: uint,
        duration-blocks: uint,
        benefits: (string-utf8 256),
        is-available: bool
    }
)

;; Access NFTs - tokenized content access rights
(define-map access-nfts
    { nft-id: uint }
    {
        content-id: uint,
        owner: principal,
        tier-level: uint,
        purchased-at: uint,
        expires-at: uint,
        original-price: uint,
        resale-price: uint,
        is-for-sale: bool,
        is-active: bool
    }
)

;; Creator royalty settings
(define-map royalty-settings
    { content-id: uint }
    {
        primary-royalty: uint,
        secondary-royalty: uint,
        cascade-enabled: bool,
        max-cascade-depth: uint
    }
)

;; Revenue tracking
(define-map creator-revenue
    { creator: principal, content-id: uint }
    {
        primary-sales: uint,
        secondary-sales: uint,
        total-earned: uint,
        withdrawable: uint
    }
)

;; Patron (supporter) records
(define-map patrons
    { patron: principal }
    {
        joined-at: uint,
        total-spent: uint,
        active-subscriptions: uint,
        owned-nfts: uint
    }
)

;; Content access log
(define-map access-grants
    { patron: principal, content-id: uint }
    {
        nft-id: uint,
        granted-at: uint,
        tier-level: uint,
        access-count: uint,
        last-accessed: uint
    }
)

;; Royalty cascade tracking
(define-map royalty-cascade
    { nft-id: uint, cascade-level: uint }
    {
        beneficiary: principal,
        percentage: uint,
        total-earned: uint
    }
)

;; IP protection timestamps
(define-map ip-timestamps
    { content-id: uint }
    {
        creator: principal,
        content-hash: (buff 32),
        timestamp: uint,
        block-height: uint,
        verified: bool
    }
)

;; Revenue splits for collaborations
(define-map revenue-splits
    { content-id: uint, collaborator: principal }
    {
        split-percentage: uint,
        total-earned: uint,
        withdrawable: uint
    }
)

;; Read-only functions
(define-read-only (get-creator-profile (creator principal))
    (map-get? creators { creator: creator })
)

(define-read-only (get-content-vault (content-id uint))
    (map-get? content-vaults { content-id: content-id })
)

(define-read-only (get-content-tier (content-id uint) (tier-level uint))
    (map-get? content-tiers { content-id: content-id, tier-level: tier-level })
)

(define-read-only (get-access-nft (nft-id uint))
    (map-get? access-nfts { nft-id: nft-id })
)

(define-read-only (get-royalty-settings (content-id uint))
    (map-get? royalty-settings { content-id: content-id })
)

(define-read-only (get-creator-revenue (creator principal) (content-id uint))
    (map-get? creator-revenue { creator: creator, content-id: content-id })
)

(define-read-only (get-patron-profile (patron principal))
    (map-get? patrons { patron: patron })
)

(define-read-only (get-access-grant (patron principal) (content-id uint))
    (map-get? access-grants { patron: patron, content-id: content-id })
)

(define-read-only (get-ip-timestamp (content-id uint))
    (map-get? ip-timestamps { content-id: content-id })
)

(define-read-only (has-valid-access (patron principal) (content-id uint))
    (match (map-get? access-grants { patron: patron, content-id: content-id })
        grant (let
            (
                (nft (unwrap! (get-access-nft (get nft-id grant)) false))
            )
            (and 
                (get is-active nft)
                (or 
                    (is-eq (get expires-at nft) u0)
                    (< block-height (get expires-at nft))
                )
            )
        )
        false
    )
)

(define-read-only (get-total-creators)
    (ok (var-get total-creators))
)

;; Creator registration and management
(define-public (register-creator)
    (let
        (
            (existing (map-get? creators { creator: tx-sender }))
        )
        (asserts! (is-none existing) err-already-exists)
        
        (map-set creators
            { creator: tx-sender }
            {
                registered-at: block-height,
                total-content: u0,
                total-revenue: u0,
                reputation-score: u100,
                verified: false,
                is-active: true
            }
        )
        
        (var-set total-creators (+ (var-get total-creators) u1))
        (ok true)
    )
)

(define-public (verify-creator (creator principal))
    (let
        (
            (profile (unwrap! (get-creator-profile creator) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (ok (map-set creators
            { creator: creator }
            (merge profile { verified: true })
        ))
    )
)

;; Content vault creation
(define-public (create-content-vault
    (title (string-utf8 256))
    (description (string-utf8 1024))
    (category uint)
    (ipfs-hash (string-ascii 64))
    (encrypted-key-hash (buff 32)))
    (let
        (
            (content-id (+ (var-get content-nonce) u1))
            (creator-profile (unwrap! (get-creator-profile tx-sender) err-unauthorized))
        )
        (asserts! (get is-active creator-profile) err-unauthorized)
        (asserts! (<= category CATEGORY-VIDEO) err-invalid-params)
        
        ;; Create content vault
        (map-set content-vaults
            { content-id: content-id }
            {
                creator: tx-sender,
                title: title,
                description: description,
                category: category,
                ipfs-hash: ipfs-hash,
                encrypted-key-hash: encrypted-key-hash,
                timestamp: block-height,
                total-access-nfts: u0,
                is-active: true
            }
        )
        
        ;; Create IP timestamp
        (map-set ip-timestamps
            { content-id: content-id }
            {
                creator: tx-sender,
                content-hash: encrypted-key-hash,
                timestamp: block-height,
                block-height: block-height,
                verified: true
            }
        )
        
        ;; Initialize royalty settings
        (map-set royalty-settings
            { content-id: content-id }
            {
                primary-royalty: u10,
                secondary-royalty: u10,
                cascade-enabled: true,
                max-cascade-depth: u5
            }
        )
        
        ;; Initialize revenue tracking
        (map-set creator-revenue
            { creator: tx-sender, content-id: content-id }
            {
                primary-sales: u0,
                secondary-sales: u0,
                total-earned: u0,
                withdrawable: u0
            }
        )
        
        ;; Update creator profile
        (map-set creators
            { creator: tx-sender }
            (merge creator-profile { total-content: (+ (get total-content creator-profile) u1) })
        )
        
        (var-set content-nonce content-id)
        (ok content-id)
    )
)

;; Set tiered access pricing
(define-public (set-content-tier
    (content-id uint)
    (tier-level uint)
    (price uint)
    (max-supply uint)
    (duration-blocks uint)
    (benefits (string-utf8 256)))
    (let
        (
            (content (unwrap! (get-content-vault content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (and (>= tier-level TIER-BASIC) (<= tier-level TIER-LIFETIME)) err-invalid-tier)
        (asserts! (> price u0) err-invalid-params)
        
        (ok (map-set content-tiers
            { content-id: content-id, tier-level: tier-level }
            {
                price: price,
                max-supply: max-supply,
                current-supply: u0,
                duration-blocks: duration-blocks,
                benefits: benefits,
                is-available: true
            }
        ))
    )
)

;; Purchase access NFT
(define-public (purchase-access-nft (content-id uint) (tier-level uint))
    (let
        (
            (content (unwrap! (get-content-vault content-id) err-not-found))
            (tier (unwrap! (get-content-tier content-id tier-level) err-not-found))
            (nft-id (+ (var-get access-nft-nonce) u1))
            (creator (get creator content))
            (price (get price tier))
            (platform-fee (/ (* price (var-get platform-fee-percentage)) u100))
            (creator-payment (- price platform-fee))
            (expires-at (if (> (get duration-blocks tier) u0)
                (+ block-height (get duration-blocks tier))
                u0))
        )
        (asserts! (get is-available tier) err-not-for-sale)
        (asserts! (or (is-eq (get max-supply tier) u0) 
            (< (get current-supply tier) (get max-supply tier))) 
            err-invalid-params)
        
        ;; Transfer payment
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        
        ;; Create access NFT
        (map-set access-nfts
            { nft-id: nft-id }
            {
                content-id: content-id,
                owner: tx-sender,
                tier-level: tier-level,
                purchased-at: block-height,
                expires-at: expires-at,
                original-price: price,
                resale-price: u0,
                is-for-sale: false,
                is-active: true
            }
        )
        
        ;; Update tier supply
        (map-set content-tiers
            { content-id: content-id, tier-level: tier-level }
            (merge tier { current-supply: (+ (get current-supply tier) u1) })
        )
        
        ;; Grant access
        (map-set access-grants
            { patron: tx-sender, content-id: content-id }
            {
                nft-id: nft-id,
                granted-at: block-height,
                tier-level: tier-level,
                access-count: u0,
                last-accessed: block-height
            }
        )
        
        ;; Update patron profile
        (match (map-get? patrons { patron: tx-sender })
            existing-patron (map-set patrons
                { patron: tx-sender }
                (merge existing-patron {
                    total-spent: (+ (get total-spent existing-patron) price),
                    active-subscriptions: (+ (get active-subscriptions existing-patron) u1),
                    owned-nfts: (+ (get owned-nfts existing-patron) u1)
                }))
            (map-set patrons
                { patron: tx-sender }
                {
                    joined-at: block-height,
                    total-spent: price,
                    active-subscriptions: u1,
                    owned-nfts: u1
                })
        )
        
        ;; Update creator revenue
        (let
            (
                (revenue (unwrap! (get-creator-revenue creator content-id) err-not-found))
            )
            (map-set creator-revenue
                { creator: creator, content-id: content-id }
                (merge revenue {
                    primary-sales: (+ (get primary-sales revenue) price),
                    total-earned: (+ (get total-earned revenue) creator-payment),
                    withdrawable: (+ (get withdrawable revenue) creator-payment)
                })
            )
        )
        
        ;; Transfer platform fee
        (try! (as-contract (stx-transfer? platform-fee tx-sender contract-owner)))
        
        ;; Initialize first cascade level
        (map-set royalty-cascade
            { nft-id: nft-id, cascade-level: u0 }
            {
                beneficiary: tx-sender,
                percentage: u100,
                total-earned: u0
            }
        )
        
        (var-set access-nft-nonce nft-id)
        (ok nft-id)
    )
)

;; List access NFT for resale
(define-public (list-nft-for-resale (nft-id uint) (resale-price uint))
    (let
        (
            (nft (unwrap! (get-access-nft nft-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner nft)) err-unauthorized)
        (asserts! (get is-active nft) err-not-for-sale)
        (asserts! (> resale-price u0) err-invalid-params)
        
        (ok (map-set access-nfts
            { nft-id: nft-id }
            (merge nft {
                resale-price: resale-price,
                is-for-sale: true
            })
        ))
    )
)

;; Purchase resale NFT with royalty cascade
(define-public (purchase-resale-nft (nft-id uint))
    (let
        (
            (nft (unwrap! (get-access-nft nft-id) err-not-found))
            (content (unwrap! (get-content-vault (get content-id nft)) err-not-found))
            (royalty-config (unwrap! (get-royalty-settings (get content-id nft)) err-not-found))
            (seller (get owner nft))
            (price (get resale-price nft))
            (platform-fee (/ (* price (var-get platform-fee-percentage)) u100))
            (royalty-amount (/ (* price (get secondary-royalty royalty-config)) u100))
            (seller-payment (- (- price platform-fee) royalty-amount))
        )
        (asserts! (get is-for-sale nft) err-not-for-sale)
        (asserts! (not (is-eq tx-sender seller)) err-unauthorized)
        
        ;; Transfer payment from buyer
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        
        ;; Pay seller
        (try! (as-contract (stx-transfer? seller-payment tx-sender seller)))
        
        ;; Pay royalty to creator
        (try! (as-contract (stx-transfer? royalty-amount tx-sender (get creator content))))
        
        ;; Pay platform fee
        (try! (as-contract (stx-transfer? platform-fee tx-sender contract-owner)))
        
        ;; Update creator revenue
        (let
            (
                (revenue (unwrap! (get-creator-revenue (get creator content) (get content-id nft)) err-not-found))
            )
            (map-set creator-revenue
                { creator: (get creator content), content-id: (get content-id nft) }
                (merge revenue {
                    secondary-sales: (+ (get secondary-sales revenue) royalty-amount),
                    total-earned: (+ (get total-earned revenue) royalty-amount),
                    withdrawable: (+ (get withdrawable revenue) royalty-amount)
                })
            )
        )
        
        ;; Update NFT ownership
        (map-set access-nfts
            { nft-id: nft-id }
            (merge nft {
                owner: tx-sender,
                is-for-sale: false,
                resale-price: u0
            })
        )
        
        ;; Update access grant
        (map-set access-grants
            { patron: tx-sender, content-id: (get content-id nft) }
            {
                nft-id: nft-id,
                granted-at: block-height,
                tier-level: (get tier-level nft),
                access-count: u0,
                last-accessed: block-height
            }
        )
        
        ;; Update cascade level
        (let
            (
                (previous-cascade (map-get? royalty-cascade { nft-id: nft-id, cascade-level: u0 }))
                (cascade-depth (if (is-some previous-cascade) u1 u0))
            )
            (map-set royalty-cascade
                { nft-id: nft-id, cascade-level: cascade-depth }
                {
                    beneficiary: tx-sender,
                    percentage: (- u100 (get secondary-royalty royalty-config)),
                    total-earned: u0
                }
            )
        )
        
        (ok true)
    )
)

;; Access content
(define-public (access-content (content-id uint))
    (let
        (
            (has-access (has-valid-access tx-sender content-id))
            (grant (unwrap! (get-access-grant tx-sender content-id) err-unauthorized))
        )
        (asserts! has-access err-unauthorized)
        
        ;; Update access log
        (ok (map-set access-grants
            { patron: tx-sender, content-id: content-id }
            (merge grant {
                access-count: (+ (get access-count grant) u1),
                last-accessed: block-height
            })
        ))
    )
)

;; Set royalty configuration
(define-public (set-royalty-config
    (content-id uint)
    (primary-royalty uint)
    (secondary-royalty uint)
    (cascade-enabled bool))
    (let
        (
            (content (unwrap! (get-content-vault content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (and 
            (>= primary-royalty (var-get min-royalty-percentage))
            (<= primary-royalty (var-get max-royalty-percentage)))
            err-invalid-params)
        (asserts! (and 
            (>= secondary-royalty (var-get min-royalty-percentage))
            (<= secondary-royalty (var-get max-royalty-percentage)))
            err-invalid-params)
        
        (ok (map-set royalty-settings
            { content-id: content-id }
            {
                primary-royalty: primary-royalty,
                secondary-royalty: secondary-royalty,
                cascade-enabled: cascade-enabled,
                max-cascade-depth: u5
            }
        ))
    )
)

;; Add revenue split collaborator
(define-public (add-revenue-split
    (content-id uint)
    (collaborator principal)
    (split-percentage uint))
    (let
        (
            (content (unwrap! (get-content-vault content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (and (> split-percentage u0) (<= split-percentage u100)) err-invalid-params)
        
        (ok (map-set revenue-splits
            { content-id: content-id, collaborator: collaborator }
            {
                split-percentage: split-percentage,
                total-earned: u0,
                withdrawable: u0
            }
        ))
    )
)

;; Withdraw creator revenue
(define-public (withdraw-revenue (content-id uint))
    (let
        (
            (revenue (unwrap! (get-creator-revenue tx-sender content-id) err-not-found))
            (amount (get withdrawable revenue))
        )
        (asserts! (> amount u0) err-invalid-params)
        
        ;; Transfer funds to creator
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        
        ;; Update revenue record
        (ok (map-set creator-revenue
            { creator: tx-sender, content-id: content-id }
            (merge revenue { withdrawable: u0 })
        ))
    )
)

;; Withdraw collaborator split
(define-public (withdraw-collaborator-split (content-id uint))
    (let
        (
            (split (unwrap! (map-get? revenue-splits 
                { content-id: content-id, collaborator: tx-sender }) 
                err-not-found))
            (amount (get withdrawable split))
        )
        (asserts! (> amount u0) err-invalid-params)
        
        ;; Transfer funds
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        
        ;; Update split record
        (ok (map-set revenue-splits
            { content-id: content-id, collaborator: tx-sender }
            (merge split { withdrawable: u0 })
        ))
    )
)

;; Cancel NFT listing
(define-public (cancel-nft-listing (nft-id uint))
    (let
        (
            (nft (unwrap! (get-access-nft nft-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner nft)) err-unauthorized)
        
        (ok (map-set access-nfts
            { nft-id: nft-id }
            (merge nft {
                is-for-sale: false,
                resale-price: u0
            })
        ))
    )
)

;; Deactivate content
(define-public (deactivate-content (content-id uint))
    (let
        (
            (content (unwrap! (get-content-vault content-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        
        (ok (map-set content-vaults
            { content-id: content-id }
            (merge content { is-active: false })
        ))
    )
)

;; Administrative functions
(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u15) err-invalid-params) ;; Max 15%
        (ok (var-set platform-fee-percentage new-fee))
    )
)

(define-public (update-creator-reputation (creator principal) (new-score uint))
    (let
        (
            (profile (unwrap! (get-creator-profile creator) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-score u100) err-invalid-params)
        
        (ok (map-set creators
            { creator: creator }
            (merge profile { reputation-score: new-score })
        ))
    )
)

(define-public (emergency-pause-creator (creator principal))
    (let
        (
            (profile (unwrap! (get-creator-profile creator) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (ok (map-set creators
            { creator: creator }
            (merge profile { is-active: false })
        ))
    )
)