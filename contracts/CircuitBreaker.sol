// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title CircuitBreaker
 * @dev Emergency circuit breaker for the ERC-007 ecosystem
 * Provides a centralized mechanism to pause critical contracts in case of emergencies
 */
contract CircuitBreaker is Initializable, OwnableUpgradeable {
    // ERC007 contract address
    address public erc007;
    
    // Governance contract address
    address public governance;
    
    // Treasury contract address
    address public treasury;
    
    // Emergency council addresses
    mapping(address => bool) public emergencyCouncil;
    
    // Number of council members
    uint256 public councilSize;
    
    // Threshold of council members required to trigger emergency pause
    uint256 public emergencyThreshold;
    
    // Emergency state
    bool public emergencyActive;
    
    // Mapping to track council votes for emergency activation
    mapping(address => bool) public emergencyVotes;
    
    // Current vote count
    uint256 public currentVoteCount;
    
    // Events
    event EmergencyActivated(address indexed activator);
    event EmergencyDeactivated(address indexed deactivator);
    event CouncilMemberAdded(address indexed member);
    event CouncilMemberRemoved(address indexed member);
    event ThresholdUpdated(uint256 newThreshold);
    
    /**
     * @dev Modifier to check if the caller is a council member
     */
    modifier onlyCouncil() {
        require(emergencyCouncil[msg.sender], "CircuitBreaker: caller is not council member");
        _;
    }
    
    /**
     * @dev Modifier to check if the caller is the governance contract
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "CircuitBreaker: caller is not governance");
        _;
    }
    
    /**
     * @dev Initializes the contract
     * @param _erc007 The address of the ERC007 contract
     * @param _governance The address of the governance contract
     * @param _treasury The address of the treasury contract
     * @param initialCouncil Array of initial council member addresses
     */
    function initialize(
        address _erc007,
        address _governance,
        address _treasury,
        address[] memory initialCouncil
    ) public initializer {
        __Ownable_init();
        
        require(_erc007 != address(0), "CircuitBreaker: ERC007 is zero address");
        require(_governance != address(0), "CircuitBreaker: governance is zero address");
        require(_treasury != address(0), "CircuitBreaker: treasury is zero address");
        require(initialCouncil.length > 0, "CircuitBreaker: no council members");
        
        erc007 = _erc007;
        governance = _governance;
        treasury = _treasury;
        
        // Add initial council members
        for (uint256 i = 0; i < initialCouncil.length; i++) {
            require(initialCouncil[i] != address(0), "CircuitBreaker: council member is zero address");
            emergencyCouncil[initialCouncil[i]] = true;
        }
        
        councilSize = initialCouncil.length;
        emergencyThreshold = (councilSize * 2) / 3; // 2/3 majority
        
        if (emergencyThreshold == 0) {
            emergencyThreshold = 1; // Ensure at least 1 vote is required
        }
        
        emergencyActive = false;
        currentVoteCount = 0;
    }
    
    /**
     * @dev Votes to activate emergency mode
     */
    function voteForEmergency() external onlyCouncil {
        require(!emergencyActive, "CircuitBreaker: emergency already active");
        require(!emergencyVotes[msg.sender], "CircuitBreaker: already voted");
        
        emergencyVotes[msg.sender] = true;
        currentVoteCount++;
        
        // Check if threshold is reached
        if (currentVoteCount >= emergencyThreshold) {
            _activateEmergency();
        }
    }
    
    /**
     * @dev Activates emergency mode immediately (only owner)
     */
    function activateEmergency() external onlyOwner {
        require(!emergencyActive, "CircuitBreaker: emergency already active");
        _activateEmergency();
    }
    
    /**
     * @dev Internal function to activate emergency mode
     */
    function _activateEmergency() internal {
        emergencyActive = true;
        
        // Pause ERC007
        (bool success, ) = erc007.call(
            abi.encodeWithSignature("setGlobalPause(bool)", true)
        );
        require(success, "CircuitBreaker: failed to pause ERC007");
        
        emit EmergencyActivated(msg.sender);
    }
    
    /**
     * @dev Deactivates emergency mode (only owner)
     */
    function deactivateEmergency() external onlyOwner {
        require(emergencyActive, "CircuitBreaker: emergency not active");
        
        emergencyActive = false;
        
        // Reset votes
        for (uint256 i = 0; i < councilSize; i++) {
            address member = getCouncilMemberAtIndex(i);
            if (member != address(0)) {
                emergencyVotes[member] = false;
            }
        }
        
        currentVoteCount = 0;
        
        // Unpause ERC007
        (bool success, ) = erc007.call(
            abi.encodeWithSignature("setGlobalPause(bool)", false)
        );
        require(success, "CircuitBreaker: failed to unpause ERC007");
        
        emit EmergencyDeactivated(msg.sender);
    }
    
    /**
     * @dev Adds a council member (only governance)
     * @param member The address of the new council member
     */
    function addCouncilMember(address member) external onlyGovernance {
        require(member != address(0), "CircuitBreaker: member is zero address");
        require(!emergencyCouncil[member], "CircuitBreaker: already council member");
        
        emergencyCouncil[member] = true;
        councilSize++;
        
        // Update threshold
        emergencyThreshold = (councilSize * 2) / 3;
        if (emergencyThreshold == 0) {
            emergencyThreshold = 1;
        }
        
        emit CouncilMemberAdded(member);
        emit ThresholdUpdated(emergencyThreshold);
    }
    
    /**
     * @dev Removes a council member (only governance)
     * @param member The address of the council member to remove
     */
    function removeCouncilMember(address member) external onlyGovernance {
        require(emergencyCouncil[member], "CircuitBreaker: not council member");
        
        emergencyCouncil[member] = false;
        councilSize--;
        
        // Update threshold
        emergencyThreshold = (councilSize * 2) / 3;
        if (emergencyThreshold == 0 && councilSize > 0) {
            emergencyThreshold = 1;
        }
        
        // If member had voted, reduce vote count
        if (emergencyVotes[member]) {
            emergencyVotes[member] = false;
            currentVoteCount--;
        }
        
        emit CouncilMemberRemoved(member);
        emit ThresholdUpdated(emergencyThreshold);
    }
    
    /**
     * @dev Sets the emergency threshold (only governance)
     * @param newThreshold The new threshold value
     */
    function setEmergencyThreshold(uint256 newThreshold) external onlyGovernance {
        require(newThreshold > 0, "CircuitBreaker: threshold must be positive");
        require(newThreshold <= councilSize, "CircuitBreaker: threshold exceeds council size");
        
        emergencyThreshold = newThreshold;
        
        emit ThresholdUpdated(newThreshold);
    }
    
    /**
     * @dev Gets a council member at a specific index
     * @param index The index to check
     * @return The address of the council member
     */
    function getCouncilMemberAtIndex(uint256 index) public view returns (address) {
        uint256 count = 0;
        for (uint256 i = 0; i < 1000; i++) { // Arbitrary limit to prevent infinite loops
            address potentialMember = address(uint160(i + 1)); // Start from 1 to avoid address(0)
            if (emergencyCouncil[potentialMember]) {
                if (count == index) {
                    return potentialMember;
                }
                count++;
            }
            
            if (count > index) {
                break;
            }
        }
        return address(0);
    }
    
    /**
     * @dev Sets the ERC007 contract address (only owner)
     * @param _erc007 The new ERC007 address
     */
    function setERC007(address _erc007) external onlyOwner {
        require(_erc007 != address(0), "CircuitBreaker: ERC007 is zero address");
        erc007 = _erc007;
    }
    
    /**
     * @dev Sets the governance address (only owner)
     * @param _governance The new governance address
     */
    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "CircuitBreaker: governance is zero address");
        governance = _governance;
    }
    
    /**
     * @dev Sets the treasury address (only owner)
     * @param _treasury The new treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "CircuitBreaker: treasury is zero address");
        treasury = _treasury;
    }
}
