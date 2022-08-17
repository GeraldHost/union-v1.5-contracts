//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./UserManager.sol";
import "../interfaces/IDai.sol";

contract UserManagerDAI is UserManager {
    /**
     *  @dev Stake using DAI permit
     *  @param amount Amount to stake
     *  @param nonce Nonce
     *  @param expiry Timestamp for when the permit expires
     *  @param v secp256k1 signature part
     *  @param r secp256k1 signature part
     *  @param s secp256k1 signature part
     */
    function stakeWithPermit(
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused {
        IDai erc20Token = IDai(stakingToken);
        erc20Token.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);

        stake(uint96(amount));
    }
}
