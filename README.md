# msgraph-poll-discourse-plugin
Discourse plugin to enable polling emails usign Microsoft Graph API

## Prerequisites

- Have an application on your Azure Tenant with delegated permissions for `Mail.ReadWrite`.
- Get a refresh token for the application with permissions to the mailbox used for the poll feature.

## Get the refresh token

The easiest way to get a refresh token is to use the Device Code authorization flow (<https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-device-code>).

```bash
TENANT_ID="<TENANT_ID>"
CLIENT_ID="<CLIENT_ID>"

curl --request POST \
  --url https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/devicecode \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data client_id=${CLIENT_ID} \
  --data 'scope=mail.readwrite offline_access'
```

This request returns a JSON, from this we need the `user_code` and the `device_code`.
Open <https://microsoft.com/devicelogin> and login with the mailbox you want to use for the poll feature, inserting the `user_code` when requested.

After the login is successful:

```bash
curl --request POST \
  --url https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data grant_type=urn:ietf:params:oauth:grant-type:device_code \
  --data client_id=${CLIENT_ID} \
  --data device_code=<device_code from the earlier JSON response>
```

This request returns a JSON with the `refresh_token`.

## SiteSettings

It is possible to configure this plugin using the following SiteSettings:

- `msgraph_polling_enabled`: `true` if the plugin is enabled
- `msgraph_polling_mailbox`: the mailbox to use for the poll feature. It has to be the same you've used to retrieve when retrieving refresh token
- `msgraph_polling_client_id`: the application id of the Azure application. It has to be the same to the one you've used when retrieving the refresh token
- `msgraph_polling_tenant_id`: the tenant ID of your Azure tenant. It has to be the same to the one you've used when retrieving the refresh token
- `msgraph_polling_oauth2_refresh_token`: the refresh token previously generated.

The polling period is the same to the pop3 polling feature present in Discourse core.

## Install

Follow the official guide from Discourse: <https://meta.discourse.org/t/install-plugins-in-discourse/19157>
