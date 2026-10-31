# Verified results and evidence boundaries

Private originals are retained locally: 26 files for Block 1, 22 for Block 2, 11 for Block 3, and 15 screenshots plus an index and final cleanup text record for Block 4. They are excluded from this public package because they contain account identifiers, email details and raw portal context.

## Block 1 — Metrics and notifications

Portal configuration, CLI readbacks and Bicep deployment lab07-block1-monitoring succeeded. The metric was Percentage CPU, Average, GreaterThan 40, PT5M window, PT1M evaluation, severity 2, enabled and auto-resolving. A bounded two-process 480-second load exercised the two-vCPU VM. Fired and Resolved were observed. After recipient verification, a subsequent real CPU alert delivered a Fired/Sev2 email. A sample notification API failure is documented separately from the working real alert path. Post-adoption settings and Verified recipient status passed. Dedicated group absence returned false on October 26.

## Block 2 — Logs and KQL

Workspace PerGB2018, retention 30 days, daily quota 0.1 GB. AMA handler configuration was 1.6; Heartbeat reported installed agent software 1.45.1. Final DCR JSON contained only local0 and Info/Notice/Warning/Error/Critical/Alert/Emergency, with one workspace destination and VM association. KQL returned controlled messages; summarize and 5-minute bin grouping passed. Bicep lab07-block2-collection succeeded. New LAB07_POST_BICEP info/warning/error records arrived after adoption; debug and local1 warning controls did not appear in the filtered result. This bounded check is not exhaustive proof of every possible log exclusion. Group absence returned false on October 27.

## Block 3 — Backup and restoration

West US 3 x64 source and LRS Recovery Services vault. Enhanced policy V2, Daily 08:00 UTC, daily retention 7 days, instant snapshots 1 day. First backup completed in 27m20s. Original Version 1 sentinel was backed up, then overwritten with Version 2 and a different hash. Restore created vm-lab07-restored; job completed in 2m13s. Run Command on that resource returned Version 1 and the original SHA-256. Guest hostname remained the source hostname. This proves the specific file recovery, not full application consistency or application recovery.

Bicep lab07-block3-backup succeeded. Readback confirmed policy settings, Protected/Healthy and LastBackup Completed. The dedicated resource group was removed. An external collection in AzureBackupRG_westus3_1 required revoking an outstanding disk-restore-point access grant before deletion. Final resource inventory there was empty; the empty group itself was not claimed deleted. Service-retained soft-deleted vault data followed its retention period.

## Block 4 — Site Recovery drill

Fresh Bicep baseline deployment lab07-block4-baseline succeeded. Actual source: Ubuntu 22.04.5 x86_64, kernel 6.8.0-1070-azure, Standard_D2s_v4, West US 3, private IP 10.70.1.4. The source sentinel hash was:

```text
51a55aebb76fd1af39e4b487db648a5983e2619e237d62b6375ef1e53fd88806
```

East US was rejected by the subscription region policy. Belgium Central SKU restrictions were empty and DSv4/regional quotas had space for the test VM. Portal ASR configuration used Standard SSD, normal churn, manual updates and a 24-hour recovery-point retention policy. This retention setting is not a once-per-day replication schedule.

Both Site Recovery extensions provisioned successfully. ASR agent 9.68.7950.1 was Healthy. Synchronization advanced from 0% to 46%, then waiting for first point, then Protected/Healthy. A retained capture displayed RPO 5 minutes; another displayed 2 minutes. Overall ARM deployment remained Failed because a nested Automation job referenced a missing account. Do not treat partial ARM success as total deployment success.

The isolated test VNet was in Belgium Central, 10.72.0.0/16, snet-test 10.72.0.0/24, no peering configured. Latest processed recovery point was selected for the drill. All four test failover job tasks succeeded in approximately 2m20s. Run Command on Azure resource vm-lab07-asr-test returned the Version 1 sentinel and exactly the original SHA-256. This verifies boot and one recovered file; it does not measure a complete application RTO.

Test failover cleanup succeeded. Replicated-item removal succeeded. Five inventoried lab groups were removed, after which filtered group inventory showed only Site-recovery-vault-RG-1. The final az group exists check for that group returned false. Together these checks establish absence of the six inventoried lab groups. They do not assert absence of unrelated subscription resources, later charges or service-retained deleted data.
