// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("StreakTrackerModule", (m) => {
  // Deploy the StreakTracker contract with no constructor arguments
  const streakTracker = m.contract("StreakTracker", []);

  return { streakTracker };
});