pragma solidity ^0.8.0;

import {TestWrapper} from "../TestWrapper.sol";
import {PureTokenAdapter} from "union-v1.5-contracts/asset/PureTokenAdapter.sol";

contract TestPureTokenAdapter is TestWrapper {
    PureTokenAdapter public pureToken;

    function setUp() public virtual {
        address logic = address(new PureTokenAdapter());

        deployMocks();

        pureToken = PureTokenAdapter(
            deployProxy(logic, abi.encodeWithSignature("__PureTokenAdapter_init(address)", [address(assetManagerMock)]))
        );
    }

    function supplyToken(uint256 supplyAmount) public {
        daiMock.mint(address(pureToken), supplyAmount);
    }

    function testSetAssetManager(address assetManager) public {
        pureToken.setAssetManager(assetManager);
        assertEq(assetManager, pureToken.assetManager());
    }

    function testCannotSetAssetManagerNonAdmin() public {
        vm.prank(address(1));
        vm.expectRevert("Controller: not admin");
        pureToken.setAssetManager(address(1));
    }

    function testSetFloor(address token, uint256 amount) public {
        pureToken.setFloor(token, amount);
        assertEq(pureToken.floorMap(token), amount);
    }

    function testCannotSetFloorNonAdmin() public {
        vm.prank(address(1));
        vm.expectRevert("Controller: not admin");
        pureToken.setFloor(address(1), 0);
    }

    function testSetCeiling(address token, uint256 amount) public {
        pureToken.setCeiling(token, amount);
        assertEq(pureToken.ceilingMap(token), amount);
    }

    function testCannotSetCeilingNonAdmin() public {
        vm.prank(address(1));
        vm.expectRevert("Controller: not admin");
        pureToken.setCeiling(address(1), 0);
    }

    function testGetRate() public {
        assertEq(0, pureToken.getRate(address(0)));
    }

    function testGetSupply(uint256 amount) public {
        supplyToken(amount);
        assertEq(amount, pureToken.getSupply(address(daiMock)));
    }

    function testGetSupplyView(uint256 amount) public {
        supplyToken(amount);
        assertEq(amount, pureToken.getSupplyView(address(daiMock)));
    }

    function testSupportsToken() public {
        vm.expectRevert();
        pureToken.supportsToken(address(pureToken));
        assert(pureToken.supportsToken(address(daiMock)));
    }

    function testDeposit() public {
        // nothing to assert just check this passes
        pureToken.deposit(address(daiMock));
    }

    function testCannotDepositUnsupportedToken() public {
        vm.expectRevert();
        pureToken.deposit(address(pureToken));
    }

    function testWithdraw(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0));
        daiMock.mint(address(pureToken), amount);
        assertEq(daiMock.balanceOf(recipient), 0);
        vm.prank(pureToken.assetManager());
        pureToken.withdraw(address(daiMock), recipient, amount);
        assertEq(daiMock.balanceOf(recipient), amount);
    }

    function testCannotWithdrawNonAssetManager(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0));
        daiMock.mint(address(pureToken), amount);
        vm.expectRevert("PureTokenAdapter: only asset manager can call");
        pureToken.withdraw(address(daiMock), recipient, amount);
    }

    function testWithdrawAll(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0));
        daiMock.mint(address(pureToken), amount);
        assertEq(daiMock.balanceOf(recipient), 0);
        vm.prank(pureToken.assetManager());
        pureToken.withdrawAll(address(daiMock), recipient);
        assertEq(daiMock.balanceOf(recipient), amount);
    }

    function testCannotWithdrawAllNonAssetManager(address recipient, uint256 amount) public {
        daiMock.mint(address(pureToken), amount);
        vm.expectRevert("PureTokenAdapter: only asset manager can call");
        pureToken.withdrawAll(address(daiMock), recipient);
    }

    function testClaimTokens(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0));
        daiMock.mint(address(pureToken), amount);
        assertEq(daiMock.balanceOf(recipient), 0);
        vm.prank(pureToken.assetManager());
        pureToken.claimTokens(address(daiMock), recipient);
        assertEq(daiMock.balanceOf(recipient), amount);
    }
    
    function testCannotClaimTokensNonAssetManager(address recipient, uint256 amount) public {
        daiMock.mint(address(pureToken), amount);
        vm.expectRevert("PureTokenAdapter: only asset manager can call");
        pureToken.claimTokens(address(daiMock), recipient);
    }

    function testClaimRewards() public {
        // nothing to assert just check this passes
        pureToken.claimRewards(address(daiMock));
    }

}
