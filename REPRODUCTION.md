# Reproduction guide — Windows CMD and Azure Portal

These are independently cleaned-up exercises. Blocks 1–3 adopt existing resources; they are not standalone VM deployment templates. Block 4 creates the source baseline only. The guide records the successful path and troubleshooting boundaries; future region policies, image versions and capacity must be checked again.

## Preflight and parameters

Use a dedicated subscription context and dedicated lab groups. Examples use the subscription display name Azure for Students. Supply your own verified recipient and public SSH key; never commit private keys, email addresses or local parameter files.

```cmd
az account show --subscription "Azure for Students" --query "{Name:name,State:state}" --output json
```

Before VM creation or failover, inspect the subscription's Allowed resource deployment regions policy, the exact SKU restrictions and regional/family quotas. The historical successful ASR pair was West US 3 to Belgium Central; East US was denied despite an eligible SKU and available quota. Resource-group metadata location does not override each resource's own location.

## Common Bicep workflow

From the repository root, use the chosen template path. For each block: validate, inspect what-if, then create in Incremental mode. Compilation alone is not proof of Azure deployability. Omitted resources remain outside a targeted incremental template's management scope; Ignore does not mean deleted.

### Block 1 — Metric alert

Prerequisite: private Linux VM vm-lab07-monitor in dedicated rg-hn-az104-lab07-monitoring, Central US, two vCPUs. In the portal, first configure the alert/action group with the settings in README and verify the recipient. For adoption, preserve the exact existing receiver name:

```cmd
for /f "delims=" %E in ('az monitor action-group show --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --name ag-lab07-email --query "emailReceivers[0].emailAddress" --output tsv') do @set "LAB07_EMAIL=%E"
for /f "delims=" %N in ('az monitor action-group show --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --name ag-lab07-email --query "emailReceivers[0].name" --output tsv') do @set "LAB07_RECEIVER=%N"
az deployment group validate --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --template-file bicep/block1.bicep --parameters notificationEmail="%LAB07_EMAIL%" emailReceiverName="%LAB07_RECEIVER%"
az deployment group what-if --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --template-file bicep/block1.bicep --parameters notificationEmail="%LAB07_EMAIL%" emailReceiverName="%LAB07_RECEIVER%"
az deployment group create --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --name lab07-block1-monitoring --mode Incremental --template-file bicep/block1.bicep --parameters notificationEmail="%LAB07_EMAIL%" emailReceiverName="%LAB07_RECEIVER%"
```

Use %%E and %%N in a batch file. Check values loaded successfully before deployment. Clear environment variables when finished. Secure email input is still stored in the action-group resource; it is not made public by this repository.

In the VM's Portal Run Command / RunShellScript, use the following bounded load on the two-vCPU lab VM:

```sh
echo "CPU test started: $(date -u)"
timeout 480s yes > /dev/null &
timeout 480s yes > /dev/null &
wait
echo "CPU test finished: $(date -u)"
```

Do not run this in Cloud Shell: that would load the Cloud Shell machine rather than the monitored VM. Inspect metric data, actual Fired/Resolved transitions and the real email. Unsupported sample notification tests are not a prerequisite. After adoption, reread alert/receiver settings and verification status.

### Block 2 — AMA, DCR and KQL

Prerequisite: recreate the dedicated VM/group after Block 1 cleanup. Enable its system-assigned identity. Create the Log Analytics workspace and Syslog DCR through the portal, associate vm-lab07-monitor and install AMA. Use local0 Info and higher; set all other facilities to None. Select the workspace as destination. Read the persisted DCR JSON; checkboxes in the editor do not represent enabled collection.

The model preserves the original source/destination names. For another environment, read them back and pass syslogSourceName, destinationName and associationName if different.

```cmd
az deployment group validate --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --template-file bicep/block2.bicep
az deployment group what-if --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --template-file bicep/block2.bicep
az deployment group create --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --name lab07-block2-collection --mode Incremental --template-file bicep/block2.bicep
az vm run-command invoke --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --name vm-lab07-monitor --command-id RunShellScript --scripts @scripts/generate-syslog.sh --query "value[].message" --output tsv
```

Allow agent/configuration propagation, then run the three queries under queries/ in the workspace Logs KQL editor. Expect Heartbeat plus info/warning/error markers; the controlled debug and local1 markers should not appear. Inspect configuration as well as results. The 0.1 GB daily cap can be exceeded before collection stops; it is not a guaranteed spending limit.

### Block 3 — Backup and restore

Prerequisites: dedicated group, supported x64 VM vm-lab07-backup and LRS Recovery Services vault rsv-hn-az104-lab07-wus3 in West US 3. This vault/VM pair is referenced, not created, by block3.bicep. Confirm current Backup support for the selected OS, security settings and disks.

1. Create /home/azureuser/lab07-backup/recovery-test.txt with known Version 1 content through VM Run Command; retain its SHA-256.
2. Configure Enhanced VM backup, Daily 08:00 UTC, 7-day daily retention, 1-day instant snapshot retention.
3. Run Backup now. Wait for Completed and a recovery point before changing the file.
4. Overwrite only the lab sentinel with Version 2; verify its different hash.
5. Restore the original point as a new VM, vm-lab07-restored. Select a dedicated staging StorageV2 Standard LRS account in the restore region and the dedicated VNet/subnet.
6. Wait for restore completion. Run cat and sha256sum on the new Azure resource; require Version 1 and the original hash. The guest hostname may still equal the source hostname.

Read the existing policy schedule before adoption; pass scheduleTime if its anchor differs from the template's historical 2026-10-29T08:00:00Z.

```cmd
az deployment group validate --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --template-file bicep/block3.bicep
az deployment group what-if --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --template-file bicep/block3.bicep
az deployment group create --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-monitoring --name lab07-block3-backup --mode Incremental --template-file bicep/block3.bicep
```

Read back the policy and protected item after adoption. Azure-managed health/status fields can create preview noise; do not copy read-only fields into desired state to silence it.

### Block 4 — Source baseline and Site Recovery

Create a public RSA key locally if needed. Do not overwrite a key you still use. Load only the .pub file into CMD; the private key never enters Bicep:

```cmd
for /f "usebackq delims=" %K in ("%USERPROFILE%\.ssh\lab07-asr.pub") do @set "LAB07_SSH_ASR=%K"
az group create --subscription "Azure for Students" --name rg-hn-az104-lab07-recovery --location westus3 --tags Environment=Training Lab=Lab07 Project=AZ104 Owner=Hilaire
az deployment group validate --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-recovery --template-file bicep/block4-baseline.bicep --parameters sshPublicKey="%LAB07_SSH_ASR%"
az deployment group what-if --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-recovery --template-file bicep/block4-baseline.bicep --parameters sshPublicKey="%LAB07_SSH_ASR%"
az deployment group create --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-recovery --name lab07-block4-baseline --mode Incremental --template-file bicep/block4-baseline.bicep --parameters sshPublicKey="%LAB07_SSH_ASR%"
az vm run-command invoke --subscription "Azure for Students" --resource-group rg-hn-az104-lab07-recovery --name vm-lab07-asr --command-id RunShellScript --scripts @scripts/prepare-asr-source.sh --query "value[].message" --output tsv
```

Retain the actual OS/kernel and sentinel hash. The script creates/overwrites the Version 1 sentinel; run it before replication, not as a verification step after recovery. HTTPS 200 from login and 400 from the ARM root were preliminary transport observations, not full replication endpoint validation. Inspect current ASR support and service prerequisite checks.

Portal workflow used after baseline creation:

1. VM > Disaster recovery: select Belgium Central as destination after region/SKU/quota preflight. The historical Bicep output eastus is not the successful target.
2. Review target RG/VNet, Standard SSD replica, normal churn, Standard LRS cache, destination Recovery Services vault and 24-hour retention policy. Select manual Mobility service updates.
3. Start replication and inspect both ARM deployment operations and Site Recovery jobs. In this run an Automation job failed on an absent parent account, while the actual replication continued. Do not blindly retry an entire deployment or assume all future failures are harmless.
4. Wait for Protected/Healthy, agent health and a recovery point; the initial copy and first point take time.
5. Create vnet-lab07-asr-test in Belgium Central: 10.72.0.0/16, snet-test 10.72.0.0/24, no peering. The observed subnet was private. VM Run Command successfully returned the sentinel during this drill; do not generalize this to arbitrary isolated network configurations without agent connectivity checks.
6. Test Failover: Latest processed, select the test VNet. Wait for all tasks to succeed; do not initiate production Failover.
7. Open vm-lab07-asr-test and run hostname, cat and sha256sum for the sentinel using Run Command. Require the original content/hash before cleanup. scripts/verify-asr-sentinel.sh automates that comparison with the recorded lab content.
8. Cleanup test failover, record observations and confirm testing complete. Wait for success.
9. Disable Replication and wait for replicated-item removal to succeed.

The test job duration is not the application's RTO. RPO describes recoverable data lag; RTO is a recovery-time objective. This exercise did not test real regional outage detection, production traffic redirection, failback or a multi-VM recovery plan.

## Cleanup and final verification

Inventory before deleting anything. Restrict deletion to dedicated lab resources; do not delete shared NetworkWatcherRG or other unrelated groups.

- Blocks 1–2: remove the dedicated group after evidence collection; confirm az group exists returns false.
- Block 3: stop backup with Delete backup data, handle vault dependencies using the portal, remove restored/source VMs, staging storage and dedicated groups. Respect service-enforced soft deletion. Inspect external AzureBackupRG resources; delete only resources identified as belonging to the lab. An active disk restore-point SAS grant required endGetAccess before deletion in this run. Do not log the SAS URL.
- Block 4: clean up the drill and remove replication before deleting source/target resources. Inventory groups from failed attempts as well. The observed six groups were vm-lab07-backup_group, rg-hn-az104-lab07-recovery, Site-recovery-vault-RG, RG-HN-AZ104-LAB07-RECOVERY-asr, Site-recovery-vault-RG-1 and RG-HN-AZ104-LAB07-RECOVERY-asr-1. These names are historical, not a universal deletion list.

If a vault blocks deletion, read the actual dependency error and remove the indicated lab associations. Do not disable security controls or purge retained data simply to force a successful command. Final resource-group absence confirms that scope; it is not a subscription-wide zero-cost assertion.
