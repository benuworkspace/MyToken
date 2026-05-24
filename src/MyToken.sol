// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title MyToken
/// @notice standar ERC20 token dengan ownership control
/// @dev inherit dari OpenZeppelin ERC20 dan Ownable
///      deploy cotract ini untuk mendapatkan token ERC20 standard
///@dev menggunakan openzeppelin ERC20Pausable untuk pause functionality
///
/// fitur:
/// - standard ERC20 (transfer, approve, transfer from)
/// - mint: hanya owner yang bisa cetak token baru
/// - burn: siapapun bisa bakar token miliknya sendiri
/// - burnFrom: owner bisa bakar token dari address manapun
/// - pause: owner bisa pause semua transfer dalam keadaan darurat
///
contract MyToken is ERC20, ERC20Pausable, Ownable {

    //__________Events_______________________
    ///@notice diemit saat owner minta token baru
    event TokensMinted(address indexed to, uint256 amount, uint256 newTotalSupply);

    ///@notice diemit saat token di burn
    event TokensBurned(address indexed from, uint256 amount, uint256 newTotalSupply);


    //__________Errors_______________________
    error MintToZeroAddress();
    error BurnAmountExceedsBalance(address account, uint256 balance, uint256 amount);
    error MaxSupplyExceeded();
    error ZeroAmount();


    //__________Constants_______________________
    ///@notice maksimum supply yang boleh beredar
    ///@dev set ke 100 juta token - bisa diubah sesuai kebutuhan
    uint256 public constant MAX_SUPPLY =100_000_000 * 1e18;


    //__________Constructor_______________________
    /// @notice deploy token dengan initialSupply ke deployer
    /// @param initialSupply jumlah token awal (dalam unit terkecil / wei)
    constructor(
        uint256 initialSupply
    )
        ERC20("My Example Token", "MET") //nama dan simbol token
        Ownable(msg.sender) //deployer adalah owner
    {
        if (initialSupply == 0) revert ZeroAmount();
        if (initialSupply > MAX_SUPPLY) revert MaxSupplyExceeded();

        // mint semua initial supply ke deloyer
        // _mint adalah internal function dari OpenZeppelin ERC20
        _mint(msg.sender, initialSupply);
    }


    //__________Mint (onlyOwner) Function_______________________
    ///@notice cetak token baru ke address tertentu
    ///@dev hanya owner yang bisa memanggil function ini
    ///@param to address penerima token baru
    ///@param amount jumlah token yang dicetak (dalam unit terkecil)
    function mint(address to, uint256 amount) external onlyOwner {
        //validasi
        if (to == address(0)) revert MintToZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxSupplyExceeded();

        // mint menggunakan internal function OpenZeppelin
        // _mint akan:
        // 1. tambah _totalSupply
        // 2. tambah _balance[to]
        // 3. emit event transfer(address(0), to, amount)
        _mint(to, amount);

        emit TokensMinted(to, amount, totalSupply());
    }


    //__________Pause (onlyOwner) Function_______________________
    ///@notice pause semua transfer token
    ///@dev gunakan hanya dalam keadaan darurat
    function pause() external onlyOwner {
        _pause();
    }


    //__________Unpause (onlyOwner) Function_______________________
    ///@notice unpause - kembalikan fungsi normal
    function unpause() external onlyOwner {
        _unpause();
    }


    //__________Burn Function_______________________
    ///@notice bakar token milik sendiri
    ///@dev siapaun bisa burn token milik mereka sendiri
    ///@param amount: jumlah token yang akan dibakar
    function burn(uint256 amount) external {
        //validasi
        if (amount == 0) revert ZeroAmount();
        if (balanceOf(msg.sender) < amount) {
            revert BurnAmountExceedsBalance(msg.sender, balanceOf(msg.sender), amount);
        }

        // _burn akan:
        // 1. kurangi _balances[msg.sender]
        // 2. kurangi _totalSupply
        // 3. Emit event Transfer(msg.sender, address(0), amount)
        _burn(msg.sender, amount);

        emit TokensBurned(msg.sender, amount, totalSupply());
    }


    //__________BurnFrom (onlyOwner) Function_______________________
    ///@notice owner bisa burn token dari address manapun
    ///@dev dipakai untuk complience atau emergency
    ///@param from address yang tokennya akan dibakar
    ///@param amount jumlah token yang akan dibakar
    function burnFrom(address from, uint256 amount) external onlyOwner {
        //validasi
        if (amount == 0) revert ZeroAmount();
        if (balanceOf(from) < amount) {
            revert BurnAmountExceedsBalance(from, balanceOf(from), amount);
        }

        _burn(from, amount);

        emit TokensBurned(from, amount, totalSupply());
    }


    //__________Internal Override_______________________
    ///@dev override _update untuk mengintergrasikan pause check
    ///ERC20Pausable bekerja dengan override _update ini -
    ///semua transfer (termasuk mint dan burn) akan dicek
    ///apakah contract sedang paused sebelum dieksekusi
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}