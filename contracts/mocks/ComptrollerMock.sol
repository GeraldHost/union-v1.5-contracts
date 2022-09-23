//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IComptroller} from "../interfaces/IComptroller.sol";

contract ComptrollerMock is IComptroller {
    function setHalfDecayPoint(uint256 point) external {}

    function inflationPerBlock(uint256 effectiveTotalStake) external view returns (uint256) {}

    function getRewardsMultiplier(address, address) external pure override returns (uint256) {
        return 0;
    }

    function getUTokenRewardsMultiplier() external pure override returns (uint256) {
        return 0;
    }

    function withdrawRewards(address, address) external pure override returns (uint256) {
        return 0;
    }

    function withdrawUTokenRewards(address) external pure override returns (uint256) {
        return 0;
    }

    function updateTotalStaked(address, uint256) external pure override returns (bool) {
        return false;
    }

    function calculateRewardsByBlocks(
        address,
        address,
        uint256
    ) external pure override returns (uint256) {
        return 0;
    }

    function calculateUTokenRewardsByBlocks(
        address,
        address,
        uint256
    ) external pure override returns (uint256) {
        return 0;
    }

    function calculateRewards(address, address) external pure override returns (uint256) {
        return 0;
    }
}
