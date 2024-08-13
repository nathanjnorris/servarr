# servarr


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 4.31.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.2.1 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.28.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 4.31.0 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.2.1 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_access_application.bazarr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.bazarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.kopia_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.maintainerr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.maintainerr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.prowlarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.qbittorrent_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.radarr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.radarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.servarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.sonarr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.sonarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_application.tautulli_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_policy.service_bazarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_bazarr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_maintainerr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_maintainerr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_prowlarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_qbittorrent](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_radarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_radarr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_servarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_sonarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_sonarr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.service_tautulli](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_bazarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_bazarr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_kopia](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_maintainerr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_maintainerr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_prowlarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_qbittorrent](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_radarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_radarr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_servarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_sonarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_sonarr4k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_policy.user_tautulli](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_access_service_token.github_actions](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_service_token) | resource |
| [cloudflare_access_service_token.uptime_kuma](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_service_token) | resource |
| [cloudflare_bot_management.bots_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/bot_management) | resource |
| [cloudflare_r2_bucket.bucket-servarr](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket) | resource |
| [cloudflare_record.bazarr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.bazarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.kopia_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.maintainerr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.maintainerr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.overseerr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.plex_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.prowlarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.qbittorrent_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.radarr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.radarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.servarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.sonarr4k_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.sonarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.status_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.tautulli_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.wizarr_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_ruleset.cache_nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_tunnel.servarr_tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel) | resource |
| [cloudflare_tunnel_config.servarr_tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel_config) | resource |
| [cloudflare_zone_dnssec.example](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_dnssec) | resource |
| [cloudflare_zone_settings_override.nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_settings_override) | resource |
| [github_actions_secret.gluetun_preshared_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.gluetun_private_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.kopia_password](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.servar_tunnel_token](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.service_token_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.ssh_private_key_value](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_secret.sudo_password](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.service_token_id](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_host](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_port](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_private_key_filename](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.ssh_username](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [random_password.servarr_tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [cloudflare_zone.nathanjn_com](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account identifier, the basic resource for working with Cloudflare zones, teams and users | `string` | n/a | yes |
| <a name="input_cloudflare_api_token"></a> [cloudflare\_api\_token](#input\_cloudflare\_api\_token) | Token for Terraform provider to work with the Cloudflare API | `string` | n/a | yes |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | Project ID in Google Cloud | `string` | n/a | yes |
| <a name="input_github_access_token"></a> [github\_access\_token](#input\_github\_access\_token) | Personal access token for Terraform provider to act on user behalf | `string` | n/a | yes |
| <a name="input_gluetun_preshared_key"></a> [gluetun\_preshared\_key](#input\_gluetun\_preshared\_key) | The preshared key used for gluetun VPN provider | `string` | n/a | yes |
| <a name="input_gluetun_private_key"></a> [gluetun\_private\_key](#input\_gluetun\_private\_key) | The private key used for gluetun VPN provider | `string` | n/a | yes |
| <a name="input_kopia_password"></a> [kopia\_password](#input\_kopia\_password) | The password used for Kopia | `string` | n/a | yes |
| <a name="input_ssh_host"></a> [ssh\_host](#input\_ssh\_host) | The hostname of the server | `string` | n/a | yes |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | The SSH port of the server | `number` | n/a | yes |
| <a name="input_ssh_private_key_filename"></a> [ssh\_private\_key\_filename](#input\_ssh\_private\_key\_filename) | The filename of the private key used for authentication | `string` | n/a | yes |
| <a name="input_ssh_private_key_value"></a> [ssh\_private\_key\_value](#input\_ssh\_private\_key\_value) | The value of the private key used for authentication | `string` | n/a | yes |
| <a name="input_ssh_username"></a> [ssh\_username](#input\_ssh\_username) | The username used for authentication | `string` | n/a | yes |
| <a name="input_sudo_password"></a> [sudo\_password](#input\_sudo\_password) | The password of the permitted user, to execute a command as the superuser | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_servarr_tunnel_token"></a> [servarr\_tunnel\_token](#output\_servarr\_tunnel\_token) | Token used by a connector to authenticate and run the tunnel. |
<!-- END_TF_DOCS -->
