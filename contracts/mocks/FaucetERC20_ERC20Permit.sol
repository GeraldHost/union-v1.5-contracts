//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract FaucetERC20_ERC20Permit is ERC20Permit {
    constructor(string memory name_, string memory symbol_) public ERC20Permit(name_, symbol_) {}

    function mint(address account, uint256 mintAmount) external {
        _mint(account, mintAmount);
    }
}
