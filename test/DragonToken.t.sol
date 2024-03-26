// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/DragonToken.sol";

contract DragonTokenTest is Test {
    uint256 public mainnetFork;
    
    DragonFire dragonFire;
    address owner = makeAddr("Owner");
    address treasury = makeAddr("Treasury");
    address farm = makeAddr("Farm");
    
    address alice = makeAddr("Alice");
    address bob = makeAddr("Bob");
    uint256[] public maxWei = [
        0.1 ether,
        0.2 ether,
        0.3 ether,
        0.4 ether,
        0.5 ether,
        0.6 ether,
        0.7 ether
    ];
    uint256 beforeStart = 10 days;
    uint256 TOTAL_PHASES;

    function setUp() public {
        mainnetFork = vm.createSelectFork("avalanche");
        dragonFire = new DragonFire();

        owner = address(this);
        TOTAL_PHASES = dragonFire.TOTAL_PHASES();

        vm.startPrank(owner);
        dragonFire.setWhaleLimitsPerPhase(maxWei); // set the whale limits per phase (keep equal/increasing)
        dragonFire.setPhasesStartTime(block.timestamp + beforeStart); // set the startTime

        // create pair btw community tokens and dragon token
        address[] memory _communityTokens = dragonFire.getCommunityTokens();
        for (uint256 i=0; i<_communityTokens.length; i++) {
            IUniswapV2Factory(dragonFire.uniswapV2Router().factory()).createPair(address(dragonFire), _communityTokens[i]);
        }
        dragonFire.setPairs();
        vm.stopPrank();
    }

    /* test for setMainDex() function */
    function test_setMainDexRevertWhenNotFinalPhase() public {
        address otherRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; // approved

        vm.prank(owner);
        vm.expectRevert(); // should be reverted since current phase is not final
        dragonFire.setMainDex(otherRouter);
    }

    function test_setMainDexRevertWhenNotApprovedRouter() public {
        address otherRouter = 0x000000000000000000000000000000000000dEaD; // not approved

        vm.prank(owner);
        vm.expectRevert(); // should be reverted due to non-approved router
        dragonFire.setMainDex(otherRouter);
    }

    function test_setMainDex() public {
        address otherRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; // approved

        // create pair btw community tokens and dragon token
        address[] memory _communityTokens = dragonFire.getCommunityTokens();
        for (uint256 i=0; i<_communityTokens.length; i++) {
            IUniswapV2Factory(IUniswapV2Router02(otherRouter).factory()).createPair(address(dragonFire), _communityTokens[i]);
        }
        // create pair btw WAVAX and dragon token
        IUniswapV2Factory(IUniswapV2Router02(otherRouter).factory()).createPair(address(dragonFire), dragonFire.WAVAX());

        _lockPhasesSettings(TOTAL_PHASES);
  
        vm.prank(owner);
        dragonFire.setMainDex(otherRouter);
    }

    ////////////////////////////////////////////////////////
    //         setCommunityTokens and setCtRouters        //
    ////////////////////////////////////////////////////////
    function test_setCommunityTokensRevertWhenPhaseSettingsUnlock() public {
        address[] memory _communityTokens = new address[](3);
        _communityTokens[0] = 0xab592d197ACc575D16C3346f4EB70C703F308D1E;
        _communityTokens[1] = 0x420FcA0121DC28039145009570975747295f2329;
        _communityTokens[2] = 0x184ff13B3EBCB25Be44e860163A5D8391Dd568c1;

        address[] memory _routers = new address[](3);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[1] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[2] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

        vm.prank(owner);
        vm.expectRevert(); // should be reverted due to unlocked fee settings
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCommunityTokensEmptyArrayRevert() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _communityTokens;
        address[] memory _routers;

        vm.prank(owner);
        vm.expectRevert(); // should be reverted due to zero length of _communityTokens
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCommunityTokensLongArrayRevert() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _communityTokens = new address[](9);
        _communityTokens[0] = 0xab592d197ACc575D16C3346f4EB70C703F308D1E;
        _communityTokens[1] = 0x420FcA0121DC28039145009570975747295f2329;
        _communityTokens[2] = 0x184ff13B3EBCB25Be44e860163A5D8391Dd568c1;
        _communityTokens[3] = 0xb5Cc2CE99B3f98a969DBe458b96a117680AE0fA1;
        _communityTokens[4] = 0xc06E17bDC3F008F4Ce08D27d364416079289e729;
        _communityTokens[5] = 0xc8E7fB72B53D08C4f95b93b390ed3f132d03f2D5;
        _communityTokens[6] = 0x69260B9483F9871ca57f81A90D91E2F96c2Cd11d;
        _communityTokens[7] = 0x96E1056a8814De39c8c3Cd0176042d6ceCD807d7;
        _communityTokens[8] = 0x96E1056a8814De39c8c3Cd0176042d6ceCD807d7; // the length is over 8 (exactly 9)

        address[] memory _routers = new address[](9);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[1] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[2] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[3] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[4] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[5] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[6] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[7] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[8] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // the length is over 8 (exactly 9)

        vm.prank(owner);
        vm.expectRevert(); // should be reverted due to length of _communityTokens
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCtRoutersIncorrectLengthRevert() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _routers = new address[](2);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[1] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

        vm.prank(owner);
        vm.expectRevert(); // should be reverted since length of _routers is not same with communityToken's one
        dragonFire.setCtRouters(_routers);
    }

    function test_setCtRoutersNonApprovedRevert() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _communityTokens = new address[](2);
        _communityTokens[0] = 0xab592d197ACc575D16C3346f4EB70C703F308D1E;
        _communityTokens[1] = 0x420FcA0121DC28039145009570975747295f2329;

        address[] memory _routers = new address[](2);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // approved
        _routers[1] = 0x000000000000000000000000000000000000dEaD; // not approved

        vm.prank(owner);
        vm.expectRevert(); // should be reverted due to non-approved router
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCommunityTokens() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _communityTokens = new address[](2);
        _communityTokens[0] = 0xab592d197ACc575D16C3346f4EB70C703F308D1E;
        _communityTokens[1] = 0x420FcA0121DC28039145009570975747295f2329;

        address[] memory _routers = new address[](2);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[1] = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;

        vm.prank(owner);
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }
    
    /////////////////////////////////////////
    //     Setting Process Fee Minimum     //
    /////////////////////////////////////////
    function test_setProcessFeesMinimumRevertWhenPhaseSettingUnlock(uint256 _amount) public {
        vm.assume(_amount >= dragonFire.TOTAL_SUPPLY_WEI() / 1000000000);
        vm.assume(_amount <= dragonFire.TOTAL_SUPPLY_WEI() / 1000);

        vm.prank(owner);
        vm.expectRevert(); // revert due to unlocking of phase settings
        dragonFire.setProcessFeesMinimum(_amount);
    }

    function test_setProcessFeesMinimumRevertMinimumRevert(uint256 _amount) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_amount < dragonFire.TOTAL_SUPPLY_WEI() / 1000000000);

        vm.prank(owner);
        vm.expectRevert(); // revert due to non-matching of minimum limit
        dragonFire.setProcessFeesMinimum(_amount);
    }

    function test_setProcessFeesMinimumRevertMaximumRevert(uint256 _amount) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_amount > dragonFire.TOTAL_SUPPLY_WEI() / 1000);

        vm.prank(owner);
        vm.expectRevert(); // revert due to non-matching of maximum limit
        dragonFire.setProcessFeesMinimum(_amount);
    }

    function test_setProcessFeesMinimum(uint256 _amount) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_amount >= dragonFire.TOTAL_SUPPLY_WEI() / 1000000000);
        vm.assume(_amount <= dragonFire.TOTAL_SUPPLY_WEI() / 1000);

        vm.prank(owner);
        dragonFire.setProcessFeesMinimum(_amount);

        assertEq(dragonFire.processFeesMinimum(), _amount);
    }
    
    //////////////////////////////////////
    //     Setting Treasury Address     //
    //////////////////////////////////////

    function test_setTreasuryAddressRevertZeroAddress() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.prank(owner);
        vm.expectRevert(); // revert due to zero address of treasury
        dragonFire.setTreasuryAddress(address(0));
    }

    function test_setTreasuryAddressRevertWhenPhaseSettingUnlock(address _treasury) public {
        vm.assume(_treasury != address(0));

        vm.prank(owner);
        vm.expectRevert(); // revert due to unlocking of phase setting
        dragonFire.setTreasuryAddress(_treasury);
    }

    function test_setTreasuryAddress(address _treasury) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_treasury != address(0));

        vm.prank(owner);
        dragonFire.setTreasuryAddress(_treasury);
        assertEq(dragonFire.treasuryAddress(), _treasury);
    }    
    
    //////////////////////////////////
    //     Setting Farm Address     //
    //////////////////////////////////

    function test_setFarmAddressRevertWhenPhaseSettingUnlock(address _farm) public {
        vm.assume(_farm != address(0));
        
        vm.prank(owner);
        vm.expectRevert(); // revert due to unlocking of phase settings
        dragonFire.setFarmAddress(_farm);
    }

    function test_setFarmAddressRevertZeroAddress() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.prank(owner);
        vm.expectRevert(); // revert due to zero address
        dragonFire.setFarmAddress(address(0));
    }

    function test_setFarmAddress(address _farm) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_farm != address(0));

        address _previousFarm = dragonFire.farmAddress();

        vm.prank(owner);
        dragonFire.setFarmAddress(_farm);
        assertEq(dragonFire.farmAddress(), _farm);
        assertEq(dragonFire.isExcludedFromFees(_previousFarm), false);
        assertEq(dragonFire.isExcludedFromFees(_farm), true);
    }
    
    //////////////////////////////////////////////
    //     Exclude/Include Address from Fees    //
    //////////////////////////////////////////////

    function test_excludeOrIncludeFeesRevertWhenPhaseSettingUnlock() public {
        assertEq(dragonFire.isExcludedFromFees(alice), false);
        vm.prank(owner);
        vm.expectRevert(); // revert due to unlocking of phase settings
        dragonFire.excludeFromFees(alice);

        vm.prank(owner);
        vm.expectRevert(); // revert due to unlocking of phase settings
        dragonFire.includeInFees(alice);
    }

    function test_excludeFromFeesRevertAlreadyExcluded() public {
        _lockPhasesSettings(TOTAL_PHASES);
        
        vm.prank(owner);
        dragonFire.excludeFromFees(alice);
        assertEq(dragonFire.isExcludedFromFees(alice), true);
        
        vm.prank(owner);
        vm.expectRevert(); // revert due to account already excluded from fee
        dragonFire.excludeFromFees(alice);
    }

    function test_includeInFeesRevertAlreadyIncluded() public {
        _lockPhasesSettings(TOTAL_PHASES);

        assertEq(dragonFire.isExcludedFromFees(alice), false);
        vm.prank(owner);
        vm.expectRevert(); // revert due to account already included from fee
        dragonFire.includeInFees(alice);
    }

    function test_includeInFees() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.startPrank(owner);
        dragonFire.excludeFromFees(alice);
        assertEq(dragonFire.isExcludedFromFees(alice), true);

        dragonFire.includeInFees(alice);
        assertEq(dragonFire.isExcludedFromFees(alice), false);
        vm.stopPrank();
    }

    ////////////////////////////////////////////
    //     Transferring Ownership Address     //
    ////////////////////////////////////////////

    function test_transferOwnershipRevertNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        dragonFire.transferOwnership(alice);
    }

    function test_transferOwnershipZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        dragonFire.transferOwnership(address(0));
    }

    function test_transferOwnership() public {
        vm.prank(owner);
        dragonFire.transferOwnership(alice);
        vm.assertEq(dragonFire.owner(), alice);
        vm.assertEq(dragonFire.isExcludedFromFees(owner), false);
        vm.assertEq(dragonFire.isExcludedFromFees(alice), true);
    }

    ////////////////////////////////
    //     Setting Fees State     //
    ////////////////////////////////
    
    function test_setFeesInBasisPts() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.prank(owner);
        dragonFire.setFeesInBasisPts(400, 200, 100, 100);
    }

    function test_setFeesInBasisPtsRevertWhenPhaseSettingUnlock() public {
        vm.prank(owner);
        vm.expectRevert();
        dragonFire.setFeesInBasisPts(400, 200, 100, 100);
    }

    function test_setFeesInBasisPtsRevertMaximumLimit() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.prank(owner);
        vm.expectRevert();
        dragonFire.setFeesInBasisPts(500, 200, 100, 100);
    }

    ///////////////////////////
    //     Setting Pairs     //
    ///////////////////////////

    function test_setPairsRevertOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        dragonFire.setPairs();
    }

    //////////////////////////////
    //     Seed And Burn LP     //
    //////////////////////////////

    function test_seedAndBurnCtLP() public {
        uint256 ctIndex = 0;
        address communityToken = dragonFire.communityTokens(ctIndex);
        uint256 amountDragon = 0.2 ether;
        uint256 amountCt = 0.2 ether;

        deal(address(dragonFire), alice, 1 ether);
        deal(communityToken, alice, 1 ether);

        uint256 previousDragonBalance = dragonFire.balanceOf(alice);
        uint256 previousCtBalance = IERC20(communityToken).balanceOf(alice);
        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), amountDragon);
        IERC20(communityToken).approve(address(dragonFire), amountCt);

        dragonFire.seedAndBurnCtLP(ctIndex, communityToken, amountDragon, amountCt);
        assertEq(dragonFire.balanceOf(alice), previousDragonBalance - amountDragon);
        assertEq(IERC20(communityToken).balanceOf(alice), previousCtBalance - amountCt);
        vm.stopPrank();
    }

    function test_seedAndBurnDragonLP() public {
        uint256 amountDragon = 0.2 ether;
        uint256 amountAVAX = 0.2 ether;

        deal(address(dragonFire), alice, 1 ether);
        deal(alice, 1 ether);

        uint256 previousDragonBalance = dragonFire.balanceOf(alice);
        uint256 previousAVAXBalance = address(alice).balance;
        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), amountDragon);

        dragonFire.seedAndBurnDragonLP{value: amountAVAX}(amountDragon, amountAVAX);
        assertEq(dragonFire.balanceOf(alice), previousDragonBalance - amountDragon);
        assertEq(address(alice).balance, previousAVAXBalance - amountAVAX);
        vm.stopPrank();
    }

    //////////////////////////////////////
    //          helper methods          //
    //////////////////////////////////////
    function _lockPhasesSettings(uint256 phase) internal {
        // lock phase settings
        vm.prank(owner);
        dragonFire.lockPhasesSettings();
        vm.warp(dragonFire.startTime() + (dragonFire.SECONDS_PER_PHASE() * (phase - 1)));
    }
}
