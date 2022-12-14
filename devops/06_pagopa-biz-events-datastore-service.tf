variable "pagopa-biz-events-datastore-service" {
  default = {
    repository = {
      organization    = "pagopa"
      name            = "pagopa-biz-events-datastore"
      branch_name     = "refs/heads/main"
      pipelines_path  = ".devops"
      yml_prefix_name = null
    }
    pipeline = {
      enable_code_review = true
      enable_deploy      = true
      sonarcloud = {
        # TODO azure devops terraform provider does not support SonarCloud service endpoint
        service_connection = "SONARCLOUD-SERVICE-CONN"
        org                = "pagopa"
        project_key        = "pagopa_pagopa-biz-events-datastore"
        project_name       = "pagopa-biz-events-datastore"
      }
      performance_test = {
        enabled               = true
        name                  = "performance-test-pipeline"
        pipeline_yml_filename = "performance-test-pipelines.yml"
      }
    }
  }
}

locals {
  # global vars
  pagopa-biz-events-datastore-service-variables = {
    cache_version_id = "v1"
    default_branch   = var.pagopa-biz-events-datastore-service.repository.branch_name
  }
  # global secrets
  pagopa-biz-events-datastore-service-variables_secret = {

  }
  # code_review vars
  pagopa-biz-events-datastore-service-variables_code_review = {
    danger_github_api_token = "skip"
    sonarcloud_service_conn = var.pagopa-biz-events-datastore-service.pipeline.sonarcloud.service_connection
    sonarcloud_org          = var.pagopa-biz-events-datastore-service.pipeline.sonarcloud.org
    sonarcloud_project_key  = var.pagopa-biz-events-datastore-service.pipeline.sonarcloud.project_key
    sonarcloud_project_name = var.pagopa-biz-events-datastore-service.pipeline.sonarcloud.project_name

    dev_container_registry_service_conn = data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_acr_aks_dev_id

  }
  # code_review secrets
  pagopa-biz-events-datastore-service-variables_secret_code_review = {
  }
  # deploy vars
  pagopa-biz-events-datastore-service-variables_deploy = {
    git_mail          = module.secrets.values["azure-devops-github-EMAIL"].value
    git_username      = module.secrets.values["azure-devops-github-USERNAME"].value
    github_connection = data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_github_rw_name
    tenant_id         = module.secrets.values["TENANTID"].value

    # acr section
    image_repository_name                = replace(var.pagopa-biz-events-datastore-service.repository.name, "-", "")
    dev_container_registry_service_conn  = data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_acr_aks_dev_id
    uat_container_registry_service_conn  = data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_acr_aks_uat_id
    prod_container_registry_service_conn = data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_acr_aks_prod_id

    # aks section
    k8s_namespace               = "bizevents"
    dev_kubernetes_service_conn = azuredevops_serviceendpoint_kubernetes.aks_dev.id
    uat_kubernetes_service_conn = azuredevops_serviceendpoint_kubernetes.aks_uat.id
    #    prod_kubernetes_service_conn = azuredevops_serviceendpoint_kubernetes.aks_prod.id

    dev_container_namespace  = "pagopadcommonacr.azurecr.io"
    uat_container_namespace  = "pagopaucommonacr.azurecr.io"
    prod_container_namespace = "pagopapcommonacr.azurecr.io"

    TF_APPINSIGHTS_SERVICE_CONN_DEV = module.DEV-APPINSIGHTS-SERVICE-CONN.service_endpoint_name
    TF_APPINSIGHTS_RESOURCE_ID_DEV  = data.azurerm_application_insights.application_insights_dev.id

    TF_APPINSIGHTS_SERVICE_CONN_UAT = module.UAT-APPINSIGHTS-SERVICE-CONN.service_endpoint_name
    TF_APPINSIGHTS_RESOURCE_ID_UAT  = data.azurerm_application_insights.application_insights_uat.id

    #    TF_APPINSIGHTS_SERVICE_CONN_PROD = module.PROD-APPINSIGHTS-SERVICE-CONN.service_endpoint_name
    #    TF_APPINSIGHTS_RESOURCE_ID_PROD  = data.azurerm_application_insights.application_insights_prod.id
  }
  # deploy secrets
  pagopa-biz-events-datastore-service-variables_secret_deploy = {
  }
  # integration vars
  pagopa-biz-events-datastore-variables_integration_test = {
  }
  # integration secrets
  pagopa-biz-events-datastore-variables_secret_integration_test = {
    DEV_COSMOS_DB_PRIMARY_KEY = module.bizevents_dev_secrets.values["cosmos-d-biz-key"].value
    DEV_EHUB_TX_PRIMARY_KEY   = module.bizevents_dev_secrets.values["ehub-tx-d-biz-key"].value

    UAT_COSMOS_DB_PRIMARY_KEY = module.bizevents_uat_secrets.values["cosmos-u-biz-key"].value
    UAT_EHUB_TX_PRIMARY_KEY   = module.bizevents_uat_secrets.values["ehub-tx-u-biz-key"].value
  }
  # performance vars
  pagopa-biz-events-datastore-variables_performance_test = {
  }
  # performance secrets
  pagopa-biz-events-datastore-variables_secret_performance_test = {
    DEV_COSMOS_DB_PRIMARY_KEY = module.bizevents_dev_secrets.values["cosmos-d-biz-key"].value
    DEV_EHUB_TX_PRIMARY_KEY   = module.bizevents_dev_secrets.values["ehub-tx-d-biz-key"].value

    UAT_COSMOS_DB_PRIMARY_KEY = module.bizevents_uat_secrets.values["cosmos-u-biz-key"].value
    UAT_EHUB_TX_PRIMARY_KEY   = module.bizevents_uat_secrets.values["ehub-tx-u-biz-key"].value
  }
}

module "pagopa-biz-events-datastore-service_performance_test" {
  source = "git::https://github.com/pagopa/azuredevops-tf-modules.git//azuredevops_build_definition_generic?ref=v2.6.3"
  count  = var.pagopa-biz-events-datastore-service.pipeline.performance_test.enabled == true ? 1 : 0

  project_id                   = data.azuredevops_project.project.id
  repository                   = var.pagopa-biz-events-datastore-service.repository
  github_service_connection_id = data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_github_ro_id
  path                         = "${local.domain}\\pagopa-biz-events-datastore-service"
  pipeline_name                = var.pagopa-biz-events-datastore-service.pipeline.performance_test.name
  pipeline_yml_filename        = var.pagopa-biz-events-datastore-service.pipeline.performance_test.pipeline_yml_filename

  variables = merge(
    local.pagopa-biz-events-datastore-service-variables,
    local.pagopa-biz-events-datastore-variables_performance_test,
  )

  variables_secret = merge(
    local.pagopa-biz-events-datastore-service-variables_secret,
    local.pagopa-biz-events-datastore-variables_secret_performance_test,
  )

  service_connection_ids_authorization = [
    data.terraform_remote_state.app.outputs.service_endpoint_azure_devops_github_ro_id,
  ]
}
