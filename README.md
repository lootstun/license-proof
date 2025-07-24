# License-Proof Smart Contract

A self-sovereign identity verification system for professional licenses built on the Stacks blockchain using Clarity smart contracts.

## Overview

License-Proof enables professionals to register, manage, and verify their professional licenses in a decentralized manner. The system provides trustless verification while giving license holders full control over their credentials.

## Features

### Core Functionality
- **License Registration**: Professionals can register their licenses with verification hashes
- **Self-Sovereign Control**: License holders maintain full control over their credentials
- **Decentralized Verification**: Anyone can verify license validity without intermediaries
- **Expiry Management**: Automatic handling of license expiration
- **Revocation System**: License holders can revoke their own licenses

### Security Features
- Ownership-based access control
- Authorized verifier system for institutions
- Built-in data validation
- Tamper-proof blockchain storage

## Contract Structure

### Data Maps
- `licenses`: Stores license details indexed by license ID
- `holder-licenses`: Tracks all licenses per holder
- `authorized-verifiers`: Manages institutional verifiers

### License Data Structure
```clarity
{
  holder: principal,
  license-type: (string-ascii 32),
  issuing-authority: (string-ascii 64),
  issue-date: uint,
  expiry-date: uint,
  license-number: (string-ascii 32),
  status: (string-ascii 16), // "active", "expired", "revoked"
  verification-hash: (string-ascii 64)
}
```

## Public Functions

### `register-license`
Registers a new professional license.

**Parameters:**
- `license-type`: Type of professional license (e.g., "Medical", "Legal")
- `issuing-authority`: Name of the issuing organization
- `expiry-date`: Block height when license expires
- `license-number`: Official license number
- `verification-hash`: Hash for additional verification

**Returns:** License ID on success

**Example:**
```clarity
(contract-call? .license-proof register-license 
  "Medical Doctor" 
  "State Medical Board" 
  u1000000 
  "MD123456" 
  "abc123hash...")
```

### `verify-license`
Verifies a license by its ID and returns detailed information.

**Parameters:**
- `license-id`: The unique license identifier

**Returns:** License details with validity status

### `get-holder-licenses`
Retrieves all licenses for a specific holder.

**Parameters:**
- `holder`: Principal address of the license holder

**Returns:** List of license IDs and count

### `revoke-license`
Allows license holders to revoke their own licenses.

**Parameters:**
- `license-id`: ID of the license to revoke

**Returns:** Success confirmation

### `update-license-status`
Updates license status based on expiry date.

**Parameters:**
- `license-id`: ID of the license to update

**Returns:** New status

### `authorize-verifier`
Authorizes institutional verifiers (contract owner only).

**Parameters:**
- `verifier`: Principal address of the verifier
- `verifier-name`: Name of the verifying institution

## Read-Only Functions

### `is-authorized-verifier`
Checks if an address is an authorized verifier.

### `get-total-licenses`
Returns the total number of registered licenses.

### `get-contract-owner`
Returns the contract owner's address.

## Usage Examples

### For License Holders

#### Register a License
```clarity
;; Register a medical license
(contract-call? .license-proof register-license 
  "Medical Doctor"
  "California Medical Board"
  u1500000  ;; Expiry block height
  "CA-MD-789012"
  "verification-hash-here")
```

#### Revoke Your License
```clarity
;; Revoke your own license
(contract-call? .license-proof revoke-license "LIC123")
```

### For Verifiers

#### Verify a License
```clarity
;; Check if a license is valid
(contract-call? .license-proof verify-license "LIC123")
```

#### Get All Licenses for a Holder
```clarity
;; Get all licenses for a professional
(contract-call? .license-proof get-holder-licenses 'SP1ABC...)
```

## Error Codes

- `u100`: Unauthorized access
- `u101`: License already exists
- `u102`: License not found
- `u103`: Invalid expiry date
- `u104`: License expired
- `u105`: License already revoked

## Deployment

1. Deploy the contract to Stacks blockchain
2. The deployer becomes the contract owner
3. Contract owner can authorize institutional verifiers
4. Professionals can start registering licenses

## Security Considerations

- License holders have full control over their credentials
- Only license holders can revoke their own licenses
- Contract owner manages authorized verifiers
- All data is immutably stored on blockchain
- Verification hashes provide additional security layer

## Integration

### For Institutions
Integrate license verification into your systems:

```javascript
// Example integration (pseudo-code)
const verifyProfessional = async (licenseId) => {
  const result = await stacksContract.callReadOnly('verify-license', [licenseId]);
  return result.is_valid;
};
```

### For Professionals
Use the contract to manage your professional credentials and provide verifiable proof to employers or clients.

## Benefits

- **Decentralized**: No single point of failure
- **Transparent**: All verifications are publicly auditable
- **Tamper-proof**: Blockchain immutability prevents fraud
- **Self-sovereign**: Users control their own data
- **Cost-effective**: Reduces verification overhead
- **Global**: Works across jurisdictions


**Note**: This contract provides a foundation for professional license verification. Always consult with legal and regulatory experts when implementing in production environments.