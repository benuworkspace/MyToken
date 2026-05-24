// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

/// @title DeployMyToken
/// @notice Script untuk deploy MyToken ke network manapun
/// @dev Jalankan dengan: forge script script/DeployMyToken.s.sol
contract DeployMyToken is Script {

    // ─── Konfigurasi Deploy ───────────────────────────────────────

    // Initial supply: 1 juta token
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;

    // ─── Main Deploy Function ─────────────────────────────────────

    function run() public returns (MyToken token) {

        // Ambil private key dari environment variable
        // JANGAN pernah hardcode private key di sini
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Ambil address deployer dari private key
        address deployer = vm.addr(deployerPrivateKey);

        // Log info sebelum deploy
        console.log("================================================================================");
        console.log("                               Deploying MyToken                                ");
        console.log("================================================================================");
        console.log("Deployer        :", deployer);
        console.log("Initial Supply  :", INITIAL_SUPPLY / 1e18, "MET");
        console.log("Network Chain ID:", block.chainid);
        console.log("================================================================================");
        console.log("                                                                                ");
        console.log("................................................................................");
        console.log("                                                                                ");

        // vm.startBroadcast → semua transaksi di sini akan dikirim ke network
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contract
        token = new MyToken(INITIAL_SUPPLY);

        // vm.stopBroadcast → selesai broadcast
        vm.stopBroadcast();

        // Log hasil deploy
        console.log("================================================================================");
        console.log("                               Deploy Successful!                               ");
        console.log("================================================================================");
        console.log("Contract Address :", address(token));
        console.log("Token Name       :", token.name());
        console.log("Token Symbol     :", token.symbol());
        console.log("Total Supply     :", token.totalSupply() / 1e18, "MET");
        console.log("Owner            :", token.owner());
        console.log("================================================================================");
        console.log("Etherscan        :");
        console.log(
            string(abi.encodePacked(
                "https://sepolia.etherscan.io/address/",
                vm.toString(address(token))
            ))
        );
        console.log("================================================================================");

        return token;
    }
}