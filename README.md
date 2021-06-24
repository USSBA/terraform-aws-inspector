# terraform-aws-inspector

A terraform module to deploy [Amazon Inspector](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_introduction.html)

## Prerequisites

* Amazon Inspector Agent [installed](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_installing-uninstalling-agents.html#install-linux) on desired EC2 instances.
* Amazon Inspector [Region-Specific ARNs](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html) for rules packages.

## Usage

Module version 3.1 supports Terraform 0.13 up to (but not including) 1.0 (which is yet to be released at the). Module version 1.x supports Terraform 0.12.

Note: this module currently does not support the customization of assessment targets. All EC2 instances with the AWS Inspector agent installed will be included on an assessment.

### Variables

#### Required

* `name_prefix` - Used as a prefix for resources created in AWS.

#### Optional

* `enable_scheduled_event` - Default `true`; A way to disable Inspector from running on a schedule
* `schedule_expression` - Default `rate(7 days)`; How often to run an Inspector assessment. See [AWS Schedule Expression documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html) for more info on formatting.s
* `assessment_duration` - Default `3600`; How long the assessment runs in seconds.
* `ruleset_cve` - Default `true`; Includes the Common Vulnerabilties and Exposures [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rule-packages.html) in the Inspector assessment.
* `ruleset_cis` - Default `true`; Includes the CIS Benchmarks [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rule-packages.html) in the Inspector assessment.
* `ruleset_security_best_practices` - Default `true`; Includes the AWS Security Best Practices [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rule-packages.html) in the Inspector assessment.
* `ruleset_network_reachability` - Default `true`; Includes the Network Reachability [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rule-packages.html) in the Inspector assessment.
* `ruleset_cve_arn` - Default `arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7`; ARN for Common Vulnerabilities and Exposures [Ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html)
* `ruleset_cis_arn` - Default `arn:aws:inspector:us-east-1:316112463485:rulespackage/0-rExsr2X8`; ARN for CIS Operating System Security Configuration Benchmarks [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html)
* `ruleset_network_reachability_arn` - Default `arn:aws:inspector:us-east-1:316112463485:rulespackage/0-PmNV0Tcd`; ARN for AWS Network Reachability [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html)
* `ruleset_security_best_practices_arn` - Default `arn:aws:inspector:us-east-1:316112463485:rulespackage/0-R01qwB5Q`; ARN for AWS Security Best Practices [ruleset](https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html)

### Simple Example

It doesn't take much to get off the ground with this module. All you need to get started scanning is this:

```terraform
module "my-inspector-deployment" {
  source      = "USSBA/inspector/aws"
  version     = "~> 2.0"
  name_prefix = "my-inspector"
}
```

### Complex Example

An example showing a customized schedule and rulesets:

```terraform
module "my-inspector-deployment" {
  source                          = "USSBA/inspector/aws"
  version                         = "~> 3.0"
  name_prefix                     = "my-inspector"
  enable_scheduled_event          = true
  schedule_expression             = "cron(0 14 * * ? *)"
  ruleset_cve                     = true
  ruleset_cis                     = false
  ruleset_security_best_practices = true
  ruleset_network_reachability    = false
}
```
An example showcasing the ability to pass ruleset ARN's for use in `eu-west-1` region.

```terraform
module "my-inspector-deployment" {
  source                              = "USSBA/inspector/aws"
  version                             = "~> 3.0"
  name_prefix                         = "my-inspector"
  ruleset_cis_arn                     = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-sJBhCr0F"
  ruleset_cve_arn                     = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-ubA5XvBh"
  ruleset_network_reachability_arn    = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SPzU33xe"
  ruleset_security_best_practices_arn = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SnojL3Z6"
}
```

## Contributing

We welcome contributions.
To contribute please read our [CONTRIBUTING](CONTRIBUTING.md) document.

All contributions are subject to the license and in no way imply compensation for contributions.

### Terraform 0.12

Our code base now exists in Terraform 0.13 and we are halting new features in the Terraform 0.12 major version.  If you wish to make a PR or merge upstream changes back into 0.12, please submit a PR to the `terraform-0.12` branch.

## Code of Conduct

We strive for a welcoming and inclusive environment for all SBA projects.

Please follow this guidelines in all interactions:

* Be Respectful: use welcoming and inclusive language.
* Assume best intentions: seek to understand other's opinions.

## Security Policy

Please do not submit an issue on GitHub for a security vulnerability.
Instead, contact the development team through [HQVulnerabilityManagement](mailto:HQVulnerabilityManagement@sba.gov).
Be sure to include **all** pertinent information.

The agency reserves the right to change this policy at any time.
