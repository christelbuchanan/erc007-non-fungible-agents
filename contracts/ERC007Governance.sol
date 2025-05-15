// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title ERC007Governance
 * @dev Governance contract for the ERC-007 ecosystem
 * Handles protocol upgrades, parameter changes, and treasury management
 */
contract ERC007Governance is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // Treasury contract address
    address public treasury;
    
    // ERC007 contract address
    address public erc007;
    
    // Memory module registry address
    address public memoryModuleRegistry;
    
    // Governance parameters
    uint256 public proposalThreshold;     // Minimum voting power to create a proposal
    uint256 public votingPeriod;          // Duration of voting in blocks
    uint256 public votingDelay;           // Delay before voting starts in blocks
    uint256 public quorumVotes;           // Minimum votes for a proposal to pass
    
    // Proposal states
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        string description;
        bytes[] calldatas;
        address[] targets;
        uint256[] values;
        bool executed;
        bool canceled;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => Receipt) receipts;
    }
    
    // Vote receipt
    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }
    
    // Approved contracts that can be called by governance
    EnumerableSetUpgradeable.AddressSet private _approvedContracts;
    
    // Mapping of proposal IDs to proposals
    mapping(uint256 => Proposal) public proposals;
    
    // Current proposal count
    uint256 public proposalCount;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description,
        uint256 startBlock,
        uint256 endBlock
    );
    
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        bool support,
        uint256 votes
    );
    
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ContractApproved(address indexed contractAddress);
    event ContractRemoved(address indexed contractAddress);
    
    /**
     * @dev Initializes the contract
     * @param _treasury The address of the treasury contract
     * @param _erc007 The address of the ERC007 contract
     * @param _memoryModuleRegistry The address of the memory module registry
     */
    function initialize(
        address _treasury,
        address _erc007,
        address _memoryModuleRegistry
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        require(_treasury != address(0), "ERC007Governance: treasury is zero address");
        require(_erc007 != address(0), "ERC007Governance: ERC007 is zero address");
        require(_memoryModuleRegistry != address(0), "ERC007Governance: registry is zero address");
        
        treasury = _treasury;
        erc007 = _erc007;
        memoryModuleRegistry = _memoryModuleRegistry;
        
        // Default governance parameters
        proposalThreshold = 1e18;  // 1 token
        votingPeriod = 40320;      // ~7 days at 15s blocks
        votingDelay = 5760;        // ~1 day at 15s blocks
        quorumVotes = 4e18;        // 4 tokens
        
        // Add initial approved contracts
        _approvedContracts.add(_treasury);
        _approvedContracts.add(_erc007);
        _approvedContracts.add(_memoryModuleRegistry);
    }
    
    /**
     * @dev Creates a new governance proposal
     * @param targets The addresses of the contracts to call
     * @param values The ETH values to send with the calls
     * @param calldatas The calldata for each call
     * @param description A description of the proposal
     * @return proposalId The ID of the new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            targets.length == values.length && targets.length == calldatas.length,
            "ERC007Governance: proposal function information mismatch"
        );
        require(targets.length > 0, "ERC007Governance: proposal must provide actions");
        
        // Check that proposer has enough voting power
        require(
            getVotingPower(msg.sender) >= proposalThreshold,
            "ERC007Governance: proposer votes below threshold"
        );
        
        // Validate targets are approved contracts
        for (uint256 i = 0; i < targets.length; i++) {
            require(
                _approvedContracts.contains(targets[i]),
                "ERC007Governance: target not approved"
            );
        }
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = block.number + votingDelay;
        newProposal.endBlock = block.number + votingDelay + votingPeriod;
        newProposal.description = description;
        newProposal.calldatas = calldatas;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.executed = false;
        newProposal.canceled = false;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        
        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            calldatas,
            description,
            newProposal.startBlock,
            newProposal.endBlock
        );
        
        return proposalId;
    }
    
    /**
     * @dev Casts a vote on a proposal
     * @param proposalId The ID of the proposal
     * @param support Whether to support the proposal
     */
    function castVote(uint256 proposalId, bool support) public {
        require(
            state(proposalId) == ProposalState.Active,
            "ERC007Governance: proposal not active"
        );
        
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];
        
        require(!receipt.hasVoted, "ERC007Governance: voter already voted");
        
        uint256 votes = getVotingPower(msg.sender);
        
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }
        
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        
        emit VoteCast(msg.sender, proposalId, support, votes);
    }
    
    /**
     * @dev Executes a successful proposal
     * @param proposalId The ID of the proposal
     */
    function execute(uint256 proposalId) public nonReentrant {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "ERC007Governance: proposal not successful"
        );
        
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                proposal.calldatas[i]
            );
            require(success, "ERC007Governance: transaction execution reverted");
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Cancels a proposal
     * @param proposalId The ID of the proposal
     */
    function cancel(uint256 proposalId) public {
        require(
            state(proposalId) != ProposalState.Executed,
            "ERC007Governance: proposal already executed"
        );
        
        Proposal storage proposal = proposals[proposalId];
        
        // Only proposer or if proposer's voting power dropped below threshold
        require(
            msg.sender == proposal.proposer || 
            getVotingPower(proposal.proposer) < proposalThreshold,
            "ERC007Governance: only proposer or if proposer votes below threshold"
        );
        
        proposal.canceled = true;
        
        emit ProposalCanceled(proposalId);
    }
    
    /**
     * @dev Gets the current state of a proposal
     * @param proposalId The ID of the proposal
     * @return The current state of the proposal
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId <= proposalCount, "ERC007Governance: invalid proposal id");
        
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number > proposal.endBlock + 80640) { // ~14 days after end
            return ProposalState.Expired;
        } else {
            return ProposalState.Succeeded;
        }
    }
    
    /**
     * @dev Gets the voting power of an address
     * @param voter The address to check
     * @return The voting power of the address
     */
    function getVotingPower(address voter) public view returns (uint256) {
        // In a real implementation, this would check token balance or delegation
        // For simplicity, we'll return a fixed value for the owner and zero for others
        if (voter == owner()) {
            return 10e18; // 10 tokens
        }
        return 0;
    }
    
    /**
     * @dev Approves a contract to be called by governance
     * @param contractAddress The address of the contract to approve
     */
    function approveContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "ERC007Governance: zero address");
        require(
            !_approvedContracts.contains(contractAddress),
            "ERC007Governance: contract already approved"
        );
        
        _approvedContracts.add(contractAddress);
        
        emit ContractApproved(contractAddress);
    }
    
    /**
     * @dev Removes a contract from the approved list
     * @param contractAddress The address of the contract to remove
     */
    function removeContract(address contractAddress) external onlyOwner {
        require(
            _approvedContracts.contains(contractAddress),
            "ERC007Governance: contract not approved"
        );
        
        _approvedContracts.remove(contractAddress);
        
        emit ContractRemoved(contractAddress);
    }
    
    /**
     * @dev Checks if a contract is approved
     * @param contractAddress The address to check
     * @return Whether the contract is approved
     */
    function isContractApproved(address contractAddress) external view returns (bool) {
        return _approvedContracts.contains(contractAddress);
    }
    
    /**
     * @dev Updates governance parameters
     * @param _proposalThreshold The new proposal threshold
     * @param _votingPeriod The new voting period
     * @param _votingDelay The new voting delay
     * @param _quorumVotes The new quorum votes
     */
    function updateGovernanceParameters(
        uint256 _proposalThreshold,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _quorumVotes
    ) external onlyOwner {
        proposalThreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        votingDelay = _votingDelay;
        quorumVotes = _quorumVotes;
    }
    
    /**
     * @dev Sets the treasury address
     * @param _treasury The new treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "ERC007Governance: treasury is zero address");
        treasury = _treasury;
    }
    
    /**
     * @dev Sets the ERC007 contract address
     * @param _erc007 The new ERC007 address
     */
    function setERC007(address _erc007) external onlyOwner {
        require(_erc007 != address(0), "ERC007Governance: ERC007 is zero address");
        erc007 = _erc007;
    }
    
    /**
     * @dev Sets the memory module registry address
     * @param _memoryModuleRegistry The new registry address
     */
    function setMemoryModuleRegistry(address _memoryModuleRegistry) external onlyOwner {
        require(_memoryModuleRegistry != address(0), "ERC007Governance: registry is zero address");
        memoryModuleRegistry = _memoryModuleRegistry;
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {}
}
