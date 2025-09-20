
;; title: InitiativeVote
;; version: 1.0.0
;; summary: Community-driven voting platform for citizen-proposed legislation
;; description: A decentralized voting system that allows citizens to propose and vote on policy initiatives

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INITIATIVE-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-VOTING-ENDED (err u103))
(define-constant ERR-VOTING-NOT-STARTED (err u104))
(define-constant ERR-INVALID-INITIATIVE (err u105))
(define-constant ERR-INSUFFICIENT-VOTES (err u106))
(define-constant ERR-INITIATIVE-ALREADY-EXISTS (err u107))
(define-constant ERR-INVALID-DURATION (err u108))
(define-constant ERR-ALREADY-EXECUTED (err u109))

;; Minimum votes required for an initiative to pass (can be adjusted)
(define-constant MIN-VOTES-REQUIRED u100)
;; Maximum voting duration in blocks (approximately 30 days)
(define-constant MAX-VOTING-DURATION u4320)
;; Minimum voting duration in blocks (approximately 7 days)
(define-constant MIN-VOTING-DURATION u1008)

;; data vars
;;
(define-data-var initiative-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; data maps
;;
;; Store initiative details
(define-map initiatives
    uint
    {
        proposer: principal,
        title: (string-ascii 100),
        description: (string-utf8 500),
        votes-for: uint,
        votes-against: uint,
        start-block: uint,
        end-block: uint,
        executed: bool,
        passed: bool
    }
)

;; Track who has voted on which initiative
(define-map user-votes
    { initiative-id: uint, voter: principal }
    { voted: bool, vote-for: bool }
)

;; Track user's voting history
(define-map user-voting-history
    principal
    (list 100 uint)
)

;; public functions
;;

;; Create a new initiative
(define-public (create-initiative
    (title (string-ascii 100))
    (description (string-utf8 500))
    (duration uint))

    (let
        (
            (new-id (+ (var-get initiative-counter) u1))
            (start-block block-height)
            (end-block (+ block-height duration))
        )

        ;; Validate duration
        (asserts! (>= duration MIN-VOTING-DURATION) ERR-INVALID-DURATION)
        (asserts! (<= duration MAX-VOTING-DURATION) ERR-INVALID-DURATION)

        ;; Create the initiative
        (map-set initiatives new-id {
            proposer: tx-sender,
            title: title,
            description: description,
            votes-for: u0,
            votes-against: u0,
            start-block: start-block,
            end-block: end-block,
            executed: false,
            passed: false
        })

        ;; Update counter
        (var-set initiative-counter new-id)

        ;; Return the new initiative ID
        (ok new-id)
    )
)

;; Vote on an initiative
(define-public (vote (initiative-id uint) (vote-for bool))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) ERR-INITIATIVE-NOT-FOUND))
            (has-voted (default-to { voted: false, vote-for: false }
                (map-get? user-votes { initiative-id: initiative-id, voter: tx-sender })))
        )

        ;; Check if voting is active
        (asserts! (>= block-height (get start-block initiative)) ERR-VOTING-NOT-STARTED)
        (asserts! (<= block-height (get end-block initiative)) ERR-VOTING-ENDED)

        ;; Check if user has already voted
        (asserts! (not (get voted has-voted)) ERR-ALREADY-VOTED)

        ;; Update vote counts
        (if vote-for
            (map-set initiatives initiative-id
                (merge initiative { votes-for: (+ (get votes-for initiative) u1) }))
            (map-set initiatives initiative-id
                (merge initiative { votes-against: (+ (get votes-against initiative) u1) }))
        )

        ;; Record user's vote
        (map-set user-votes
            { initiative-id: initiative-id, voter: tx-sender }
            { voted: true, vote-for: vote-for }
        )

        ;; Update user's voting history
        (let
            (
                (history (default-to (list) (map-get? user-voting-history tx-sender)))
                (new-history (unwrap! (as-max-len? (append history initiative-id) u100) ERR-INVALID-INITIATIVE))
            )
            (map-set user-voting-history tx-sender new-history)
        )

        (ok true)
    )
)

;; Execute a passed initiative (marks it as executed)
(define-public (execute-initiative (initiative-id uint))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) ERR-INITIATIVE-NOT-FOUND))
        )

        ;; Check if voting has ended
        (asserts! (> block-height (get end-block initiative)) ERR-VOTING-NOT-STARTED)

        ;; Check if already executed
        (asserts! (not (get executed initiative)) ERR-ALREADY-EXECUTED)

        ;; Check if initiative passed (more votes for than against and meets minimum threshold)
        (asserts! (> (get votes-for initiative) (get votes-against initiative)) ERR-INSUFFICIENT-VOTES)
        (asserts! (>= (get votes-for initiative) MIN-VOTES-REQUIRED) ERR-INSUFFICIENT-VOTES)

        ;; Mark as executed and passed
        (map-set initiatives initiative-id
            (merge initiative {
                executed: true,
                passed: true
            })
        )

        (ok true)
    )
)

;; Cancel an initiative (only by proposer before voting ends)
(define-public (cancel-initiative (initiative-id uint))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) ERR-INITIATIVE-NOT-FOUND))
        )

        ;; Only proposer can cancel
        (asserts! (is-eq tx-sender (get proposer initiative)) ERR-NOT-AUTHORIZED)

        ;; Can only cancel if voting hasn't ended
        (asserts! (<= block-height (get end-block initiative)) ERR-VOTING-ENDED)

        ;; Mark as executed but not passed (effectively cancelled)
        (map-set initiatives initiative-id
            (merge initiative {
                executed: true,
                passed: false
            })
        )

        (ok true)
    )
)

;; read only functions
;;

;; Get initiative details
(define-read-only (get-initiative (initiative-id uint))
    (map-get? initiatives initiative-id)
)

;; Get current vote counts
(define-read-only (get-vote-counts (initiative-id uint))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) ERR-INITIATIVE-NOT-FOUND))
        )
        (ok {
            votes-for: (get votes-for initiative),
            votes-against: (get votes-against initiative),
            total-votes: (+ (get votes-for initiative) (get votes-against initiative))
        })
    )
)

;; Check if a user has voted on an initiative
(define-read-only (has-user-voted (initiative-id uint) (voter principal))
    (let
        (
            (vote-record (map-get? user-votes { initiative-id: initiative-id, voter: voter }))
        )
        (if (is-some vote-record)
            (get voted (unwrap-panic vote-record))
            false
        )
    )
)

;; Get user's vote on an initiative
(define-read-only (get-user-vote (initiative-id uint) (voter principal))
    (map-get? user-votes { initiative-id: initiative-id, voter: voter })
)

;; Get voting status
(define-read-only (get-voting-status (initiative-id uint))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) ERR-INITIATIVE-NOT-FOUND))
            (current-block block-height)
        )
        (ok {
            is-active: (and
                (>= current-block (get start-block initiative))
                (<= current-block (get end-block initiative))
                (not (get executed initiative))
            ),
            has-ended: (> current-block (get end-block initiative)),
            blocks-remaining: (if (> (get end-block initiative) current-block)
                (some (- (get end-block initiative) current-block))
                none
            ),
            executed: (get executed initiative),
            passed: (get passed initiative)
        })
    )
)

;; Get user's voting history
(define-read-only (get-user-voting-history (user principal))
    (default-to (list) (map-get? user-voting-history user))
)

;; Get total number of initiatives
(define-read-only (get-initiative-count)
    (var-get initiative-counter)
)

;; Check if an initiative would pass if voting ended now
(define-read-only (would-pass-now (initiative-id uint))
    (let
        (
            (initiative (map-get? initiatives initiative-id))
        )
        (if (is-some initiative)
            (let
                (
                    (init (unwrap-panic initiative))
                )
                (and
                    (> (get votes-for init) (get votes-against init))
                    (>= (get votes-for init) MIN-VOTES-REQUIRED)
                )
            )
            false
        )
    )
)

;; private functions
;;

;; Helper function to check if caller is contract owner
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)
