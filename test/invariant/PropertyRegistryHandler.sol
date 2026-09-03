// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PropertyRegistry} from "../../src/PropertyRegistry.sol";

contract PropertyRegistryHandler is Test {
    PropertyRegistry internal immutable registry;

    uint256 internal constant MAX_PROPERTIES = 25;

    string internal constant PROPERTY_URI = "ipfs://QmInvariantPropertyMetadata";

    constructor(PropertyRegistry _registry) {
        registry = _registry;
    }

    function registerProperty(address user, uint256 price) external {
        if (registry.propertyCount() >= MAX_PROPERTIES) {
            return;
        }

        if (user == address(0)) {
            return;
        }

        price = bound(price, 1, type(uint128).max);

        vm.prank(user);

        registry.registerProperty(PROPERTY_URI, price);
    }

    function transferPropertyOwnership(uint256 propertyId, address newOwner) external {
        uint256 count = registry.propertyCount();

        if (count == 0) {
            return;
        }

        propertyId = bound(propertyId, 0, count - 1);

        PropertyRegistry.Property memory property = registry.getProperty(propertyId);

        if (newOwner == address(0) || newOwner == property.owner) {
            return;
        }

        vm.prank(property.owner);

        registry.transferPropertyOwnership(propertyId, newOwner);
    }
}
