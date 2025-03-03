# DocuChain
A document verification and storage system built on the Stacks blockchain using Clarity.

## Features
- Store document hashes on-chain
- Verify document authenticity
- Track document history
- Manage document ownership
- Support multiple document types

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Store a new document hash
(contract-call? .docu-chain store-document 0x1234... "contract.pdf" "application/pdf")

;; Verify a document
(contract-call? .docu-chain verify-document 0x1234...)

;; Get document history
(contract-call? .docu-chain get-document-history 0x1234...)

;; Transfer document ownership
(contract-call? .docu-chain transfer-ownership 0x1234... 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
