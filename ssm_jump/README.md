# SSM jump host module

Deploys a small EC2 instance in a private subnet that can reach resources in your VPC (e.g. RDS). The instance has **no public IP** and **no SSH**; you connect from your laptop using **AWS Systems Manager (SSM) port forwarding**. Useful for secure access to Aurora/RDS or other private services from tools like Postico, DBeaver, or `psql`.

## How it works

- The instance runs Amazon Linux 2023 with the SSM agent and uses the `AmazonSSMManagedInstanceCore` IAM policy.
- It must be able to reach SSM endpoints: either via **VPC interface endpoints** (ssm, ssmmessages, ec2messages) in your VPC, or via **NAT** (internet egress).
- From your machine you run `aws ssm start-session` with the port-forwarding document: local port → jump host → RDS (or other target). Your DB client then connects to `127.0.0.1:<local_port>`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | `"ssm-jump"` | Prefix for resource names (e.g. project name). Final name is `{name}-{workspace}-ssm-jump`. |
| `subnet_id` | `string` | (required) | Subnet for the instance (e.g. private app subnet). Must have route to SSM (VPC endpoints or NAT). |
| `security_group_ids` | `list(string)` | (required) | Security groups for the instance. Must allow outbound to SSM (and to the DB if used for port forwarding). |
| `tags` | `map(string)` | `{}` | Tags applied to all resources. |
| `instance_type` | `string` | `"t3.nano"` | EC2 instance type. |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID. Use with `aws ssm start-session --target <id> --document-name AWS-StartPortForwardingSessionToRemoteHost ...` for port forwarding. |

## Usage example

```hcl
module "ssm_jump" {
  source = "git@github.com:jihoun/terraform.git//ssm_jump"

  name               = "robert"
  subnet_id          = module.network.app_subnet_ids[0]
  security_group_ids = module.network.app_security_group_ids
  tags               = local.tags
}

output "ssm_jump_instance_id" {
  value = module.ssm_jump.instance_id
}
```

Then from your laptop (with AWS CLI and [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) installed):

```bash
aws ssm start-session \
  --target "$(terraform output -raw ssm_jump_instance_id)" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

Connect your DB client to `127.0.0.1:5432` (use 127.0.0.1, not localhost, so the client uses IPv4 and the tunnel).

## Requirements

- **VPC:** The instance must reach SSM. Add VPC interface endpoints for `ssm`, `ssmmessages`, and `ec2messages` (with private DNS enabled), or ensure the subnet has a route to the internet via NAT.
- **Client:** AWS CLI and the Session Manager plugin on your laptop. See the [install guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for macOS, Linux, and Windows.
