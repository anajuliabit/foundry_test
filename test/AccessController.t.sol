// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "../src/protocol/AccessController.sol";
import "../src/domain/BosonConstants.sol";

contract AccessControllerTest is Test {
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    address ADMIN_ADDRESS = 0x04cc783b4505AE7CD7c5568C79220623E4991aa7;
    address RANDOM_ADDRESS = 0x04cC783b4505Ae7cd7C5568C79220623E4991aa8;

    AccessController public accessController;

    function setUp() public {
        accessController = new AccessController();
    }

    function testDeployerHasOnlyAdminRole() public {
        assertEq(accessController.hasRole(ADMIN, address(this)), true);

        bytes32[5] memory roles = [
            PROTOCOL,
            PAUSER,
            CLIENT,
            FEE_COLLECTOR,
            keccak256("RANDOM")
        ];

        for (uint256 i = 0; i < roles.length; i++) {
            assertEq(accessController.hasRole(roles[i], address(this)), false);
        }
    }

    function testAdminRoleIsAdminForAllRoles() public {
        bytes32[5] memory roles = [
            ADMIN,
            PROTOCOL,
            PAUSER,
            CLIENT,
            FEE_COLLECTOR
        ];

        for (uint256 i = 0; i < roles.length; i++) {
            assertEq(accessController.getRoleAdmin(roles[i]), ADMIN);
        }
    }

    function testAnyAdminCanGrantAllOtherRoles() public {
        accessController.grantRole(ADMIN, ADMIN_ADDRESS);
        assertEq(accessController.hasRole(ADMIN, ADMIN_ADDRESS), true);

        vm.startPrank(ADMIN_ADDRESS);

        vm.expectEmit(true, true, true, false);
        emit RoleRevoked(ADMIN, address(this), ADMIN_ADDRESS);
        accessController.revokeRole(ADMIN, address(this));

        bytes32[5] memory roles = [
            ADMIN,
            PROTOCOL,
            PAUSER,
            CLIENT,
            FEE_COLLECTOR
        ];

        for (uint256 i = 0; i < roles.length; i++) {
            accessController.grantRole(roles[i], RANDOM_ADDRESS);
            assertEq(accessController.hasRole(roles[i], RANDOM_ADDRESS), true);
        }

        vm.stopPrank();
    }

    function testAnyAdminCanRevokeAllOtherRoles() public {
        testAnyAdminCanGrantAllOtherRoles();

        vm.startPrank(ADMIN_ADDRESS);
        bytes32[5] memory roles = [
            ADMIN,
            PROTOCOL,
            PAUSER,
            CLIENT,
            FEE_COLLECTOR
        ];

        for (uint256 i = 0; i < roles.length; i++) {
            vm.expectEmit(true, true, true, false);
            emit RoleRevoked(roles[i], RANDOM_ADDRESS, ADMIN_ADDRESS);
            accessController.revokeRole(roles[i], RANDOM_ADDRESS);
            assertEq(accessController.hasRole(roles[i], RANDOM_ADDRESS), false);
        }

        vm.stopPrank();
    }

    function testAnyAddressCanRevokeItsRoles() public {
        testAnyAdminCanGrantAllOtherRoles();

        bytes32[5] memory roles = [
            PROTOCOL,
            PAUSER,
            CLIENT,
            FEE_COLLECTOR,
            ADMIN
        ];

        vm.startPrank(RANDOM_ADDRESS);

        for (uint256 i = 0; i < roles.length; i++) {
            vm.expectEmit(true, true, true, false);
            emit RoleRevoked(roles[i], RANDOM_ADDRESS, RANDOM_ADDRESS);
            accessController.revokeRole(roles[i], RANDOM_ADDRESS);
            assertEq(accessController.hasRole(roles[i], RANDOM_ADDRESS), false);
        }
    }
}
