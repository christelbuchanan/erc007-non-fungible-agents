# ERC007Governance

## Overview
The ERC007Governance contract manages the decentralized governance system for the ERC-007 ecosystem. It enables token holders to create, vote on, and execute proposals that affect the protocol parameters and operations.

## Key Features
- Proposal creation and management
- Voting mechanism based on token ownership
- Configurable voting parameters (period, quorum, execution delay)
- Secure proposal execution

## Contract Structure

### State Variables
- `erc007Token`: Reference to the ERC007 token contract
- `treasury`: Address of the treasury contract
- `agentFactory`: Address of the agent factory contract
- `votingPeriod`: Duration of voting in days
- `quorumPercentage`: Percentage of total supply needed for quorum
- `executionDelay`: Delay before execution in days after voting ends

### Structs
- `Proposal`: Contains proposal details including ID, proposer, description, call data, target contract, timestamps, vote counts, and execution status

### Events
- `ProposalCreated`: Emitted when a new proposal is created
- `VoteCast`: Emitted when a vote is cast
- `ProposalExecuted`: Emitted when a proposal is executed
- `ProposalCanceled`: Emitted when a proposal is canceled
- `TreasuryUpdated`, `AgentFactoryUpdated`, `VotingParametersUpdated`: Emitted when configuration changes

### Functions

#### Initialization
```solidity
function initialize(
    string memory name,
    address _erc007Token,
    address _owner,
    uint256 _votingPeriod,
    uint256 _quorumPercentage,
    uint256 _executionDelay
) public initializer
```
Initializes the governance contract with token reference and voting parameters.

#### Proposal Management
```solidity
function createProposal(
    string memory description,
    bytes memory callData,
    address targetContract
) external returns (uint256)
```
Creates a new governance proposal.

```solidity
function castVote(uint256 proposalId, bool support) external
```
Casts a vote on a proposal.

```solidity
function executeProposal(uint256 proposalId) external
```
Executes a proposal that has passed.

```solidity
function cancelProposal(uint256 proposalId) external
```
Cancels a proposal (only proposer or owner).

#### Configuration
```solidity
function setTreasury(address _treasury) external onlyOwner
```
Sets the treasury address.

```solidity
function setAgentFactory(address _agentFactory) external onlyOwner
```
Sets the agent factory address.

```solidity
function updateVotingParameters(
    uint256 _votingPeriod,
    uint256 _quorumPercentage,
    uint256 _executionDelay
) external onlyOwner
```
Updates the voting parameters.

## Security Considerations
- Voting weight based on token ownership
- Quorum requirements to prevent minority control
- Execution delay for security
- Proposal cancellation by proposer or owner

## Integration Points
- Interacts with ERC007 token for voting weight
- Controls ERC007Treasury for fund management
- Controls AgentFactory for template approvals
