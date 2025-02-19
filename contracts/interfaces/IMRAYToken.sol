// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMRAYToken {
    function setTreasury(address newTreasury) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
