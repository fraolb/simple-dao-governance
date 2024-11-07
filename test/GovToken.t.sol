// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovTokenTest is Test {
    GovToken govToken;
    address deployer = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy the GovToken contract
        govToken = new GovToken();
    }

    function testDeployment() public {
        // Check name and symbol of the token
        assertEq(govToken.name(), "GovToken");
        assertEq(govToken.symbol(), "GT");
    }

    function testMinting() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Mint tokens to user1
        govToken.mint(user1, mintAmount);

        // Verify user1's balance
        assertEq(govToken.balanceOf(user1), mintAmount);
    }

    function testTransfer() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 500 * 10 ** 18;

        // Mint tokens to user1
        govToken.mint(user1, mintAmount);

        // User1 transfers tokens to user2
        vm.prank(user1);
        govToken.transfer(user2, transferAmount);

        // Verify balances of user1 and user2
        assertEq(govToken.balanceOf(user1), mintAmount - transferAmount);
        assertEq(govToken.balanceOf(user2), transferAmount);
    }

    function testPermit() public {
        uint256 permitAmount = 1000 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 days;

        // Generate a permit signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            uint256(uint160(user1)),
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    govToken.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            user1,
                            address(this),
                            permitAmount,
                            govToken.nonces(user1),
                            deadline
                        )
                    )
                )
            )
        );

        // Execute permit with the generated signature
        govToken.permit(user1, address(this), permitAmount, deadline, v, r, s);

        // Verify the allowance
        assertEq(govToken.allowance(user1, address(this)), permitAmount);
    }

    function testVotingDelegation() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Mint tokens to user1 and delegate to user2
        govToken.mint(user1, mintAmount);
        vm.prank(user1);
        govToken.delegate(user2);

        // Verify user2 has the voting power from user1
        assertEq(govToken.getVotes(user2), mintAmount);
    }
}
