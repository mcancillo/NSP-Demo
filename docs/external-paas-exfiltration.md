# Exercise: stop PaaS-to-PaaS exfiltration with NSP

This exercise demonstrates a PaaS client **outside** the perimeter attempting to write data to the protected Storage account **inside** the perimeter. The expected result is a network denial at the NSP boundary, before the Storage data-plane operation completes.

## Scenario

```text
External Function App (outside NSP)
        |
        | HTTPS Blob PUT with a short-lived SAS
        v
NSP-demo-storage (inside NSP, association = Enforced)
        |
        +--> NSP access/diagnostic evidence --> NSP-demo-log
```

Use a disposable Consumption-plan Function App or another supported PaaS client in the same region. Do not associate the probe app with the NSP. The probe should have no broad Storage RBAC role; use a short-lived, write-only SAS so the test isolates network enforcement from identity authorization.

## Safety and setup

1. Create a test container named `exfiltration-test` in the deployed Storage account.
2. Generate a short-lived SAS limited to that container and `w`/`c` permissions. Keep it in the Function App configuration or a local secret store; never commit it.
3. Deploy the probe Function App without an NSP association.
4. Confirm the target Storage account is associated with `NSP-demo-profile` in `Enforced` mode.
5. Enable diagnostic settings on the NSP and the Storage account to the `NSP-demo-log` workspace. Discover supported categories first because categories vary by resource/API version:

   ```powershell
   $perimeterId = az resource show `
     --resource-group NSP-Demo-RG `
     --resource-type Microsoft.Network/networkSecurityPerimeters `
     --name NSP-demo-perimeter `
     --query id -o tsv

   az monitor diagnostic-settings categories list --resource $perimeterId
   ```

   In the portal, select the available NSP access/flow or audit categories and send them to `NSP-demo-log`. If the service exposes no access-log category in the target region, use Activity Log plus Storage logs and record that limitation in the lab result.

## Probe code

The probe should attempt a single upload and return the complete HTTP error without retrying:

```python
import os
import requests

account = os.environ["TARGET_STORAGE_ACCOUNT"]
sas = os.environ["TARGET_CONTAINER_SAS"]  # short-lived; do not log this value
blob_url = (
    f"https://{account}.blob.core.windows.net/"
    f"exfiltration-test/probe.txt?{sas.lstrip('?')}"
)

response = requests.put(
    blob_url,
    data=b"controlled NSP exfiltration test\n",
    headers={"x-ms-blob-type": "BlockBlob"},
    timeout=20,
)

print({"status": response.status_code, "request_id": response.headers.get("x-ms-request-id")})
response.raise_for_status()
```

## Run the exercise

### A. Baseline

Temporarily set the Storage association to `Audit` (or remove the association only in a disposable lab copy). Invoke the external probe and verify that the SAS is otherwise valid. The blob should be created. Record:

- Function invocation timestamp and request ID.
- Storage `PutBlob` data-plane log entry.
- Any NSP audit event.

### B. Enforced perimeter

Set the association back to `Enforced` and invoke the same function without changing its code, SAS, or identity. The request should fail at the network boundary. The expected evidence is a denied/blocked NSP event or equivalent diagnostic record, and no successful `PutBlob` data-plane operation.

Do not interpret an HTTP status alone as proof. Correlate the function timestamp, NSP diagnostic record, Storage logs, and the blob's existence.

### C. Exfiltration conclusion

Complete this table:

| Observation | Expected result |
| --- | --- |
| External PaaS client location | Outside NSP |
| Target resource | Storage associated with `NSP-demo-profile` |
| Identity/SAS | Valid but least-privilege and short-lived |
| Association mode | `Audit` permits baseline; `Enforced` blocks |
| Storage object after enforced attempt | Not created |
| NSP evidence | Denied/blocked access record when the category is available |
| Residual controls | RBAC, SAS lifetime, encryption, logging, and alerting still required |

## What this proves

NSP adds a resource-level network boundary around supported PaaS resources. It can prevent a validly authenticated external PaaS workload from reaching a protected resource, which reduces a data-exfiltration path. It does not prove that data is safe by itself: an attacker with an approved path, compromised identity, or an allowed destination can still require RBAC, DLP, application controls, and monitoring.

## Cleanup

Delete the probe Function App, revoke the SAS, remove the test container, and restore the association to the intended demo mode. Keep the core NSP-Demo resources if the environment is being reused.
