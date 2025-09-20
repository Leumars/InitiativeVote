# InitiativeVote

A decentralized voting platform for citizen-proposed legislation and policy changes built on the Stacks blockchain using Clarity smart contracts.

## Overview

InitiativeVote is a community-driven voting platform that empowers citizens to propose, vote on, and track legislative initiatives directly on the blockchain. The platform ensures transparent, tamper-proof voting processes with clear rules for proposal creation, voting periods, and execution thresholds.

## Features

### Core Functionality

- **Initiative Creation**: Citizens can propose new initiatives with titles and detailed descriptions
- **Time-Bound Voting**: Each initiative has a defined voting period (7-30 days)
- **Binary Voting**: Support for or against proposed initiatives
- **Vote Tracking**: Comprehensive tracking of individual votes and voting history
- **Execution Mechanism**: Automatic execution of passed initiatives based on predefined thresholds
- **Cancellation Option**: Proposers can cancel their initiatives before voting ends

### Security Features

- **Single Vote Protection**: Each user can only vote once per initiative
- **Time Window Enforcement**: Strict enforcement of voting start and end blocks
- **Minimum Threshold Requirements**: Initiatives must meet minimum vote requirements to pass
- **Execution Control**: Prevents double execution of initiatives
- **Authorization Checks**: Only proposers can cancel their own initiatives

## Technical Specifications

### Blockchain Details
- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity (Version 2)
- **Epoch**: 2.5

### Contract Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `MIN-VOTES-REQUIRED` | 100 | Minimum votes needed for an initiative to pass |
| `MAX-VOTING-DURATION` | 4,320 blocks | Maximum voting period (~30 days) |
| `MIN-VOTING-DURATION` | 1,008 blocks | Minimum voting period (~7 days) |

### Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `ERR-NOT-AUTHORIZED` | User is not authorized to perform this action |
| u101 | `ERR-INITIATIVE-NOT-FOUND` | Initiative with specified ID does not exist |
| u102 | `ERR-ALREADY-VOTED` | User has already voted on this initiative |
| u103 | `ERR-VOTING-ENDED` | Voting period has ended |
| u104 | `ERR-VOTING-NOT-STARTED` | Voting period has not started |
| u105 | `ERR-INVALID-INITIATIVE` | Invalid initiative parameters |
| u106 | `ERR-INSUFFICIENT-VOTES` | Initiative did not meet minimum vote requirements |
| u107 | `ERR-INITIATIVE-ALREADY-EXISTS` | Initiative already exists |
| u108 | `ERR-INVALID-DURATION` | Voting duration is outside allowed range |
| u109 | `ERR-ALREADY-EXECUTED` | Initiative has already been executed |

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) (latest version)
- [Stacks CLI](https://docs.stacks.co/docs/cli) (optional for deployment)
- Node.js and npm (for development tooling)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/InitiativeVote.git
cd InitiativeVote
```

2. Install dependencies:
```bash
cd InitiativeVote_contract
npm install
```

3. Run tests:
```bash
clarinet test
```

4. Check contract:
```bash
clarinet check
```

## Usage Examples

### Creating an Initiative

```clarity
(contract-call? .InitiativeVote create-initiative
    "Reduce Carbon Emissions by 50%"
    u"Comprehensive plan to reduce city carbon emissions through renewable energy incentives and public transport improvements"
    u2016) ;; 14-day voting period
```

### Voting on an Initiative

```clarity
;; Vote in favor
(contract-call? .InitiativeVote vote u1 true)

;; Vote against
(contract-call? .InitiativeVote vote u1 false)
```

### Executing a Passed Initiative

```clarity
(contract-call? .InitiativeVote execute-initiative u1)
```

### Cancelling an Initiative

```clarity
;; Only the proposer can cancel
(contract-call? .InitiativeVote cancel-initiative u1)
```

## Contract Functions Documentation

### Public Functions

#### `create-initiative`
Creates a new voting initiative.

**Parameters:**
- `title`: (string-ascii 100) - Initiative title (max 100 characters)
- `description`: (string-utf8 500) - Detailed description (max 500 characters)
- `duration`: uint - Voting duration in blocks (1008-4320)

**Returns:** `(response uint error-code)` - Initiative ID on success

---

#### `vote`
Cast a vote on an active initiative.

**Parameters:**
- `initiative-id`: uint - ID of the initiative
- `vote-for`: bool - true for support, false for opposition

**Returns:** `(response bool error-code)` - true on success

---

#### `execute-initiative`
Execute a passed initiative after voting ends.

**Parameters:**
- `initiative-id`: uint - ID of the initiative to execute

**Returns:** `(response bool error-code)` - true on success

**Requirements:**
- Voting period must have ended
- Initiative must have more votes for than against
- Must meet minimum vote threshold (100 votes)
- Cannot be already executed

---

#### `cancel-initiative`
Cancel an initiative (only by proposer).

**Parameters:**
- `initiative-id`: uint - ID of the initiative to cancel

**Returns:** `(response bool error-code)` - true on success

### Read-Only Functions

#### `get-initiative`
Retrieve complete details of an initiative.

**Parameters:**
- `initiative-id`: uint - ID of the initiative

**Returns:** Initiative data structure or none

---

#### `get-vote-counts`
Get current voting statistics for an initiative.

**Parameters:**
- `initiative-id`: uint - ID of the initiative

**Returns:** `{ votes-for: uint, votes-against: uint, total-votes: uint }`

---

#### `has-user-voted`
Check if a user has voted on an initiative.

**Parameters:**
- `initiative-id`: uint - ID of the initiative
- `voter`: principal - Address of the voter

**Returns:** bool - true if voted, false otherwise

---

#### `get-user-vote`
Retrieve a user's specific vote on an initiative.

**Parameters:**
- `initiative-id`: uint - ID of the initiative
- `voter`: principal - Address of the voter

**Returns:** Vote record or none

---

#### `get-voting-status`
Get comprehensive voting status of an initiative.

**Parameters:**
- `initiative-id`: uint - ID of the initiative

**Returns:** Status object with:
- `is-active`: bool - Whether voting is currently active
- `has-ended`: bool - Whether voting period has ended
- `blocks-remaining`: (optional uint) - Blocks until voting ends
- `executed`: bool - Whether initiative has been executed
- `passed`: bool - Whether initiative passed

---

#### `get-user-voting-history`
Get list of all initiatives a user has voted on.

**Parameters:**
- `user`: principal - Address of the user

**Returns:** List of initiative IDs (max 100)

---

#### `get-initiative-count`
Get total number of initiatives created.

**Returns:** uint - Total initiative count

---

#### `would-pass-now`
Check if an initiative would pass if voting ended now.

**Parameters:**
- `initiative-id`: uint - ID of the initiative

**Returns:** bool - true if would pass, false otherwise

## Deployment Guide

### Local Development (Devnet)

1. Start local Stacks node:
```bash
clarinet integrate
```

2. Deploy contract:
```bash
clarinet deploy --devnet
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Audit the contract thoroughly

3. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Security Considerations

### Best Practices

1. **Vote Integrity**: The contract prevents double voting and ensures votes cannot be changed once cast
2. **Time Boundaries**: Strict enforcement of voting periods prevents early or late voting
3. **Authorization**: Only proposers can cancel their initiatives, preventing malicious cancellations
4. **Execution Safety**: Initiatives can only be executed once and only after meeting all requirements

### Audit Recommendations

Before mainnet deployment:
- Conduct thorough testing of all edge cases
- Perform formal verification of critical functions
- Get professional smart contract audit
- Test with various voting scenarios and attack vectors
- Verify gas costs for all operations

### Known Limitations

- Maximum of 100 initiatives in user voting history
- Initiative titles limited to 100 ASCII characters
- Descriptions limited to 500 UTF-8 characters
- No mechanism to update initiative details after creation
- No delegation or proxy voting capabilities

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes with clear messages
4. Write or update tests as needed
5. Ensure all tests pass (`clarinet test`)
6. Submit a pull request

## License

This project is open source. Please check the repository for license details.

## Support

For questions, issues, or suggestions:
- Open an issue in the GitHub repository
- Contact the development team
- Join the community discussion forums

## Roadmap

Future enhancements under consideration:
- Weighted voting based on token holdings
- Delegation mechanisms for proxy voting
- Multi-option voting (beyond binary yes/no)
- Integration with governance tokens
- On-chain execution of passed initiatives
- Reputation system for successful proposers
- Categories and tags for initiatives
- Quorum requirements based on initiative type