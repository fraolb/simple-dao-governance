// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract TimeLockTest is Test {
    TimeLock timeLock;
    address deployer = address(this);
    address proposer = address(0x1);
    address executor = address(0x2);
    address nonProposer = address(0x3);
    address nonExecutor = address(0x4);
    uint256 minDelay = 1 days;

    bytes32 public constant TIMELOCK_ADMIN_ROLE =
        keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    function setUp() public {
        // Deploy the TimeLock contract
        address;
        proposers[0] = proposer;

        address;
        executors[0] = executor;

        timeLock = new TimeLock(minDelay, proposers, executors);
    }

    function testDeployment() public {
        // Check the minimum delay
        assertEq(timeLock.getMinDelay(), minDelay);

        // Verify the roles for proposer and executor
        assertTrue(timeLock.hasRole(PROPOSER_ROLE, proposer));
        assertTrue(timeLock.hasRole(EXECUTOR_ROLE, executor));

        // Verify non-proposer and non-executor do not have roles
        assertFalse(timeLock.hasRole(PROPOSER_ROLE, nonProposer));
        assertFalse(timeLock.hasRole(EXECUTOR_ROLE, nonExecutor));
    }

    function testProposeAndExecute() public {
        // Define the target, value, and data for the transaction
        address target = address(this);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature("dummyFunction()");

        // Generate the operation ID (hash of the operation)
        bytes32 operationId = keccak256(
            abi.encode(target, value, data, bytes32(0), keccak256(""), minDelay)
        );

        // Schedule the operation with proposer privileges
        vm.prank(proposer);
        timeLock.schedule(
            target,
            value,
            data,
            bytes32(0),
            keccak256(""),
            minDelay
        );

        // Fast-forward time to meet the minimum delay
        vm.warp(block.timestamp + minDelay);

        // Execute the operation with executor privileges
        vm.prank(executor);
        timeLock.execute(target, value, data, bytes32(0), keccak256(""));

        // Verify that the operation has been executed
        assertTrue(timeLock.isOperationDone(operationId));
    }
}
