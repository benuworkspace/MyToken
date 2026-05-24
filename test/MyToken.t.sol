// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {

    // ─── Setup ────────────────────────────────────────────────────

    MyToken public token;

    address public owner;
    address public user1;
    address public user2;
    address public spender;

    // Initial supply: 1 juta token
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;

    // Helper constant
    uint256 public constant ONE_TOKEN = 1e18;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 1e18;

    // Events untuk expectEmit
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensMinted(address indexed to, uint256 amount, uint256 newTotalSupply);
    event TokensBurned(address indexed from, uint256 amount, uint256 newTotalSupply);

    function setUp() public {
        owner   = address(this);
        user1   = makeAddr("user1");
        user2   = makeAddr("user2");
        spender = makeAddr("spender");

        token = new MyToken(INITIAL_SUPPLY);
    }

    // =============================================================
    //                    DEPLOYMENT TESTS
    // =============================================================

    function test_Deploy_Name() public view {
        assertEq(token.name(), "My Example Token");
    }

    function test_Deploy_Symbol() public view {
        assertEq(token.symbol(), "MET");
    }

    function test_Deploy_Decimals() public view {
        assertEq(token.decimals(), 18);
    }

    function test_Deploy_TotalSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_Deploy_OwnerBalance() public view {
        // Semua initial supply ada di owner
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function test_Deploy_Owner() public view {
        assertEq(token.owner(), owner);
    }

    function test_Deploy_NotPaused() public view {
        assertFalse(token.paused());
    }

    function test_Deploy_MaxSupply() public view {
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
    }

    function test_Deploy_RevertsIfZeroSupply() public {
        vm.expectRevert(MyToken.ZeroAmount.selector);  // ← Cara paling clean
        new MyToken(0);
    }

    // =============================================================
    //                    TRANSFER TESTS
    // =============================================================

    function test_Transfer_Success() public {
        uint256 amount = 100 * ONE_TOKEN;

        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function test_Transfer_EmitsEvent() public {
        uint256 amount = 100 * ONE_TOKEN;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, amount);

        token.transfer(user1, amount);
    }

    function test_Transfer_TotalSupplyUnchanged() public {
        // Transfer tidak ubah total supply
        token.transfer(user1, 100 * ONE_TOKEN);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_Transfer_RevertsIfInsufficientBalance() public {
        uint256 tooMuch = INITIAL_SUPPLY + 1;

        vm.expectRevert();
        token.transfer(user1, tooMuch);
    }

    function test_Transfer_RevertsToZeroAddress() public {
        vm.expectRevert();
        token.transfer(address(0), 100 * ONE_TOKEN);
    }

    function test_Transfer_ZeroAmount() public {
        // Transfer 0 token harus berhasil — ini valid di ERC20
        bool success = token.transfer(user1, 0);
        assertTrue(success);
    }

    function test_Transfer_ToSelf() public {
        // Transfer ke diri sendiri — valid
        uint256 balanceBefore = token.balanceOf(owner);
        token.transfer(owner, 100 * ONE_TOKEN);
        assertEq(token.balanceOf(owner), balanceBefore);
    }

    function test_Transfer_MultipleUsers() public {
        // Setup: owner → user1 → user2
        token.transfer(user1, 500 * ONE_TOKEN);

        vm.prank(user1);
        token.transfer(user2, 200 * ONE_TOKEN);

        assertEq(token.balanceOf(user1), 300 * ONE_TOKEN);
        assertEq(token.balanceOf(user2), 200 * ONE_TOKEN);
    }

    // =============================================================
    //                    APPROVE TESTS
    // =============================================================

    function test_Approve_Success() public {
        uint256 amount = 100 * ONE_TOKEN;

        bool success = token.approve(spender, amount);

        assertTrue(success);
        assertEq(token.allowance(owner, spender), amount);
    }

    function test_Approve_EmitsEvent() public {
        uint256 amount = 100 * ONE_TOKEN;

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);

        token.approve(spender, amount);
    }

    function test_Approve_OverwriteExisting() public {
        // Approve kedua menimpa yang pertama
        token.approve(spender, 100 * ONE_TOKEN);
        token.approve(spender, 200 * ONE_TOKEN);

        assertEq(token.allowance(owner, spender), 200 * ONE_TOKEN);
    }

    function test_Approve_RevokeBySettingZero() public {
        token.approve(spender, 100 * ONE_TOKEN);
        token.approve(spender, 0);

        assertEq(token.allowance(owner, spender), 0);
    }

    function test_Approve_InfiniteApproval() public {
        uint256 infinite = type(uint256).max;
        token.approve(spender, infinite);

        assertEq(token.allowance(owner, spender), infinite);
    }

    function test_Approve_MultipleSpenders() public {
        address spender2 = makeAddr("spender2");

        token.approve(spender, 100 * ONE_TOKEN);
        token.approve(spender2, 200 * ONE_TOKEN);

        assertEq(token.allowance(owner, spender), 100 * ONE_TOKEN);
        assertEq(token.allowance(owner, spender2), 200 * ONE_TOKEN);
    }

    // =============================================================
    //                  TRANSFER FROM TESTS
    // =============================================================

    function test_TransferFrom_Success() public {
        uint256 amount = 100 * ONE_TOKEN;

        // Step 1: owner approve spender
        token.approve(spender, amount);

        // Step 2: spender gunakan allowance
        vm.prank(spender);
        bool success = token.transferFrom(owner, user1, amount);

        assertTrue(success);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function test_TransferFrom_ReducesAllowance() public {
        uint256 allowanceAmount = 300 * ONE_TOKEN;
        uint256 transferAmount  = 100 * ONE_TOKEN;

        token.approve(spender, allowanceAmount);

        vm.prank(spender);
        token.transferFrom(owner, user1, transferAmount);

        // Allowance berkurang sesuai yang dipakai
        assertEq(
            token.allowance(owner, spender),
            allowanceAmount - transferAmount
        );
    }

    function test_TransferFrom_InfiniteApprovalNotReduced() public {
        // Infinite approval tidak berkurang setelah transferFrom
        token.approve(spender, type(uint256).max);

        vm.prank(spender);
        token.transferFrom(owner, user1, 100 * ONE_TOKEN);

        // Masih infinite
        assertEq(token.allowance(owner, spender), type(uint256).max);
    }

    function test_TransferFrom_RevertsIfInsufficientAllowance() public {
        token.approve(spender, 50 * ONE_TOKEN);

        vm.prank(spender);
        vm.expectRevert();
        token.transferFrom(owner, user1, 100 * ONE_TOKEN);
    }

    function test_TransferFrom_RevertsIfNoAllowance() public {
        // Tidak ada approve sama sekali
        vm.prank(spender);
        vm.expectRevert();
        token.transferFrom(owner, user1, 100 * ONE_TOKEN);
    }

    function test_TransferFrom_EmitsTransferEvent() public {
        uint256 amount = 100 * ONE_TOKEN;
        token.approve(spender, amount);

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, amount);

        vm.prank(spender);
        token.transferFrom(owner, user1, amount);
    }

    function test_TransferFrom_FullFlow() public {
        // Simulasi flow DEX yang realistis:
        // 1. User approve DEX contract
        // 2. DEX ambil token dari user
        // 3. DEX kirim token ke pool

        address dex  = makeAddr("dex");
        address pool = makeAddr("pool");
        uint256 swapAmount = 500 * ONE_TOKEN;

        // Step 1: User approve DEX
        token.approve(dex, swapAmount);
        assertEq(token.allowance(owner, dex), swapAmount);

        // Step 2: DEX execute transferFrom
        vm.prank(dex);
        token.transferFrom(owner, pool, swapAmount);

        // Verifikasi
        assertEq(token.balanceOf(pool), swapAmount);
        assertEq(token.allowance(owner, dex), 0);
    }

    // =============================================================
    //                      MINT TESTS
    // =============================================================

    function test_Mint_Success() public {
        uint256 mintAmount = 500 * ONE_TOKEN;

        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function test_Mint_EmitsEvent() public {
        uint256 mintAmount = 100 * ONE_TOKEN;

        vm.expectEmit(true, false, false, true);
        emit TokensMinted(user1, mintAmount, INITIAL_SUPPLY + mintAmount);

        token.mint(user1, mintAmount);
    }

    function test_Mint_EmitsTransferFromZero() public {
        uint256 mintAmount = 100 * ONE_TOKEN;

        // Mint juga emit Transfer(address(0), to, amount)
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, mintAmount);

        token.mint(user1, mintAmount);
    }

    function test_Mint_IncreasesTotalSupply() public {
        token.mint(user1, 100 * ONE_TOKEN);
        token.mint(user2, 200 * ONE_TOKEN);

        assertEq(
            token.totalSupply(),
            INITIAL_SUPPLY + 300 * ONE_TOKEN
        );
    }

    function test_Mint_RevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 100 * ONE_TOKEN);
    }

    function test_Mint_RevertsIfZeroAmount() public {
        vm.expectRevert(
            abi.encodeWithSelector(MyToken.ZeroAmount.selector)
        );
        token.mint(user1, 0);
    }

    function test_Mint_RevertsIfToZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(MyToken.MintToZeroAddress.selector)
        );
        token.mint(address(0), 100 * ONE_TOKEN);
    }

    function test_Mint_RevertsIfExceedsMaxSupply() public {
        // Coba mint melebihi MAX_SUPPLY
        uint256 tooMuch = MAX_SUPPLY;
        // Total supply sudah INITIAL_SUPPLY, jadi mint MAX_SUPPLY akan exceed

        vm.expectRevert();
        token.mint(user1, tooMuch);
    }

    function test_Mint_UpToMaxSupply() public {
        // Mint tepat sampai MAX_SUPPLY harus berhasil
        uint256 remaining = MAX_SUPPLY - INITIAL_SUPPLY;
        token.mint(user1, remaining);

        assertEq(token.totalSupply(), MAX_SUPPLY);
    }

    // =============================================================
    //                      BURN TESTS
    // =============================================================

    function test_Burn_Success() public {
        uint256 burnAmount = 100 * ONE_TOKEN;

        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    function test_Burn_EmitsEvent() public {
        uint256 burnAmount = 100 * ONE_TOKEN;

        vm.expectEmit(true, false, false, true);
        emit TokensBurned(owner, burnAmount, INITIAL_SUPPLY - burnAmount);

        token.burn(burnAmount);
    }

    function test_Burn_EmitsTransferToZero() public {
        uint256 burnAmount = 100 * ONE_TOKEN;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);

        token.burn(burnAmount);
    }

    function test_Burn_DecreasesTotalSupply() public {
        token.burn(100 * ONE_TOKEN);
        token.burn(200 * ONE_TOKEN);

        assertEq(
            token.totalSupply(),
            INITIAL_SUPPLY - 300 * ONE_TOKEN
        );
    }

    function test_Burn_AnyUserCanBurnOwn() public {
        // Transfer dulu ke user1
        token.transfer(user1, 500 * ONE_TOKEN);

        // user1 bisa burn token miliknya
        vm.prank(user1);
        token.burn(100 * ONE_TOKEN);

        assertEq(token.balanceOf(user1), 400 * ONE_TOKEN);
    }

    function test_Burn_RevertsIfZeroAmount() public {
        vm.expectRevert(
            abi.encodeWithSelector(MyToken.ZeroAmount.selector)
        );
        token.burn(0);
    }

    function test_Burn_RevertsIfInsufficientBalance() public {
        uint256 tooMuch = INITIAL_SUPPLY + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                MyToken.BurnAmountExceedsBalance.selector,
                owner,
                INITIAL_SUPPLY,
                tooMuch
            )
        );
        token.burn(tooMuch);
    }

    function test_BurnFrom_OwnerCanBurnFromAny() public {
        token.transfer(user1, 500 * ONE_TOKEN);

        token.burnFrom(user1, 200 * ONE_TOKEN);

        assertEq(token.balanceOf(user1), 300 * ONE_TOKEN);
    }

    function test_BurnFrom_RevertsIfNotOwner() public {
        token.transfer(user1, 500 * ONE_TOKEN);

        vm.prank(user2);
        vm.expectRevert();
        token.burnFrom(user1, 100 * ONE_TOKEN);
    }

    // =============================================================
    //                      PAUSE TESTS
    // =============================================================

    function test_Pause_Success() public {
        token.pause();
        assertTrue(token.paused());
    }

    function test_Unpause_Success() public {
        token.pause();
        token.unpause();
        assertFalse(token.paused());
    }

    function test_Pause_BlocksTransfer() public {
        token.pause();

        vm.expectRevert();
        token.transfer(user1, 100 * ONE_TOKEN);
    }

    function test_Pause_BlocksMint() public {
        token.pause();

        vm.expectRevert();
        token.mint(user1, 100 * ONE_TOKEN);
    }

    function test_Pause_BlocksBurn() public {
        token.pause();

        vm.expectRevert();
        token.burn(100 * ONE_TOKEN);
    }

    function test_Pause_BlocksTransferFrom() public {
        token.approve(spender, 100 * ONE_TOKEN);
        token.pause();

        vm.prank(spender);
        vm.expectRevert();
        token.transferFrom(owner, user1, 100 * ONE_TOKEN);
    }

    function test_Pause_DoesNotBlockApprove() public {
        // Approve masih bisa saat paused — hanya transfer yang diblock
        token.pause();

        bool success = token.approve(spender, 100 * ONE_TOKEN);
        assertTrue(success);
    }

    function test_Pause_RevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }

    function test_Unpause_RestoresTransfer() public {
        token.pause();
        token.unpause();

        // Transfer seharusnya berhasil lagi
        bool success = token.transfer(user1, 100 * ONE_TOKEN);
        assertTrue(success);
    }

    function test_Pause_ToggleMultipleTimes() public {
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());

        token.pause();
        assertTrue(token.paused());
    }

    // =============================================================
    //                      FUZZ TESTS
    // =============================================================

    /// @notice Fuzz test transfer dengan amount acak
    function test_Fuzz_Transfer(uint256 amount) public {
        // Batasi amount ke range yang valid
        vm.assume(amount > 0);
        vm.assume(amount <= INITIAL_SUPPLY);

        uint256 ownerBefore = token.balanceOf(owner);
        uint256 user1Before = token.balanceOf(user1);

        token.transfer(user1, amount);

        assertEq(token.balanceOf(owner), ownerBefore - amount);
        assertEq(token.balanceOf(user1), user1Before + amount);
        // Total supply tidak berubah
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    /// @notice Fuzz test approve dengan amount acak
    function test_Fuzz_Approve(uint256 amount) public {
        token.approve(spender, amount);
        assertEq(token.allowance(owner, spender), amount);
    }

    /// @notice Fuzz test mint dengan amount acak
    function test_Fuzz_Mint(uint256 amount) public {
        // Batasi agar tidak exceed MAX_SUPPLY
        vm.assume(amount > 0);
        vm.assume(amount <= MAX_SUPPLY - INITIAL_SUPPLY);

        uint256 supplyBefore = token.totalSupply();

        token.mint(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), supplyBefore + amount);
    }

    /// @notice Fuzz test burn dengan amount acak
    function test_Fuzz_Burn(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= INITIAL_SUPPLY);

        uint256 supplyBefore = token.totalSupply();
        uint256 balanceBefore = token.balanceOf(owner);

        token.burn(amount);

        assertEq(token.balanceOf(owner), balanceBefore - amount);
        assertEq(token.totalSupply(), supplyBefore - amount);
    }

    /// @notice Fuzz test: transfer + burn = total supply invariant
    /// @dev Invariant: totalSupply harus selalu sama kecuali ada mint/burn
    function test_Fuzz_TransferPreservesTotalSupply(
        uint256 amount,
        address recipient
    ) public {
        vm.assume(amount > 0);
        vm.assume(amount <= INITIAL_SUPPLY);
        vm.assume(recipient != address(0));
        vm.assume(recipient != owner);  // avoid self-transfer complexity

        uint256 supplyBefore = token.totalSupply();

        token.transfer(recipient, amount);

        // Invariant: total supply tidak berubah setelah transfer
        assertEq(token.totalSupply(), supplyBefore);
    }

    // =============================================================
    //                      GAS REPORT
    // =============================================================

    function test_Gas_Transfer() public {
        uint256 before = gasleft();
        token.transfer(user1, 100 * ONE_TOKEN);
        uint256 gasUsed = before - gasleft();
        console.log("Gas transfer():", gasUsed);
    }

    function test_Gas_Approve() public {
        uint256 before = gasleft();
        token.approve(spender, 100 * ONE_TOKEN);
        uint256 gasUsed = before - gasleft();
        console.log("Gas approve():", gasUsed);
    }

    function test_Gas_TransferFrom() public {
        token.approve(spender, 100 * ONE_TOKEN);

        vm.prank(spender);
        uint256 before = gasleft();
        token.transferFrom(owner, user1, 100 * ONE_TOKEN);
        uint256 gasUsed = before - gasleft();
        console.log("Gas transferFrom():", gasUsed);
    }

    function test_Gas_Mint() public {
        uint256 before = gasleft();
        token.mint(user1, 100 * ONE_TOKEN);
        uint256 gasUsed = before - gasleft();
        console.log("Gas mint():", gasUsed);
    }

    function test_Gas_Burn() public {
        uint256 before = gasleft();
        token.burn(100 * ONE_TOKEN);
        uint256 gasUsed = before - gasleft();
        console.log("Gas burn():", gasUsed);
    }
}