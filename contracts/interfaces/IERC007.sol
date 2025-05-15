// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC007 - Interface for Non-Fungible Agent (NFA) tokens
 * @dev This interface defines the core functionality for ERC-007 compliant tokens
 */
interface IERC007 {
    /**
     * @dev Enum representing the current status of an agent
     */
    enum Status { Active, Paused, Terminated }
    
    /**
     * @dev Struct representing the state of an agent
     */
    struct State {
        uint256 balance;
        Status status;
        address owner;
        address logicAddress;
        uint256 lastActionTimestamp;
    }

    /**
     * @dev Struct representing the extended metadata of an agent
     */
    struct AgentMetadata {
        string persona;       // JSON-encoded string for character traits, style, tone
        string memory;        // Short summary string for agent's role/purpose
        string voiceHash;     // Reference ID to stored audio profile
        string animationURI;  // URI to video or animation file
        string vaultURI;      // URI to the agent's vault (extended data storage)
        bytes32 vaultHash;    // Hash of the vault contents for verification
    }
    
    /**
     * @dev Emitted when an agent executes an action
     */
    event ActionExecuted(address indexed agent, bytes result);
    
    /**
     * @dev Emitted when an agent's logic is upgraded
     */
    event LogicUpgraded(address indexed agent, address oldLogic, address newLogic);
    
    /**
     * @dev Emitted when an agent is funded
     */
    event AgentFunded(address indexed agent, address indexed funder, uint256 amount);
    
    /**
     * @dev Emitted when an agent's status changes
     */
    event StatusChanged(address indexed agent, Status newStatus);

    /**
     * @dev Emitted when an agent's metadata is updated
     */
    event MetadataUpdated(uint256 indexed tokenId, string metadataURI);

    /**
     * @dev Emitted when a memory module is registered
     */
    event MemoryModuleRegistered(uint256 indexed tokenId, address indexed moduleAddress);
    
    /**
     * @dev Creates a new agent token with extended metadata
     * @param to The address that will own the agent
     * @param logicAddress The address of the logic contract
     * @param metadataURI The URI for the agent's metadata
     * @param extendedMetadata The extended metadata for the agent
     * @return tokenId The ID of the new agent token
     */
    function createAgent(
        address to, 
        address logicAddress, 
        string memory metadataURI,
        AgentMetadata memory extendedMetadata
    ) external returns (uint256 tokenId);
    
    /**
     * @dev Creates a new agent token with basic metadata
     * @param to The address that will own the agent
     * @param logicAddress The address of the logic contract
     * @param metadataURI The URI for the agent's metadata
     * @return tokenId The ID of the new agent token
     */
    function createAgent(
        address to, 
        address logicAddress, 
        string memory metadataURI
    ) external returns (uint256 tokenId);
    
    /**
     * @dev Executes an action using the agent's logic
     * @param tokenId The ID of the agent token
     * @param data The encoded function call to execute
     */
    function executeAction(uint256 tokenId, bytes calldata data) external;
    
    /**
     * @dev Updates the logic address for the agent
     * @param tokenId The ID of the agent token
     * @param newLogic The address of the new logic contract
     */
    function setLogicAddress(uint256 tokenId, address newLogic) external;
    
    /**
     * @dev Funds the agent with ETH for gas fees
     * @param tokenId The ID of the agent token
     */
    function fundAgent(uint256 tokenId) external payable;
    
    /**
     * @dev Returns the current state of the agent
     * @param tokenId The ID of the agent token
     * @return The agent's state
     */
    function getState(uint256 tokenId) external view returns (State memory);
    
    /**
     * @dev Gets the agent's extended metadata
     * @param tokenId The ID of the agent token
     * @return The agent's extended metadata
     */
    function getAgentMetadata(uint256 tokenId) external view returns (AgentMetadata memory);
    
    /**
     * @dev Updates the agent's extended metadata
     * @param tokenId The ID of the agent token
     * @param metadata The new metadata
     */
    function updateAgentMetadata(uint256 tokenId, AgentMetadata memory metadata) external;
    
    /**
     * @dev Registers a memory module for the agent
     * @param tokenId The ID of the agent token
     * @param moduleAddress The address of the memory module
     */
    function registerMemoryModule(uint256 tokenId, address moduleAddress) external;
    
    /**
     * @dev Pauses the agent
     * @param tokenId The ID of the agent token
     */
    function pause(uint256 tokenId) external;
    
    /**
     * @dev Resumes the agent
     * @param tokenId The ID of the agent token
     */
    function unpause(uint256 tokenId) external;
    
    /**
     * @dev Terminates the agent permanently
     * @param tokenId The ID of the agent token
     */
    function terminate(uint256 tokenId) external;
}
