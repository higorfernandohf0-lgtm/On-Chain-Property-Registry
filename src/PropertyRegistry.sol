// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title On-Chain Property Registry
/// @author Higor Fernando
/// @notice Registry for recording property metadata and ownership on-chain.
/// @dev Property documents and descriptive metadata should remain off-chain
///      and be referenced through an IPFS-compatible URI.
contract PropertyRegistry is Ownable2Step, Pausable {
    error PropertyNotFound(uint256 propertyId);

    error NotPropertyOwner(uint256 propertyId, address caller, address currentOwner);

    error ZeroAddress();
    error EmptyPropertyURI();
    error InvalidPrice(uint256 price);
    error SameOwner(address owner);

    /// @notice Represents a registered property.
    /// @dev owner and registeredAt are packed into the same storage slot.
    struct Property {
        uint256 price;
        address owner;
        uint40 registeredAt;
        string propertyURI;
    }

    /// @notice Chain ID where this registry was deployed.
    uint256 public immutable DEPLOYMENT_CHAIN_ID;

    uint256 private _nextPropertyId;

    mapping(uint256 propertyId => Property property) private _properties;

    event PropertyRegistered(uint256 indexed propertyId, address indexed owner, uint256 price, string propertyURI);

    event PropertyOwnershipTransferred(
        uint256 indexed propertyId, address indexed previousOwner, address indexed newOwner
    );

    /// @param initialOwner Address that receives administrative ownership.
    /// @dev OpenZeppelin Ownable rejects address(0) automatically.
    constructor(address initialOwner) Ownable(initialOwner) {
        DEPLOYMENT_CHAIN_ID = block.chainid;
    }

    /// @notice Registers a new property.
    /// @param propertyURI URI referencing the property's off-chain metadata.
    /// @param price Property valuation in the application's chosen base unit.
    /// @return propertyId Identifier assigned to the property.
    function registerProperty(string calldata propertyURI, uint256 price)
        external
        whenNotPaused
        returns (uint256 propertyId)
    {
        if (bytes(propertyURI).length == 0) {
            revert EmptyPropertyURI();
        }

        if (price == 0) {
            revert InvalidPrice(price);
        }

        propertyId = _nextPropertyId;

        _properties[propertyId] = Property({
            price: price, owner: msg.sender, registeredAt: uint40(block.timestamp), propertyURI: propertyURI
        });

        _nextPropertyId = propertyId + 1;

        emit PropertyRegistered(propertyId, msg.sender, price, propertyURI);
    }

    /// @notice Transfers a registered property's ownership.
    /// @param propertyId Identifier of the property.
    /// @param newOwner Address that will receive ownership.
    function transferPropertyOwnership(uint256 propertyId, address newOwner) external whenNotPaused {
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        Property storage property = _getPropertyStorage(propertyId);

        address currentOwner = property.owner;

        if (msg.sender != currentOwner) {
            revert NotPropertyOwner(propertyId, msg.sender, currentOwner);
        }

        if (newOwner == currentOwner) {
            revert SameOwner(currentOwner);
        }

        property.owner = newOwner;

        emit PropertyOwnershipTransferred(propertyId, currentOwner, newOwner);
    }

    /// @notice Returns the stored information for a property.
    /// @param propertyId Identifier of the property.
    function getProperty(uint256 propertyId) external view returns (Property memory) {
        return _getPropertyStorage(propertyId);
    }

    /// @notice Returns the number of registered properties.
    function propertyCount() external view returns (uint256) {
        return _nextPropertyId;
    }

    /// @notice Pauses property registration and ownership transfers.
    /// @dev Only the administrative owner may call this function.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resumes property registration and ownership transfers.
    /// @dev Only the administrative owner may call this function.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Returns a storage reference after validating property existence.
    function _getPropertyStorage(uint256 propertyId) internal view returns (Property storage property) {
        if (propertyId >= _nextPropertyId) {
            revert PropertyNotFound(propertyId);
        }

        property = _properties[propertyId];
    }
}
