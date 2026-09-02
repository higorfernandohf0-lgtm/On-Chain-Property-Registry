// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PropertyRegistry} from "../src/PropertyRegistry.sol";

contract Deploy is Script {
    function run() external returns (PropertyRegistry registry) {
        address initialOwner = vm.envAddress("INITIAL_OWNER");

        vm.startBroadcast();

        registry = new PropertyRegistry(initialOwner);

        vm.stopBroadcast();
    }
}
