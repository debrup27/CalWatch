// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title StreakTracker
/// @notice Records and retrieves consecutive daily streaks per user.
contract StreakTracker {
    mapping(address => uint256) private lastActionDay;
    mapping(address => uint256) private streak;

    event StreakUpdated(address indexed user, uint256 newStreak);

    /// @dev Returns the current day index since Unix epoch.
    function _currentDay() private view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice Records today’s action and updates the user’s streak.
    function recordAction() external {
        uint256 today = _currentDay();
        uint256 lastDay = lastActionDay[msg.sender];

        if (today == lastDay) {
            // Already recorded today → no change
            return;
        } else if (today == lastDay + 1) {
            // Consecutive day → increment streak
            streak[msg.sender]++;
        } else {
            // Gap detected → reset streak
            streak[msg.sender] = 1;
        }

        lastActionDay[msg.sender] = today;
        emit StreakUpdated(msg.sender, streak[msg.sender]);
    }

    /// @notice Returns the current streak of `user`.
    function getStreak(address user) external view returns (uint256) {
        return streak[user];
    }

    /// @notice Returns the last day index on which `user` recorded an action.
    function getLastActionDay(address user) external view returns (uint256) {
        return lastActionDay[user];
    }
}
