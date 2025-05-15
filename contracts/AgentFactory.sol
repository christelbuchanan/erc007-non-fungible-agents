//<pivotalAction type="file" filePath="contracts/AgentFactory.sol">// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IERC007.sol";

/**
 * @title AgentFactory
 * @dev Factory contract for creating and managing ERC-007 agents
 */
contract AgentFactory is Initializable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // ERC007 contract address
    address public erc007;
    
    // Governance contract address
    address public governance;
    
    // Approved logic templates
    EnumerableSetUpgradeable.AddressSet private _approvedTemplates;
    
    // Mapping from template address to template metadata
    mapping(address => TemplateMetadata) private _templateMetadata;
    
    // Mapping from user address to their created agents
    mapping(address => uint256[]) private _userAgents;
    
    // Template metadata structure
    struct TemplateMetadata {
        string name;
        string description;
        string category;
        address developer;
        bool verified;
    }
    
    // Events
    event AgentCreated(
        address indexed owner,
        uint256 indexed tokenId,
        address logicAddress,
        string metadataURI
    );
    event TemplateApproved(address indexed templateAddress, string name);
    event TemplateRemoved(address indexed templateAddress);
    
    /**
     * @dev Modifier to check if the caller is the governance contract
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "AgentFactory: caller is not governance");
        _;
    }
    
    /**
     * @dev Initializes the contract
     * @param _erc007 The address of the ERC007 contract
     * @param _governance The address of the governance contract
     */
    function initialize(address _erc007, address _governance) public initializer {
        __Ownable_init();
        
        require(_erc007 != address(0), "AgentFactory: ERC007 is zero address");
        require(_governance != address(0), "AgentFactory: governance is zero address");
        
        erc007 = _erc007;
        governance = _governance;
    }
    
    /**
     * @dev Creates a new agent using a template
     * @param templateAddress The address of the template to use
     * @param metadataURI The URI for the agent's metadata
     * @param persona The persona string for the agent
     * @param memory The memory string for the agent
     * @return tokenId The ID of the new agent token
     */
    function createAgent(
        address templateAddress,
        string memory metadataURI,
        string memory persona,
        string memory memory
    ) external returns (uint256) {
        require(
            _approvedTemplates.contains(templateAddress),
            "AgentFactory: template not approved"
        );
        
        // Create extended metadata
        IERC007.AgentMetadata memory extendedMetadata = IERC007.AgentMetadata({
            persona: persona,
            memory: memory,
            voiceHash: "",
            animationURI: "",
            vaultURI: "",
            vaultHash: bytes32(0)
        });
        
        // Create the agent
        uint256 tokenId = IERC007(erc007).createAgent(
            msg.sender,
            templateAddress,
            metadataURI,
            extendedMetadata
        );
        
        // Add to user's agents
        _userAgents[msg.sender].push(tokenId);
        
        emit AgentCreated(msg.sender, tokenId, templateAddress, metadataURI);
        
        return tokenId;
    }
    
    /**
     * @dev Approves a template (only governance)
     * @param templateAddress The address of the template
     * @param name The name of the template
     * @param description The description of the template
     * @param category The category of the template
     */
    function approveTemplate(
        address templateAddress,
        string memory name,
        string memory description,
        string memory category
    ) external onlyGovernance {
        require(templateAddress != address(0), "AgentFactory: template is zero address");
        require(
            !_approvedTemplates.contains(templateAddress),
            "AgentFactory: template already approved"
        );
        
        _approvedTemplates.add(templateAddress);
        
        _templateMetadata[templateAddress] = TemplateMetadata({
            name: name,
            description: description,
            category: category,
            developer: msg.sender,
            verified: true
        });
        
        emit TemplateApproved(templateAddress, name);
    }
    
    /**
     * @dev Removes a template (only governance)
     * @param templateAddress The address of the template
     */
    function removeTemplate(address templateAddress) external onlyGovernance {
        require(
            _approvedTemplates.contains(templateAddress),
            "AgentFactory: template not approved"
        );
        
        _approvedTemplates.remove(templateAddress);
        
        emit TemplateRemoved(templateAddress);
    }
    
    /**
     * @dev Gets all approved templates
     * @return An array of approved template addresses
     */
    function getApprovedTemplates() external view returns (address[] memory) {
        return _approvedTemplates.values();
    }
    
    /**
     * @dev Gets the metadata for a template
     * @param templateAddress The address of the template
     * @return The template's metadata
     */
    function getTemplateMetadata(address templateAddress) external view returns (TemplateMetadata memory) {
        return _templateMetadata[templateAddress];
    }
    
    /**
     * @dev Gets all agents created by a user
     * @param user The address of the user
     * @return An array of agent token IDs
     */
    function getUserAgents(address user) external view returns (uint256[] memory) {
        return _userAgents[user];
    }
    
    /**
     * @dev Checks if a template is approved
     * @param templateAddress The address of the template
     * @return True if the template is approved, false otherwise
     */
    function isTemplateApproved(address templateAddress) external view returns (bool) {
        return _approvedTemplates.contains(templateAddress);
    }
    
    /**
     * @dev Sets the ERC007 contract address (only owner)
     * @param _erc007 The new ERC007 address
     */
    function setERC007(address _erc007) external onlyOwner {
        require(_erc007 != address(0), "AgentFactory: ERC007 is zero address");
        erc007 = _erc007;
    }
    
    /**
     * @dev Sets the governance address (only owner)
     * @param _governance The new governance address
     */
    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "AgentFactory: governance is zero address");
        governance = _governance;
    }
}
