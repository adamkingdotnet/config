output "zone_id" {
  value       = cloudflare_zone.this.id
  description = "The managed zone's ID (consume as module.site.zone_id in DNS/redirect resources)."
}
