// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PropertyRegistry} from "../src/PropertyRegistry.sol";

contract PropertyRegistryTest is Test {
    PropertyRegistry internal registry;

    address internal admin;
    address internal alice;
    address internal bob;
    address internal attacker;

    string internal constant PROPERTY_URI = "ipfs://QmExamplePropertyMetadata";

    function setUp() public {
        admin = makeAddr("admin");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        attacker = makeAddr("attacker");

        registry = new PropertyRegistry(admin);
    }

    function testInitialOwnerIsAdmin() public view {
        assertEq(registry.owner(), admin);
    }

    function testDeploymentChainIdIsStored() public view {
        assertEq(registry.DEPLOYMENT_CHAIN_ID(), block.chainid);
    }

    function testRegisterProperty() public {
        vm.prank(alice);

        uint256 propertyId = registry.registerProperty(PROPERTY_URI, 100 ether);

        PropertyRegistry.Property memory property = registry.getProperty(propertyId);

        assertEq(propertyId, 0);
        assertEq(property.owner, alice);
        assertEq(property.price, 100 ether);
        assertEq(property.propertyURI, PROPERTY_URI);
        assertEq(property.registeredAt, block.timestamp);
        assertEq(registry.propertyCount(), 1);
    }

    function testRegisterPropertyEmitsEvent() public {
        vm.expectEmit(true, true, false, true);

        emit PropertyRegistry.PropertyRegistered(0, alice, 100 ether, PROPERTY_URI);

        vm.prank(alice);

        registry.registerProperty(PROPERTY_URI, 100 ether);
    }

    function testCannotRegisterEmptyURI() public {
        vm.prank(alice);

        vm.expectRevert(PropertyRegistry.EmptyPropertyURI.selector);

        registry.registerProperty("", 100 ether);
    }

    function testCannotRegisterZeroPrice() public {
        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSelector(PropertyRegistry.InvalidPrice.selector, 0));

        registry.registerProperty(PROPERTY_URI, 0);
    }

    function testTransferPropertyOwnership() public {
        vm.prank(alice);
        registry.registerProperty(PROPERTY_URI, 100 ether);

        vm.expectEmit(true, true, true, true);

        emit PropertyRegistry.PropertyOwnershipTransferred(0, alice, bob);

        vm.prank(alice);
        registry.transferPropertyOwnership(0, bob);

        PropertyRegistry.Property memory property = registry.getProperty(0);

        assertEq(property.owner, bob);
    }

    function testUnauthorizedUserCannotTransferProperty() public {
        vm.prank(alice);
        registry.registerProperty(PROPERTY_URI, 100 ether);

        vm.prank(attacker);

        vm.expectRevert(abi.encodeWithSelector(PropertyRegistry.NotPropertyOwner.selector, 0, attacker, alice));

        registry.transferPropertyOwnership(0, bob);
    }

    function testCannotTransferToZeroAddress() public {
        vm.prank(alice);
        registry.registerProperty(PROPERTY_URI, 100 ether);

        vm.prank(alice);

        vm.expectRevert(PropertyRegistry.ZeroAddress.selector);

        registry.transferPropertyOwnership(0, address(0));
    }

    function testCannotTransferToSameOwner() public {
        vm.prank(alice);
        registry.registerProperty(PROPERTY_URI, 100 ether);

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSelector(PropertyRegistry.SameOwner.selector, alice));

        registry.transferPropertyOwnership(0, alice);
    }

    function testNonexistentPropertyReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PropertyRegistry.PropertyNotFound.selector, 999));

        registry.getProperty(999);
    }

    function testOwnerCanPause() public {
        vm.prank(admin);
        registry.pause();

        assertTrue(registry.paused());
    }

    function testRegistrationRevertsWhenPaused() public {
        vm.prank(admin);
        registry.pause();

        vm.prank(alice);

        vm.expectRevert();

        registry.registerProperty(PROPERTY_URI, 100 ether);
    }

    function testOwnerCanUnpause() public {
        vm.startPrank(admin);

        registry.pause();
        registry.unpause();

        vm.stopPrank();

        assertFalse(registry.paused());
    }

    function testFuzzRegisterProperty(address user, uint256 price) public {
        vm.assume(user != address(0));

        price = bound(price, 1, type(uint128).max);

        vm.prank(user);

        uint256 propertyId = registry.registerProperty(PROPERTY_URI, price);

        PropertyRegistry.Property memory property = registry.getProperty(propertyId);

        assertEq(propertyId, 0);
        assertEq(property.owner, user);
        assertEq(property.price, price);
        assertEq(property.propertyURI, PROPERTY_URI);
        assertEq(registry.propertyCount(), 1);
    }

    function testFuzzTransferPropertyOwnership(address originalOwner, address newOwner, uint256 price) public {
        vm.assume(originalOwner != address(0));
        vm.assume(newOwner != address(0));
        vm.assume(originalOwner != newOwner);

        price = bound(price, 1, type(uint128).max);

        vm.prank(originalOwner);

        registry.registerProperty(PROPERTY_URI, price);

        vm.prank(originalOwner);

        registry.transferPropertyOwnership(0, newOwner);

        PropertyRegistry.Property memory property = registry.getProperty(0);

        assertEq(property.owner, newOwner);
        assertEq(property.price, price);
        assertEq(property.propertyURI, PROPERTY_URI);
    }
}
