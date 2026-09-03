// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PropertyRegistry} from "../../src/PropertyRegistry.sol";
import {PropertyRegistryHandler} from "./PropertyRegistryHandler.sol";

contract PropertyRegistryInvariantTest is Test {
    PropertyRegistry internal registry;
    PropertyRegistryHandler internal handler;

    address internal admin;

    function setUp() public {
        admin = makeAddr("admin");

        registry = new PropertyRegistry(admin);
        handler = new PropertyRegistryHandler(registry);

        targetContract(address(handler));
    }

    function invariantPropertyOwnersNeverZero() public view {
        uint256 count = registry.propertyCount();

        for (uint256 i; i < count; ++i) {
            PropertyRegistry.Property memory property = registry.getProperty(i);

            assertTrue(property.owner != address(0));
        }
    }

    function invariantPropertyPricesNeverZero() public view {
        uint256 count = registry.propertyCount();

        for (uint256 i; i < count; ++i) {
            PropertyRegistry.Property memory property = registry.getProperty(i);

            assertGt(property.price, 0);
        }
    }

    function invariantPropertyURIsNeverEmpty() public view {
        uint256 count = registry.propertyCount();

        for (uint256 i; i < count; ++i) {
            PropertyRegistry.Property memory property = registry.getProperty(i);

            assertGt(bytes(property.propertyURI).length, 0);
        }
    }

    function invariantRegisteredPropertiesAreReadable() public view {
        uint256 count = registry.propertyCount();

        for (uint256 i; i < count; ++i) {
            PropertyRegistry.Property memory property = registry.getProperty(i);

            assertTrue(property.registeredAt > 0);
        }
    }
}
