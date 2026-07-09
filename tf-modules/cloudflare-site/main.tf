resource "cloudflare_zone" "this" {
  account = {
    id = var.account_id
  }
  name = var.zone_name
  type = "full"
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "extra" {
  for_each   = var.extra_zone_settings
  zone_id    = cloudflare_zone.this.id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_workers_custom_domain" "apex" {
  account_id  = var.account_id
  zone_id     = cloudflare_zone.this.id
  hostname    = var.zone_name
  service     = var.worker_name
  environment = var.worker_environment
}

resource "cloudflare_workers_custom_domain" "www" {
  count       = var.create_www ? 1 : 0
  account_id  = var.account_id
  zone_id     = cloudflare_zone.this.id
  hostname    = "www.${var.zone_name}"
  service     = var.worker_name
  environment = var.worker_environment
}

resource "cloudflare_workers_custom_domain" "extra" {
  for_each    = toset(var.extra_worker_hostnames)
  account_id  = var.account_id
  zone_id     = cloudflare_zone.this.id
  hostname    = "${each.value}.${var.zone_name}"
  service     = var.worker_name
  environment = var.worker_environment
}
