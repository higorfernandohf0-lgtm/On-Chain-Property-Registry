// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PropertyRegistry} from "../src/PropertyRegistry.sol";

contract PropertyRegistryTest is Test {
    PropertyRegistry registry;

    address owner = address(1);
    address newOwner = address(2);
    address attacker = address(3);

    function setUp() public {
        registry = new PropertyRegistry();
    }

    function testRegisterProperty() public {
        vm.prank(owner);

        registry.registerProperty("123 Main Street", 100 ether);

        (string memory propertyAddress, address propertyOwner, uint256 price) = registry.getProperty(0);

        assertEq(propertyAddress, "123 Main Street");
        assertEq(propertyOwner, owner);
        assertEq(price, 100 ether);
    }

    function testTransferOwnership() public {
        vm.prank(owner);

        registry.registerProperty("123 Main Street", 100 ether);

        vm.prank(owner);

        registry.transferOwnership(0, newOwner);

        (, address propertyOwner,) = registry.getProperty(0);

        assertEq(propertyOwner, newOwner);
    }

    function testOnlyOwnerCanTransfer() public {
        vm.prank(owner);

        registry.registerProperty("123 Main Street", 100 ether);

        vm.prank(attacker);

        vm.expectRevert(bytes("Only owner can transfer ownership"));

        registry.transferOwnership(0, newOwner);
    }
}
