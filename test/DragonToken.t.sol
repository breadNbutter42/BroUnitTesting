// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {TestERC721} from "./mock/TestERC721.sol";
import "../src/DragonToken.sol";

contract DragonTokenTest is Test {
    uint256 public mainnetFork;
    MockERC20 mockERC20;
    TestERC721 testERC721;
    
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
        mockERC20 = new MockERC20();
        testERC721 = new TestERC721();
        dragonFire = new DragonFire();

        owner = address(this);
        TOTAL_PHASES = dragonFire.TOTAL_PHASES();

        vm.startPrank(owner);
        // dragonFire.setWhaleLimitsPerPhase(maxWei); // set the whale limits per phase (keep equal/increasing)
        dragonFire.setPhasesStartTime(block.timestamp + beforeStart); // set the startTime

        // create pair btw community tokens and dragon token
        address[] memory _communityTokens = dragonFire.getCommunityTokens();
        for (uint256 i=0; i<_communityTokens.length; i++) {
            IUniswapV2Factory(dragonFire.uniswapV2Router().factory()).createPair(address(dragonFire), _communityTokens[i]);
        }
        dragonFire.setPairs();
        vm.stopPrank();
    }

    ////////////////////////
    //     SetMainDex     //
    ////////////////////////

    function test_setMainDexRevertWhenNotFinalPhase() public {
        address otherRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; // approved

        vm.prank(owner);
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.setMainDex(otherRouter);
    }

    function test_setMainDexRevertWhenNotApprovedRouter() public {
        _lockPhasesSettings(TOTAL_PHASES);
        address otherRouter = 0x000000000000000000000000000000000000dEaD; // not approved

        vm.prank(owner);
        vm.expectRevert("Router not approved"); // should be reverted due to non-approved router
        dragonFire.setMainDex(otherRouter);
    }

    function test_setMainDexRevertNoPairBtwDragonAndAvax() public {
        address otherRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; // approved

        _lockPhasesSettings(TOTAL_PHASES);
  
        vm.prank(owner);
        vm.expectRevert("LP Pair must be created first, paired with WAVAX");
        dragonFire.setMainDex(otherRouter);
    }

    function test_setMainDexRevertNoPairBtwDragonAndCt() public {
        address otherRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; // approved

        // create pair btw WAVAX and dragon token
        IUniswapV2Factory(IUniswapV2Router02(otherRouter).factory()).createPair(address(dragonFire), dragonFire.WAVAX());

        _lockPhasesSettings(TOTAL_PHASES);
  
        vm.prank(owner);
        vm.expectRevert("All CT/DRAGON LP Pairs must be created first on main dex");
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
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCommunityTokensEmptyArrayRevert() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _communityTokens;
        address[] memory _routers;

        vm.prank(owner);
        vm.expectRevert("Must include at least one community token");
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
        vm.expectRevert("Cannot include more than 8 tokens in the communityTokens array");
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCtRoutersIncorrectLengthRevert() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _routers = new address[](2);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[1] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

        vm.prank(owner);
        vm.expectRevert("Each token in the communityTokens array must have a corresponding router in the ctRouters array");
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
        vm.expectRevert("Router not approved");
        dragonFire.setCommunityTokens(_communityTokens, _routers);
    }

    function test_setCtRouters() public {
        _lockPhasesSettings(TOTAL_PHASES);

        address[] memory _routers = new address[](8);
        _routers[0] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[1] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[2] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[3] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[4] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[5] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[6] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        _routers[7] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

        vm.prank(owner);
        dragonFire.setCtRouters(_routers);
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
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.setProcessFeesMinimum(_amount);
    }

    function test_setProcessFeesMinimumRevertMinimumRevert(uint256 _amount) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_amount < dragonFire.TOTAL_SUPPLY_WEI() / 1000000000);

        vm.prank(owner);
        vm.expectRevert("Amount too low, cannot be less than 0.0000001% of supply");
        dragonFire.setProcessFeesMinimum(_amount);
    }

    function test_setProcessFeesMinimumRevertMaximumRevert(uint256 _amount) public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.assume(_amount > dragonFire.TOTAL_SUPPLY_WEI() / 1000);

        vm.prank(owner);
        vm.expectRevert("Amount too high, cannot be more than 0.1% of supply");
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
        vm.expectRevert("Cannot set to 0 address");
        dragonFire.setTreasuryAddress(address(0));
    }

    function test_setTreasuryAddressRevertWhenPhaseSettingUnlock(address _treasury) public {
        vm.assume(_treasury != address(0));

        vm.prank(owner);
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
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
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.setFarmAddress(_farm);
    }

    function test_setFarmAddressRevertZeroAddress() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.prank(owner);
        vm.expectRevert("Cannot set to 0 address");
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
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.excludeFromFees(alice);

        vm.prank(owner);
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.includeInFees(alice);
    }

    function test_excludeFromFeesRevertAlreadyExcluded() public {
        _lockPhasesSettings(TOTAL_PHASES);
        
        vm.prank(owner);
        dragonFire.excludeFromFees(alice);
        assertEq(dragonFire.isExcludedFromFees(alice), true);
        
        vm.prank(owner);
        vm.expectRevert("Account is already excluded");
        dragonFire.excludeFromFees(alice);
    }

    function test_includeInFeesRevertAlreadyIncluded() public {
        _lockPhasesSettings(TOTAL_PHASES);

        assertEq(dragonFire.isExcludedFromFees(alice), false);
        vm.prank(owner);
        vm.expectRevert("Account is already included");
        dragonFire.includeInFees(alice);
    }

    function test_includeInFeesRevertIncludingDragonToken() public {
        _lockPhasesSettings(TOTAL_PHASES);

        assertEq(dragonFire.isExcludedFromFees(address(dragonFire)), true);
        vm.prank(owner);
        vm.expectRevert("Cannot include DRAGON contract in fees");
        dragonFire.includeInFees(address(dragonFire));
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

    function test_transferOwnershipOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        dragonFire.transferOwnership(alice);
    }

    function test_transferOwnershipZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Cannot set to 0 address");
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
        vm.expectRevert("Cannot change fees processing functions until IDO launch is completed");
        dragonFire.setFeesInBasisPts(400, 200, 100, 100);
    }

    function test_setFeesInBasisPtsRevertMaximumLimit() public {
        _lockPhasesSettings(TOTAL_PHASES);

        vm.prank(owner);
        vm.expectRevert("Total fees cannot add up to over 8%");
        dragonFire.setFeesInBasisPts(500, 200, 100, 100);
    }

    ///////////////////////////////
    //     Lock Fee Settings     //
    ///////////////////////////////

    function test_lockFeeSettings() public {
        assertEq(dragonFire.feesLocked(), false);
        
        vm.prank(owner);
        dragonFire.lockFeeSettings();
        assertEq(dragonFire.feesLocked(), true);
    }

    function test_lockFeeSettingsRevertAlreadyLocked() public {
        assertEq(dragonFire.feesLocked(), false);
        
        vm.prank(owner);
        dragonFire.lockFeeSettings();
        assertEq(dragonFire.feesLocked(), true);

        vm.prank(owner);
        vm.expectRevert("Fees settings already locked");
        dragonFire.lockFeeSettings();
    }

    ////////////////////////////////
    //     Set Purchase Tiime     //
    ////////////////////////////////

    function test_setPhasesStartTimeRevertInvalidValue() public {
        vm.prank(owner);
        vm.expectRevert("Start time must be greater than 0");
        dragonFire.setPhasesStartTime(0);
    }

    ///////////////////////////
    //     Trading Phase     //
    ///////////////////////////

    function test_tradingPhaseReturnTotalPhase(uint8 phase) public {
        vm.assume(phase > TOTAL_PHASES);
        _lockPhasesSettings(phase);

        assertEq(dragonFire.tradingPhase(), TOTAL_PHASES);
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

    function test_seedAndBurnRevertWhenTotalPhase() public {
        _lockPhasesSettings(TOTAL_PHASES);

        uint256 ctIndex = 0;
        address communityToken = dragonFire.communityTokens(ctIndex);
        uint256 amountDragon = 0.2 ether;
        uint256 amountCt = 0.2 ether;
        uint256 amountAVAX = 0.2 ether;

        deal(address(dragonFire), alice, 1 ether);
        deal(communityToken, alice, 1 ether);
        deal(alice, 1 ether);

        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), amountDragon);
        IERC20(communityToken).approve(address(dragonFire), amountCt);

        vm.expectRevert("Phases are completed already");
        dragonFire.seedAndBurnCtLP(ctIndex, communityToken, amountDragon, amountCt);
        vm.expectRevert("Phases are completed already");
        dragonFire.seedAndBurnDragonLP{value: amountAVAX}(amountDragon, amountAVAX);
        vm.stopPrank();
    }

    function test_seedAndBurnRevertWhenInvalidCommunityTokenIndex(uint256 ctIndex, uint256 otherCtIndex) public {
        vm.assume(ctIndex != otherCtIndex && ctIndex < 8 && otherCtIndex < 8);
        address communityToken = dragonFire.communityTokens(otherCtIndex);
        uint256 amountDragon = 0.2 ether;
        uint256 amountCt = 0.2 ether;

        deal(address(dragonFire), alice, 1 ether);
        deal(communityToken, alice, 1 ether);

        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), amountDragon);
        IERC20(communityToken).approve(address(dragonFire), amountCt);
        vm.expectRevert("Token not found in communityTokens array at that index");
        dragonFire.seedAndBurnCtLP(ctIndex, communityToken, amountDragon, amountCt);
        vm.stopPrank();
    }

    function test_seedAndBurnRevertWhenAmountLimit(uint256 lowerAmount, uint256 greaterAmount) public {
        vm.assume(lowerAmount < 0.1 ether);
        vm.assume(greaterAmount > 0.1 ether && greaterAmount < 1 ether);

        uint256 ctIndex = 0;
        address communityToken = dragonFire.communityTokens(ctIndex);
        deal(address(dragonFire), alice, 1 ether);
        deal(communityToken, alice, 1 ether);
        deal(alice, 1 ether);

        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), greaterAmount);
        IERC20(communityToken).approve(address(dragonFire), greaterAmount);

        vm.expectRevert("Must send at least 0.1 Dragon tokens");
        dragonFire.seedAndBurnCtLP(ctIndex, communityToken, lowerAmount, greaterAmount);
        vm.expectRevert("Must send at least 0.1 Dragon tokens");
        dragonFire.seedAndBurnDragonLP{value: greaterAmount}(lowerAmount, greaterAmount);

        vm.expectRevert("Must send at least 0.1 Community tokens");
        dragonFire.seedAndBurnCtLP(ctIndex, communityToken, greaterAmount, lowerAmount);
        vm.expectRevert("Must send at least 0.1 AVAX");
        dragonFire.seedAndBurnDragonLP{value: lowerAmount}(greaterAmount, lowerAmount);

        vm.stopPrank();
    }

    function test_seedAndBurnDragonLPRevertWhenAVAXAmountNotMatched(uint256 amount, uint256 differAmount) public {
        uint256 amountDragon = 0.2 ether;
        vm.assume(
            amount < 1 ether &&
            differAmount < 1 ether &&
            amount != differAmount
        );

        deal(address(dragonFire), alice, 1 ether);
        deal(alice, 1 ether);

        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), amount);
        vm.expectRevert("Different amount of Avax sent than indicated in call values");
        dragonFire.seedAndBurnDragonLP{value: amount}(amountDragon, differAmount);
        vm.stopPrank();
    }

    /////////////////////////////
    //     Processing Fees     //
    /////////////////////////////

    // function test_processFeesPreventBackToBackDumping() public {
    //     _lockPhasesSettings(TOTAL_PHASES);

    //     vm.startPrank(alice);
    //     dragonFire.processFees();

    //     vm.warp(block.timestamp + dragonFire.SECONDS_PER_PHASE() / 2);
    //     vm.expectRevert("Cannot process fees more than once every 8 minutes");
    //     dragonFire.processFees();
    //     vm.stopPrank();
    // }

    function test_processFeesWhenZeroTotalFees() public {
        _lockPhasesSettings(TOTAL_PHASES);

        uint256 miniumAmountForSwap = 111111.11 ether;

        deal(address(dragonFire), address(dragonFire), miniumAmountForSwap);
        deal(address(dragonFire), dragonFire.uniswapV2Pair(), miniumAmountForSwap); // can swap

        vm.prank(owner);
        dragonFire.setFeesInBasisPts(0, 0, 0, 0); // totalFees = 0

        vm.prank(alice);
        dragonFire.processFees();

        assertEq(dragonFire.balanceOf(address(dragonFire)), 0);
        assertEq(dragonFire.balanceOf(dragonFire.DEAD()), miniumAmountForSwap);
    }

    function test_processFeesSuccess(uint256 phase) public {
        vm.assume(phase > 0 && phase < TOTAL_PHASES);
        
        _lockPhasesSettings(phase);

        deal(address(dragonFire), alice, 1000000 ether);
        deal(alice, 1000000 ether);
        vm.startPrank(alice);
        dragonFire.approve(address(dragonFire), 1000000 ether);
        dragonFire.seedAndBurnDragonLP{value: 1000000 ether}(1000000 ether, 1000000 ether); // add liqudity to Dragon/WAVAX pair
        vm.stopPrank();

        uint256 minimumAmountForSwap = 111111.11 ether;
        deal(address(dragonFire), address(dragonFire), minimumAmountForSwap);

        vm.prank(alice);
        dragonFire.processFees();
    }

    /////////////////////////////////////////
    //     Checking Trading Restricted     //
    /////////////////////////////////////////

    function test_tradingRestricted(uint256 phase) public {
        vm.assume(phase > 0 && phase < TOTAL_PHASES);
        bool restricted;

        restricted = dragonFire.tradingRestricted();
        assertEq(restricted, false);

        _lockPhasesSettings(phase);
        restricted = dragonFire.tradingRestricted();
        assertEq(restricted, true);
    }

    ///////////////////////////////////////
    //     Set Whale Limits Per Phase     //
    ///////////////////////////////////////

    function test_setWhaleLimitsPerPhaseRevertInvalidLength(uint8 length) public {
        vm.assume(length != (TOTAL_PHASES - 1));
        uint256[] memory _maxWei = new uint256[](length);
        for (uint8 i=0; i < length; i++) {
            _maxWei[i] = uint256(i) * 1000;
        }

        vm.prank(owner);
        vm.expectRevert("You must set maximum wei for every whale limited phase");
        dragonFire.setWhaleLimitsPerPhase(_maxWei);
    }

    function test_setWhaleLimitsPerPhaseRevertInvalidValue() public {
        uint256[] memory _maxWei = new uint256[](TOTAL_PHASES - 1);
        for (uint8 i=0; i < TOTAL_PHASES - 1; i++) {
            _maxWei[i] = 0;
        }

        vm.prank(owner);
        vm.expectRevert("Whale limit must be greater than 0 wei");
        dragonFire.setWhaleLimitsPerPhase(_maxWei);
    }

    function test_setWhaleLimitsPerPhaseRevertInvalidIncreasing() public {
        uint256[] memory _maxWei = new uint256[](TOTAL_PHASES - 1);
        for (uint8 i=0; i < TOTAL_PHASES - 1; i++) {
            _maxWei[i] = (0.1 ether) * (TOTAL_PHASES - i);
        }

        vm.prank(owner);
        vm.expectRevert("Max amount users can hold must increase or stay the same through the phases.");
        dragonFire.setWhaleLimitsPerPhase(_maxWei);
    }

    /////////////////////////////////
    //     Lock Phase Settings     //
    /////////////////////////////////

    function test_lockPhaseSettings() public {
        _setWhaleLimitsPerShare();

        vm.prank(owner);
        dragonFire.lockPhasesSettings();
        assertEq(dragonFire.phasesInitialized(), true);
    }

    function test_lockPhaseSettingsRevertAlreadyLockedAndOnlyOwner() public {
        _setWhaleLimitsPerShare();

        vm.prank(alice);
        vm.expectRevert();
        dragonFire.lockPhasesSettings();

        vm.prank(owner);
        dragonFire.lockPhasesSettings();
        assertEq(dragonFire.phasesInitialized(), true);

        vm.prank(owner);
        vm.expectRevert("Phases initialization is locked");
        dragonFire.lockPhasesSettings();
    }

    function test_lockPhasesSettingsInvalidCurrentTime(uint32 time) public {
        vm.assume(time > 0);
        vm.warp(dragonFire.startTime() + time);
        
        vm.prank(owner);
        vm.expectRevert("startTime must be set for the future");
        dragonFire.lockPhasesSettings();
    }

    function test_lockPhasesSettingsInvalidWhaleLimit() public {
        vm.prank(owner);
        vm.expectRevert("Whale limited phases maxWeiPerPhase must be greater than 0");
        dragonFire.lockPhasesSettings();
    }

    /////////////////////////////////////////
    //    Set AllowList For Some Phase     //
    /////////////////////////////////////////

    function test_setAllowlistedForSomePhase(uint256 usersLength, uint256 phase) public {
        vm.assume(phase <= TOTAL_PHASES);
        vm.assume(usersLength > 0 && usersLength <= 200);
        address[] memory users = new address[](usersLength);
        for (uint256 i=0; i< usersLength; i++) {
            users[i] = address(uint160(i));
        }

        vm.prank(owner);
        dragonFire.setAllowlistedForSomePhase(users, phase);
        for (uint256 i=0; i< usersLength; i++) {
            assertEq(dragonFire.allowlisted(users[i]), phase);
        }
    }

    function test_setAllowlistedForSomePhaseRevertInvalidPhase(uint256 usersLength, uint256 phase) public {
        vm.assume(phase > TOTAL_PHASES);
        vm.assume(usersLength > 0 && usersLength <= 200);

        address[] memory users = new address[](usersLength);
        for (uint256 i=0; i< usersLength; i++) {
            users[i] = address(uint160(i));
        }

        vm.prank(owner);
        vm.expectRevert("Phases are already completed");
        dragonFire.setAllowlistedForSomePhase(users, phase);
    }

    function test_setAllowlistedForSomePhaseRevertZeroUsersLength(uint256 phase) public {
        vm.assume(phase <= TOTAL_PHASES);

        address[] memory users;

        vm.prank(owner);
        vm.expectRevert("Must include at least one user");
        dragonFire.setAllowlistedForSomePhase(users, phase);
    }

    function test_setAllowlistedForSomePhaseRevertInvalidUsersLength(uint256 phase) public {
        vm.assume(phase <= TOTAL_PHASES);
        uint256 usersLength = 201;

        address[] memory users = new address[](usersLength);
        for (uint256 i=0; i< usersLength; i++) {
            users[i] = address(uint160(i));
        }

        vm.prank(owner);
        vm.expectRevert("Cannot add more than 200 users in one transaction");
        dragonFire.setAllowlistedForSomePhase(users, phase);
    }

    ///////////////////////////
    //     Withdraw Avax     //
    ///////////////////////////

    function test_withdrawAvaxTo(uint256 amount) public {
        vm.assume(amount < 1 ether);
        deal(address(dragonFire), 1 ether);
        uint256 previousBalance = address(alice).balance;

        vm.prank(owner);
        vm.expectEmit();
        emit DragonFire.AvaxWithdraw(alice, amount);
        dragonFire.withdrawAvaxTo(payable(alice), amount);
        assertEq(address(alice).balance, previousBalance + amount);
        assertEq(address(dragonFire).balance, 1 ether - amount);
    }

    function test_withdrawAvaxToRevertZeroAddress(uint256 amount) public {
        vm.assume(amount < 1 ether);
        deal(address(dragonFire), 1 ether);

        vm.prank(owner);
        vm.expectRevert("Cannot withdraw to 0 address");
        dragonFire.withdrawAvaxTo(payable(0), amount);
    }

    ///////////////////////////
    //    iERC20Transfer     //
    ///////////////////////////

    function test_iERC20TransferFrom(uint256 amount) public {
        vm.assume(amount < 1 ether);
        deal(address(mockERC20), address(dragonFire), 1 ether);

        vm.prank(owner);
        dragonFire.iERC20Approve(address(mockERC20), address(dragonFire), 1 ether);

        vm.prank(owner);
        dragonFire.iERC20TransferFrom(address(mockERC20), alice, amount);
        assertEq(mockERC20.balanceOf(alice), amount);
        assertEq(mockERC20.balanceOf(address(dragonFire)), 1 ether - amount);
    }

    function test_iERC20TransferFromRevertDragonToken(uint256 amount) public {
        vm.assume(amount < 1 ether);
        
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC20TransferFrom(address(dragonFire), alice, amount);
    }

    function test_iERC20ApproveRevertDragonToken(uint256 amount) public {
        vm.assume(amount < 1 ether);
        
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC20Approve(address(dragonFire), alice, amount);
    }

    function test_iERC20Transfer(uint256 amount) public {
        vm.assume(amount < 1 ether);
        deal(address(mockERC20), address(dragonFire), 1 ether);

        vm.prank(owner);
        dragonFire.iERC20Transfer(address(mockERC20), alice, amount);
        assertEq(mockERC20.balanceOf(alice), amount);
        assertEq(mockERC20.balanceOf(address(dragonFire)), 1 ether - amount);
    }

    function test_iERC20TransferRevertDragonToken(uint256 amount) public {
        vm.assume(amount < 1 ether);
        
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC20Transfer(address(dragonFire), alice, amount);
    }

    ////////////////////////////////
    //     iERC721 Transfer       //
    ////////////////////////////////

    function test_iERC721TransferFrom(uint256 tokenId) public {
        vm.assume(testERC721.exists(tokenId) == false);
        testERC721.mint(address(dragonFire), tokenId);
        assertEq(testERC721.ownerOf(tokenId), address(dragonFire));

        vm.prank(address(dragonFire));
        testERC721.setApprovalForAll(address(dragonFire), true);

        vm.prank(owner);
        dragonFire.iERC721TransferFrom(address(testERC721), alice, tokenId);
        assertEq(testERC721.ownerOf(tokenId), alice);
    }

    function test_iERC721SafeTransferFrom(uint256 tokenId) public {
        vm.assume(testERC721.exists(tokenId) == false);
        testERC721.mint(address(dragonFire), tokenId);
        assertEq(testERC721.ownerOf(tokenId), address(dragonFire));

        vm.prank(address(dragonFire));
        testERC721.setApprovalForAll(address(dragonFire), true);

        vm.prank(owner);
        dragonFire.iERC721SafeTransferFrom(address(testERC721), alice, tokenId);
        assertEq(testERC721.ownerOf(tokenId), alice);
    }

    function test_iERC721Transfer(uint256 tokenId) public {
        vm.assume(testERC721.exists(tokenId) == false);
        testERC721.mint(address(dragonFire), tokenId);
        assertEq(testERC721.ownerOf(tokenId), address(dragonFire));

        vm.prank(address(dragonFire));
        testERC721.setApprovalForAll(address(dragonFire), true);

        vm.prank(owner);
        dragonFire.iERC721Transfer(address(testERC721), alice, tokenId);
        assertEq(testERC721.ownerOf(tokenId), alice);
    }

    function test_iERC721SafeTransfer(uint256 tokenId) public {
        vm.assume(testERC721.exists(tokenId) == false);
        testERC721.mint(address(dragonFire), tokenId);
        assertEq(testERC721.ownerOf(tokenId), address(dragonFire));

        vm.prank(address(dragonFire));
        testERC721.setApprovalForAll(address(dragonFire), true);

        vm.prank(owner);
        dragonFire.iERC721SafeTransfer(address(testERC721), alice, tokenId);
        assertEq(testERC721.ownerOf(tokenId), alice);
    }

    function test_iERC721TransferFromRevertDragonToken(uint256 tokenId) public {
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC721TransferFrom(address(dragonFire), alice, tokenId);
    }

    function test_iERC721SafeTransferFromRevertDragonToken(uint256 tokenId) public {
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC721SafeTransferFrom(address(dragonFire), alice, tokenId);
    }

    function test_iERC721TransferRevertDragonToken(uint256 tokenId) public {
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC721Transfer(address(dragonFire), alice, tokenId);
    }

    function test_iERC721SafeTransferRevertDragonToken(uint256 tokenId) public {
        vm.prank(owner);
        vm.expectRevert("Owner cannot withdraw $DRAGON token fees collected");
        dragonFire.iERC721SafeTransfer(address(dragonFire), alice, tokenId);
    }

    //////////////////////////////////////
    //          helper methods          //
    //////////////////////////////////////
    function _lockPhasesSettings(uint256 phase) internal {
        _setWhaleLimitsPerShare();
        // lock phase settings
        vm.prank(owner);
        dragonFire.lockPhasesSettings();
        vm.warp(dragonFire.startTime() + (dragonFire.SECONDS_PER_PHASE() * (phase - 1)));
    }

    function _setWhaleLimitsPerShare() internal {
        vm.prank(owner);
        dragonFire.setWhaleLimitsPerPhase(maxWei);
    }
}
