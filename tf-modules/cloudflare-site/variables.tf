variable "account_id" {
  type        = string
  description = "Cloudflare account ID"
}

variable "zone_name" {
  type        = string
  description = "Zone / apex domain (e.g. example.com)"
}

variable "worker_name" {
  type        = string
  description = "Worker service name the custom domains attach to"
}

variable "create_www" {
  type        = bool
  default     = true
  description = "Attach www.<zone_name> to the worker"
}

variable "worker_environment" {
  type        = string
  default     = "production"
  description = "Worker environment for the custom-domain attachments"
}

variable "extra_worker_hostnames" {
  type        = list(string)
  default     = []
  description = "Extra subdomain labels attached as worker custom domains, e.g. [\"form\"] -> form.<zone_name>"
}

variable "extra_zone_settings" {
  type        = map(string)
  default     = {}
  description = "Additional cloudflare_zone_setting entries as setting_id => value, e.g. { http3 = \"off\" }"
}
