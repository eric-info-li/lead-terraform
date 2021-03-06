terraform {
  backend "local" {}
}

provider "kubernetes" {
  alias            = "staging"
  load_config_file = var.load_config_file
  config_context   = var.config_context
}

provider "helm" {
  alias   = "staging"
  version = "1.1.1"

  kubernetes {
    load_config_file = var.load_config_file
    config_context   = var.config_context
  }
}

module "staging_namespace" {
  source      = "../../modules/common/namespace"
  namespace   = "${var.product_name}-staging"
  labels      = {
    "istio-injection"                        = "enabled"
    "appmesh.k8s.aws/sidecarInjectorWebhook" = "enabled"
  }
  annotations = {
    name                                 = "${var.product_name}-staging"
    "opa.lead.liatrio/ingress-whitelist" = "*.${var.product_name}-staging.${var.cluster_domain}"
    "opa.lead.liatrio/image-whitelist"   = var.image_whitelist
  }
  providers   = {
    helm       = helm.staging
    kubernetes = kubernetes.staging
  }
}

resource "kubernetes_pod" "nginx" {
  provider = kubernetes.staging

  metadata {
    name      = "nginx"
    namespace = module.staging_namespace.name
  }
  spec {
    container {
      name  = "nginx"
      image = "nginx:latest"
    }
  }
}
