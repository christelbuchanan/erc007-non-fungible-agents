// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title MemoryModuleRegistry
 * @dev Registry for memory modules used by ERC-007 agents
 */
contract MemoryModuleRegistry is Initializable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // ERC007 contract address
    address public erc007;
    
    // Governance contract address
    address public governance;
    
    // Mapping from agent token ID to registered memory modules
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _registeredModules;
    
    // Mapping from module address to module metadata
    mapping(address => ModuleMetadata) private _moduleMetadata;
    
    // Approved module types
    EnumerableSetUpgradeable.Bytes32Set private _approvedModuleTypes;
    
    // Module metadata structure
    struct ModuleMetadata {
        string name;
        string description;
        bytes32 moduleType;
        address developer;
        bool verified;
    }
    
    // Events
    event ModuleRegistered(uint256 indexed tokenId, address indexed moduleAddress);
    event ModuleUnregistered(uint256 indexed tokenId, address indexed moduleAddress);
    event ModuleVerified(address indexed moduleAddress);
    event ModuleTypeApproved(bytes32 indexed moduleType);
    event ModuleTypeRemoved(bytes32 indexed moduleType);
    
    /**
     * @dev Modifier to check if the caller is the governance contract
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "MemoryModuleRegistry: caller is not governance");
        _;
    }
    
    /**
     * @dev Modifier to check if the caller is the ERC007 contract
     */
    modifier onlyERC007() {
        require(msg.sender == erc007, "MemoryModuleRegistry: caller is not ERC007");
        _;
    }
    
    /**
     * @dev Initializes the contract
     * @param _erc007 The address of the ERC007 contract
     * @param _governance The address of the governance contract
     */
    function initialize(address _erc007, address _governance) public initializer {
        __Ownable_init();
        
        require(_erc007 != address(0), "MemoryModuleRegistry: ERC007 is zero address");
        require(_governance != address(0), "MemoryModuleRegistry: governance is zero address");
        
        erc007 = _erc007;
        governance = _governance;
        
        // Add initial approved module types
        _approvedModuleTypes.add(keccak256("episodic"));
        _approvedModuleTypes.add(keccak256("semantic"));
        _approvedModuleTypes.add(keccak256("procedural"));
        _approvedModuleTypes.add(keccak256("associative"));
    }
    
    /**
     * @dev Registers a memory module for an agent
     * @param tokenId The ID of the agent token
     * @param moduleAddress The address of the memory module
     */
    function registerModule(uint256 tokenId, address moduleAddress) external onlyERC007 {
        require(moduleAddress != address(0), "MemoryModuleRegistry: module is zero address");
        require(
            _moduleMetadata[moduleAddress].developer != address(0),
            "MemoryModuleRegistry: module not registered in registry"
        );
        
        _registeredModules[tokenId].add(moduleAddress);
        
        emit ModuleRegistered(tokenId, moduleAddress);
    }
    
    /**
     * @dev Unregisters a memory module for an agent
     * @param tokenId The ID of the agent token
     * @param moduleAddress The address of the memory module
     */
    function unregisterModule(uint256 tokenId, address moduleAddress) external onlyERC007 {
        require(
            _registeredModules[tokenId].contains(moduleAddress),
            "MemoryModuleRegistry: module not registered for agent"
        );
        
        _registeredModules[tokenId].remove(moduleAddress);
        
        emit ModuleUnregistered(tokenId, moduleAddress);
    }
    
    /**
     * @dev Adds a new memory module to the registry
     * @param moduleAddress The address of the memory module
     * @param name The name of the module
     * @param description The description of the module
     * @param moduleType The type of the module
     */
    function addModule(
        address moduleAddress,
        string memory name,
        string memory description,
        bytes32 moduleType
    ) external {
        require(moduleAddress != address(0), "MemoryModuleRegistry: module is zero address");
        require(
            _moduleMetadata[moduleAddress].developer == address(0),
            "MemoryModuleRegistry: module already registered"
        );
        require(
            _approvedModuleTypes.contains(moduleType),
            "MemoryModuleRegistry: module type not approved"
        );
        
        _moduleMetadata[moduleAddress] = ModuleMetadata({
            name: name,
            description: description,
            moduleType: moduleType,
            developer: msg.sender,
            verified: false
        });
    }
    
    /**
     * @dev Verifies a memory module (only governance)
     * @param moduleAddress The address of the memory module
     */
    function verifyModule(address moduleAddress) external onlyGovernance {
        require(
            _moduleMetadata[moduleAddress].developer != address(0),
            "MemoryModuleRegistry: module not registered"
        );
        
        _moduleMetadata[moduleAddress].verified = true;
        
        emit ModuleVerified(moduleAddress);
    }
    
    /**
     * @dev Approves a new module type (only governance)
     * @param moduleType The type to approve
     */
    function approveModuleType(bytes32 moduleType) external onlyGovernance {
        require(
            !_approvedModuleTypes.contains(moduleType),
            "MemoryModuleRegistry: module type already approved"
        );
        
        _approvedModuleTypes.add(moduleType);
        
        emit ModuleTypeApproved(moduleType);
    }
    
    /**
     * @dev Removes an approved module type (only governance)
     * @param moduleType The type to remove
     */
    function removeModuleType(bytes32 moduleType) external onlyGovernance {
        require(
            _approvedModuleTypes.contains(moduleType),
            "MemoryModuleRegistry: module type not approved"
        );
        
        _approvedModuleTypes.remove(moduleType);
        
        emit ModuleTypeRemoved(moduleType);
    }
    
    /**
     * @dev Gets all registered modules for an agent
     * @param tokenId The ID of the agent token
     * @return An array of registered module addresses
     */
    function getModules(uint256 tokenId) external view returns (address[] memory) {
        return _registeredModules[tokenId].values();
    }
    
    /**
     * @dev Gets the metadata for a module
     * @param moduleAddress The address of the memory module
     * @return The module's metadata
     */
    function getModuleMetadata(address moduleAddress) external view returns (ModuleMetadata memory) {
        return _moduleMetadata[moduleAddress];
    }
    
    /**
     * @dev Checks if a module is registered for an agent
     * @param tokenId The ID of the agent token
     * @param moduleAddress The address of the memory module
     * @return True if the module is registered, false otherwise
     */
    function isModuleRegistered(uint256 tokenId, address moduleAddress) external view returns (bool) {
        return _registeredModules[tokenId].contains(moduleAddress);
    }
    
    /**
     * @dev Checks if a module type is approved
     * @param moduleType The type to check
     * @return True if the module type is approved, false otherwise
     */
    function isModuleTypeApproved(bytes32 moduleType) external view returns (bool) {
        return _approvedModuleTypes.contains(moduleType);
    }
    
    /**
     * @dev Gets all approved module types
     * @return An array of approved module types
     */
    function getApprovedModuleTypes() external view returns (bytes32[] memory) {
        return _approvedModuleTypes.values();
    }
    
    /**
     * @dev Sets the ERC007 contract address (only owner)
     * @param _erc007 The new ERC007 address
     */
    function setERC007(address _erc007) external onlyOwner {
        require(_erc007 != address(0), "MemoryModuleRegistry: ERC007 is zero address");
        erc007 = _erc007;
    }
    
    /**
     * @dev Sets the governance address (only owner)
     * @param _governance The new governance address
     */
    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "MemoryModuleRegistry: governance is zero address");
        governance = _governance;
    }
}
