//SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    //some list of addressess
    using SafeERC20 for IERC20;
    //Allow someone  in the list of tokens

    address[] claimers;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;
    mapping(address => bool) private s_hasClaimed;

    // Events
    event Claim(address indexed account, uint256 amount);

    // Errors
    error MerkleAirdrop_InvalidProof();
    error MerkleAirdrop_AlreadyClaimed();

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // CHECK if already claimed
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop_AlreadyClaimed();
        }
        // CHECK Merkle proof
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }

        // EFFECT - update state
        s_hasClaimed[account] = true;
        emit Claim(account, amount);

        // INTERACTION - external call
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }
}

