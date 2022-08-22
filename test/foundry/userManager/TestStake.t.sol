pragma solidity ^0.8.0;
import {TestUserManagerBase} from "./TestUserManagerBase.sol";
import {UserManager} from "union-v1.5-contracts/user/UserManager.sol";
import {AssetManager} from "union-v1.5-contracts/asset/AssetManager.sol";

contract TestStakeAndUnstake is TestUserManagerBase {
    function setUp() public override {
        super.setUp();
    }

    function testCannotStakeAboveLimit(uint96 amount) public {
        vm.assume(amount > 10000 ether);
        vm.expectRevert("UNION#104");
        userManager.stake(amount);
    }

    function testCannotStakeWhenDepositFailed(uint96 amount) public {
        vm.assume(amount <= 100 ether);
        vm.mockCall(
            address(assetManagerMock),
            abi.encodeWithSelector(AssetManager.deposit.selector, daiMock, amount),
            abi.encode(false)
        );
        vm.expectRevert("UNION#105");
        userManager.stake(amount);
        vm.clearMockedCalls();
    }

    function testStake(uint96 amount) public {
        vm.assume(amount <= 100 ether && amount > 0);
        vm.prank(MEMBER);
        userManager.stake(amount);
        uint256 stakeAmount = userManager.getStakerBalance(MEMBER);
        assertEq(stakeAmount, amount);
    }

    function testCannotUnstakeAboveStake(uint96 amount) public {
        vm.assume(amount <= 100 ether && amount > 0);
        vm.startPrank(MEMBER);
        userManager.stake(amount);
        vm.expectRevert("UNION#402");
        userManager.unstake(amount + 1);
        vm.stopPrank();
    }

    function testCannotUnstakeWhenWithdrawFailed(uint96 amount) public {
        vm.assume(amount <= 100 ether && amount > 0);
        vm.startPrank(MEMBER);
        userManager.stake(amount);
        vm.mockCall(
            address(assetManagerMock),
            abi.encodeWithSelector(AssetManager.withdraw.selector, daiMock, MEMBER, amount),
            abi.encode(false)
        );
        vm.expectRevert("UNION#106");
        userManager.unstake(amount);
        vm.stopPrank();
        vm.clearMockedCalls();
    }

    function testUnstake(uint96 amount) public {
        vm.assume(amount <= 100 ether && amount > 0);
        vm.startPrank(MEMBER);
        userManager.stake(amount);
        userManager.unstake(amount);
        uint256 stakeAmount = userManager.getStakerBalance(MEMBER);
        assertEq(stakeAmount, 0);
        vm.stopPrank();
    }
}
