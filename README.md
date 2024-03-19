# servarr
 
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | >= 4.9.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 4.9.0 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_access_application.servarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_policy.service_servarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_servarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_service_token.github_actions](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_service_token) | resource |
| [cloudflare_record.plex_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.servarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_ruleset.bots_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_ruleset.cache_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_tunnel.servarr_tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel) | resource |
| [cloudflare_tunnel_config.servarr_tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel_config) | resource |
| [cloudflare_zone_dnssec.example](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_dnssec) | resource |
| [cloudflare_zone_settings_override.nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_settings_override) | resource |
| [github_actions_secret.servar_tunnel_token](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.service_token_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.ssh_private_key_value](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.ssh_username](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.service_token_id](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_host](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_port](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_private_key_filename](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [random_password.servarr_tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [cloudflare_zone.nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account identifier, the basic resource for working with Cloudflare zones, teams and users | `string` | n/a | yes |
| <a name="input_cloudflare_api_token"></a> [cloudflare\_api\_token](#input\_cloudflare\_api\_token) | Token for Terraform provider to work with the Cloudflare API | `string` | n/a | yes |
| <a name="input_github_access_token"></a> [github\_access\_token](#input\_github\_access\_token) | Personal access token for Terraform provider to act on user behalf | `string` | n/a | yes |
| <a name="input_ssh_host"></a> [ssh\_host](#input\_ssh\_host) | The hostname of the server | `string` | n/a | yes |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | The SSH port of the server | `number` | n/a | yes |
| <a name="input_ssh_private_key_filename"></a> [ssh\_private\_key\_filename](#input\_ssh\_private\_key\_filename) | The filename of the private key used for authentication | `string` | n/a | yes |
| <a name="input_ssh_private_key_value"></a> [ssh\_private\_key\_value](#input\_ssh\_private\_key\_value) | The value of the private key used for authentication. Use '<br>' to escape new lines. | `string` | n/a | yes |
| <a name="input_ssh_username"></a> [ssh\_username](#input\_ssh\_username) | The username used for authentication | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | The DNS zone name | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | The zone identifier, the basic resource for working with Cloudflare and is roughly equivalent to a domain name that the user purchases. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
