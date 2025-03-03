# GridFlow: Decentralized Energy Distribution Network

A blockchain-based platform for managing peer-to-peer energy trading and distribution on the Stacks network.

## Features
- Register as an energy producer or consumer
- List available energy capacity for sale
- Purchase energy from producers
- Track energy distribution and payments
- View transaction history and energy metrics

## Setup and Installation
1. Clone the repository
2. Install Clarinet 
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Register as energy producer
(contract-call? .gridflow register-producer u1000)

;; List energy for sale 
(contract-call? .gridflow list-energy u100 u500)

;; Purchase energy
(contract-call? .gridflow purchase-energy u50 'ST1PRODUCER...)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
