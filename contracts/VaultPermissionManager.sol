// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title VaultPermissionManager
 * @dev Manages permissions for accessing agent vaults
 */
contract VaultPermissionManager is Initializable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // ERC007 contract address
    address public erc007;
    
    // Mapping from token ID to approved applications
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _approvedApplications;
    
    // Mapping from application address to application metadata
    mapping(address => ApplicationMetadata) private _applicationMetadata;
    
    // Mapping from token ID to vault access nonce
    mapping(uint256 => uint256) private _vaultNonces;
    
    // Application metadata structure
    struct ApplicationMetadata {
        string name;
        string description;
        string url;
        address developer;
        bool verified;
    }
    
    // Events
    event ApplicationApproved(uint256 indexed tokenId, address indexed application);
    event ApplicationRevoked(uint256 indexed tokenId, address indexed application);
    event ApplicationRegistered(address indexed application, string name);
    event ApplicationVerified(address indexed application);
    
    /**
     * @dev Initializes the contract
     * @param _erc007 The address of the ERC007 contract
     */
    function initialize(address _erc007) public initializer {
        __Ownable_init();
        
        require(_erc007 != address(0), "VaultPermissionManager: ERC007 is zero address");
        erc007 = _erc007;
    }
    
    /**
     * @dev Approves an application to access an agent's vault
     * @param tokenId The ID of the agent token
     * @param application The address of the application
     */
    function approveApplication(uint256 tokenId, address application) external {
        // Check that caller is the agent owner
        require(
            isAgentOwner(msg.sender, tokenId),
            "VaultPermissionManager: caller is not agent owner"
        );
        
        require(application != address(0), "VaultPermissionManager: application is zero address");
        require(
            _applicationMetadata[application].developer != address(0),
            "VaultPermissionManager: application not registered"
        );
        
        _approvedApplications[tokenId].add(application);
        
        emit ApplicationApproved(tokenId, application);
    }
    
    /**
     * @dev Revokes an application's access to an agent's vault
     * @param tokenId The ID of the agent token
     * @param application The address of the application
     */
    function revokeApplication(uint256 tokenId, address application) external {
        // Check that caller is the agent owner
        require(
            isAgentOwner(msg.sender, tokenId),
            "VaultPermissionManager: caller is not agent owner"
        );
        
        require(
            _approvedApplications[tokenId].contains(application),
            "VaultPermissionManager: application not approved"
        );
        
        _approvedApplications[tokenId].remove(application);
        
        emit ApplicationRevoked(tokenId, application);
    }
    
    /**
     * @dev Registers a new application
     * @param name The name of the application
     * @param description The description of the application
     * @param url The URL of the application
     */
    function registerApplication(
        string memory name,
        string memory description,
        string memory url
    ) external {
        require(
            _applicationMetadata[msg.sender].developer == address(0),
            "VaultPermissionManager: application already registered"
        );
        
        _applicationMetadata[msg.sender] = ApplicationMetadata({
            name: name,
            description: description,
            url: url,
            developer: msg.sender,
            verified: false
        });
        
        emit ApplicationRegistered(msg.sender, name);
    }
    
    /**
     * @dev Verifies an application (only owner)
     * @param application The address of the application
     */
    function verifyApplication(address application) external onlyOwner {
        require(
            _applicationMetadata[application].developer != address(0),
            "VaultPermissionManager: application not registered"
        );
        
        _applicationMetadata[application].verified = true;
        
        emit ApplicationVerified(application);
    }
    
    /**
     * @dev Generates a vault access token
     * @param tokenId The ID of the agent token
     * @param application The address of the application
     * @param expiration The expiration timestamp
     * @param signature The signature from the agent owner
     * @return accessToken The generated access token
     */
    function getVaultAccessToken(
        uint256 tokenId,
        address application,
        uint256 expiration,
        bytes memory signature
    ) external returns (bytes32) {
        require(
            _approvedApplications[tokenId].contains(application),
            "VaultPermissionManager: application not approved"
        );
        
        require(expiration > block.timestamp, "VaultPermissionManager: token expired");
        
        // Verify signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(tokenId, application, expiration, _vaultNonces[tokenId])
        );
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        
        require(
            isAgentOwner(signer, tokenId),
            "VaultPermissionManager: invalid signature"
        );
        
        // Increment nonce
        _vaultNonces[tokenId]++;
        
        // Generate access token
        bytes32 accessToken = keccak256(
            abi.encodePacked(tokenId, application, block.timestamp, _vaultNonces[tokenId] - 1)
        );
        
        return accessToken;
    }
    
    /**
     * @dev Checks if an address is the owner of an agent
     * @param owner The address to check
     * @param tokenId The ID of the agent token
     * @return True if the address is the owner, false otherwise
     */
    function isAgentOwner(address owner, uint256 tokenId) public view returns (bool) {
        // Call ERC007 contract to check ownership
        (bool success, bytes memory data) = erc007.staticcall(
            abi.encodeWithSignature("ownerOf(uint256)", tokenId)
        );
        
        if (!success || data.length == 0) {
            return false;
        }
        
        address tokenOwner = abi.decode(data, (address));
        return owner == tokenOwner;
    }
    
    /**
     * @dev Gets all approved applications for an agent
     * @param tokenId The ID of the agent token
     * @return An array of approved application addresses
     */
    function getApprovedApplications(uint256 tokenId) external view returns (address[] memory) {
        return _approvedApplications[tokenId].values();
    }
    
    /**
     * @dev Gets the metadata for an application
     * @param application The address of the application
     * @return The application's metadata
     */
    function getApplicationMetadata(address application) external view returns (ApplicationMetadata memory) {
        return _applicationMetadata[application];
    }
    
    /**
     * @dev Checks if an application is approved for an agent
     * @param tokenId The ID of the agent token
     * @param application The address of the application
     * @return True if the application is approved, false otherwise
     */
    function isApplicationApproved(uint256 tokenId, address application) external view returns (bool) {
        return _approvedApplications[tokenId].contains(application);
    }
    
    /**
     * @dev Gets the current nonce for an agent's vault
     * @param tokenId The ID of the agent token
     * @return The current nonce
     */
    function getVaultNonce(uint256 tokenId) external view returns (uint256) {
        return _vaultNonces[tokenId];
    }
    
    /**
     * @dev Sets the ERC007 contract address (only owner)
     * @param _erc007 The new ERC007 address
     */
    function setERC007(address _erc007) external onlyOwner {
        require(_erc007 != address(0), "VaultPermissionManager: ERC007 is zero address");
        erc007 = _erc007;
    }
}
